import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart' show IterableExtension;

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

/// Signature of JSON Schema writer functions.
///
/// See [jsonSchemaValidatorGenerators].
typedef JsonSchemaWriterFunction = void Function(Object validator,
    SchemaType<Object?> type, StringBuffer buffer, JsonSchemaOptions options);

/// Registry for functions that can generate JSON Schema declarations.
///
/// This Map can handle all schemake validators. Custom validators can be
/// added to it as needed, or changed by [Zone] as explained later.
///
/// The JSON Schema for the validator is written to the [StringBuffer] provided
/// to the function. The buffer will be writing inside the JSON object
/// containing the `type` wrapped by the Validator.
///
/// For example, if the type is `Validatable(Strings(), validator)`, the buffer
/// will have written `{ "type": "string"` when the function is called.
/// The generator function could write something like `, "pattern": "[a-z]+"`,
/// resulting in the schema `{ "type": "string", "pattern": "[a-z]+" }`
///
/// Notice that the [JsonSchemaOptions] argument will always have value `false`
/// for properties [JsonSchemaOptions.startObject] and [JsonSchemaOptions.endObject]
/// because the JSON object is started and ended by schemake.
///
/// ## Changing the generators only for a specific [Zone]
///
/// This registry can be modified globally by modifying this Map or,
/// if you prefer to avoid modifying global state, by setting the [Zone] key
/// [jsonSchemaValidatorGeneratorsZoneKey]
/// with a `Map` with the same type as this value.
/// See [runZoned] for details on how to customize a [Zone].
final jsonSchemaValidatorGenerators = <Type, JsonSchemaWriterFunction>{
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
/// including setting it to `null` so `$schema` will not be added to the result.
/// Notice that if another value is given, it makes no difference to how the
/// rest of the schema is generated (i.e. this method cannot generate schemas
/// for other JSON Schema versions).
///
/// See [jsonSchemaValidatorGenerators].
StringBuffer generateJsonSchema(SchemaType<Object?> schemaType,
    {String? schemaUri = jsonSchema_2020_12,
    String? schemaId,
    JsonSchemaOptions options = const JsonSchemaOptions()}) {
  final buffer = StringBuffer();
  if (options.startObject) {
    buffer.write('{ ');
  }
  if (schemaUri != null) {
    buffer.write(r'"$schema": ');
    buffer.writeJson(schemaUri);
  }
  if (schemaId != null) {
    buffer.write(r', "$id": ');
    buffer.writeJson(schemaId);
  }
  if (schemaUri != null || schemaId != null) {
    buffer.write(', ');
  }

  _generate(schemaType, buffer, null, options.copyWith(startObject: false));

  return buffer;
}

/// [Zone] key for non-global [jsonSchemaValidatorGenerators].
const Symbol jsonSchemaValidatorGeneratorsZoneKey =
    #jsonSchemaValidatorGenerators;

/// Simplified version of [generateJsonSchema] that only generates the type
/// definition.
StringBuffer generateTypeJsonSchema(SchemaType<Object?> schemaType) {
  final buffer = StringBuffer();
  _generate(schemaType, buffer);
  return buffer;
}

void _generate(SchemaType<Object?> type, StringBuffer buffer,
    [String? description,
    JsonSchemaOptions options = const JsonSchemaOptions()]) {
  final useRefs = options.useRefsForNestedTypes;
  Map<String, ObjectsBase<Object?>> refs = useRefs ? {} : const {};
  buffer.writeSchemaType(
      type, refs, description, options.copyWith(endObject: !useRefs));
  if (useRefs) {
    buffer.writeRefs(refs, options.externalTypes);
    if (options.endObject) {
      buffer.write(' }');
    }
  }
}

/// Options for generating JSON Schemas.
///
/// Parameter [useRefsForNestedTypes] defines whether to use `$ref` pointing to
/// local `$defs` for nested types. This setting does not apply to any types in
/// [externalTypes].
///
/// Parameter [externalTypes] defines the types which should always be pointed
/// at by a `$ref` to an external schema (given by the values of the Map).
/// Notice that because [SchemaType] is used as a key on the Map, you should
/// only use `const` values as keys as [SchemaType] does not define equality.
///
/// Parameters [startObject] and [endObject] define whether to  open/close
/// the JSON object. For example, you can set [endObject] to `false` and then
/// continue writing more definitions in the resulting schema object, in which
/// case you must remember to close the JSON object with `}`.
///
/// See also [generateJsonSchema].
class JsonSchemaOptions {
  final bool startObject;
  final bool endObject;
  final bool nullable;
  final bool useRefsForNestedTypes;
  final Map<SchemaType<Object?>, String> externalTypes;

  const JsonSchemaOptions(
      {this.startObject = true,
      this.endObject = true,
      this.nullable = false,
      this.useRefsForNestedTypes = true,
      this.externalTypes = const {}});

  JsonSchemaOptions copyWith({
    bool? startObject,
    bool? endObject,
    bool? nullable,
    bool? useRefsForNestedTypes,
    Map<SchemaType<Object?>, String>? externalTypes,
  }) {
    return JsonSchemaOptions(
      startObject: startObject ?? this.startObject,
      endObject: endObject ?? this.endObject,
      nullable: nullable ?? this.nullable,
      useRefsForNestedTypes:
          useRefsForNestedTypes ?? this.useRefsForNestedTypes,
      externalTypes: externalTypes ?? this.externalTypes,
    );
  }

  ///  Returns a [JsonSchemaOptions] for use with an inner type.
  ///
  /// For example, when writing the type of an item in an array or a property
  /// in an object, this method can be used to ensure the type is fully written
  /// even if the original options set [startObject] or [endObject] to false.
  /// This method also sets [nullable] to false.
  JsonSchemaOptions forInnerType() {
    if (startObject && endObject && !nullable) {
      return this;
    }
    return JsonSchemaOptions(
      startObject: true,
      endObject: true,
      nullable: false,
      useRefsForNestedTypes: useRefsForNestedTypes,
      externalTypes: externalTypes,
    );
  }
}

_AdditionalPropsType _getAdditionalPropsType(
    UnknownPropertiesStrategy strategy, SchemaType<Object?>? schemaType) {
  final additionalPropsType = switch (strategy) {
    UnknownPropertiesStrategy.ignore => const _Any(),
    UnknownPropertiesStrategy.keep => schemaType == null
        ? const _Any()
        : _AdditionalPropsSchemaType(schemaType),
    UnknownPropertiesStrategy.forbid => _None(),
  };
  return additionalPropsType;
}

extension on StringBuffer {
  void writeSchemaType(
      SchemaType<Object?> type, Map<String, ObjectsBase<Object?>> refs,
      [String? description,
      JsonSchemaOptions options = const JsonSchemaOptions()]) {
    return switch (type) {
      Nullable<Object?, NonNull>(type: var innerType) => writeSchemaType(
          innerType, refs, description, options.copyWith(nullable: true)),
      Ints() => writeType("integer", description, options),
      Floats() => writeType("number", description, options),
      Strings() => writeType("string", description, options),
      Bools() => writeType("boolean", description, options),
      Arrays<dynamic, SchemaType>(itemsType: var type) =>
        writeArray(type, refs, description, options),
      ObjectsBase<Object?>() =>
        writeObjectsBase(type, refs, description, options),
      Validatable<Object?>() =>
        writeValidatable(type, refs, description, options),
    };
  }

  void writeArray(
      SchemaType<Object?> type, Map<String, ObjectsBase<Object?>> refs,
      [String? description,
      JsonSchemaOptions options = const JsonSchemaOptions()]) {
    writeType('array', description, options.copyWith(endObject: false));
    write(', "items": ');
    if (type is ObjectsBase) {
      writeInnerType(options, type, refs, type.description);
      refs[type.name] = type;
    } else {
      writeSchemaType(type, refs, null, options.forInnerType());
    }
    if (options.endObject) {
      write(' }');
    }
  }

  void writeObject(Objects obj, Map<String, ObjectsBase<Object?>> refs,
      [JsonSchemaOptions options = const JsonSchemaOptions(),
      String? description]) {
    writeObjectType(
      obj.properties.entries,
      refs,
      additionalPropsType:
          _getAdditionalPropsType(obj.unknownPropertiesStrategy, null),
      title: obj.name,
      description: description ?? obj.description,
      options: options,
    );
  }

  void writeMap(Maps<Object?, SchemaType<Object?>> obj,
      Map<String, ObjectsBase<Object?>> refs,
      [JsonSchemaOptions options = const JsonSchemaOptions(),
      String? description]) {
    final additionalPropsType =
        _getAdditionalPropsType(obj.unknownPropertiesStrategy, obj.valueType);

    return writeObjectType(
        obj.knownProperties.map((p) => MapEntry(p, Property(obj.valueType))),
        refs,
        additionalPropsType: additionalPropsType,
        title: obj.name,
        description: description ?? obj.description,
        options: options);
  }

  void writeType(String type,
      [String? description,
      JsonSchemaOptions options = const JsonSchemaOptions()]) {
    if (options.startObject) {
      write('{ ');
    }
    if (options.nullable) {
      write('"type": ["$type", "null"]');
    } else {
      write('"type": "$type"');
    }
    if (description != null) {
      write(', "description": ');
      writeJson(description);
    }
    if (options.endObject) {
      write(' }');
    }
  }

  void writeObjectsBase(
      ObjectsBase<Object?> type, Map<String, ObjectsBase<Object?>> refs,
      [String? description,
      JsonSchemaOptions options = const JsonSchemaOptions()]) {
    return switch (type) {
      Objects() => writeObject(type, refs, options, description),
      Maps() => writeMap(type, refs, options, description),
      _ => writeType("object", type.description ?? description, options),
    };
  }

  void writeObjectType(Iterable<MapEntry<String, Property<Object?>>> props,
      Map<String, ObjectsBase<Object?>> refs,
      {_AdditionalPropsType additionalPropsType = const _Any(),
      String? title,
      String? description,
      JsonSchemaOptions options = const JsonSchemaOptions()}) {
    if (options.startObject) {
      write('{ ');
    }
    if (title != null) {
      write('"title": ');
      writeJson(title);
      write(', ');
    }
    if (description != null) {
      write('"description": ');
      writeJson(description);
      write(', ');
    }
    if (options.nullable) {
      write('"type": ["object", "null"]');
    } else {
      write('"type": "object"');
    }
    if (props.isNotEmpty) {
      write(', "properties": { ');
      final finalIndex = props.length - 1;
      for (final (i, prop) in props.indexed) {
        writeJson(prop.key);
        write(': ');
        writeInnerType(options, prop.value.type, refs, prop.value.description,
            prop.value.defaultValue);
        if (i != finalIndex) {
          write(', ');
        }
      }
      write(' }');
      final required =
          props.where((p) => p.value.isMandatory).map((p) => p.key).toList();
      if (required.isNotEmpty) {
        write(', "required": ');
        writeJson(required);
      }
    }
    switch (additionalPropsType) {
      case _AdditionalPropsSchemaType(type: var type):
        write(', "additionalProperties": ');
        writeInnerType(options.forInnerType(), type, refs, null);
        break;
      case _Any():
        // nothing to do, default for JSON Schema
        break;
      case _None():
        write(', "additionalProperties": false');
    }
    if (options.endObject) {
      write(' }');
    }
  }

  void writeInnerType(JsonSchemaOptions options, SchemaType<Object?> schemaType,
      Map<String, ObjectsBase<Object?>> refs, String? description,
      [Object? defaultValue]) {
    final externalType = options.externalTypes[schemaType];
    if (externalType != null) {
      writeRefType(externalType, isDef: false, description: description);
    } else if (options.useRefsForNestedTypes && schemaType is ObjectsBase) {
      writeRefType(schemaType.name, description: description);
      refs[schemaType.name] = schemaType;
    } else {
      var innerOptions = options.forInnerType();
      if (defaultValue != null) {
        innerOptions = innerOptions.copyWith(endObject: false);
      }
      writeSchemaType(schemaType, refs, description, innerOptions);
      if (defaultValue != null) {
        writeDefaultValue(defaultValue);
        write(' }');
      }
    }
  }

  void writeRefType(String path, {bool isDef = true, String? description}) {
    write(r'{ "$ref": ');
    writeJson((isDef ? r"#/$defs/" : '') + path);
    if (description != null) {
      write(', "description": ');
      writeJson(description);
    }
    write(' }');
  }

  void writeValidatable(
      Validatable<Object?> type, Map<String, ObjectsBase<Object?>> refs,
      [String? description,
      JsonSchemaOptions options = const JsonSchemaOptions()]) {
    final validator = type.validator;
    final writerFunctions = _getWriterFunctions();
    final generator = writerFunctions[validator.runtimeType];
    if (generator == null) {
      throw Exception('No JSON Schema registered for ${validator.runtimeType}. '
          'To register one, add it to the `jsonSchemaValidatorGenerators` Map.');
    }
    writeSchemaType(
        type.type, refs, description, options.copyWith(endObject: false));
    generator(
        validator,
        type.type,
        this,
        options.copyWith(
          startObject: false,
          endObject: false,
          nullable: false,
        ));
    if (options.endObject) {
      write(' }');
    }
  }

  void writeJson(Object value) {
    write(jsonEncode(value));
  }

  void writeRefs(Map<String, ObjectsBase<Object?>> refs,
      Map<SchemaType<Object?>, String> externalTypes) {
    if (refs.isEmpty) return;
    final options = JsonSchemaOptions(externalTypes: externalTypes);
    write(r', "$defs": { ');
    Set<String> writtenDefs = {};
    Map<String, ObjectsBase<Object?>> nextRefs = refs;
    while (nextRefs.isNotEmpty) {
      final finalIndex = nextRefs.length - 1;
      Map<String, ObjectsBase<Object?>> innerRefs = {};
      for (final (index, entry)
          in nextRefs.entries.sortedBy((e) => e.key).indexed) {
        writeJson(entry.key);
        writtenDefs.add(entry.key);
        write(': ');
        final ref = entry.value;
        writeObjectsBase(ref, innerRefs, null, options);
        if (index < finalIndex) {
          write(', ');
        }
      }
      innerRefs.removeWhere((name, t) => writtenDefs.contains(name));
      if (innerRefs.isNotEmpty) {
        write(', ');
      }
      nextRefs = innerRefs;
    }
    write(' }');
  }

  void writeDefaultValue(Object? defaultValue) {
    if (defaultValue == null) return;
    write(r', "default": ');
    writeJson(defaultValue);
  }
}

Map<Type, JsonSchemaWriterFunction> _getWriterFunctions() {
  final zoneMap = Zone.current[jsonSchemaValidatorGeneratorsZoneKey]
      as Map<Type, JsonSchemaWriterFunction>?;
  return zoneMap ?? jsonSchemaValidatorGenerators;
}

extension<T> on Property<T> {
  bool get isOptional => type is Nullable || defaultValue != null;

  bool get isMandatory => !isOptional;
}
