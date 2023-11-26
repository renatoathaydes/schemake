import 'package:schemake/src/types.dart';

import '../_text.dart';
import '../validator.dart';
import 'dart_gen.dart';
import 'json.dart';

class DartEnumGeneratorOptions
    implements DartValidatorGenerationOptions<EnumValidator> {
  final String? dartTypeName;
  final String Function(String) dartVariantName;

  const DartEnumGeneratorOptions(
      {this.dartTypeName, this.dartVariantName = identityString});

  @override
  String dartTypeFor(EnumValidator validator) {
    return dartTypeName ?? validator.name;
  }

  @override
  GeneratorExtras? getDartTypeGenerator(EnumValidator validator) {
    return GeneratorExtras(
        const {'dart:convert', 'package:schemake/schemake.dart'}, (writer) {
      _generateEnum(writer, validator);
      _generateConverter(writer, validator);
    });
  }

  void _generateEnum(StringBuffer buffer, EnumValidator validator) {
    final typeName = dartTypeName ?? validator.name;
    buffer.writeln('enum $typeName {');
    for (var name in validator.values) {
      buffer.writeln('  ${dartVariantName(name)},');
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
    final typeName = dartTypeName ?? validator.name;
    return '_${typeName}Converter';
  }

  void _generateConverter(StringBuffer buffer, EnumValidator validator) {
    final typeName = dartTypeName ?? validator.name;
    final converterName = _converterName(validator);

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

class DartIntRangeGeneratorOptions
    implements DartValidatorGenerationOptions<IntRangeValidator> {
  const DartIntRangeGeneratorOptions();

  @override
  String dartTypeFor(IntRangeValidator validator) => 'int';

  @override
  GeneratorExtras? getDartTypeGenerator(IntRangeValidator validator) {
    // nothing to do: a plain int is used
    return null;
  }

  @override
  String selfCreateString(IntRangeValidator validator) {
    final typeName = validator.runtimeType;
    return "Validatable(${schemaTypeString(const Ints())}, "
        "$typeName(${validator.min}, ${validator.max}))";
  }
}

class DartNonBlankStringGeneratorOptions
    implements DartValidatorGenerationOptions<NonBlankStringValidator> {
  const DartNonBlankStringGeneratorOptions();

  @override
  String dartTypeFor(NonBlankStringValidator validator) => 'String';

  @override
  GeneratorExtras? getDartTypeGenerator(NonBlankStringValidator validator) {
    // nothing to do: a plain String is used
    return null;
  }

  @override
  String selfCreateString(NonBlankStringValidator validator) =>
      'Validatable(Strings(), ${validator.runtimeType}())';
}
