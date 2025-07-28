import 'dart:convert';

import '../types.dart';
import '../property.dart';

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
  void writeSchemaType(SchemaType<Object?> type, [String? description]) {
    return switch (type) {
      Nullable<Object?, NonNull>(type: var innerType) =>
        writeNullable(innerType, description),
      Ints() => writeType("integer", description: description),
      Floats() => writeType("number", description: description),
      Strings() => writeType("string", description: description),
      Bools() => writeType("boolean", description: description),
      Arrays<dynamic, SchemaType>(itemsType: var type) =>
        writeArray(type, description: description),
      ObjectsBase<Object?>() => switch (type) {
          Objects() => writeObject(type),
          Maps() => writeMap(type),
          _ => writeType("object", description: type.description),
        },
      Validatable<Object?>() => throw UnimplementedError(),
    };
  }

  void writeNullable(NonNull<Object?> schemaType, [String? description]) {
    return switch (schemaType) {
      Ints() => writeNullableType("integer", description: description),
      Floats() => writeNullableType("number", description: description),
      Strings() => writeNullableType("string", description: description),
      Bools() => writeNullableType("boolean", description: description),
      Arrays<dynamic, SchemaType>(itemsType: var type) =>
        writeArray(type, description: description, nullable: true),
      ObjectsBase<Object?>() => throw UnimplementedError(),
      Validatable<Object?>() => throw UnimplementedError(),
    };
  }

  void writeArray(SchemaType<Object?> type,
      {String? description, bool nullable = false}) {
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
    write(' }');
  }

  void writeObject(Objects obj) {
    writeObjectType(obj.properties.entries,
        title: obj.name, description: obj.description);
  }

  void writeMap(Maps<Object?, SchemaType<Object?>> obj) {
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
        description: obj.description);
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
        writeSchemaType(prop.value.type, prop.value.description);
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
    write(' }');
  }

  void writeJson(Object value) {
    write(jsonEncode(value));
  }
}
