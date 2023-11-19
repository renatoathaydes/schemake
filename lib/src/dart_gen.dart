import 'package:conveniently/conveniently.dart';

import '../schemake.dart';

String _identity(String s) => s;

String _quote(String s) => "'$s'";

String _dollar(String s) => "\$$s";

String _quoteAndDollar(String s) => '"\$$s"';

String _nullable(String s) => "$s?";

String _array(String s) => "List<$s>";

final class DartGeneratorOptions with GeneratorOptions {
  final String? insertBeforeClass;
  final String Function(String propertyName)? fieldName;
  final String Function(Property<Object?> property)? insertBeforeField;
  final String Function(Property<Object?> property)? insertBeforeConstructorArg;
  final String? insertWithinClass;
  final bool generateToString;
  final bool generateEqualsAndHashCode;
  final bool generateToJson;
  final bool generateFromJson;

  const DartGeneratorOptions({
    this.insertBeforeClass,
    this.fieldName,
    this.insertBeforeField,
    this.insertBeforeConstructorArg,
    this.insertWithinClass,
    this.generateToString = true,
    this.generateEqualsAndHashCode = true,
    this.generateToJson = false,
    this.generateFromJson = false,
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
    options.insertWithinClass?.vmap(writeln);
    if (options.generateToString) writeToString(objects, options);
    if (options.generateEqualsAndHashCode) {
      writeEquals(objects);
      writeHashCode(objects);
    }
    if (options.generateFromJson) writeFromJson(objects);
    if (options.generateToJson) writeToJson(objects);
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
      final wrapValue =
          value.type.isStringOrNull() ? _quoteAndDollar : _dollar;
      writeln(_quote('$fieldName = ${wrapValue(fieldName)},'));
    });
    write('    ');
    write(_quote('}'));
    writeln(';');
  }

  void writeEquals(Objects objects) {}

  void writeHashCode(Objects objects) {}

  void writeFromJson(Objects objects) {}

  void writeToJson(Objects objects) {}
}

extension on SchemaType<dynamic> {
  bool isStringOrNull() {
    final self = this;
    return self is Strings ||
        (self is Nullable<Object?, Object?> && self.type is Strings);
  }
}
