import 'package:conveniently/conveniently.dart';

import '../_text.dart';
import '../_utils.dart';
import '../types.dart';
import '_utils.dart';
import '_value_writer.dart';
import 'java_gen.dart';

class JavaToJsonMethodGenerator with JavaMethodGenerator {
  const JavaToJsonMethodGenerator();

  @override
  GeneratorExtras? generateMethod(
      StringBuffer buffer, Objects objects, JavaGeneratorOptions options) {
    buffer.writeToJson(objects, options);
    return null;
  }
}

class JavaFromJsonMethodGenerator with JavaMethodGenerator {
  const JavaFromJsonMethodGenerator();

  @override
  GeneratorExtras generateMethod(
      StringBuffer buffer, Objects objects, JavaGeneratorOptions options) {
    final reviverName = _reviverName(options.className(objects.name));
    buffer.writeFromJson(objects, reviverName, options);
    return GeneratorExtras(
        const {'dart:convert', 'package:schemake/schemake.dart'},
        {reviverName},
        (writer) => writer.writeJsonReviver(objects, reviverName, options));
  }
}

extension on StringBuffer {
  void writeToJson(Objects objects, JavaGeneratorOptions options) {
    writeln('  Map<String, Object?> toJson() => {');
    objects.properties.forEach((key, value) {
      write('    ');
      final fieldName = options.fieldName(key);
      if (!options.encodeNulls && value.type is Nullable<dynamic, dynamic>) {
        write('if ($fieldName != null) ');
      }
      writeln("'$key': $fieldName,");
    });
    if (objects.unknownPropertiesStrategy == UnknownPropertiesStrategy.keep) {
      writeln("    ...extras,");
    }
    writeln('  };');
  }

  void writeFromJson(
      Objects objects, String reviverName, JavaGeneratorOptions options) {
    writeln(
        '  static ${options.className(objects.name)} fromJson(Object? value) =>');
    writeln('    const $reviverName().convert(switch(value) {\n'
        '      String() => jsonDecode(value),\n'
        '      List<int>() => jsonDecode(utf8.decode(value)),\n'
        '      _ => value,\n'
        '    });');
  }

