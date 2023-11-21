import 'package:schemake/schemake.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'matchers.dart';

const ages = IntRangeValidator(0, 100);

const myObject = Objects('Person', {
  'name': Property<String>(type: Strings()),
  'age': Property<int>(type: Validatable(Ints(), ages)),
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

  group('Schemake object validator', () {
    test('validator allows field within range', () {
      expect(myObject.convert(loadYaml('name: Joe\nage: 30')),
          equals({'name': 'Joe', 'age': 30}));
    });

    test('validator does not allow field outside range', () {
      expect(() => myObject.convert(loadYaml('name: Joe\nage: 130')),
          throwsPropertyValidationException(['age'], myObject, ['130 > 100']));
    });
  });
}
