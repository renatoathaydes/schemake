import '../_utils.dart';
import '../types.dart';
import '../validator.dart';
import 'gen_options.dart';
import 'java_gen.dart';

extension ValidatableJavaGenerationExtension<T> on Validatable<T> {
  JavaValidatorGenerationOptions<Validator<T>>? get javaGenOption {
    final configuredOptions = validator.generatorOptions
        .whereType<JavaValidatorGenerationOptions<Validator<T>>>()
        .firstOrNull;
    if (configuredOptions != null) return configuredOptions;

    // use built-in options if possible
    final result = switch (validator) {
      EnumValidator() => const JavaEnumGeneratorOptions(),
      IntRangeValidator() => const JavaIntRangeGeneratorOptions(),
      FloatRangeValidator() => const JavaFloatRangeGeneratorOptions(),
      NonBlankStringValidator() => const JavaNonBlankStringGeneratorOptions(),
      _ => null,
    };
    return result as JavaValidatorGenerationOptions<Validator<T>>?;
  }
}

typedef _TypeOf<T> = T;

extension SchemakeTypeExtension on SchemaType<Object?> {
  String javaTypeString(JavaGeneratorOptions options) {
    final self = this;
    return switch (self) {
      Nullable<Object?, NonNull>(type: var t) =>
        '${t.javaTypeString(options)}?',
      Ints() => 'int',
      Floats() => 'double',
      Strings() => 'String',
      Bools() => 'boolean',
      Arrays<Object?, SchemaType>(itemsType: var t) =>
        'List<${t.javaTypeString(options)}>',
      Maps(valueType: var t) => 'Map<String, ${t.javaTypeString(options)}>',
      Objects() when (self.isSimpleMap) => self.dartType().toString(),
      Objects() => options.className(self.name),
      ObjectsBase<Object?>() => self.dartType().toString(),
      Validatable<Object?>(validator: var v) =>
        self.javaGenOption?.javaTypeFor(v) ?? self.type.javaTypeString(options),
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

  Object? listItemsTypeOrNull(JavaGeneratorOptions options) {
    final self = unwrap();
    if (self is Arrays<Object?, SchemaType<Object?>>) {
      return self.itemsType.javaTypeString(options);
    }
    return null;
  }

  Object? mapValueTypeOrNull(JavaGeneratorOptions options) {
    final self = unwrap();
    if (self is Maps<Object?, SchemaType<Object?>>) {
      return self.valueType.javaTypeString(options);
    }
    if (self is Objects && self.isSimpleMap) {
      return _TypeOf<Object?>;
    }
    return null;
  }
}
