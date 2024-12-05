import '../_text.dart';
import '../types.dart';
import '../validator.dart';
import 'java_gen.dart';
import 'json.dart';

class JavaEnumGeneratorOptions
    implements JavaValidatorGenerationOptions<EnumValidator> {
  final String Function(String validatorName) dartTypeName;
  final String Function(String) dartVariantName;
  final String Function(String) insertBeforeEnumVariant;

  const JavaEnumGeneratorOptions(
      {this.dartTypeName = toPascalCase,
      this.dartVariantName = toCamelCase,
      this.insertBeforeEnumVariant = emptyString});

  @override
  String javaTypeFor(EnumValidator validator) {
    return dartTypeName(validator.name);
  }

  @override
  GeneratorExtras? getJavaTypeGenerator(EnumValidator validator) {
    final typeName = javaTypeFor(validator);
    final converterName = _converterName(validator);
    return GeneratorExtras(
        const {'dart:convert', 'package:schemake/schemake.dart'},
        {typeName, converterName}, (writer) {
      _generateEnum(writer, typeName, validator);
      _generateConverter(writer, typeName, converterName, validator);
    });
  }

  void _generateEnum(
      StringBuffer buffer, String typeName, EnumValidator validator) {
    buffer.writeln('enum $typeName {');
    for (var name in validator.values) {
      buffer.writeln(
          '  ${insertBeforeEnumVariant(name)}${dartVariantName(name)},');
    }
    buffer.writeln('  ;\n'
        '  static $typeName from(String s) => switch(s) {');
    for (var name in validator.values) {
      buffer.writeln("    '$name' => ${dartVariantName(name)},");
    }
    buffer.writeln("    _ => throw ValidationException("
        "['value not allowed for $typeName: \"\$s\" - should be one of "
        "${validator.values}']),");
    buffer.writeln('  };\n}');
  }

  @override
  String selfCreateString(EnumValidator validator) {
    return '${_converterName(validator)}()';
  }

  String _converterName(EnumValidator validator) {
    final typeName = dartTypeName(validator.name);
    return '_${typeName}Converter';
  }

  void _generateConverter(StringBuffer buffer, String typeName,
      String converterName, EnumValidator validator) {
    buffer.writeln('class $converterName '
        'extends Converter<Object?, $typeName> {\n'
        '  const $converterName();\n'
        '  @override\n'
        '  $typeName convert(Object? input) {\n'
        '    return $typeName.from(const Strings().convert(input));\n'
        '  }\n'
        '}');
  }
}

class JavaIntRangeGeneratorOptions
    implements JavaValidatorGenerationOptions<IntRangeValidator> {
  const JavaIntRangeGeneratorOptions();

  @override
  String javaTypeFor(IntRangeValidator validator) => 'int';

  @override
  GeneratorExtras? getJavaTypeGenerator(IntRangeValidator validator) {
    // nothing to do: a plain int is used
    return null;
  }

  @override
  String selfCreateString(IntRangeValidator validator) {
    final typeName = validator.runtimeType;
    return "Validatable(${schemaTypeString(const Ints(), const JavaGeneratorOptions())}, "
        "$typeName(${validator.min}, ${validator.max}))";
  }
}

class JavaFloatRangeGeneratorOptions
    implements JavaValidatorGenerationOptions<FloatRangeValidator> {
  const JavaFloatRangeGeneratorOptions();

  @override
  String javaTypeFor(FloatRangeValidator validator) => 'double';

  @override
  GeneratorExtras? getJavaTypeGenerator(FloatRangeValidator validator) {
    // nothing to do: a plain int is used
    return null;
  }

  @override
  String selfCreateString(FloatRangeValidator validator) {
    final typeName = validator.runtimeType;
    return "Validatable(${schemaTypeString(const Floats(), const JavaGeneratorOptions())}, "
        "$typeName(${validator.min}, ${validator.max}))";
  }
}

class JavaNonBlankStringGeneratorOptions
    implements JavaValidatorGenerationOptions<NonBlankStringValidator> {
  const JavaNonBlankStringGeneratorOptions();

  @override
  String javaTypeFor(NonBlankStringValidator validator) => 'String';

  @override
  GeneratorExtras? getJavaTypeGenerator(NonBlankStringValidator validator) {
    // nothing to do: a plain String is used
    return null;
  }

  @override
  String selfCreateString(NonBlankStringValidator validator) =>
      'Validatable(Strings(), ${validator.runtimeType}())';
}
