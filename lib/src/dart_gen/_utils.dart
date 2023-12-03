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
  Object? get listItemsTypeOrNull {
    final self = this;
    if (self is Arrays<Object?, Object?>) {
      final type = self.itemsType;
      if (type is Objects && !type.isSimpleMap) {
        return type.name;
      }
      return (self.itemsType as SchemaType<Object?>).dartType();
    }
    return null;
  }

  Type? get mapValueTypeOrNull {
    final self = this;
    if (self is Maps<Object?, Object?>) {
      return (self.valueType as NonNull<Object?>).dartType();
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
