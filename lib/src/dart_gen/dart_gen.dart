import 'package:conveniently/conveniently.dart';

import '../../schemake.dart';

String _identity(String s) => s;

String _quote(String s) => "'$s'";

String _dollar(String s) => "\$$s";

String _quoteAndDollar(String s) => '"\$$s"';

String _nullable(String s) => "$s?";

String _array(String s) => "List<$s>";

mixin DartMethodGenerator {
  void generateMethod(
      StringBuffer buffer, Objects objects, DartGeneratorOptions options);
}

class DartToStringMethodGenerator with DartMethodGenerator {
  const DartToStringMethodGenerator();

  @override
  void generateMethod(
      StringBuffer buffer, Objects objects, DartGeneratorOptions options) {
    buffer.writeToString(objects, options);
  }
}

class DartEqualsAndHashCodeMethodGenerator with DartMethodGenerator {
  const DartEqualsAndHashCodeMethodGenerator();

  @override
  void generateMethod(
      StringBuffer buffer, Objects objects, DartGeneratorOptions options) {
    buffer.writeEquals(objects, options);
    buffer.writeHashCode(objects, options);
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

StringBuffer generateDart(List<Objects> schemaTypes, [StringBuffer? buffer]) {
  final writer = buffer ?? StringBuffer();
  final remainingSchemas = [...schemaTypes];
  while (remainingSchemas.isNotEmpty) {
    final schemaType = remainingSchemas.removeLast();
    writer.writeObjects(schemaType, remainingSchemas);
  }
  return writer;
}

extension on StringBuffer {
  StringBuffer addingTo(List<Objects> list, Objects objects) {
    list.add(objects);
    return this;
  }

  void writeType(SchemaType<dynamic> schemaType, List<Objects> remainingObjects,
      [String Function(String) typeWrapper = _identity]) {
    final _ = switch (schemaType) {
      Nullable<dynamic, NonNull>(type: var type) =>
        writeType(type, remainingObjects, _nullable),
      Validatable(type: var type) => writeType(type, remainingObjects),
      Ints() => write(typeWrapper('int')),
      Floats() => write(typeWrapper('double')),
      Strings() => write(typeWrapper('String')),
      Bools() => write(typeWrapper('bool')),
      Arrays<dynamic, SchemaType>(itemsType: var type) =>
        writeType(type, remainingObjects, _array),
      Objects(name: var className) =>
        addingTo(remainingObjects, schemaType).write(typeWrapper(className)),
      Dictionaries<dynamic, SchemaType>() =>
        // TODO: Handle this case.
        null,
    };
  }

  void writeObjects(Objects objects, List<Objects> remainingObjects) {
    final options = objects.generatorOptions
            .whereType<DartGeneratorOptions>()
            .firstOrNull ??
        const DartGeneratorOptions();
    options.insertBeforeClass?.vmap(write);
    writeln('\nclass ${objects.name} {');
    writeFields(objects, options, remainingObjects);
    // constructor
    writeConstructor(objects, options);
    for (final methodGenerator in options.methodGenerators) {
      methodGenerator.generateMethod(this, objects, options);
    }
    writeln('}');
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
    writeln(_quote('${objects.name}{'));
    objects.properties.forEach((key, value) {
      write('    ');
      final fieldName = options.fieldName?.vmap((f) => f(key)) ?? key;
      final wrapValue = value.type.isStringOrNull() ? _quoteAndDollar : _dollar;
      writeln(_quote('$fieldName = ${wrapValue(fieldName)},'));
    });
    write('    ');
    write(_quote('}'));
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

// @override
//   int get hashCode => name.hashCode ^ age.hashCode;
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
}

extension on SchemaType<dynamic> {
  bool isStringOrNull() {
    final self = this;
    return self is Strings ||
        (self is Nullable<Object?, Object?> && self.type is Strings);
  }
}
