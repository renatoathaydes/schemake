import 'package:schemake/json_schema.dart';
import 'package:schemake/schemake.dart';
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

  group('Arrays', () {
    test('of integer', () {
      expect(generateJsonSchema([Arrays<int, Ints>(Ints())]).toString(),
          '{ "type": "array", "items": { "type": "integer" } }');
    });

    test('of string', () {
      expect(
          generateJsonSchema([Arrays<String, Strings>(Strings())]).toString(),
          '{ "type": "array", "items": { "type": "string" } }');
    });

    test('of nullable string', () {
      expect(
          generateJsonSchema([
            Arrays<String?, Nullable<String?, Strings>>(Nullable(Strings()))
          ]).toString(),
          '{ "type": "array", "items": { "type": ["string", "null"] } }');
    });
  });

  group('Nullable Arrays', () {
    test('integer', () {
      expect(
          generateJsonSchema([Nullable(Arrays<int, Ints>(Ints()))]).toString(),
          '{ "type": ["array", "null"], "items": { "type": "integer" } }');
    });
    test('number', () {
      expect(
          generateJsonSchema([Nullable(Arrays<double, Floats>(Floats()))])
              .toString(),
          '{ "type": ["array", "null"], "items": { "type": "number" } }');
    });
  });

  group('Maps', () {
    test('default Maps with value type Strings', () {
      expect(
          generateJsonSchema(
                  const [Maps<String, Strings>('MyMap', valueType: Strings())])
              .toString(),
          '{ "type": "object", "title": "MyMap", "additionalProperties": { "type": "string" } }');
    });

    test('default Maps with value type Ints', () {
      expect(
          generateJsonSchema(
              const [Maps<int, Ints>('MyMap', valueType: Ints())]).toString(),
          '{ "type": "object", "title": "MyMap", "additionalProperties": { "type": "integer" } }');
    });

    test('default Maps with value type Ints, some known properties', () {
      expect(
          generateJsonSchema(const [
            Maps<int, Ints>('MyMap',
                valueType: Ints(), knownProperties: {'hello', 'bye'})
          ]).toString(),
          '{ "type": "object", '
          '"title": "MyMap", '
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
          generateJsonSchema(const [
            Maps<int, Ints>('MyMap',
                valueType: Ints(),
                unknownPropertiesStrategy: UnknownPropertiesStrategy.ignore)
          ]).toString(),
          '{ "type": "object", "title": "MyMap" }');
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
          '{ "type": "object", "title": "MyMap", "properties": { '
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
          '{ "type": "object", "title": "MyMap", "properties": { '
          '"foo": { "type": "integer" }, '
          '"bar": { "type": "integer" } '
          '}, "required": ["foo","bar"], '
          '"additionalProperties": false }');
    });
  });

  group('Objects', () {
    test('default Object with one property', () {
      expect(
          generateJsonSchema([
            Objects('Foo', {'bar': Property(Strings())})
          ]).toString(),
          '{ "type": "object", '
          '"title": "Foo", '
          '"properties": { '
          '"bar": { "type": "string" } '
          '}, "required": ["bar"] }');
    });

    test('default Object with one optional property', () {
      expect(
          generateJsonSchema([
            Objects('Foo', {'bar': Property(Nullable(Strings()))})
          ]).toString(),
          '{ "type": "object", '
          '"title": "Foo", '
          '"properties": { '
          '"bar": { "type": ["string", "null"] } '
          '} }');
    });

    test('default Object with a mandatory and an optional property', () {
      expect(
          generateJsonSchema([
            Objects('Foo',
                {'foo': Property(Nullable(Ints())), 'bar': Property(Strings())})
          ]).toString(),
          '{ "type": "object", '
          '"title": "Foo", '
          '"properties": { '
          '"foo": { "type": ["integer", "null"] }, '
          '"bar": { "type": "string" } '
          '}, "required": ["bar"] }');
    });

    test('Object with descriptions', () {
      expect(
          generateJsonSchema([
            Objects(
                'MyObject',
                {
                  'myProp': Property(Ints(), description: 'my property'),
                  'otherProp': Property(Nullable(Strings()),
                      description: 'another property'),
                },
                description: 'this is an object')
          ]).toString(),
          '{ "type": "object", '
          '"title": "MyObject", '
          '"description": "this is an object", '
          '"properties": { '
          '"myProp": { "type": "integer", "description": "my property" }, '
          '"otherProp": { "type": ["string", "null"], "description": "another property" } '
          '}, "required": ["myProp"] }');
    });
  });

  group('Nullable Objects', () {
    test('Nullable Object with a mandatory and an optional property', () {
      expect(
          generateJsonSchema([
            Nullable(Objects('Foo',
                {'foo': Property(Nullable(Ints())), 'bar': Property(Strings())},
                description: 'nullable object'))
          ]).toString(),
          '{ "type": ["object", "null"], '
          '"title": "Foo", '
          '"description": "nullable object", '
          '"properties": { '
          '"foo": { "type": ["integer", "null"] }, '
          '"bar": { "type": "string" } '
          '}, "required": ["bar"] }');
    });
  });

  group('Nullable Maps', () {
    test('Nullable Maps with value type Strings', () {
      expect(
          generateJsonSchema([
            Nullable(Maps<String, Strings>('MyMap', valueType: Strings()))
          ]).toString(),
          '{ "type": ["object", "null"], "title": "MyMap", "additionalProperties": { "type": "string" } }');
    });
  });

  group('Validatable types', () {
    test('string enum', () {
      expect(
          generateJsonSchema([
            Validatable(Strings(), EnumValidator('Foo', {'a', 'b', 'c'}))
          ]).toString(),
          '{ "type": "string", "enum": ["a","b","c"] }');
    });

    test('non-blank string', () {
      expect(
          generateJsonSchema(
                  [Validatable(Strings(), const NonBlankStringValidator())])
              .toString(),
          r'{ "type": "string", "pattern": ".*\\S.*" }');
    });

    test('int range', () {
      expect(
          generateJsonSchema(
                  [Validatable<int>(Ints(), const IntRangeValidator(1, 10))])
              .toString(),
          r'{ "type": "integer", "minimum": 1, "maximum": 10 }');
    });

    test('float range', () {
      expect(
          generateJsonSchema([
            Validatable<double>(Floats(), const FloatRangeValidator(0.1, 0.85))
          ]).toString(),
          r'{ "type": "number", "minimum": 0.1, "maximum": 0.85 }');
    });
  });

  group('Nullable Validatable', () {
    test('string enum', () {
      expect(
          generateJsonSchema([
            Nullable(
                Validatable(Strings(), EnumValidator('Foo', {'a', 'b', 'c'})))
          ]).toString(),
          '{ "type": ["string", "null"], "enum": ["a","b","c"] }');
    });
  });
}
