import 'package:conveniently/conveniently.dart';
import 'package:schemake/src/validator.dart';

import 'errors.dart';
import 'property.dart';

sealed class SchemaType<T> {
  const SchemaType();

  Type dartType() => T;

  T convertToDart(Object? yaml);
}

sealed class NonNull<T> extends SchemaType<T> {
  const NonNull();

  @override
  T convertToDart(Object? yaml) {
    if (yaml == null) throw TypeException(T, yaml);
    return convertToDartNonNull(yaml);
  }

  T convertToDartNonNull(Object yaml) {
    return _cast(yaml);
  }
}

final class Nullable<S, T extends NonNull<S>> extends SchemaType<S?> {
  final NonNull<S> type;

  const Nullable(this.type);

  @override
  S? convertToDart(Object? yaml) {
    return yaml == null ? null : type.convertToDart(yaml);
  }

  @override
  String toString() {
    return 'schemake.Nullable{$type}';
  }
}

final class Ints extends NonNull<int> {
  const Ints();

  @override
  String toString() => 'schemake.Ints';
}

final class Floats extends NonNull<double> {
  const Floats();

  @override
  String toString() => 'schemake.Floats';
}

final class Strings extends NonNull<String> {
  const Strings();

  @override
  String toString() => 'schemake.Strings';
}

final class Bools extends NonNull<bool> {
  const Bools();

  @override
  String toString() => 'schemake.Bools';
}

final class Arrays<S, T extends SchemaType<S>> extends NonNull<List<S>> {
  final T itemsType;

  const Arrays(this.itemsType);

  @override
  List<S> convertToDartNonNull(Object yaml) {
    if (yaml is Iterable) {
      return yaml
          .map((e) => itemsType.convertToDart(e))
          .toList(growable: false);
    }
    throw TypeException(List<S>, yaml);
  }

  @override
  String toString() => 'schemake.Arrays{$itemsType}';
}

mixin GeneratorOptions {}

class Objects extends ObjectsBase<Map<String, Object?>> {
  final Map<String, Property<Object?>> properties;
  final List<GeneratorOptions> generatorOptions;

  const Objects(super.name, this.properties,
      {super.ignoreUnknownProperties = false,
      super.location = const [],
      this.generatorOptions = const []});

  @override
  Map<String, Object?> convertToDartNonNull(Object yaml) {
    return convertToMap(yaml);
  }

  @override
  Object? Function(Object?)? getPropertyConverter(String property) {
    return properties[property]?.type.convertToDart;
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

abstract class ObjectsBase<T> extends NonNull<T> {
  final String name;
  final bool ignoreUnknownProperties;
  final List<String> location;

  const ObjectsBase(this.name,
      {this.ignoreUnknownProperties = false, this.location = const []});

  Object? Function(Object?)? getPropertyConverter(String property);

  Iterable<String> getRequiredProperties();

  Map<String, Object?> convertToMap(Object yaml) {
    if (yaml is Map) {
      final result = <String, Object?>{};
      for (final entry in yaml.entries) {
        final name = _cast<String>(entry.key);
        final propertyConverter = getPropertyConverter(name);
        if (propertyConverter == null) {
          if (ignoreUnknownProperties) continue;
          throw UnknownPropertyException([...location, name], this);
        }
        try {
          result[name] = propertyConverter(entry.value);
        } on PropertyException catch (e) {
          throw e.prependPath(name);
        } on ToPropertyException catch (e) {
          throw e.toPropertyException(name, this);
        }
      }
      checkRequiredProperties(result.keys);
      return result;
    }
    throw TypeException(Map<String, Object?>, yaml);
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

class Validatable<T> extends SchemaType<T> {
  final SchemaType<T> type;
  final Validator<T> validator;

  const Validatable(this.type, this.validator);

  @override
  T convertToDart(Object? yaml) {
    final result = type.convertToDart(yaml);
    validator.validate(result);
    return result;
  }
}

T _cast<T>(Object? value) {
  if (value is T) return value;
  throw TypeException(T, value);
}
