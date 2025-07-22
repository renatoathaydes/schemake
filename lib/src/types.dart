import 'dart:convert';

import 'package:conveniently/conveniently.dart';
import 'package:schemake/src/validator.dart';

import 'errors.dart';
import 'property.dart';

/// The supertype of all Schemake types.
///
/// A [SchemaType] is also a [Converter] from a Dart value to the target
/// type [T] for the Schemake type.
///
/// The primitive types, like [Strings] and [Ints], attempt to simply _cast_
/// a given value to [String] and [int], respectively. But more complex types
/// like [ObjectsBase] can convert from a [Map] to a Dart class matching the
/// Map data structure.
sealed class SchemaType<T> extends Converter<Object?, T> {
  const SchemaType();

  Type dartType() => T;
}

/// A non-null type.
sealed class NonNull<T> extends SchemaType<T> {
  const NonNull();
}

/// A nullable type.
final class Nullable<S, T extends NonNull<S>> extends SchemaType<S?> {
  final NonNull<S> type;

  const Nullable(this.type);

  @override
  S? convert(Object? input) {
    return input == null ? null : type.convert(input);
  }

  @override
  String toString() {
    return 'schemake.Nullable{$type}';
  }
}

mixin _ConvertNonNullByCasting<T> {
  T convert(Object? input) {
    if (input == null) throw TypeException(T, input);
    return _cast<T>(input);
  }
}

/// The Schemake type matching a Dart [int].
final class Ints extends NonNull<int> with _ConvertNonNullByCasting<int> {
  const Ints();

  @override
  String toString() => 'schemake.Ints';
}

/// The Schemake type matching a Dart [double].
final class Floats extends NonNull<double> {
  const Floats();

  @override
  String toString() => 'schemake.Floats';

  @override
  double convert(Object? input) {
    if (input is num) {
      return input.toDouble();
    }
    throw TypeException(double, input);
  }
}

/// The Schemake type matching a Dart [String].
final class Strings extends NonNull<String>
    with _ConvertNonNullByCasting<String> {
  const Strings();

  @override
  String toString() => 'schemake.Strings';
}

/// The Schemake type matching a Dart [bool].
final class Bools extends NonNull<bool> with _ConvertNonNullByCasting<bool> {
  const Bools();

  @override
  String toString() => 'schemake.Bools';
}

/// The Schemake type matching a Dart [List].
final class Arrays<S, T extends SchemaType<S>> extends NonNull<List<S>> {
  final T itemsType;

  const Arrays(this.itemsType);

  @override
  List<S> convert(Object? input) {
    if (input is Iterable) {
      return input.map((e) => itemsType.convert(e)).toList(growable: false);
    }
    throw TypeException(List<S>, input);
  }

  @override
  String toString() => 'schemake.Arrays{$itemsType}';
}

/// A strategy for dealing with unknown properties in data structures.
/// See [Objects] for details.
enum UnknownPropertiesStrategy { ignore, keep, forbid }

/// The Schemake type matching a Dart [Map], but providing a schema for its
/// entries (similar to a class in languages like Dart and Java).
///
/// For example, an [Objects] type can be defined that matches only Maps that
/// have a key `"name"` of type [Strings].
/// It may define a strategy for dealing with other properties that are not
/// defined in the schema via [UnknownPropertiesStrategy].
/// If [UnknownPropertiesStrategy.ignore] is used, unknown properties are simply
/// ignored (no error is raised, but values are discarded).
/// With [UnknownPropertiesStrategy.keep], unknown properties are kept but their
/// types are not limited in any way (i.e. they are kept as is). This allows
/// defining _semi-structured_ data structures where only some of the properties
/// have a known data type.
/// With [UnknownPropertiesStrategy.forbid], no properties may appear which are
/// not defined by the [Objects.properties]. An error is raised if that happens.
/// This can be used for strictly ensuring the data structure matches the
/// expected schema.
class Objects extends ObjectsBase<Map<String, Object?>> {
  final Map<String, Property<Object?>> properties;

  const Objects(
    super.name,
    this.properties, {
    super.unknownPropertiesStrategy = UnknownPropertiesStrategy.forbid,
    super.description = '',
  });

  @override
  Map<String, Object?> convert(Object? input) {
    if (input == null) throw TypeException(Map<String, Object?>, input);
    return convertToMap(input);
  }

  @override
  Converter<Object?, Object?>? getPropertyConverter(String property) {
    return properties[property]?.type;
  }

  @override
  Iterable<String> getRequiredProperties() {
    return properties.entries
        .where((e) => e.value.type is NonNull)
        .map((e) => e.key);
  }

  @override
  String toString() => 'schemake.Objects{name: $name, '
      'unknownPropertiesStrategy: $unknownPropertiesStrategy, '
      'description: $description, '
      'properties: $properties}';
}

/// A Schemake type matching a Dart [Map] from [String] to some known type [V].
class Maps<V, T extends SchemaType<V>> extends ObjectsBase<Map<String, V>> {
  final T valueType;

