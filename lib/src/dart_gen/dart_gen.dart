import 'package:conveniently/conveniently.dart';
import 'package:schemake/dart_gen.dart';

import '../_text.dart';
import '../property.dart';
import '../types.dart';
import '../validator.dart';
import '_utils.dart';
import '_value_writer.dart';

export '_copy_with.dart' show DartCopyWithMethodGenerator;

class GeneratorExtras {
  final Set<String> imports;
  final Set<String> types;
  final void Function(StringBuffer) writeTypes;

  const GeneratorExtras(this.imports,
      [this.types = const {}, this.writeTypes = _noOpWriter]);

  static void _noOpWriter(StringBuffer _) {}
}

mixin DartMethodGenerator {
  GeneratorExtras? generateMethod(
      StringBuffer buffer, Objects objects, DartGeneratorOptions options);
}

class DartToStringMethodGenerator with DartMethodGenerator {
  const DartToStringMethodGenerator();

  @override
  GeneratorExtras? generateMethod(
      StringBuffer buffer, Objects objects, DartGeneratorOptions options) {
    buffer.writeToString(objects, options);
    return null;
  }
}

class DartEqualsAndHashCodeMethodGenerator with DartMethodGenerator {
  const DartEqualsAndHashCodeMethodGenerator();

  @override
  GeneratorExtras? generateMethod(
      StringBuffer buffer, Objects objects, DartGeneratorOptions options) {
    final extras = buffer.writeEquals(objects, options);
    buffer.writeHashCode(objects, options);
    return extras;
  }
}

final class DartGeneratorOptions {
  static const defaultMethodGenerators = [
    DartToStringMethodGenerator(),
    DartEqualsAndHashCodeMethodGenerator(),
    DartCopyWithMethodGenerator(),
  ];

  static const jsonMethodGenerators = [
    DartFromJsonMethodGenerator(),
    DartToJsonMethodGenerator(),
  ];

  static String _finalField(String name, Property<Object?> _) => 'final ';

  static String _const() => 'const ';

  static String _newline(String _) => '\n';

  final String Function(String name) insertBeforeClass;
  final String Function(String propertyName) fieldName;
  final String Function(String className) className;
  final String Function(String name, Property<Object?> property)?
      insertBeforeField;
  final String Function()? insertBeforeConstructor;
  final String Function(String name, Property<Object?> property)?
      insertBeforeConstructorArg;
  final List<DartMethodGenerator> methodGenerators;
  final bool encodeNulls;

  const DartGeneratorOptions({
    this.insertBeforeClass = _newline,
    this.fieldName = toCamelCase,
    this.className = toPascalCase,
    this.insertBeforeField = _finalField,
    this.insertBeforeConstructor = _const,
    this.insertBeforeConstructorArg,
    this.methodGenerators = defaultMethodGenerators,
    this.encodeNulls = false,
  });
}

abstract class DartValidatorGenerationOptions<V extends Validator<dynamic>>
    implements ValidatorGenerationOptions {
  /// Returns Dart code that re-creates the Validatable instance
  /// or the equivalent [Converter] instance that can be used to convert
  /// properties of the type the validator validates.
  String selfCreateString(V validator);

  /// The Dart type name for the given validator type.
  String dartTypeFor(V validator);

  /// Return a Dart type generator for the validator type if necessary.
  ///
  /// The type should have the name given by [dartTypeFor] for any given
  /// [Validator].
  GeneratorExtras? getDartTypeGenerator(V validator);
}

/// Generates Dart code for the given schema types.
///
/// The generated code is written to the buffer provided in the argument,
/// or a new one is created if not provided, and then returned.
StringBuffer generateDartClasses(List<Objects> schemaTypes,
    {DartGeneratorOptions options = const DartGeneratorOptions()}) {
  final writer = StringBuffer();
  final generatorExtras = <GeneratorExtras>[];
  for (final type in schemaTypes) {
    writer.writeObjects(type, generatorExtras, options);
  }
  if (generatorExtras.isNotEmpty) {
    return writer.withExtras(generatorExtras);
  }
  return writer;
}

extension on StringBuffer {
  StringBuffer addExtrasIfOwnType(List<GeneratorExtras> extras,
      ObjectsBase<dynamic> objects, DartGeneratorOptions options) {
    if (objects is Maps) {
      _addExtrasInType(objects.valueType, extras, options);
      return this;
    }
    // in case of a simple Map, there's no extra type to write
    if (objects.isSimpleMap) return this;
    if (objects is Objects) {
      extras.add(GeneratorExtras(const {}, {options.className(objects.name)},
          (writer) => writer.writeObjects(objects, extras, options)));
    } else {
      throw UnsupportedError('The only subtypes of ObjectsBase allowed to be '
          'used for code generation are Objects and Maps. '
          'Cannot generate Dart code for $objects');
    }
    return this;
  }

