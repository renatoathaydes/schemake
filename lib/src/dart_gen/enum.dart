import '../validator.dart';
import 'dart_gen.dart';

class DartEnumGeneratorOptions
    implements DartValidatorGenerationOptions<EnumValidator> {
  @override
  final Type validatorType = EnumValidator;

  const DartEnumGeneratorOptions();

  @override
  void generateDartType(StringBuffer buffer, EnumValidator validator) {
    buffer.writeln('enum ${validator.name} {\n');
    validator.values.forEach((name, dartName) {
      buffer.writeln('  ${dartName ?? name},');
    });
    buffer.writeln(';\n'
        '  static ${validator.name} from(String s) => switch(s) {');
    validator.values.forEach((name, dartName) {
      buffer.writeln('    "$name" => ${dartName ?? name},');
    });
    buffer.writeln("    _ => throw ValidationException("
        "['value not allowed for ${validator.name}: \"\$s\"']),");
    buffer.writeln('  };\n}');
  }
}
