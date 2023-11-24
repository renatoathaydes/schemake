import '../validator.dart';
import 'dart_gen.dart';

class DartEnumGeneratorOptions
    implements DartValidatorGenerationOptions<EnumValidator> {
  @override
  final Type validatorType = EnumValidator;
  final String? dartTypeName;

  const DartEnumGeneratorOptions({this.dartTypeName});

  @override
  String dartTypeFor(EnumValidator validator) {
    return dartTypeName ?? validator.name;
  }

  @override
  void generateDartType(StringBuffer buffer, EnumValidator validator) {
    final name = dartTypeName ?? validator.name;
    buffer.writeln('enum $name {');
    validator.values.forEach((name, dartName) {
      buffer.writeln('  ${dartName ?? name},');
    });
    buffer.writeln('  ;\n'
        '  static $name from(String s) => switch(s) {');
    validator.values.forEach((name, dartName) {
      buffer.writeln("    '$name' => ${dartName ?? name},");
    });
    buffer.writeln("    _ => throw ValidationException("
        "['value not allowed for $name: \"\$s\"']),");
    buffer.writeln('  };\n}');
  }
}
