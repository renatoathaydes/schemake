import 'package:schemake/src/validator.dart';

import 'errors.dart';
import 'property.dart';

sealed class SchemaType<T> {
  const SchemaType();

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

class Objects extends NonNull<Map<String, Object?>> {
  final String dartClassName;
  final Map<String, Property<Object?>> properties;
  final bool ignoreUnknownProperties;
  final List<String> location;
  final List<GeneratorOptions> generatorOptions;

  const Objects(this.dartClassName, this.properties,
      {this.ignoreUnknownProperties = false,
      this.location = const [],
      this.generatorOptions = const []});

  @override
  Map<String, Object?> convertToDartNonNull(Object yaml) {
    if (yaml is Map) {
      final result = <String, Object?>{};

      for (final entry in yaml.entries) {
        final name = _cast<String>(entry.key);
        final property = properties[name];
        if (property == null) {
          if (ignoreUnknownProperties) continue;
          throw UnknownPropertyException([...location, name], properties);
        }
        try {
          result[name] = property.type.convertToDart(entry.value);
        } on ValidationException catch (e) {
          if (e is PropertyValidationException) rethrow;
          throw PropertyValidationException(
              [...location, name], properties, e.errors);
        }
      }
      _checkRequiredProperties(result, location);
      return result;
    }
    throw TypeException(Map<String, Object?>, yaml);
  }

  void _checkRequiredProperties(
      Map<String, Object?> map, List<String> location) {
    final missingProperties = properties.entries
        .where((e) => e.value.type is NonNull && !map.containsKey(e.key))
        .map((e) => e.key);
    if (missingProperties.isNotEmpty) {
      throw MissingPropertyException(
          location, properties, missingProperties.toList());
    }
  }

  @override
  String toString() => 'schemake.Objects{$properties}';
}

final class Dictionaries<S, T extends SchemaType<S>>
    extends NonNull<Map<String, S>> {
  final T valueType;

  const Dictionaries(this.valueType);

  @override
  Map<String, S> convertToDartNonNull(Object yaml) {
    if (yaml is Map) {
      return yaml.map((k, v) {
        return MapEntry(_cast<String>(k), valueType.convertToDart(v));
      });
    }
    throw TypeException(S, yaml);
  }
}

class Validatable<T> implements SchemaType<T> {
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
