import 'dart:convert';

import '../types.dart';

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
  void writeSchemaType(SchemaType<Object?> type) {
    return switch (type) {
      Nullable<Object?, NonNull>(type: var innerType) =>
        writeNullable(innerType),
      Ints() => writeType("integer"),
      Floats() => writeType("number"),
      Strings() => writeType("string"),
      Bools() => writeType("boolean"),
      Arrays<dynamic, SchemaType>() => throw UnimplementedError(),
      ObjectsBase<Object?>() => switch (type) {
          Objects() => writeObject(type),
          Maps() => writeMap(type),
          _ => writeType("object"),
        },
      Validatable<Object?>() => throw UnimplementedError(),
    };
  }

  void writeNullable(NonNull<Object?> schemaType) {
    return switch (schemaType) {
      Ints() => writeNullableType("integer"),
      Floats() => writeNullableType("number"),
      Strings() => writeNullableType("string"),
      Bools() => writeNullableType("boolean"),
      Arrays<dynamic, SchemaType>() => throw UnimplementedError(),
      ObjectsBase<Object?>() => throw UnimplementedError(),
      Validatable<Object?>() => throw UnimplementedError(),
    };
  }

  void writeObject(Objects obj) {}

  void writeMap(Maps<Object?, SchemaType<Object?>> obj) {
    return switch (obj.unknownPropertiesStrategy) {
      UnknownPropertiesStrategy.ignore => writeObjectType(
          obj.knownProperties.map((p) => MapEntry(p, obj.valueType)), _Any()),
      UnknownPropertiesStrategy.keep => writeObjectType(
          obj.knownProperties.map((p) => MapEntry(p, obj.valueType)),
          _AdditionalPropsSchemaType(obj.valueType)),
      UnknownPropertiesStrategy.forbid => writeObjectType(
          obj.knownProperties.map((p) => MapEntry(p, obj.valueType)), _None()),
    };
  }

  void writeType(String type) {
    write('{ "type": "$type" }');
  }

  void writeNullableType(String type) {
    write('{ "type": ["$type", "null"] }');
  }

  void writeObjectType(
    Iterable<MapEntry<String, SchemaType<Object?>>> props,
    _AdditionalPropsType additionalPropsType,
  ) {
    write('{ "type": "object"');
    if (props.isNotEmpty) {
      write(', "properties": { ');
      final finalIndex = props.length - 1;
      for (final (i, prop) in props.indexed) {
        writeJson(prop.key);
        write(': ');
        writeSchemaType(prop.value);
        if (i != finalIndex) {
          write(', ');
        }
      }
      write(' }');
      final required = props
          .where((p) => p.value is! Nullable<Object?, NonNull<Object?>>)
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
