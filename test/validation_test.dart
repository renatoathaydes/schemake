import 'package:schemake/schemake.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'matchers.dart';

const ages = IntRangeValidator(0, 100);

const myObject = Objects('Person', {
  'name': Property<String>(Strings()),
  'age': Property<int>(Validatable(Ints(), ages)),
  'status': Property<String>(Validatable(
      Strings(), EnumValidator('Status', {'alive', 'dead', 'unknown'})))
});

void main() {
  group('Schemake int validator', () {
    final ints = const Validatable(Ints(), ages);

    test('allows int within range', () {
      expect(ints.convert(0), equals(0));
      expect(ints.convert(50), equals(50));
      expect(ints.convert(100), equals(100));
    });

    test('does not allow int outside range', () {
      expect(() => ints.convert(101), throwsValidationException(['101 > 100']));
      expect(() => ints.convert(-1), throwsValidationException(['-1 < 0']));
    });
  });
  group('Schemake NonBlank validator', () {
    final ints =
        const Validatable<String>(Strings(), NonBlankStringValidator());

    test('allows non-blank strings', () {
      expect(ints.convert('a'), equals('a'));
      expect(ints.convert('   a'), equals('   a'));
      expect(ints.convert('hello world'), equals('hello world'));
    });

    test('does not allow blank strings', () {
      expect(
          () => ints.convert(''), throwsValidationException(['blank string']));
      expect(
          () => ints.convert(' '), throwsValidationException(['blank string']));
      expect(() => ints.convert('         '),
          throwsValidationException(['blank string']));
      expect(() => ints.convert(' \n\t '),
          throwsValidationException(['blank string']));
    });
  });

  group('Schemake enum validator', () {
    test('allows field within enum values', () {
      expect(myObject.convert(loadYaml('name: Joe\nage: 30\nstatus: alive')),
          equals({'name': 'Joe', 'age': 30, 'status': 'alive'}));
    });

    test('does not allow field enum values', () {
      expect(
          () => myObject.convert(loadYaml('name: Joe\nage: 0\nstatus: unborn')),
          throwsPropertyValidationException(['status'], myObject,
              ['"unborn" not in {alive, dead, unknown}']));
    });
  });

  group('Schemake object validator', () {
    test('allows field within range', () {
      expect(myObject.convert(loadYaml('name: Joe\nage: 30\nstatus: alive')),
          equals({'name': 'Joe', 'age': 30, 'status': 'alive'}));
    });

    test('does not allow field outside range', () {
      expect(
          () =>
              myObject.convert(loadYaml('name: Joe\nage: 130\nstatus: alive')),
          throwsPropertyValidationException(['age'], myObject, ['130 > 100']));
    });
  });
}