  void writeType(SchemaType<dynamic> schemaType,
      List<GeneratorExtras> generatorExtras, DartGeneratorOptions options,
      [String Function(String) typeWrapper = identityString]) {
    final _ = switch (schemaType) {
      Nullable<dynamic, NonNull>(type: var type) =>
        writeType(type, generatorExtras, options, nullable),
      Validatable() =>
        writeValidatableType(schemaType, generatorExtras, options, typeWrapper),
      Ints() => write(typeWrapper('int')),
      Floats() => write(typeWrapper('double')),
      Strings() => write(typeWrapper('String')),
      Bools() => write(typeWrapper('bool')),
      Arrays<dynamic, SchemaType>(itemsType: var type) =>
        writeType(type, generatorExtras, options, (t) => array(t, typeWrapper)),
      ObjectsBase() => addExtrasIfOwnType(generatorExtras, schemaType, options)
          .write(typeWrapper(schemaType.dartTypeString(options))),
    };
  }

  void writeValidatableType(Validatable<dynamic> schemaType,
      List<GeneratorExtras> generatorExtras, DartGeneratorOptions options,
      [String Function(String) typeWrapper = identityString]) {
    final validator = schemaType.validator;
    final generator = schemaType.dartGenOption;
    if (generator == null) {
      writeType(schemaType.type, generatorExtras, options, typeWrapper);
    } else {
      write(typeWrapper(generator.dartTypeFor(validator)));
      generator.getDartTypeGenerator(validator)?.vmap(generatorExtras.add);
    }
  }

  void writeObjects(Objects objects, List<GeneratorExtras> extras,
      DartGeneratorOptions options) {
    writeComments(objects.description);
    write(options.insertBeforeClass(objects.name));
    writeln('class ${options.className(objects.name)} {');
    writeFields(objects, extras, options);
    writeConstructor(objects, options);
    options.methodGenerators
        .map((gen) => gen.generateMethod(this, objects, options))
        .nonNulls
        .forEach(extras.add);
    writeln('}');
  }

  void writeComments(String comments, [String indent = '']) {
    if (comments.isEmpty) return;
    for (final line in comments.split("\n")) {
      if (line.isEmpty) {
        writeln('$indent///');
      } else {
        write('$indent/// ');
        writeln(line);
      }
    }
  }

  void writeFields(Objects objects, List<GeneratorExtras> extras,
      DartGeneratorOptions options) {
    objects.properties.forEach((key, value) {
      writeComments(value.description, '  ');
      write('  ');
      options.insertBeforeField?.vmap((get) => write(get(key, value)));
      writeType(value.type, extras, options);
      write(' ${options.fieldName(key)}');
      writeln(';');
    });
    if (objects.unknownPropertiesStrategy == UnknownPropertiesStrategy.keep) {
      write('  ');
      options.insertBeforeField?.vmap(
          (get) => write(get('extras', const Property(Objects('Map', {})))));
      writeln('Map<String, Object?> extras;');
    }
  }

  void writeConstructor(Objects objects, DartGeneratorOptions options) {
    write('  ');
    options.insertBeforeConstructor?.vmap((get) => write(get()));
    writeln('${options.className(objects.name)}({');
    objects.properties.forEach((key, value) {
      options.insertBeforeConstructorArg?.vmap((get) => get(key, value));
      write(value.isRequired ? '    required ' : '    ');
      write('this.');
      write(options.fieldName(key));
      value.defaultValue?.vmap((def) {
        final type = value.type;
        if (type is ObjectsBase && !type.isSimpleMap) {
          throw UnsupportedError(
              'default values of type ObjectsBase are not supported '
              'unless the type is Objects with empty properties, or Maps.');
        }
        write(' = ');
        writeValue(value.type, def, consted: true);
      });
      writeln(',');
    });
    if (objects.unknownPropertiesStrategy == UnknownPropertiesStrategy.keep) {
      writeln('    this.extras = const {},');
    }
    writeln('  });');
  }

  void writeToString(Objects objects, DartGeneratorOptions options) {
    write('  @override\n'
        '  String toString() =>\n'
        '    ');
    writeln(quote('${options.className(objects.name)}{'));
    final hasExtras =
        objects.unknownPropertiesStrategy == UnknownPropertiesStrategy.keep;
    final lastIndex = objects.properties.length - (hasExtras ? 0 : 1);
    var index = 0;
    objects.properties.forEach((key, value) {
      write('    ');
      final fieldName = options.fieldName(key);
      final wrapValue = value.type.isStringOrNull() ? quoteAndDollar : dollar;
      final suffix = index++ == lastIndex ? '' : ', ';
      if (value.type.isNullableString()) {
        writeln(quote(
            '$fieldName: \${$fieldName == null ? "null" : \'${wrapValue(fieldName)}\'}$suffix'));
      } else {
        writeln(quote('$fieldName: ${wrapValue(fieldName)}$suffix'));
      }
    });
    if (hasExtras) {
      writeln(r"    'extras: $extras'");
    }
    write('    ');
    write(quote('}'));
    writeln(';');
  }

