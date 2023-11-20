import 'package:conveniently/conveniently.dart';

import '../_text.dart';
import '../property.dart';
import '../types.dart';

class GeneratorExtras {
  final Set<String> imports;
  final void Function(StringBuffer) topLevelWriter;

  const GeneratorExtras(this.imports, this.topLevelWriter);
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
    buffer.writeEquals(objects, options);
    buffer.writeHashCode(objects, options);
    return null;
  }
}

final class DartGeneratorOptions with GeneratorOptions {
  final String? insertBeforeClass;
  final String Function(String propertyName)? fieldName;
  final String Function(Property<Object?> property)? insertBeforeField;
  final String Function(Property<Object?> property)? insertBeforeConstructorArg;
  final List<DartMethodGenerator> methodGenerators;

  const DartGeneratorOptions({
    this.insertBeforeClass,
    this.fieldName,
    this.insertBeforeField,
    this.insertBeforeConstructorArg,
    this.methodGenerators = const [
      DartToStringMethodGenerator(),
      DartEqualsAndHashCodeMethodGenerator()
    ],
  });
}

StringBuffer generateDart(List<Objects> schemaTypes) {
  final writer = StringBuffer();
  final remainingSchemas = [...schemaTypes];
  final generatorExtras = <GeneratorExtras>[];
  while (remainingSchemas.isNotEmpty) {
    final schemaType = remainingSchemas.removeLast();
    generatorExtras.addAll(writer.writeObjects(schemaType, remainingSchemas));
  }
  if (generatorExtras.isNotEmpty) {
    final extras = StringBuffer();
    // prepend the extras to the result
    extras.writeExtras(generatorExtras);
    extras.write(writer);
    return extras;
  }
  return writer;
}

extension on StringBuffer {
  StringBuffer acceptIfObjects(
      List<Objects> list, ObjectsBase<dynamic> objects) {
    if (objects is Objects) {
      list.add(objects);
    } else {
      throw UnsupportedError('The only subtype of ObjectsBase allowed to be '
          'used for code generation is Objects.');
    }
    return this;
  }

  void writeType(SchemaType<dynamic> schemaType, List<Objects> remainingObjects,
      [String Function(String) typeWrapper = identityString]) {
    final _ = switch (schemaType) {
      Nullable<dynamic, NonNull>(type: var type) =>
        writeType(type, remainingObjects, nullable),
      Validatable(type: var type) => writeType(type, remainingObjects),
      Ints() => write(typeWrapper('int')),
      Floats() => write(typeWrapper('double')),
      Strings() => write(typeWrapper('String')),
      Bools() => write(typeWrapper('bool')),
      Arrays<dynamic, SchemaType>(itemsType: var type) =>
        writeType(type, remainingObjects, array),
      ObjectsBase(name: var className) =>
        acceptIfObjects(remainingObjects, schemaType)
            .write(typeWrapper(className)),
    };
  }

  List<GeneratorExtras> writeObjects(
      Objects objects, List<Objects> remainingObjects) {
    final options = objects.generatorOptions
            .whereType<DartGeneratorOptions>()
            .firstOrNull ??
        const DartGeneratorOptions();
    options.insertBeforeClass?.vmap(write);
    writeln('\nclass ${objects.name} {');
    writeFields(objects, options, remainingObjects);
    // constructor
    writeConstructor(objects, options);
    final generatorExtras = options.methodGenerators
        .map((gen) => gen.generateMethod(this, objects, options))
        .whereType<GeneratorExtras>()
        .toList(growable: false);
    writeln('}');
    return generatorExtras;
  }

  void writeFields(Objects objects, DartGeneratorOptions options,
      List<Objects> remainingObjects) {
    objects.properties.forEach((key, value) {
      write('  ');
      options.insertBeforeField?.vmap((insert) => insert(value));
      writeType(value.type, remainingObjects);
      write(' ${options.fieldName?.vmap((f) => f(key)) ?? key}');
      writeln(';');
    });
  }

  void writeConstructor(Objects objects, DartGeneratorOptions options) {
    writeln('  ${objects.name}({');
    objects.properties.forEach((key, value) {
      options.insertBeforeConstructorArg?.vmap((insert) => insert(value));
      write(value.type is Nullable ? '    ' : '    required ');
      write('this.');
      write(options.fieldName?.vmap((f) => f(key)) ?? key);
      writeln(',');
    });
    writeln('  });');
  }

  void writeToString(Objects objects, DartGeneratorOptions options) {
    write('  @override\n'
        '  String toString() =>\n'
        '    ');
    writeln(quote('${objects.name}{'));
    objects.properties.forEach((key, value) {
      write('    ');
      final fieldName = options.fieldName?.vmap((f) => f(key)) ?? key;
      final wrapValue = value.type.isStringOrNull() ? quoteAndDollar : dollar;
      writeln(quote('$fieldName = ${wrapValue(fieldName)},'));
    });
    write('    ');
    write(quote('}'));
    writeln(';');
  }

  void writeEquals(Objects objects, DartGeneratorOptions options) {
    writeln('  @override\n'
        '  bool operator ==(Object other) =>\n'
        '    identical(this, other) ||');
    write('    other is ${objects.name} &&\n'
        '    runtimeType == other.runtimeType');
    if (objects.properties.isNotEmpty) {
      writeln(' &&');
      write(objects.properties.entries.map((entry) {
        final fieldName =
            options.fieldName?.vmap((f) => f(entry.key)) ?? entry.key;
        final isList = entry.value.type is Arrays<Object?, Object?>;
        return isList
            ? '    const ListEquality().equals($fieldName, other.$fieldName)'
            : '    $fieldName == other.$fieldName';
      }).join(' &&\n'));
    }
    writeln(';');
  }

  void writeHashCode(Objects objects, DartGeneratorOptions options) {
    writeln('  @override\n'
        '  int get hashCode =>');
    if (objects.properties.isEmpty) {
      write('    runtimeType.hashCode');
    } else {
      write('    ');
      write(objects.properties.entries.map((entry) {
        final fieldName =
            options.fieldName?.vmap((f) => f(entry.key)) ?? entry.key;
        return '$fieldName.hashCode';
      }).join(' ^ '));
    }
    writeln(';');
  }

  void writeExtras(Iterable<GeneratorExtras> extras) {
    for (final imp in extras.expand((e) => e.imports)) {
      writeln('import ${quote(imp)};');
    }
    for (final extra in extras) {
      extra.topLevelWriter(this);
    }
  }
}

extension on SchemaType<dynamic> {
  bool isStringOrNull() {
    final self = this;
    return self is Strings ||
        (self is Nullable<Object?, Object?> && self.type is Strings);
  }
}
