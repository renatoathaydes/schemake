import 'package:schemake/schemake.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'matchers.dart';

void main() {
  group('Schemake', () {
    test('can convert from YAML String to String', () {
      expect(
          const Strings().convertToDart(loadYaml('"hello"')), equals('hello'));
    });
    test('can convert from YAML bool to bool', () {
      expect(const Bools().convertToDart(loadYaml('true')), isTrue);
    });
    test('can convert from YAML int to int', () {
      expect(const Ints().convertToDart(loadYaml('10')), equals(10));
    });
    test('can convert from YAML float to double', () {
      expect(const Floats().convertToDart(loadYaml('0.1')), equals(0.1));
    });
    test('can convert from YAML array to List', () {
      expect(const Arrays<int, Ints>(Ints()).convertToDart(loadYaml('[1,2]')),
          equals([1, 2]));
    });
    test('can convert from YAML empty array to List', () {
      expect(const Arrays<int, Ints>(Ints()).convertToDart(loadYaml('[]')),
          equals(<int>[]));
    });
    test('can convert from YAML object to Map<String, int>', () {
      expect(
          const Dictionaries<int, Ints>(Ints())
              .convertToDart(loadYaml('{foo: 10}')),
          equals({'foo': 10}));
    });
    test('can convert from YAML object to Map<String, String>', () {
      expect(
          const Dictionaries<String, Strings>(Strings())
              .convertToDart(loadYaml('{foo: bar}')),
          equals({'foo': 'bar'}));
    });
  });

  group('Schemake null errors', () {
    test('cannot convert from YAML null to String', () {
      expect(() => const Strings().convertToDart(loadYaml('null')),
          throwsTypeException(String, null));
    });
    test('cannot convert from YAML null to bool', () {
      expect(() => const Bools().convertToDart(loadYaml('null')),
          throwsTypeException(bool, null));
    });
    test('cannot convert from YAML null to int', () {
      expect(() => const Ints().convertToDart(loadYaml('null')),
          throwsTypeException(int, null));
    });
    test('cannot convert from YAML null to double', () {
      expect(() => const Floats().convertToDart(loadYaml('null')),
          throwsTypeException(double, null));
    });
    test('cannot convert from YAML null to List', () {
      expect(
          () => const Arrays<int, Ints>(Ints()).convertToDart(loadYaml('null')),
          throwsTypeException(List<int>, null));
    });
    test('cannot convert from YAML null to Map<String, int>', () {
      expect(
          () => const Dictionaries<int, Ints>(Ints())
              .convertToDart(loadYaml('null')),
          throwsTypeException(Map<String, int>, null));
    });
    test('cannot convert from YAML null to Map<String, String>', () {
      expect(
          () => const Dictionaries<String, Strings>(Strings())
              .convertToDart(loadYaml('null')),
          throwsTypeException(Map<String, String>, null));
    });
  });

  group('Schemake nullable', () {
    test('can convert from YAML String to String', () {
      expect(const Nullable(Strings()).convertToDart(loadYaml('"hello"')),
          equals('hello'));
    });
    test('can convert from YAML String to String', () {
      expect(const Nullable(Strings()).convertToDart(loadYaml('null')), isNull);
    });
    test('can convert from YAML bool to bool', () {
      expect(const Nullable(Bools()).convertToDart(loadYaml('true')), isTrue);
    });
    test('can convert from YAML bool to null', () {
      expect(const Nullable(Bools()).convertToDart(loadYaml('null')), isNull);
    });
    test('can convert from YAML int to int', () {
      expect(const Nullable(Ints()).convertToDart(loadYaml('10')), equals(10));
    });
    test('can convert from YAML int to null', () {
      expect(const Nullable(Ints()).convertToDart(loadYaml('null')), isNull);
    });
    test('can convert from YAML float to double', () {
      expect(
          const Nullable(Floats()).convertToDart(loadYaml('0.1')), equals(0.1));
    });
    test('can convert from YAML float to null', () {
      expect(const Nullable(Floats()).convertToDart(loadYaml('null')), isNull);
    });
    test('can convert from YAML array to List', () {
      expect(
          const Nullable(Arrays<int, Ints>(Ints()))
              .convertToDart(loadYaml('[1,2]')),
          equals([1, 2]));
    });
    test('can convert from YAML array to null', () {
      expect(
          const Nullable(Arrays<int, Ints>(Ints()))
              .convertToDart(loadYaml('null')),
          isNull);
    });
    test('can convert from YAML object to Map<String, int>', () {
      expect(
          const Nullable(Dictionaries<int, Ints>(Ints()))
              .convertToDart(loadYaml('{foo: 10}')),
          equals({'foo': 10}));
    });
    test('can convert from YAML object to null', () {
      expect(
          const Nullable(Dictionaries<int, Ints>(Ints()))
              .convertToDart(loadYaml('null')),
          isNull);
    });
    test('can convert from YAML object to Map<String, String>', () {
      expect(
          const Nullable(Dictionaries<String, Strings>(Strings()))
              .convertToDart(loadYaml('{foo: bar}')),
          equals({'foo': 'bar'}));
    });
    test('can convert from YAML object to null', () {
      expect(
          const Nullable(Dictionaries<String, Strings>(Strings()))
              .convertToDart(loadYaml('null')),
          isNull);
    });
  });
}
