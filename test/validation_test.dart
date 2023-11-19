import 'package:schemake/schemake.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'matchers.dart';

const ages = IntRange(0, 100);

const myObject = Objects({
  'name': Property<String>(type: Strings()),
  'age': Property<int>(type: Validatable(Ints(), ages)),
});

void main() {
  group('Schemake scalar', () {
    final ints = const Validatable(Ints(), ages);

    test('allows int within range', () {
      expect(ints.convertToDart(0), equals(0));
      expect(ints.convertToDart(50), equals(50));
      expect(ints.convertToDart(100), equals(100));
    });

    test('does not allow int outside range', () {
      expect(() => ints.convertToDart(101),
          throwsValidationException(['101 > 100']));
      expect(
          () => ints.convertToDart(-1), throwsValidationException(['-1 < 0']));
    });
  });

  group('Schemake objects', () {
    test('validator allows field within range', () {
      expect(myObject.convertToDart(loadYaml('name: Joe\nage: 30')),
          equals({'name': 'Joe', 'age': 30}));
    });

    test('validator does not allow field outside range', () {
      expect(
          () => myObject.convertToDart(loadYaml('name: Joe\nage: 130')),
          throwsPropertyValidationException(
              ['age'], myObject.properties, ['130 > 100']));
    });
  });
}
