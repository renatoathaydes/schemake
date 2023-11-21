import 'dart:convert';

import 'package:schemake/schemake.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'matchers.dart';

const _personSchema = Objects('Person', {
  'name': Property<String>(type: Strings()),
  'age': Property<int?>(type: Nullable(Ints())),
});

const _companySchema = Objects('Company', {
  'name': Property<String>(type: Strings()),
  'employees':
      Property<List<Map<String, Object?>>>(type: Arrays(_personSchema)),
});

void main() {
  group('Schemake objects', () {
    test('can convert from YAML object to custom type (full object)', () {
      expect(_personSchema.convert(loadYaml('name: Joe\nage: 30')),
          equals({'name': 'Joe', 'age': 30}));
    });

    test('can convert from YAML object to custom type (missing field)', () {
      expect(_personSchema.convert(loadYaml('name: Joe')),
          equals({'name': 'Joe'}));
    });

    test(
        'cannot convert from YAML object to custom type (missing mandatory field)',
        () {
      expect(() => _personSchema.convert(loadYaml('age: 10')),
          throwsMissingPropertyException([], _personSchema, ['name']));
    });

    test('cannot convert from YAML object to custom type (unknown field)', () {
      expect(() => _personSchema.convert(loadYaml('name: Joe\nheight: 180')),
          throwsUnknownPropertyException(['height'], _personSchema));
    });
  });

  group('Schemake JSON', () {
    test('can convert from JSON to custom type (nested schema)', () {
      expect(
          _companySchema.convert(jsonDecode('{'
              '  "name": "ACME",'
              '  "employees": [ {'
              '    "name": "Joe",'
              '    "age": 30'
              '  } ]'
              '}')),
          equals({
            'name': 'ACME',
            'employees': [
              {'name': 'Joe', 'age': 30}
            ]
          }));
    });

    test('cannot convert from JSON to custom type (nested schema problem)', () {
      expect(
          () => _companySchema.convert(jsonDecode('{'
              '  "name": "ACME",'
              '  "employees": [ {'
              '    "name": true,'
              '    "age": 30'
              '  } ]'
              '}')),
          throwsPropertyTypeException(
              String, true, ['employees', 'name'], _personSchema));
    });
  });
}
