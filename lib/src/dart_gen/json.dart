import 'package:conveniently/conveniently.dart';

import '../_text.dart';
import '../types.dart';
import '../validator.dart';
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
  const FromJsonMethodGenerator();

  @override
  GeneratorExtras generateMethod(
      StringBuffer buffer, Objects objects, DartGeneratorOptions options) {
    buffer.writeFromJson(objects, options);
    return GeneratorExtras(
        const {}, (writer) => writer.writeJsonReviver(objects, options));
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
    writeln('    const ${_reviverName(objects.name)}().convert(value);');
  }

  void writeJsonReviver(Objects objects, DartGeneratorOptions options) {
    final name = objects.name;
    writeln('class ${_reviverName(name)} extends ObjectsBase<$name> {\n'
        '  const ${_reviverName(name)}(): super("$name");\n'
        '  Object? call(Object? key, Object? value) {\n'
        '    if (key == null) {\n'
        '      return convert(value);\n'
        '    }\n'
        '    return value;\n'
        '  }');
    writeln('\n'
        '  @override\n'
        '  $name convert(Object? value) {\n'
        '    if (value is! Map) throw TypeException($name, value);\n'
        '    final keys = value.keys.map((key) {\n'
        '      if (key is! String) {\n'
        '        throw TypeException(String, key, "object key is not a String");\n'
        '      }\n'
        '      return key;\n'
        '    }).toSet();\n'
        '    checkRequiredProperties(keys);');
    writeConstructorCall(objects, options, indent: '      ');
    writeln('  }');
    writePropertyConverter(objects, options);
    writeGetRequiredProperties(objects, options);
    writeln('}');
  }

  void writeConstructorCall(Objects objects, DartGeneratorOptions options,
      {required String indent}) {
    writeln('${indent}return ${objects.name}(');
    objects.properties.forEach((key, value) {
      final fieldName = options.fieldName?.vmap((f) => f(key)) ?? key;
      write("  $indent$fieldName: convertProperty(const ");
      write(schemaTypeString(value.type));
      writeln(', ${quote(fieldName)}, value),');
    });
    writeln('$indent);');
  }

  void writePropertyConverter(Objects objects, DartGeneratorOptions options) {
    writeln('\n  @override\n'
        '  Converter<Object?, Object?>? getPropertyConverter(String property) {\n'
        '    switch(property) {');
    objects.properties.forEach((key, value) {
      final fieldName = options.fieldName?.vmap((f) => f(key)) ?? key;
      write('      case ${quote(fieldName)}: return const ');
      write(schemaTypeString(value.type));
      writeln(';');
    });
    writeln('      default: return null;\n'
        '    }\n'
        '  }');
  }

  void writeGetRequiredProperties(
      Objects objects, DartGeneratorOptions options) {
    final mandatoryKeys = objects.properties.entries
        .where((e) => e.value.type is NonNull)
        .map((e) => quote(e.key));
    write('  @override\n'
        '  Iterable<String> getRequiredProperties() {\n'
        '    return const {');
    write(mandatoryKeys.join(', '));
    writeln('};\n'
        '  }');
  }
}

String _reviverName(String name) => '${name}JsonReviver';

/// Returns a String that represents the [SchemaType] in "Dart syntax".
///
/// For example, if the schema type is created with the Dart code
/// `Nullable(Ints())`, then this function returns just that.
///
/// For [ObjectsBase] instances that are not [Objects],
/// this method returns the name of the schema type that would've
/// been generated by [generateDartClasses].
String schemaTypeString(SchemaType<Object?> type) {
  return switch (type) {
    Arrays<dynamic, SchemaType>(itemsType: var items) =>
      _schemaTypeStringWrapper('Arrays', items),
    Objects() => throw ArgumentError.value(
        type, 'type', 'Objects schema type String cannot be generated'),
    ObjectsBase<Object?>() => '${type.runtimeType}()',
    Nullable<dynamic, NonNull>(type: var inner) =>
      _schemaTypeStringWrapper('Nullable', inner),
    Validatable<Object?>(type: var inner, validator: var val) =>
      _schemaTypeValidatable(inner, val),
    Ints() => 'Ints()',
    Floats() => 'Floats()',
    Strings() => 'Strings()',
    Bools() => 'Bools()',
  };
}

String _schemaTypeBasic(SchemaType<Object?> type) {
  return switch (type) {
    Arrays<dynamic, SchemaType>(itemsType: var items) =>
      _schemaTypeBasicWrapper('Arrays', items),
    ObjectsBase<Object?>() => type.runtimeType.toString(),
    Ints() => 'Ints',
    Floats() => 'Floats',
    Strings() => 'Strings',
    Bools() => 'Bools',
    _ => throw UnsupportedError('Schema type $type '
        'is not supported for code generation in this position'),
  };
}

String _schemaTypeStringWrapper(String kind, SchemaType<Object?> items) {
  return "$kind<${items.dartType()}, ${_schemaTypeBasic(items)}>"
      "(${schemaTypeString(items)})";
}

String _schemaTypeBasicWrapper(String kind, SchemaType<Object?> items) {
  return "$kind<${items.dartType()}, ${_schemaTypeBasic(items)}>";
}

String _schemaTypeValidatable(
    SchemaType<Object?> inner, Validator<Object?> validator) {
  final typeParam = validator.runtimeType;
  return "Validatable(${schemaTypeString(inner)}, "
      "$typeParam(${validator.ownArgumentsString}))";
}
