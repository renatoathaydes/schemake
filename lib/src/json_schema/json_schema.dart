import 'dart:convert';

import '../property.dart';
import '../types.dart';
import '../validator.dart';
import 'validators.dart';

sealed class _AdditionalPropsType {
  const _AdditionalPropsType();
}

final class _AdditionalPropsSchemaType extends _AdditionalPropsType {
  final SchemaType<Object?> type;

  const _AdditionalPropsSchemaType(this.type);
}

final class _Any extends _AdditionalPropsType {
  const _Any();
}

final class _None extends _AdditionalPropsType {
  const _None();
}

/// Registry for functions that can generate JSON Schema declarations.
///
/// This Map can handle all schemake validators. Custom validators can be
/// added to it as needed.
/// The JSON Schema for the validator is written to the [StringBuffer] provided
/// to the function. The buffer will be writing inside the JSON object
/// containing the `type` wrapped by the Validator.
///
/// For example, if the type is `Validatable(Strings(), validator)`, the buffer
/// will have written `{ "type": "string"` when the function is called.
/// The generator function could write something like `, "pattern": "[a-z]+"`,
/// resulting in the schema `{ "type": "string", "pattern": "[a-z]+" }`
/// (the JSON object is closed by schemake).
final jsonSchemaValidatorGenerators = <Type,
    void Function(
        Object validator, SchemaType<Object?> type, StringBuffer buffer)>{
  EnumValidator: generateEnum,
  NonBlankStringValidator: generateNonBlankString,
  IntRangeValidator: generateIntRange,
  FloatRangeValidator: generateFloatRange,
};

const String jsonSchema_2020_12 =
    'https://json-schema.org/draft/2020-12/schema';

///
/// Generate a JSON Schema where the given [schemaType] is the root type.
///
/// An optional [schemaId] may be given and is the value of `$id` unless set
/// to `null`.
///
/// The default [schemaUri] is [jsonSchema_2020_12] but may be overridden,
/// including setting it to `null` so `$schema` will not be added to the schema.
/// Notice that if another value is given, it makes no difference to how the
/// rest of the schema is generated (i.e. it cannot generate schemas for other
/// JSON Schema versions).
///
/// Parameter [useRefsForNestedTypes] defines whether to use `$ref` pointing to
/// local `$defs` for nested types. This setting does not apply to any types in
/// [externalTypes].
///
/// Parameter [externalTypes] defines the types which should always be pointed
/// at by a `$ref` to an external schema (given by the values of the Map).
///
/// Parameter [endObject] defines whether to close the JSON object written
/// to the returned [StringBuffer]. You can set this to `false` and then
/// continue writing more definitions in the resulting schema object, in which
/// case you must remember to close the JSON object with `}`.
///
StringBuffer generateJsonSchema(
  SchemaType<Object?> schemaType, {
  String? schemaUri = jsonSchema_2020_12,
  String? schemaId,
  bool useRefsForNestedTypes = true,
  Map<SchemaType<Object?>, String> externalTypes = const {},
  bool endObject = true,
}) {
  final buffer = StringBuffer();
  buffer.write('{ ');
  var isFirstKey = true;
  if (schemaUri != null) {
    buffer.write(r'"$schema": ');
    buffer.writeJson(schemaUri);
    isFirstKey = false;
  }
  if (schemaId != null) {
    if (!isFirstKey) {
      buffer.write(', ');
    }
    buffer.write(r'"$id": ');
    buffer.writeJson(schemaId);
    isFirstKey = false;
  }

  _generate(schemaType, buffer, startObject: false, endObject: endObject);

  return buffer;
}

StringBuffer generateTypeJsonSchema(SchemaType<Object?> schemaType) {
  final buffer = StringBuffer();
  _generate(schemaType, buffer);
  return buffer;
}

void _generate(
  SchemaType<Object?> type,
  StringBuffer buffer, {
  bool startObject = true,
  bool endObject = true,
}) {
  buffer.writeSchemaType(type, startObject: startObject, endObject: endObject);
}

extension on StringBuffer {
  void writeSchemaType(SchemaType<Object?> type,
      {String? description,
      bool startObject = true,
      bool endObject = true,
      bool nullable = false}) {
    return switch (type) {
      Nullable<Object?, NonNull>(type: var innerType) => writeSchemaType(
          innerType,
          description: description,
          endObject: endObject,
          startObject: startObject,
          nullable: true),
      Ints() => writeType("integer",
          description: description,
          startObject: startObject,
          endObject: endObject,
          nullable: nullable),
      Floats() => writeType("number",
          description: description,
          startObject: startObject,
          endObject: endObject,
          nullable: nullable),
      Strings() => writeType("string",
          description: description,
          startObject: startObject,
          endObject: endObject,
          nullable: nullable),
      Bools() => writeType("boolean",
          description: description,
          startObject: startObject,
          endObject: endObject,
          nullable: nullable),
      Arrays<dynamic, SchemaType>(itemsType: var type) => writeArray(type,
          description: description,
          startObject: startObject,
          endObject: endObject,
          nullable: nullable),
      ObjectsBase<Object?>() => writeObjectsBase(type,
          description: description,
          startObject: startObject,
          endObject: endObject,
          nullable: nullable),
      Validatable<Object?>(type: var type, validator: var validator) =>
        writeValidatable(type, validator,
            startObject: startObject, endObject: endObject, nullable: nullable),
    };
  }

