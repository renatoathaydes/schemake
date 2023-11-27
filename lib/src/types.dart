import 'dart:convert';

import 'package:conveniently/conveniently.dart';
import 'package:schemake/src/validator.dart';

import 'errors.dart';
import 'property.dart';

sealed class SchemaType<T> extends Converter<Object?, T> {
  const SchemaType();

  Type dartType() => T;
}

sealed class NonNull<T> extends SchemaType<T> {
  const NonNull();
}

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

final class Ints extends NonNull<int> with _ConvertNonNullByCasting<int> {
  const Ints();

  @override
  String toString() => 'schemake.Ints';
}

final class Floats extends NonNull<double>
    with _ConvertNonNullByCasting<double> {
  const Floats();

  @override
  String toString() => 'schemake.Floats';
}

final class Strings extends NonNull<String>
    with _ConvertNonNullByCasting<String> {
  const Strings();

  @override
  String toString() => 'schemake.Strings';
}

final class Bools extends NonNull<bool> with _ConvertNonNullByCasting<bool> {
  const Bools();

  @override
  String toString() => 'schemake.Bools';
}

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

class Objects extends ObjectsBase<Map<String, Object?>> {
  final Map<String, Property<Object?>> properties;

  const Objects(
    super.name,
    this.properties, {
    super.ignoreUnknownProperties = false,
    super.location = const [],
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
  String toString() => 'schemake.Objects{$properties}';
}

class Maps<V, T extends NonNull<V>> extends ObjectsBase<Map<String, V>> {
  final T valueType;

  const Maps(super.name,
      {required this.valueType,
      super.location = const [],
      super.description = ''});

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
  Converter<Object?, V> getPropertyConverter(String property) {
    return valueType;
  }

  @override
  Iterable<String> getRequiredProperties() {
    return const [];
  }
}

abstract class ObjectsBase<T> extends NonNull<T> {
  final String name;
  final bool ignoreUnknownProperties;
  final List<String> location;
  final String description;

  const ObjectsBase(
    this.name, {
    this.ignoreUnknownProperties = false,
    this.location = const [],
    this.description = '',
  });

  Converter<Object?, Object?>? getPropertyConverter(String property);

  Iterable<String> getRequiredProperties();

  Map<String, Object?> convertToMap(Object? input) {
    if (input is Map) {
      final result = <String, Object?>{};
      for (final entry in input.entries) {
        final name = _cast<String>(entry.key);
        final converter = getPropertyConverter(name);
        if (converter == null) {
          if (ignoreUnknownProperties) continue;
          throw UnknownPropertyException([...location, name], this);
        }
        result[name] = convertProperty(converter, name, input);
      }
      checkRequiredProperties(result.keys);
      return result;
    }
    throw TypeException(Map<String, Object?>, input);
  }

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

  void checkRequiredProperties(Iterable<String> providedProperties) {
    final missingProperties =
        getRequiredProperties().where(providedProperties.contains.not$);
    if (missingProperties.isNotEmpty) {
      throw MissingPropertyException(
          location, this, missingProperties.toList());
    }
  }
}

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

class Enums extends Validatable<String> {
  const Enums(EnumValidator validator) : super(const Strings(), validator);
}

T _cast<T>(Object? value) {
  if (value is T) return value;
  throw TypeException(T, value);
}
