import 'package:schemake/schemake.dart';
import 'package:schemake/src/json_schema/json_schema.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('Basic types', () {
    test('integer', () {
      expect(generateJsonSchema([Ints()]).toString(), '{ "type": "integer" }');
    });
    test('number', () {
      expect(generateJsonSchema([Floats()]).toString(), '{ "type": "number" }');
    });
    test('boolean', () {
      expect(generateJsonSchema([Bools()]).toString(), '{ "type": "boolean" }');
    });
    test('string', () {
      expect(
          generateJsonSchema([Strings()]).toString(), '{ "type": "string" }');
    });
  });

  group('Nullable Basic types', () {
    test('integer', () {
      expect(generateJsonSchema([Nullable(Ints())]).toString(),
          '{ "type": ["integer", "null"] }');
    });
    test('number', () {
      expect(generateJsonSchema([Nullable(Floats())]).toString(),
          '{ "type": ["number", "null"] }');
    });
    test('boolean', () {
      expect(generateJsonSchema([Nullable(Bools())]).toString(),
          '{ "type": ["boolean", "null"] }');
    });
    test('string', () {
      expect(generateJsonSchema([Nullable(Strings())]).toString(),
          '{ "type": ["string", "null"] }');
    });
  });

  group('Maps', () {
    test('default Maps with value type Strings', () {
      expect(
          generateJsonSchema(
                  const [Maps<String, Strings>('MyMap', valueType: Strings())])
              .toString(),
          '{ "type": "object", "additionalProperties": { "type": "string" } }');
    });

    test('default Maps with value type Ints', () {
      expect(
          generateJsonSchema(
              const [Maps<int, Ints>('MyMap', valueType: Ints())]).toString(),
          '{ "type": "object", "additionalProperties": { "type": "integer" } }');
    });

    test('Maps with value type Ints, ignore additional properties', () {
      expect(
          generateJsonSchema(const [
            Maps<int, Ints>('MyMap',
                valueType: Ints(),
                unknownPropertiesStrategy: UnknownPropertiesStrategy.ignore)
          ]).toString(),
          '{ "type": "object" }');
    });

    test(
        'Maps with value type Ints, some known properties, ignore additional properties',
        () {
      expect(
          generateJsonSchema(const [
            Maps<int, Ints>('MyMap',
                valueType: Ints(),
                knownProperties: {'foo', 'bar'},
                unknownPropertiesStrategy: UnknownPropertiesStrategy.ignore)
          ]).toString(),
          '{ "type": "object", "properties": { '
          '"foo": { "type": "integer" }, '
          '"bar": { "type": "integer" } '
          '}, "required": ["foo","bar"] }');
    });

    test(
        'Maps with value type Ints, some known properties, forbid additional properties',
        () {
      expect(
          generateJsonSchema(const [
            Maps<int, Ints>('MyMap',
                valueType: Ints(),
                knownProperties: {'foo', 'bar'},
                unknownPropertiesStrategy: UnknownPropertiesStrategy.forbid)
          ]).toString(),
          '{ "type": "object", "properties": { '
          '"foo": { "type": "integer" }, '
          '"bar": { "type": "integer" } '
          '}, "required": ["foo","bar"], '
          '"additionalProperties": false }');
    });
  });
}