  void writeArray(SchemaType<Object?> type,
      {String? description,
      bool startObject = true,
      bool endObject = true,
      bool nullable = false}) {
    writeType('array',
        description: description,
        startObject: startObject,
        endObject: false,
        nullable: nullable);
    if (description != null) {
      write(', "description": ');
      writeJson(description);
    }
    write(', "items": ');
    writeSchemaType(type);
    if (endObject) {
      write(' }');
    }
  }

  void writeObject(Objects obj,
      {bool startObject = true, bool endObject = true, bool nullable = false}) {
    writeObjectType(obj.properties.entries,
        title: obj.name,
        description: obj.description,
        startObject: startObject,
        endObject: endObject,
        nullable: nullable);
  }

  void writeMap(Maps<Object?, SchemaType<Object?>> obj,
      {bool startObject = true, bool endObject = true, bool nullable = false}) {
    final additionalPropsType = switch (obj.unknownPropertiesStrategy) {
      UnknownPropertiesStrategy.ignore => const _Any(),
      UnknownPropertiesStrategy.keep =>
        _AdditionalPropsSchemaType(obj.valueType),
      UnknownPropertiesStrategy.forbid => _None(),
    };

    return writeObjectType(
        obj.knownProperties.map((p) => MapEntry(p, Property(obj.valueType))),
        additionalPropsType: additionalPropsType,
        title: obj.name,
        description: obj.description,
        startObject: startObject,
        endObject: endObject,
        nullable: nullable);
  }

  void writeType(String type,
      {String? description,
      bool startObject = true,
      bool endObject = true,
      bool nullable = false}) {
    if (startObject) {
      write('{ ');
    } else {
      write(', ');
    }
    if (nullable) {
      write('"type": ["$type", "null"]');
    } else {
      write('"type": "$type"');
    }
    if (description != null) {
      write(', "description": ');
      writeJson(description);
    }
    if (endObject) {
      write(' }');
    }
  }

  void writeObjectsBase(ObjectsBase<Object?> type,
      {String? description,
      required bool startObject,
      required bool endObject,
      bool nullable = false}) {
    return switch (type) {
      Objects() => writeObject(type,
          startObject: startObject, endObject: endObject, nullable: nullable),
      Maps() => writeMap(type,
          startObject: startObject, endObject: endObject, nullable: nullable),
      _ => writeType("object",
          description: type.description,
          startObject: startObject,
          endObject: endObject,
          nullable: nullable),
    };
  }

  void writeObjectType(
    Iterable<MapEntry<String, Property<Object?>>> props, {
    _AdditionalPropsType additionalPropsType = const _Any(),
    String? title,
    String? description,
    bool startObject = true,
    bool endObject = true,
    bool nullable = false,
  }) {
    if (startObject) {
      write('{ ');
    } else {
      write(', ');
    }
    if (nullable) {
      write('"type": ["object", "null"]');
    } else {
      write('"type": "object"');
    }
    if (title != null) {
      write(', "title": ');
      writeJson(title);
    }
    if (description != null) {
      write(', "description": ');
      writeJson(description);
    }
    if (props.isNotEmpty) {
      write(', "properties": { ');
      final finalIndex = props.length - 1;
      for (final (i, prop) in props.indexed) {
        writeJson(prop.key);
        write(': ');
        writeSchemaType(prop.value.type, description: prop.value.description);
        if (i != finalIndex) {
          write(', ');
        }
      }
      write(' }');
      final required = props
          .where((p) => p.value.type is! Nullable<Object?, NonNull<Object?>>)
          .map((p) => p.key)
          .toList();
      if (required.isNotEmpty) {
        write(', "required": ');
        writeJson(required);
      }
    }
    switch (additionalPropsType) {
      case _AdditionalPropsSchemaType(type: var type):
        write(', "additionalProperties": ');
        writeSchemaType(type);
        break;
      case _Any():
        // nothing to do
        break;
      case _None():
        write(', "additionalProperties": false');
    }
    if (endObject) {
      write(' }');
    }
  }

  void writeValidatable(NonNull<Object?> type, Validator<Object?> validator,
      {bool startObject = true, bool endObject = true, bool nullable = false}) {
    final generator = jsonSchemaValidatorGenerators[validator.runtimeType];
    if (generator == null) {
      throw Exception('No JSON Schema registered for ${validator.runtimeType}. '
          'To register one, add it to the `jsonSchemaValidatorGenerators` Map.');
    }
    writeSchemaType(type,
        startObject: startObject, endObject: false, nullable: nullable);
    generator(validator, type, this);
    if (endObject) {
      write(' }');
    }
  }

  void writeJson(Object value) {
    write(jsonEncode(value));
  }
}
