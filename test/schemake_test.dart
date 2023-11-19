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
  });
}
