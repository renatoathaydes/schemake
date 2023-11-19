import 'package:schemake/schemake.dart';
import 'package:schemake/src/dart_gen.dart';
import 'package:test/test.dart';

const personSchema = Objects('Person', {
  'name': Property<String>(type: Strings()),
  'age': Property<int?>(type: Nullable(Ints())),
});

const stringItemsSchema = Objects('StringItems', {
  'items': Property(type: Arrays<String, Strings>(Strings())),
});

const nestedObjectSchema = Objects('Nested', {
  'inner': Property(type: personSchema),
});

void main() {
  group('Schemake Dart class gen', () {
    test('can write simple Dart class', () {
      expect(
          generateDart([personSchema]).toString(),
          equals('class Person {\n'
              '  String name;\n'
              '  int? age;\n'
              '}\n'));
    });

    test('can write Dart class with array', () {
      expect(
          generateDart([stringItemsSchema]).toString(),
          equals('class StringItems {\n'
              '  List<String> items;\n'
              '}\n'));
    });

    test('can write Dart class with nested Objects', () {
      expect(
          generateDart([nestedObjectSchema]).toString(),
          equals('class Nested {\n'
              '  Person inner;\n'
              '}\n'
              'class Person {\n'
              '  String name;\n'
              '  int? age;\n'
              '}\n'));
    });
  });
}
