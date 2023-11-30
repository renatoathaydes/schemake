import 'package:conveniently/conveniently.dart';
import 'package:schemake/src/dart_gen/_utils.dart';

import '../_text.dart';
import '../types.dart';
import 'dart_gen.dart';

class DartToJsonMethodGenerator with DartMethodGenerator {
  const DartToJsonMethodGenerator();

  @override
  GeneratorExtras? generateMethod(
      StringBuffer buffer, Objects objects, DartGeneratorOptions options) {
    buffer.writeToJson(objects, options);
    return null;
  }
}

class DartFromJsonMethodGenerator with DartMethodGenerator {
  const DartFromJsonMethodGenerator();

  @override
  GeneratorExtras generateMethod(
      StringBuffer buffer, Objects objects, DartGeneratorOptions options) {
    buffer.writeFromJson(objects, options);
    return GeneratorExtras(
        const {'dart:convert', 'package:schemake/schemake.dart'},
        (writer) => writer.writeJsonReviver(objects, options));
  }
}

extension on StringBuffer {
  void writeToJson(Objects objects, DartGeneratorOptions options) {
    writeln('  Map<String, Object?> toJson() => {');
    objects.properties.forEach((key, value) {
      write('    ');
      final fieldName = options.fieldName(key);
      if (!options.encodeNulls && value.type is Nullable<dynamic, dynamic>) {
        write('if ($fieldName != null) ');
      }
      writeln("'$fieldName': $fieldName,");
    });
    if (objects.unknownPropertiesStrategy == UnknownPropertiesStrategy.keep) {
      writeln("    ...extras,");
    }
    writeln('  };');
  }

  void writeFromJson(Objects objects, DartGeneratorOptions options) {
    writeln('  static ${objects.name} fromJson(Object? value) =>');
    writeln(
        '    const ${_reviverName(objects.name)}().convert(switch(value) {\n'
        '      String() => jsonDecode(value),\n'
        '      List<int>() => jsonDecode(utf8.decode(value)),\n'
        '      _ => value,\n'
        '    });');
  }

  void writeJsonReviver(Objects objects, DartGeneratorOptions options) {
    final name = objects.name;
    writeln('class ${_reviverName(name)} extends ObjectsBase<$name> {\n'
        '  const ${_reviverName(name)}(): super("$name",\n'
        '    unknownPropertiesStrategy: ${objects.unknownPropertiesStrategy},\n'
        '    location: const [${objects.location.map(quote).join(', ')}]);\n'
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
    writeConstructorCall(objects, options, indent: '    ');
    writeln('  }');
    writePropertyConverter(objects, options);
    writeGetRequiredProperties(objects, options);
    writeToString(objects);
    writeUnknownPropertiesMap(objects);
    writeln('}');
  }

  void writeConstructorCall(Objects objects, DartGeneratorOptions options,
      {required String indent}) {
    writeln('${indent}return ${objects.name}(');
    objects.properties.forEach((key, value) {
      final fieldName = options.fieldName(key);
      write("  $indent$fieldName: convertProperty(const ");
      write(schemaTypeString(value.type));
      writeln(', ${quote(fieldName)}, value),');
    });
    if (objects.unknownPropertiesStrategy == UnknownPropertiesStrategy.keep) {
      writeln('  ${indent}extras: _unknownPropertiesMap(value),');
    }
    writeln('$indent);');
  }

  void writePropertyConverter(Objects objects, DartGeneratorOptions options) {
    writeln('\n  @override\n'
        '  Converter<Object?, Object?>? getPropertyConverter(String property) {\n'
        '    switch(property) {');
    objects.properties.forEach((key, value) {
      final fieldName = options.fieldName(key);
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

  void writeToString(Objects objects) {
    writeln('  @override\n'
        "  String toString() => '${objects.name}';");
  }
}

String _reviverName(String name) => '_${name}JsonReviver';

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
    ObjectsBase<dynamic>() when type.mapValueTypeOrNull != null =>
      _schemaTypeMaps(type),
    Objects() => throw ArgumentError.value(
        type, 'type', 'Objects schema type cannot be generated'),
    ObjectsBase<Object?>() => '${type.runtimeType}()',
    Nullable<dynamic, NonNull>(type: var inner) =>
      _schemaTypeStringWrapper('Nullable', inner),
    Validatable<Object?>() => _schemaTypeValidatable(type),
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

String _schemaTypeValidatable(Validatable<Object?> validatable) {
  return validatable.dartGenOption
      .orThrow(() => StateError(
          'Validatable does not support Dart code generation: $validatable. '
          'Add a DartValidatorGenerationOptions to its "generatorOptions" '
          'to fix the problem.'))
      .selfCreateString(validatable.validator);
}

String _schemaTypeMaps(ObjectsBase<dynamic> objects) {
  if (objects is Maps) {
    return "Maps(${quote(objects.name)}, "
        "valueType: ${schemaTypeString(objects.valueType)})";
  }
  if (objects is Objects && objects.isSimpleMap) {
    return "Objects(${quote(objects.name)}, {}, "
        "unknownPropertiesStrategy: UnknownPropertiesStrategy.keep)";
  }
  throw StateError('cannot generate Maps Schemake type for $objects');
}
