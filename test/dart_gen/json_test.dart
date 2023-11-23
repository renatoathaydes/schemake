import 'dart:convert';

import 'package:schemake/schemake.dart';
import 'package:test/test.dart';

class _Testing {}

class _TestObject extends ObjectsBase<_Testing> {
  _TestObject() : super('Test');

  @override
  _Testing convert(Object? input) {
    throw UnimplementedError();
  }

  @override
  Converter<Object?, Object?>? getPropertyConverter(String name) {
    throw UnimplementedError();
  }

  @override
  Iterable<String> getRequiredProperties() {
    throw UnimplementedError();
  }
}

void main() {
  group('schemaTypeString', () {
    test('strings', () {
      expect(schemaTypeString(Strings()), equals('Strings()'));
    });

    test('ints', () {
      expect(schemaTypeString(Ints()), equals('Ints()'));
    });

    test('bools', () {
      expect(schemaTypeString(Bools()), equals('Bools()'));
    });

    test('floats', () {
      expect(schemaTypeString(Floats()), equals('Floats()'));
    });

    test('enums', () {
      expect(
          schemaTypeString(Validatable(
              Strings(), EnumValidator('MyEnum', {'abc': null, 'def': 'DEF'}))),
          equals(
              "Validatable(Strings(), EnumValidator('MyEnum', {'abc': null, 'def': 'DEF'}))"));
    });

    test('int ranges', () {
      expect(schemaTypeString(Validatable(Ints(), IntRangeValidator(2, 3))),
          equals('Validatable(Ints(), IntRangeValidator(2, 3))'));
    });

    test('non-blank strings', () {
      expect(
          schemaTypeString(Validatable(Strings(), NonBlankStringValidator())),
          equals('Validatable(Strings(), NonBlankStringValidator())'));
    });

    test('custom objects', () {
      // the auto-generated name is assumed
      expect(schemaTypeString(_TestObject()), equals('_TestObject()'));
    });

    test('arrays', () {
      expect(schemaTypeString(Arrays<double, Floats>(Floats())),
          equals('Arrays<double, Floats>(Floats())'));

      expect(schemaTypeString(Arrays<String, Strings>(Strings())),
          equals('Arrays<String, Strings>(Strings())'));
    });

    test('nested arrays', () {
      expect(
          schemaTypeString(Arrays<List<double>, Arrays<double, Floats>>(
              Arrays<double, Floats>(Floats()))),
          equals('Arrays<List<double>, Arrays<double, Floats>>('
              'Arrays<double, Floats>(Floats()))'));
    });

    test('arrays of custom objects', () {
      expect(schemaTypeString(Arrays<_Testing, _TestObject>(_TestObject())),
          equals('Arrays<_Testing, _TestObject>(_TestObject())'));
    });

    test('nullable', () {
      expect(schemaTypeString(Nullable<int, Ints>(Ints())),
          equals('Nullable<int, Ints>(Ints())'));
    });

    test('nullable custom object', () {
      expect(schemaTypeString(Nullable<_Testing, _TestObject>(_TestObject())),
          equals('Nullable<_Testing, _TestObject>(_TestObject())'));
    });
  });
}
