import '../schemake.dart';

String _identity(String s) => s;

String _nullable(String s) => "$s?";

String _array(String s) => "List<$s>";

StringBuffer generateDart(SchemaType<dynamic> schemaType,
    [StringBuffer? buffer, String Function(String) typeWrapper = _identity]) {
  final writer = buffer ?? StringBuffer();
  final _ = switch (schemaType) {
    Nullable<dynamic, NonNull>(type: var type) =>
      generateDart(type, writer, _nullable),
    Validatable(type: var type) => generateDart(type, writer),
    Ints() => writer.write(typeWrapper('int')),
    Floats() => writer.write(typeWrapper('double')),
    Strings() => writer.write(typeWrapper('String')),
    Bools() => writer.write(typeWrapper('bool')),
    Arrays<dynamic, SchemaType>(itemsType: var type) =>
      generateDart(type, writer, _array),
    Objects(properties: var props, dartClassName: var className) =>
      writer.writeObjects(className, props),
    Dictionaries<dynamic, SchemaType>() =>
      // TODO: Handle this case.
      null,
  };
  return writer;
}

extension on StringBuffer {
  void writeObjects(
      String className, Map<String, Property<Object?>> properties) {
    writeln('class $className {');
    properties.forEach((key, value) {
      write('  ');
      generateDart(value.type, this);
      write(' $key');
      writeln(';');
    });
    writeln('}');
  }
}
