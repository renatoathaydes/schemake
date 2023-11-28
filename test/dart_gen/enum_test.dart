import 'package:schemake/dart_gen.dart';
import 'package:schemake/schemake.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

void main() {
  group('Enums', () {
    test('toJson works', () async {
      final (stdout, stderr) = await generateAndRunDartClass(
          Objects('Foo', {
            'prop': Property(Enums(EnumValidator('Bar', {'bar', 'zort'}))),
          }),
          '''
      void main() {
        print(Foo(prop: Bar.bar).toJson());
        print(Foo(prop: Bar.zort).toJson());
      }''',
          DartGeneratorOptions(methodGenerators: [
            ToJsonMethodGenerator(),
          ]));
      expect(stderr, isEmpty);
      expect(
          stdout,
          equals([
            {'prop': 'Bar.bar'}.toString(),
            {'prop': 'Bar.zort'}.toString(),
          ]));
    });

    test('fromJson works', () async {
      final (stdout, stderr) = await generateAndRunDartClass(
          Objects('Foo', {
            'prop': Property(Enums(EnumValidator('Bar', {'bar', 'zort'}))),
          }),
          '''
      void main() {
        print(Foo.fromJson({'prop': 'bar'}));
        print(Foo.fromJson({'prop': 'zort'}));
      }''',
          DartGeneratorOptions(methodGenerators: [
            FromJsonMethodGenerator(),
            DartToStringMethodGenerator(),
          ]));
      expect(stderr, isEmpty);
      expect(
          stdout,
          equals([
            'Foo{prop: Bar.bar}',
            'Foo{prop: Bar.zort}',
          ]));
    });

    test('error message on disallowed enum value', () async {
      final (stdout, stderr) = await generateAndRunDartClass(
          Objects('Foo', {
            'prop': Property(Enums(EnumValidator('Bar', {'bar', 'zort'}))),
          }),
          '''
      void main() {
        print(Foo.fromJson({'prop': 'no'}));
      }''',
          DartGeneratorOptions(methodGenerators: [
            FromJsonMethodGenerator(),
          ]));
      expect(
          stderr,
          contains('PropertyValidationException{'
              'propertyPath: [prop], '
              'errors: [value not allowed for Bar: "no" - should be one of '
              '{bar, zort}], '
              'objectType: Foo}'));
      expect(stdout, isEmpty);
    });
  });
}
