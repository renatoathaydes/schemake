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
      EnumValidator(name: var name) =>
        DartEnumGeneratorOptions(dartTypeName: name),
      IntRangeValidator() => const DartIntRangeGeneratorOptions(),
      NonBlankStringValidator() => const DartNonBlankStringGeneratorOptions(),
      _ => null,
    };
    return result as DartValidatorGenerationOptions<Validator<T>>?;
  }
}
