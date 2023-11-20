import 'package:conveniently/conveniently.dart';
import 'package:schemake/src/types.dart';

import '../_text.dart';
import 'dart_gen.dart';

class ToJsonMethodGenerator with DartMethodGenerator {
  const ToJsonMethodGenerator();

  @override
  GeneratorExtras? generateMethod(
      StringBuffer buffer, Objects objects, DartGeneratorOptions options) {
    buffer.writeToJson(objects, options);
    return null;
  }
}

class FromJsonMethodGenerator with DartMethodGenerator {
  final String schemaObjectName;

  const FromJsonMethodGenerator(this.schemaObjectName);

  @override
  GeneratorExtras generateMethod(
      StringBuffer buffer, Objects objects, DartGeneratorOptions options) {
    buffer.writeFromJson(objects, options);
    return GeneratorExtras(
        const {},
        (writer) =>
            writer.writeJsonReviver(schemaObjectName, objects, options));
  }
}

extension on StringBuffer {
  void writeToJson(Objects objects, DartGeneratorOptions options) {
    writeln('  Map<String, Object?> toJson() => {');
    objects.properties.forEach((key, value) {
      write('       ');
      final fieldName = options.fieldName?.vmap((f) => f(key)) ?? key;
      writeln("'$fieldName': $fieldName,");
    });
    writeln('  };');
  }

  void writeFromJson(Objects objects, DartGeneratorOptions options) {
    writeln('  static ${objects.name} fromJson(Object? value) =>');
    writeln('    const ${objects.name}JsonReviver().fromJson(value);');
  }

  void writeJsonReviver(
      String schemaObjectName, Objects objects, DartGeneratorOptions options) {
    const mapName = 'cleanValue';
    writeln('class ${objects.name}JsonReviver {\n'
        '  const ${objects.name}JsonReviver();\n'
        '  Object? call(Object? key, Object? value) {\n'
        '    if (key == null) {\n'
        '      return fromJson(value);\n'
        '    }\n'
        '    return value;\n'
        '  }');
    write('\n'
        '  ${objects.name} fromJson(Object? value) {\n'
        '      final $mapName = $schemaObjectName.convertToDart(value);\n'
        '      return ');
    writeConstructorCall(objects, options, indent: '      ', mapName: mapName);
    writeln('  }\n'
        '}');
  }

  void writeConstructorCall(Objects objects, DartGeneratorOptions options,
      {required String indent, required String mapName}) {
    writeln('${objects.name}(');
    objects.properties.forEach((key, value) {
      final fieldName = options.fieldName?.vmap((f) => f(key)) ?? key;
      // TODO handle objects where cast won't work, call fromJson
      final type = value.type.dartType();
      writeln("  $indent$fieldName: $mapName[${quote(fieldName)}] as $type,");
    });
    writeln('$indent);');
  }
}