  GeneratorExtras? writeEquals(Objects objects, DartGeneratorOptions options) {
    writeln('  @override\n'
        '  bool operator ==(Object other) =>\n'
        '    identical(this, other) ||');
    write('    other is ${options.className(objects.name)} &&\n'
        '    runtimeType == other.runtimeType');
    final hasExtras =
        objects.unknownPropertiesStrategy == UnknownPropertiesStrategy.keep;
    GeneratorExtras? extras;
    if (hasExtras) {
      extras = const GeneratorExtras({'package:collection/collection.dart'});
    }
    if (objects.properties.isNotEmpty) {
      writeln(' &&');
      write(objects.properties.entries
          .map((entry) {
            final fieldName = options.fieldName(entry.key);
            final type = entry.value.type;
            final listItemType = type.listItemsTypeOrNull(options);
            if (listItemType != null) {
              extras =
                  const GeneratorExtras({'package:collection/collection.dart'});
              return '    const ListEquality<$listItemType>()'
                  '.equals($fieldName, other.$fieldName)';
            }
            final mapValueType = type.mapValueTypeOrNull(options);
            if (mapValueType != null) {
              extras =
                  const GeneratorExtras({'package:collection/collection.dart'});
              return '    const MapEquality<String, $mapValueType>()'
                  '.equals($fieldName, other.$fieldName)';
            }
            return '    $fieldName == other.$fieldName';
          })
          .followedBy(hasExtras
              ? {
                  '    const MapEquality<String, Object?>().equals(extras, other.extras)'
                }
              : {})
          .join(' &&\n'));
    }
    writeln(';');
    return extras;
  }

  void writeHashCode(Objects objects, DartGeneratorOptions options) {
    final hasExtras =
        objects.unknownPropertiesStrategy == UnknownPropertiesStrategy.keep;
    writeln('  @override\n'
        '  int get hashCode =>');
    if (objects.properties.isEmpty && !hasExtras) {
      write('    runtimeType.hashCode');
    } else {
      write('    ');
      write(objects.properties.entries
          .map((entry) {
            final fieldName = options.fieldName(entry.key);
            final type = entry.value.type;
            final listItemType = type.listItemsTypeOrNull(options);
            if (listItemType != null) {
              return 'const ListEquality<$listItemType>()'
                  '.hash($fieldName)';
            }
            final mapValueType = type.mapValueTypeOrNull(options);
            if (mapValueType != null) {
              return 'const MapEquality<String, $mapValueType>()'
                  '.hash($fieldName)';
            }
            return '$fieldName.hashCode';
          })
          .followedBy(hasExtras
              ? {'const MapEquality<String, Object?>().hash(extras)'}
              : {})
          .join(' ^ '));
    }
    writeln(';');
  }

  StringBuffer withExtras(List<GeneratorExtras> extras) {
    // write everything extra to this buffer, but keep imports separately
    final result = StringBuffer();
    final imports = writeExtras(extras);
    for (final imp in imports) {
      result.writeln('import ${quote(imp)};');
    }
    result.write(this);
    return result;
  }

  Iterable<String> writeExtras(List<GeneratorExtras> extras) {
    final imports = <String>{};
    final typesWritten = <String>{};
    // as extras items run, they may add more items to extras itself,
    // so we make a copy of it and then run items that were added later.
    while (extras.isNotEmpty) {
      final remaining = extras.drain();
      for (final extra in remaining) {
        imports.addAll(extra.imports);
        var shouldWrite = false;
        for (final type in extra.types) {
          shouldWrite |= typesWritten.add(type);
        }
        if (shouldWrite) extra.writeTypes(this);
      }
    }
    return imports;
  }
}

void _addExtrasInType(SchemaType<Object?> type, List<GeneratorExtras> extras,
    DartGeneratorOptions options) {
  return switch (type) {
    Nullable<Object?, NonNull>(type: var t) =>
      _addExtrasInType(t, extras, options),
    Ints() || Floats() || Strings() || Bools() => null,
    Arrays<Object?, SchemaType>(itemsType: var t) =>
      _addExtrasInType(t, extras, options),
    Maps(valueType: var t) => _addExtrasInType(t, extras, options),
    Objects() when (type.isSimpleMap) => null,
    Objects() => extras.add(GeneratorExtras(
        const {},
        {options.className(type.name)},
        (w) => w.writeObjects(type, extras, options))),
    ObjectsBase<Object?>() => null,
    Validatable<Object?>() => _addExtrasInValidator(type, extras, options),
  };
}

void _addExtrasInValidator(Validatable<Object?> type,
    List<GeneratorExtras> extras, DartGeneratorOptions options) {
  final dartGen = type.dartGenOption;
  if (dartGen == null) {
    return _addExtrasInType(type.type, extras, options);
  }
  final generator = dartGen.getDartTypeGenerator(type.validator);
  if (generator != null) {
    extras.add(generator);
  }
}

extension on SchemaType<dynamic> {
  bool isNullableString() {
    final self = this;
    return self is Nullable<Object?, Object?> && self.type is Strings;
  }

  bool isStringOrNull() {
    final self = this;
    return self is Strings || isNullableString();
  }
}
