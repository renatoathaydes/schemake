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
  void generateDartType(StringBuffer buffer, EnumValidator validator) {
    _generateEnum(buffer, validator);
    _generateConverter(buffer, validator);
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
  void generateDartType(StringBuffer buffer, IntRangeValidator validator) {
    // nothing to do: a plain int is used
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
  void generateDartType(
      StringBuffer buffer, NonBlankStringValidator validator) {
    // nothing to do: a plain String is used
  }

  @override
  String selfCreateString(NonBlankStringValidator validator) =>
      'Validatable(Strings(), ${validator.runtimeType}())';
}
