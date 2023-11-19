import 'package:schemake/schemake.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'matchers.dart';

const myObject = Objects({
  'name': Property<String>(type: Strings()),
  'age': Property<int?>(type: Nullable(Ints())),
});

void main() {
  group('Schemake objects', () {
    test('can convert from YAML object to custom type (full object)', () {
      expect(myObject.convertToDart(loadYaml('name: Joe\nage: 30')),
          equals({'name': 'Joe', 'age': 30}));
    });

    test('can convert from YAML object to custom type (missing field)', () {
      expect(myObject.convertToDart(loadYaml('name: Joe')),
          equals({'name': 'Joe'}));
    });

    test(
        'cannot convert from YAML object to custom type (missing mandatory field)',
        () {
      expect(() => myObject.convertToDart(loadYaml('age: 10')),
          throwsMissingPropertyException([], myObject.properties, ['name']));
    });

    test('cannot convert from YAML object to custom type (unknown field)', () {
      expect(() => myObject.convertToDart(loadYaml('name: Joe\nheight: 180')),
          throwsUnknownPropertyException(['height'], myObject.properties));
    });
  });
}
