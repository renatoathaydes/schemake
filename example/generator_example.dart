import 'package:schemake/schemake.dart';

StringBuffer generateSimpleSchemaDescription(SchemaType<Object> schemaType) {
  final result = StringBuffer();
  result.writeSchema(schemaType);
  return result;
}

extension on StringBuffer {
  void writeSchema(SchemaType<Object?> schemaType,
      {int level = 0, bool nullable = false}) {
    final _ = switch (schemaType) {
      Ints() => writeType('int', level: level, nullable: nullable),
      Floats() => writeType('float', level: level, nullable: nullable),
      Strings() => writeType('string', level: level, nullable: nullable),
      Bools() => writeType('boolean', level: level, nullable: nullable),
      Nullable<Object?, NonNull>(type: var type) =>
        writeSchema(type, level: level, nullable: true),
      Validatable(type: var type, validator: var validator) =>
        writeValidatable(type, validator, level: level, nullable: nullable),
      Arrays<Object?, SchemaType>(itemsType: var type) =>
        writeArrays(type, level: level, nullable: nullable),
      Objects() => writeObjects(schemaType, level: level, nullable: nullable),
      Maps() => writeMaps(schemaType, level: level, nullable: nullable),
      ObjectsBase() =>
        throw Exception('Custom object type is not supported: $schemaType'),
    };
  }

  void writeIndent(int level, [String line = '']) {
    for (var i = 0; i < level; i++) {
      write('    ');
    }
    write(line);
  }

  void writeType(String type, {required int level, required bool nullable}) {
    writeIndent(level, type);
    if (nullable) write('?');
  }

  void writeValidatable(
      SchemaType<Object?> schemaType, Validator<Object?> validator,
      {required int level, required bool nullable}) {
    writeIndent(level, 'validatable:\n');
    writeIndent(level + 1, 'validator:\n');
    writeIndent(level + 2, '$validator\n');
    writeIndent(level + 1, 'type:\n');
    writeSchema(schemaType, level: level + 2);
    write('\n');
  }

  void writeArrays(SchemaType<Object?> valueType,
      {required int level, required bool nullable}) {
    writeIndent(level, 'nullable: $nullable\n');
    writeIndent(level, 'arrayOf:\n');
    writeSchema(valueType, level: level + 1);
    writeln();
  }

  void writeObjects(Objects obj, {required int level, required bool nullable}) {
    writeIndent(level, 'object:\n');
    writeIndent(level + 1, 'name: ${obj.name}\n');
    writeIndent(level + 1, 'nullable: $nullable\n');
    writeIndent(level + 1, 'properties:\n');
    obj.properties.forEach((key, prop) {
      writeIndent(level + 2, '$key:\n');
      writeSchema(prop.type, level: level + 3);
      writeln();
    });
    writeln();
  }

  void writeMaps(Maps<Object?, SchemaType<Object?>> type,
      {required int level, required bool nullable}) {
    writeIndent(level, 'Map:\n');
    writeIndent(level + 1, 'nullable: $nullable\n');
    writeIndent(level + 1, 'keyType: string\n');
    writeIndent(level + 1, 'valType:\n');
    writeSchema(type.valueType, level: level + 2);
    writeln();
  }
}

void main() {
  const exampleSchema = Objects('Person', {
    'name': Property(Strings()),
    'age': Property(Nullable(Ints())),
    'hobbies': Property(Arrays<String, Strings>(Strings())),
  });

  print(generateSimpleSchemaDescription(exampleSchema));
}