  /// The known properties (or keys) of the Map.
  ///
  /// If [unknownPropertiesStrategy] is [UnknownPropertiesStrategy.forbid],
  /// only properties contained in `knownProperties` are allowed.
  /// If [unknownPropertiesStrategy] is [UnknownPropertiesStrategy.ignore],
  /// any properties NOT contained in `knownProperties` are thrown away.
  final Set<String> knownProperties;

  const Maps(
    super.name, {
    required this.valueType,
    super.description = '',
    super.unknownPropertiesStrategy = UnknownPropertiesStrategy.keep,
    this.knownProperties = const {},
  });

  @override
  Map<String, V> convert(Object? input) {
    if (input is Map) {
      final result = <String, V>{};
      for (final entry in input.entries) {
        final name = _cast<String>(entry.key);
        result[name] = convertProperty(valueType, name, input);
      }
      checkRequiredProperties(result.keys);
      return result;
    }
    throw TypeException(Map<String, Object?>, input);
  }

  @override
  Converter<Object?, V>? getPropertyConverter(String property) {
    if (knownProperties.isNotEmpty) {
      return knownProperties.contains(property) ? valueType : null;
    }
    return valueType;
  }

  @override
  Iterable<String> getRequiredProperties() {
    return valueType is Nullable<Object?, Object?> ? const [] : knownProperties;
  }
}

/// A Schemake type matching a Dart [Map] from [String] to any other type.
///
/// Subtypes may impose further limitations. For example, [Maps] enforces that
/// all values must be of the same type, and [Objects] enforces that entries in
/// the [Map] may have certain types.
abstract class ObjectsBase<T> extends NonNull<T> {
  final String name;
  final UnknownPropertiesStrategy unknownPropertiesStrategy;
  final String description;

  const ObjectsBase(
    this.name, {
    this.unknownPropertiesStrategy = UnknownPropertiesStrategy.forbid,
    this.description = '',
  });

  /// Get the [Converter] for the property of this object with the given name.
  Converter<Object?, Object?>? getPropertyConverter(String property);

  /// Get all required (non-nullable, without default values)
  /// properties of this object.
  Iterable<String> getRequiredProperties();

  /// Convert a value to [Map], enforcing any restrictions imposed by this type.
  Map<String, Object?> convertToMap(Object? input) {
    if (input is Map) {
      final result = <String, Object?>{};
      for (final entry in input.entries) {
        final name = _cast<String>(entry.key);
        final converter = getPropertyConverter(name);
        if (converter == null) {
          switch (unknownPropertiesStrategy) {
            case UnknownPropertiesStrategy.ignore:
              break;
            case UnknownPropertiesStrategy.keep:
              result[name] = entry.value;
            case UnknownPropertiesStrategy.forbid:
              throw UnknownPropertyException([name], this);
          }
        } else {
          result[name] = convertProperty(converter, name, input);
        }
      }
      checkRequiredProperties(result.keys);
      return result;
    }
    throw TypeException(Map<String, Object?>, input);
  }

  /// Convert a property to its expected value.
  ///
  /// This method takes care of calling the [Converter] with the appropriate
  /// value from the given map, and error handling.
  V convertProperty<V>(
      Converter<Object?, V> converter, String name, Map<Object?, Object?> map) {
    try {
      return converter.convert(map[name]);
    } on PropertyException catch (e) {
      throw e.prependPath(name);
    } on ToPropertyException catch (e) {
      throw e.toPropertyException(name, this);
    }
  }

  /// Convert a property to its expected value or returns a default value
  /// in case the property is not present.
  ///
  /// This method takes care of calling the [Converter] with the appropriate
  /// value from the given map, and error handling.
  V convertPropertyOrDefault<V>(Converter<Object?, V> converter, String name,
      Map<Object?, Object?> map, V defaultValue) {
    if (!map.containsKey(name)) return defaultValue;
    try {
      return converter.convert(map[name]);
    } on PropertyException catch (e) {
      throw e.prependPath(name);
    } on ToPropertyException catch (e) {
      throw e.toPropertyException(name, this);
    }
  }

  /// Check whether all required properties have been provided, raising a
  /// [MissingPropertyException] if not.
  void checkRequiredProperties(Iterable<String> providedProperties) {
    final missingProperties =
        getRequiredProperties().where(providedProperties.contains.not$);
    if (missingProperties.isNotEmpty) {
      throw MissingPropertyException([], this, missingProperties.toList());
    }
  }
}

/// A validatable Schemake type.
///
/// This can be used to impose further restrictions on values of another
/// Schematype [T]. The restrictions are provided by the associated
/// [Validator].
class Validatable<T> extends NonNull<T> {
  final NonNull<T> type;
  final Validator<T> validator;

  const Validatable(this.type, this.validator);

  @override
  T convert(Object? input) {
    final result = type.convert(input);
    validator.validate(result);
    return result;
  }

  @override
  String toString() {
    return 'schemake.Validatable{type: $type, validator: $validator}';
  }
}

/// A Schemake type that enforces that only certain [String] values may be
/// provided.
class Enums extends Validatable<String> {
  const Enums(EnumValidator validator) : super(const Strings(), validator);
}

T _cast<T>(Object? value) {
  if (value is T) return value;
  throw TypeException(T, value);
}
