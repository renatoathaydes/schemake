import 'dart:async';

import 'package:schemake/json_schema.dart';
import 'package:schemake/schemake.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('Basic types', () {
    test('integer', () {
      expect(
          generateTypeJsonSchema(Ints()).toString(), '{ "type": "integer" }');
    });
    test('number', () {
      expect(
          generateTypeJsonSchema(Floats()).toString(), '{ "type": "number" }');
    });
    test('boolean', () {
      expect(
          generateTypeJsonSchema(Bools()).toString(), '{ "type": "boolean" }');
    });
    test('string', () {
      expect(
          generateTypeJsonSchema(Strings()).toString(), '{ "type": "string" }');
    });
  });

  group('Nullable Basic types', () {
    test('integer', () {
      expect(generateTypeJsonSchema(Nullable(Ints())).toString(),
          '{ "type": ["integer", "null"] }');
    });
    test('number', () {
      expect(generateTypeJsonSchema(Nullable(Floats())).toString(),
          '{ "type": ["number", "null"] }');
    });
    test('boolean', () {
      expect(generateTypeJsonSchema(Nullable(Bools())).toString(),
          '{ "type": ["boolean", "null"] }');
    });
    test('string', () {
      expect(generateTypeJsonSchema(Nullable(Strings())).toString(),
          '{ "type": ["string", "null"] }');
    });
  });

  group('Arrays', () {
    test('of integer', () {
      expect(generateTypeJsonSchema(Arrays<int, Ints>(Ints())).toString(),
          '{ "type": "array", "items": { "type": "integer" } }');
    });

    test('of string', () {
      expect(
          generateTypeJsonSchema(Arrays<String, Strings>(Strings())).toString(),
          '{ "type": "array", "items": { "type": "string" } }');
    });

    test('of nullable string', () {
      expect(
          generateTypeJsonSchema(Arrays<String?, Nullable<String?, Strings>>(
                  Nullable(Strings())))
              .toString(),
          '{ "type": "array", "items": { "type": ["string", "null"] } }');
    });
  });

  group('Nullable Arrays', () {
    test('integer', () {
      expect(
          generateTypeJsonSchema(Nullable(Arrays<int, Ints>(Ints())))
              .toString(),
          '{ "type": ["array", "null"], "items": { "type": "integer" } }');
    });
    test('number', () {
      expect(
          generateTypeJsonSchema(Nullable(Arrays<double, Floats>(Floats())))
              .toString(),
          '{ "type": ["array", "null"], "items": { "type": "number" } }');
    });
  });

  group('Maps', () {
    test('default Maps with value type Strings', () {
      expect(
          generateTypeJsonSchema(
                  Maps<String, Strings>('MyMap', valueType: Strings()))
              .toString(),
          '{ "title": "MyMap", "type": "object", "additionalProperties": { "type": "string" } }');
    });

    test('default Maps with value type Ints', () {
      expect(
          generateTypeJsonSchema(Maps<int, Ints>('MyMap', valueType: Ints()))
              .toString(),
          '{ "title": "MyMap", "type": "object", "additionalProperties": { "type": "integer" } }');
    });

    test('default Maps with value type Ints, some known properties', () {
      expect(
          generateTypeJsonSchema(Maps<int, Ints>('MyMap',
              valueType: Ints(), knownProperties: {'hello', 'bye'})).toString(),
          '{ '
          '"title": "MyMap", '
          '"type": "object", '
          '"properties": { '
          '"hello": { "type": "integer" }, '
          '"bye": { "type": "integer" } '
          '}, '
          '"required": ["hello","bye"], '
          '"additionalProperties": { "type": "integer" } '
          '}');
    });

    test('Maps with value type Ints, ignore additional properties', () {
      expect(
          generateTypeJsonSchema(Maps<int, Ints>('MyMap',
                  valueType: Ints(),
                  unknownPropertiesStrategy: UnknownPropertiesStrategy.ignore))
              .toString(),
          '{ "title": "MyMap", "type": "object" }');
    });

    test(
        'Maps with value type Ints, some known properties, ignore additional properties',
        () {
      expect(
          generateTypeJsonSchema(Maps<int, Ints>('MyMap',
                  valueType: Ints(),
                  knownProperties: {'foo', 'bar'},
                  unknownPropertiesStrategy: UnknownPropertiesStrategy.ignore))
              .toString(),
          '{ "title": "MyMap", "type": "object", "properties": { '
          '"foo": { "type": "integer" }, '
          '"bar": { "type": "integer" } '
          '}, "required": ["foo","bar"] }');
    });

    test(
        'Maps with value type Ints, some known properties, forbid additional properties',
        () {
      expect(
          generateTypeJsonSchema(Maps<int, Ints>('MyMap',
                  valueType: Ints(),
                  knownProperties: {'foo', 'bar'},
                  unknownPropertiesStrategy: UnknownPropertiesStrategy.forbid))
              .toString(),
          '{ "title": "MyMap", "type": "object", "properties": { '
          '"foo": { "type": "integer" }, '
          '"bar": { "type": "integer" } '
          '}, "required": ["foo","bar"], '
          '"additionalProperties": false }');
    });
  });

  group('Objects', () {
    test('default Object with one property', () {
      expect(
          generateTypeJsonSchema(Objects('Foo', {'bar': Property(Strings())}))
              .toString(),
          '{ "title": "Foo", '
          '"type": "object", '
          '"properties": { '
          '"bar": { "type": "string" } '
          '}, "required": ["bar"], "additionalProperties": false }');
    });

    test('default Object with one optional property', () {
      expect(
          generateTypeJsonSchema(
                  Objects('Foo', {'bar': Property(Nullable(Strings()))}))
              .toString(),
          '{ "title": "Foo", '
          '"type": "object", '
          '"properties": { '
          '"bar": { "type": ["string", "null"] } '
          '}, "additionalProperties": false }');
    });

    test('default Object with a mandatory and an optional property', () {
      expect(
          generateTypeJsonSchema(Objects('Foo', {
            'foo': Property(Nullable(Ints())),
            'bar': Property(Strings())
          })).toString(),
          '{ "title": "Foo", '
          '"type": "object", '
          '"properties": { '
          '"foo": { "type": ["integer", "null"] }, '
          '"bar": { "type": "string" } '
          '}, "required": ["bar"], "additionalProperties": false }');
    });

    test('Object with descriptions', () {
      expect(
          generateTypeJsonSchema(Objects(
                  'MyObject',
                  {
                    'myProp': Property(Ints(), description: 'my property'),
                    'otherProp': Property(
                        Nullable(Objects(
                            'HasDescription',
                            {
                              'prop':
                                  Property(Strings(), description: 'the prop'),
                            },
                            description: 'Object description')),
                        // the property description wins
                        description: 'Property description'),
                  },
                  description: 'this is an object'))
              .toString(),
          '{ "title": "MyObject", '
          '"description": "this is an object", '
          '"type": "object", '
          '"properties": { '
          '"myProp": { "type": "integer", "description": "my property" }, '
          r'"otherProp": { "title": "HasDescription",'
          r' "description": "Property description", "type": ["object", "null"],'
          r' "properties": { "prop": { "type": "string", "description": "the prop" } },'
          r' "required": ["prop"], "additionalProperties": false } '
          '}, "required": ["myProp"], "additionalProperties": false'
          ' }');
    });

    test('Object with nullable property with default values', () {
      expect(
          generateTypeJsonSchema(Objects('Foo', {
            'foo': Property(Nullable(Ints()), defaultValue: 10),
          })).toString(),
          '{ "title": "Foo", '
          '"type": "object", '
          '"properties": { '
          '"foo": { "type": ["integer", "null"], "default": 10 } '
          '}, "additionalProperties": false }');
    });

    test('Object with mandatory property with default values', () {
      expect(
          generateTypeJsonSchema(Objects('Foo', {
            'foo': Property(Ints(), defaultValue: 10),
          })).toString(),
          '{ "title": "Foo", '
          '"type": "object", '
          '"properties": { '
          '"foo": { "type": "integer", "default": 10 } '
          '}, "additionalProperties": false }');
    });

    test('Object with optional array property with default value', () {
      expect(
          generateTypeJsonSchema(Objects('Foo', {
            'foo': Property(Nullable(Arrays<String, Strings>(Strings())),
                defaultValue: const []),
          })).toString(),
          '{ "title": "Foo", '
          '"type": "object", '
          '"properties": { '
          '"foo": { "type": ["array", "null"], "items": { "type": "string" }, "default": [] } '
          '}, "additionalProperties": false }');
    });
  });

  group('Nullable Objects', () {
    test('Nullable Object with a mandatory and an optional property', () {
      expect(
          generateTypeJsonSchema(Nullable(Objects(
                  'Foo',
                  {
                    'foo': Property(Nullable(Ints())),
                    'bar': Property(Strings())
                  },
                  description: 'nullable object')))
              .toString(),
          '{ "title": "Foo", '
          '"description": "nullable object", '
          '"type": ["object", "null"], '
          '"properties": { '
          '"foo": { "type": ["integer", "null"] }, '
          '"bar": { "type": "string" } '
          '}, "required": ["bar"], "additionalProperties": false }');
    });
  });

  group('Nullable Maps', () {
    test('Nullable Maps with value type Strings', () {
      expect(
          generateTypeJsonSchema(Nullable(
                  Maps<String, Strings>('MyMap', valueType: Strings())))
              .toString(),
          '{ "title": "MyMap", "type": ["object", "null"], "additionalProperties": { "type": "string" } }');
    });
  });

  group('Validatable types', () {
    test('string enum', () {
      expect(
          generateTypeJsonSchema(
                  Validatable(Strings(), EnumValidator('Foo', {'a', 'b', 'c'})))
              .toString(),
          '{ "type": "string", "enum": ["a","b","c"] }');
    });

    test('non-blank string', () {
      expect(
          generateTypeJsonSchema(
                  Validatable(Strings(), const NonBlankStringValidator()))
              .toString(),
          r'{ "type": "string", "pattern": ".*\\S.*" }');
    });

    test('int range', () {
      expect(
          generateTypeJsonSchema(
                  Validatable<int>(Ints(), const IntRangeValidator(1, 10)))
              .toString(),
          r'{ "type": "integer", "minimum": 1, "maximum": 10 }');
    });

    test('float range', () {
      expect(
          generateTypeJsonSchema(Validatable<double>(
                  Floats(), const FloatRangeValidator(0.1, 0.85)))
              .toString(),
          r'{ "type": "number", "minimum": 0.1, "maximum": 0.85 }');
    });
  });

  group('Nullable Validatable', () {
    test('string enum', () {
      expect(
          generateTypeJsonSchema(Nullable(Validatable(
              Strings(), EnumValidator('Foo', {'a', 'b', 'c'})))).toString(),
          '{ "type": ["string", "null"], "enum": ["a","b","c"] }');
    });
  });

  group('Custom Validator generation', () {
    JsonSchemaWriterFunction? originalEnumValidatorGenerator;
    setUp(() {
      originalEnumValidatorGenerator =
          jsonSchemaValidatorGenerators[EnumValidator] = (Object validator,
              SchemaType<Object?> type,
              StringBuffer buffer,
              JsonSchemaOptions options) {
        validator as EnumValidator;
        buffer.write(validator);
        buffer.write('\n');
        buffer.write(type);
      };
    });
    tearDown(() {
      jsonSchemaValidatorGenerators[EnumValidator] =
          originalEnumValidatorGenerator!;
    });

    test('Can set validator generator globally', () {
      final testEnum = Enums(EnumValidator('TestEnum', {'a', 'b', 'c'}));
      expect(generateTypeJsonSchema(testEnum).toString(),
          '{ "type": "string"${testEnum.validator}\n${Strings()} }');
    });

    test('Can set validator generator by Zone', () {
      final testEnum = Enums(EnumValidator('TestEnumZone', {'d', 'e', 'f'}));
      void customWriter(Object validator, SchemaType<Object?> type,
          StringBuffer buffer, JsonSchemaOptions options) {
        validator as EnumValidator;
        buffer.write(type);
        buffer.write('\n');
        buffer.write(validator);
      }

      final result = runZoned(() {
        return generateTypeJsonSchema(testEnum).toString();
      }, zoneValues: {
        jsonSchemaValidatorGeneratorsZoneKey: {EnumValidator: customWriter}
      });

      expect(result, '{ "type": "string"${Strings()}\n${testEnum.validator} }');
    });
  });

  group('Full Schema', () {
    test('Can write basic JSON schema', () {
      expect(
          generateJsonSchema(Strings(), schemaId: '/mySchema').toString(),
          r'{ "$schema": '
          '"$jsonSchema_2020_12", '
          r'"$id": "/mySchema", '
          r'"type": "string"'
          r' }');
    });

    test('Objects: with ID, title and descriptions', () {
      expect(
          generateJsonSchema(
                  Objects(
                      'MySchema',
                      description: 'my JSON schema',
                      {'foo': Property(Strings(), description: 'a property')}),
                  schemaId: '/my-schema')
              .toString(),
          r'{ "$schema": '
          '"$jsonSchema_2020_12", '
          r'"$id": "/my-schema", '
          r'"title": "MySchema", '
          r'"description": "my JSON schema", '
          r'"type": "object", '
          r'"properties": {'
          r' "foo": { "type": "string", "description": "a property" } '
          r'}, "required": ["foo"], "additionalProperties": false }');
    });

    test('Objects: no json-schema version, ID or descriptions', () {
      expect(
          generateJsonSchema(
                  Objects('MySchema', {'number': Property(Nullable(Ints()))}),
                  schemaUri: null)
              .toString(),
          r'{ '
          r'"title": "MySchema", '
          r'"type": "object", '
          r'"properties": {'
          r' "number": { "type": ["integer", "null"] } '
          r'}, "additionalProperties": false }');
    });

    test('Objects: no inner refs, ignore unknown props', () {
      const inner = Objects('Inner', {
        'a': Property(Ints()),
      });
      const parent = Objects(
          'Parent',
          {
            'b': Property(inner),
          },
          unknownPropertiesStrategy: UnknownPropertiesStrategy.ignore);
      expect(
          generateJsonSchema(Objects('MySchema', {'p': Property(parent)}),
                  schemaUri: null,
                  options: JsonSchemaOptions(useRefsForNestedTypes: false))
              .toString(),
          r'{ '
          r'"title": "MySchema", '
          r'"type": "object", '
          r'"properties": {'
          r' "p": { "title": "Parent", "type": "object", "properties": {'
          r' "b": { "title": "Inner", "type": "object", "properties": {'
          r' "a": { "type": "integer" } }, "required": ["a"],'
          r' "additionalProperties": false }'
          r' }, "required": ["b"] }'
          r' }, "required": ["p"],'
          r' "additionalProperties": false }');
    });

    test('Objects: with inner refs, keep unknown props', () {
      const inner = Objects(
          'Inner',
          {
            'a': Property(Ints()),
          },
          unknownPropertiesStrategy: UnknownPropertiesStrategy.keep);
      const parent = Objects(
          'Parent',
          {
            'b': Property(inner),
          },
          unknownPropertiesStrategy: UnknownPropertiesStrategy.keep);
      expect(
          generateJsonSchema(Objects('MySchema', {'p': Property(parent)}),
                  schemaUri: null)
              .toString(),
          r'{ '
          r'"title": "MySchema", '
          r'"type": "object", '
          r'"properties": {'
          r' "p": { "$ref": "#/$defs/Parent" } '
          r'}, "required": ["p"], "additionalProperties": false, '
          r'"$defs": { '
          r'"Parent": { "title": "Parent", "type": "object", "properties": { "b": { "$ref": "#/$defs/Inner" } }, "required": ["b"] }, '
          r'"Inner": { "title": "Inner", "type": "object", "properties": { "a": { "type": "integer" } }, "required": ["a"] } '
          r'} }');
    });

    test('Objects: with inner refs, inner external type', () {
      const inner = Objects('Inner', {
        'a': Property(Ints()),
      });
      const parent = Objects(
          'Parent',
          {
            'b': Property(inner),
          },
          description: "The Parent");
      expect(
          generateJsonSchema(
              Objects('MySchema',
                  {'p': Property(parent, description: 'property description')}),
              schemaUri: null,
              options: JsonSchemaOptions(externalTypes: {
                inner: 'https://example.org/schema/Inner'
              })).toString(),
          r'{ '
          r'"title": "MySchema", '
          r'"type": "object", '
          r'"properties": {'
          r' "p": { "$ref": "#/$defs/Parent", "description": "property description" } '
          r'}, "required": ["p"], "additionalProperties": false, '
          r'"$defs": { '
          r'"Parent": { "title": "Parent", "description": "The Parent", "type": "object", "properties": {'
          r' "b": { "$ref": "https://example.org/schema/Inner" } '
          r'}, "required": ["b"], "additionalProperties": false } '
          r'} }');
    });

    test('Objects: with inner refs, all external types', () {
      const inner = Objects('Inner', {
        'a': Property(Ints()),
      });
      const parent = Objects('Parent', {
        'b': Property(inner),
      });
      expect(
          generateJsonSchema(Objects('MySchema', {'p': Property(parent)}),
              schemaUri: null,
              options: JsonSchemaOptions(externalTypes: {
                parent: 'https://example.org/schema/Parent'
              })).toString(),
          r'{ '
          r'"title": "MySchema", '
          r'"type": "object", '
          r'"properties": {'
          r' "p": { "$ref": "https://example.org/schema/Parent" } '
          r'}, "required": ["p"], "additionalProperties": false '
          r'}');
    });

    test('Array of Objects: with inner refs', () {
      const inner = Objects('Integers', {
        'ints': Property(Ints(), description: 'some integers'),
      });
      expect(
          generateJsonSchema(
                  Objects('MySchema', {
                    'arr':
                        Property(Arrays<Map<String, Object?>, Objects>(inner))
                  }),
                  schemaUri: null)
              .toString(),
          r'{ '
          r'"title": "MySchema", '
          r'"type": "object", "properties": { "arr": '
          r'{ "type": "array", "items": { "$ref": "#/$defs/Integers" } } },'
          r' "required": ["arr"], "additionalProperties": false, '
          r'"$defs": { '
          r'"Integers": { "title": "Integers", "type": "object", '
          r'"properties": { "ints": { "type": "integer", "description": "some integers" } },'
          r' "required": ["ints"], "additionalProperties": false } '
          r'} }');
    });

    test('Maps: with values of inner refs type (top-level)', () {
      const inner = Objects('Inner', {
        'a': Property(Ints()),
      });
      const parent =
          Maps<Map<String, Object?>, Objects>('Parent', valueType: inner);
      expect(
          generateJsonSchema(parent, schemaUri: null).toString(),
          r'{ '
          r'"title": "Parent", '
          r'"type": "object", '
          r'"additionalProperties": { "$ref": "#/$defs/Inner" }, '
          r'"$defs": { '
          r'"Inner": { "title": "Inner", "type": "object", "properties": { "a": { "type": "integer" } },'
          r' "required": ["a"], "additionalProperties": false } '
          r'} }');
    });

    test('Maps: with values of inner refs type (inside Objects)', () {
      const inner = Objects('Inner', {
        'a': Property(Ints()),
      });
      const parent =
          Maps<Map<String, Object?>, Objects>('Parent', valueType: inner);
      expect(
          generateJsonSchema(Objects('MySchema', {'p': Property(parent)}),
                  schemaUri: null)
              .toString(),
          r'{ '
          r'"title": "MySchema", '
          r'"type": "object", '
          r'"properties": {'
          r' "p": { "$ref": "#/$defs/Parent" } '
          r'}, "required": ["p"], "additionalProperties": false, '
          r'"$defs": { '
          r'"Parent": { "title": "Parent", "type": "object", "additionalProperties": { "$ref": "#/$defs/Inner" } }, '
          r'"Inner": { "title": "Inner", "type": "object", "properties": { "a": { "type": "integer" } },'
          r' "required": ["a"], "additionalProperties": false } '
          r'} }');
    });
  });
}