  void writeJsonReviver(
      Objects objects, String reviverName, JavaGeneratorOptions options) {
    final name = options.className(objects.name);
    writeln('class $reviverName extends ObjectsBase<$name> {\n'
        '  const $reviverName(): super("$name",\n'
        '    unknownPropertiesStrategy: ${objects.unknownPropertiesStrategy});\n'
        '\n'
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
    writeForbiddenKeysCheck(objects, name, indent: '    ');
    writeConstructorCall(objects, options, indent: '    ');
    writeln('  }');
    writePropertyConverter(objects, options);
    writeGetRequiredProperties(objects, options);
    writeToString(objects, options);
    writeUnknownPropertiesMap(objects);
    writeln('}');
  }

  void writeConstructorCall(Objects objects, JavaGeneratorOptions options,
      {required String indent}) {
    writeln('${indent}return ${options.className(objects.name)}(');
    objects.properties.forEach((key, value) {
      final fieldName = options.fieldName(key);
      if (value.defaultValue == null) {
        write("  $indent$fieldName: convertProperty(const ");
        write(schemaTypeString(value.type, options));
        writeln(', ${quote(key)}, value),');
      } else {
        write("  $indent$fieldName: convertPropertyOrDefault(const ");
        write(schemaTypeString(value.type, options));
        write(', ${quote(key)}, value, ');
        writeValue(value.type, value.defaultValue);
        writeln('),');
      }
    });
    if (objects.unknownPropertiesStrategy == UnknownPropertiesStrategy.keep) {
      writeln('  ${indent}extras: _unknownPropertiesMap(value),');
    }
    writeln('$indent);');
  }

  void writePropertyConverter(Objects objects, JavaGeneratorOptions options) {
    writeln('\n  @override\n'
        '  Converter<Object?, Object?>? getPropertyConverter(String property) {\n'
        '    switch(property) {');
    objects.properties.forEach((key, value) {
      write('      case ${quote(key)}: return const ');
      write(schemaTypeString(value.type, options));
      writeln(';');
    });
    writeln('      default: return null;\n'
        '    }\n'
        '  }');
  }

  void writeGetRequiredProperties(
      Objects objects, JavaGeneratorOptions options) {
    final mandatoryKeys = objects.properties.entries
        .where((e) => e.value.isRequired)
        .map((e) => quote(e.key));
    write('  @override\n'
        '  Iterable<String> getRequiredProperties() {\n'
        '    return const {');
    write(mandatoryKeys.join(', '));
    writeln('};\n'
        '  }');
  }

  void writeUnknownPropertiesMap(Objects objects) {
    if (objects.unknownPropertiesStrategy != UnknownPropertiesStrategy.keep) {
      return;
    }
    writeln('''
  Map<String, Object?> _unknownPropertiesMap(Map<Object?, Object?> value) {
    final result = <String, Object?>{};
    const knownProperties = {${objects.properties.keys.map(quote).join(', ')}};
    for (final entry in value.entries) {
      final key = entry.key;
      if (!knownProperties.contains(key)) {
        if (key is! String) {
          throw TypeException(String, key, "object key is not a String");
        }
        result[key] = entry.value;
      }
    }
    return result;
  }''');
  }

  void writeToString(Objects objects, JavaGeneratorOptions options) {
    writeln('  @override\n'
        "  String toString() => '${options.className(objects.name)}';");
  }

  void writeForbiddenKeysCheck(Objects objects, String name,
      {required String indent}) {
    if (objects.unknownPropertiesStrategy != UnknownPropertiesStrategy.forbid) {
      return;
    }
    final keys = objects.properties.keys.map(quote);
    write('${indent}const knownProperties = {');
    write(keys.join(', '));
    writeln('};');
    writeln('${indent}final unknownKey = '
        'keys.where((k) => !knownProperties.contains(k)).firstOrNull;');
    writeln('${indent}if (unknownKey != null) {');
    writeln('$indent  throw UnknownPropertyException([unknownKey], $name);');
    writeln('$indent}');
  }
}

String _reviverName(String name) => '_${name}JsonReviver';

/// Returns a String that represents the [SchemaType] in "Java syntax".
///
/// For example, if the schema type is created with the Java code
/// `Nullable(Ints())`, then this function returns just that.
///
/// For [ObjectsBase] instances that are not [Objects],
/// this method returns the name of the schema type that would've
/// been generated by [generateJavaClasses].
String schemaTypeString(
    SchemaType<Object?> type, JavaGeneratorOptions options) {
  return switch (type) {
    Arrays<dynamic, SchemaType>(itemsType: var items) =>
      _schemaTypeStringWrapper('Arrays', items, options),
    ObjectsBase<dynamic>() when type.mapValueTypeOrNull(options) != null =>
      _schemaTypeMaps(type, options),
    Objects(name: var name) => '${_reviverName(options.className(name))}()',
    ObjectsBase<Object?>() => '${_reviverName(type.dartType().toString())}()',
    Nullable<dynamic, NonNull>(type: var inner) =>
      _schemaTypeStringWrapper('Nullable', inner, options),
    Validatable<Object?>() => _schemaTypeValidatable(type),
    Ints() => 'Ints()',
    Floats() => 'Floats()',
    Strings() => 'Strings()',
    Bools() => 'Bools()',
  };
}

String _schemaTypeBasic(
    SchemaType<Object?> type, JavaGeneratorOptions options) {
  return switch (type) {
    Arrays<dynamic, SchemaType>(itemsType: var items) =>
      _schemaTypeBasicWrapper('Arrays', items, options),
    Objects(name: var name) => _reviverName(options.className(name)),
    ObjectsBase<Object?>() => type.runtimeType.toString(),
    Ints() => 'Ints',
    Floats() => 'Floats',
    Strings() => 'Strings',
    Bools() => 'Bools',
    Validatable(type: var vtype) => _schemaTypeBasic(vtype, options),
    _ => throw UnsupportedError('Schema type $type '
        'is not supported for code generation in this position'),
  };
}

String _schemaTypeStringWrapper(
    String kind, SchemaType<Object?> items, JavaGeneratorOptions options) {
  final typeParameter = (items is Objects && !items.isSimpleMap)
      ? options.className(items.name)
      : items.dartType();
  return "$kind<$typeParameter, ${_schemaTypeBasic(items, options)}>"
      "(${schemaTypeString(items, options)})";
}

String _schemaTypeBasicWrapper(
    String kind, SchemaType<Object?> items, JavaGeneratorOptions options) {
  final typeParameter = (items is Objects && !items.isSimpleMap)
      ? options.className(items.name)
      : items.dartType();
  return "$kind<$typeParameter, ${_schemaTypeBasic(items, options)}>";
}

String _schemaTypeValidatable(Validatable<Object?> validatable) {
  return validatable.javaGenOption
      .orThrow(() => StateError(
          'Validatable does not support Java code generation: $validatable. '
          'Add a JavaValidatorGenerationOptions to its "generatorOptions" '
          'to fix the problem.'))
      .selfCreateString(validatable.validator);
}

String _schemaTypeMaps(
    ObjectsBase<dynamic> objects, JavaGeneratorOptions options) {
  if (objects is Maps) {
    return "Maps(${quote(objects.name)}, "
        "valueType: ${schemaTypeString(objects.valueType, options)})";
  }
  if (objects is Objects && objects.isSimpleMap) {
    return "Objects(${quote(objects.name)}, {}, "
        "unknownPropertiesStrategy: UnknownPropertiesStrategy.keep)";
  }
  throw StateError('cannot generate Maps Schemake type for $objects');
}
