import '../schemake.dart';

String _identity(String s) => s;

String _nullable(String s) => "$s?";

String _array(String s) => "List<$s>";

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
      Objects(dartClassName: var className) =>
        addingTo(remainingObjects, schemaType).write(typeWrapper(className)),
      Dictionaries<dynamic, SchemaType>() =>
        // TODO: Handle this case.
        null,
    };
  }

  void writeObjects(Objects objects, List<Objects> remainingObjects) {
    writeln('class ${objects.dartClassName} {');
    objects.properties.forEach((key, value) {
      write('  ');
      writeType(value.type, remainingObjects);
      write(' $key');
      writeln(';');
    });
    writeln('}');
  }
}
