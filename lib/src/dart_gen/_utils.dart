import 'package:schemake/dart_gen.dart';

import '../types.dart';
import '../validator.dart';

extension ValidatableDartGenerationExtension<T> on Validatable<T> {
  DartValidatorGenerationOptions<Validator<T>>? get dartGenOption {
    final configuredOptions = validator.generatorOptions
        .whereType<DartValidatorGenerationOptions<Validator<T>>>()
        .firstOrNull;
    if (configuredOptions != null) return configuredOptions;

    // use built-in options if possible
    final result = switch (validator) {
      EnumValidator() => const DartEnumGeneratorOptions(),
      IntRangeValidator() => const DartIntRangeGeneratorOptions(),
      FloatRangeValidator() => const DartFloatRangeGeneratorOptions(),
      NonBlankStringValidator() => const DartNonBlankStringGeneratorOptions(),
      _ => null,
    };
    return result as DartValidatorGenerationOptions<Validator<T>>?;
  }
}

extension ObjectsExtension on ObjectsBase<Object?> {
  bool get isSimpleMap {
    final self = this;
    return self is Maps ||
        (self is Objects &&
            self.unknownPropertiesStrategy == UnknownPropertiesStrategy.keep &&
            self.properties.isEmpty);
  }
}

typedef _TypeOf<T> = T;

extension SchemakeTypeExtension on SchemaType<Object?> {
  String dartTypeString(DartGeneratorOptions options) {
    final self = this;
    return switch (self) {
      Nullable<Object?, NonNull>(type: var t) =>
        '${t.dartTypeString(options)}?',
      Ints() => 'int',
      Floats() => 'double',
      Strings() => 'String',
      Bools() => 'bool',
      Arrays<Object?, SchemaType>(itemsType: var t) =>
        'List<${t.dartTypeString(options)}>',
      Maps(valueType: var t) => 'Map<String, ${t.dartTypeString(options)}>',
      Objects() when (self.isSimpleMap) => self.dartType().toString(),
      Objects() => options.className(self.name),
      ObjectsBase<Object?>() => self.dartType().toString(),
      Validatable<Object?>(validator: var v) =>
        self.dartGenOption?.dartTypeFor(v) ?? self.type.dartTypeString(options),
    };
  }

  /// Unwraps the type from [Nullable] and [Validatable] types.
  NonNull<Object?> unwrap() {
    return switch (this) {
      Nullable<dynamic, NonNull>(type: var t) => t,
      Validatable<Object?>(type: var t) => t,
      _ => this as NonNull<Object?>,
    };
  }

  Object? listItemsTypeOrNull(DartGeneratorOptions options) {
    final self = unwrap();
    if (self is Arrays<Object?, SchemaType<Object?>>) {
      return self.itemsType.dartTypeString(options);
    }
    return null;
  }

  Object? mapValueTypeOrNull(DartGeneratorOptions options) {
    final self = unwrap();
    if (self is Maps<Object?, SchemaType<Object?>>) {
      return self.valueType.dartTypeString(options);
    }
    if (self is Objects && self.isSimpleMap) {
      return _TypeOf<Object?>;
    }
    return null;
  }
}

extension ListExtension<T> on List<T> {
  List<T> drain() {
    final copy = [...this];
    clear();
    return copy;
  }
}
