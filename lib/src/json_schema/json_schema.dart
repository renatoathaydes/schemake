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

StringBuffer generateJsonSchema(List<SchemaType<Object?>> schemaTypes) {
  final buffer = StringBuffer();
  for (final type in schemaTypes) {
    _generate(type, buffer);
  }
  return buffer;
}

void _generate(SchemaType<Object?> type, StringBuffer buffer) {
  buffer.writeSchemaType(type);
}

extension on StringBuffer {
  void writeSchemaType(SchemaType<Object?> type,
      {String? description, bool endObject = true}) {
    return switch (type) {
      Nullable<Object?, NonNull>(type: var innerType) => writeNullable(
          innerType,
          description: description,
          endObject: endObject),
      Ints() =>
        writeType("integer", description: description, endObject: endObject),
      Floats() =>
        writeType("number", description: description, endObject: endObject),
      Strings() =>
        writeType("string", description: description, endObject: endObject),
      Bools() =>
        writeType("boolean", description: description, endObject: endObject),
      Arrays<dynamic, SchemaType>(itemsType: var type) =>
        writeArray(type, description: description, endObject: endObject),
      ObjectsBase<Object?>() => switch (type) {
          Objects() => writeObject(type, endObject: endObject),
          Maps() => writeMap(type, endObject: endObject),
          _ => writeType("object",
              description: type.description, endObject: endObject),
        },
      Validatable<Object?>(type: var type, validator: var validator) =>
        writeValidatable(type, validator, endObject: endObject),
    };
  }

  void writeNullable(NonNull<Object?> schemaType,
      {String? description, bool endObject = true}) {
    return switch (schemaType) {
      Ints() => writeNullableType("integer",
          description: description, endObject: endObject),
      Floats() => writeNullableType("number",
          description: description, endObject: endObject),
      Strings() => writeNullableType("string",
          description: description, endObject: endObject),
      Bools() => writeNullableType("boolean",
          description: description, endObject: endObject),
      Arrays<dynamic, SchemaType>(itemsType: var type) => writeArray(type,
          description: description, nullable: true, endObject: endObject),
      ObjectsBase<Object?>() => throw UnimplementedError(),
      Validatable<Object?>() => throw UnimplementedError(),
    };
  }

  void writeArray(SchemaType<Object?> type,
      {String? description, bool nullable = false, bool endObject = true}) {
    if (nullable) {
      writeNullableType('array', description: description, endObject: false);
    } else {
      writeType('array', description: description, endObject: false);
    }
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

  void writeObject(Objects obj, {bool endObject = true}) {
    writeObjectType(obj.properties.entries,
        title: obj.name, description: obj.description, endObject: endObject);
  }

  void writeMap(Maps<Object?, SchemaType<Object?>> obj,
      {bool endObject = true}) {
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
        endObject: endObject);
  }

  void writeType(String type, {String? description, bool endObject = true}) {
    write('{ "type": "$type"');
    if (description != null) {
      write(', "description": ');
      writeJson(description);
    }
    if (endObject) {
      write(' }');
    }
  }

  void writeNullableType(String type,
      {String? description, bool endObject = true}) {
    write('{ "type": ["$type", "null"]');
    if (description != null) {
      write(', "description": ');
      writeJson(description);
    }
    if (endObject) {
      write(' }');
    }
  }

  void writeObjectType(
    Iterable<MapEntry<String, Property<Object?>>> props, {
    _AdditionalPropsType additionalPropsType = const _Any(),
    String? title,
    String? description,
    bool endObject = true,
  }) {
    write('{ "type": "object"');
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
      {bool endObject = true}) {
    final generator = jsonSchemaValidatorGenerators[validator.runtimeType];
    if (generator == null) {
      throw Exception('No JSON Schema registered for ${validator.runtimeType}. '
          'To register one, add it to the `jsonSchemaValidatorGenerators` Map.');
    }
    writeSchemaType(type, endObject: false);
    generator(validator, type, this);
    if (endObject) {
      write(' }');
    }
  }

  void writeJson(Object value) {
    write(jsonEncode(value));
  }
}
