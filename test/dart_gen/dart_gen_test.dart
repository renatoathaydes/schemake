import 'package:schemake/dart_gen.dart';
import 'package:schemake/schemake.dart';
import 'package:test/test.dart';

const _imports = r'''
import 'dart:convert';
import 'package:schemake/schemake.dart';
''';

const _generatedPersonClass = r'''

class Person {
  String name;
  int? age;
  Person({
    required this.name,
    this.age,
  });
  @override
  String toString() =>
    'Person{'
    'name: "$name",'
    'age: $age'
    '}';
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Person &&
    runtimeType == other.runtimeType &&
    name == other.name &&
    age == other.age;
  @override
  int get hashCode =>
    name.hashCode ^ age.hashCode;
}
''';

const _generatedEnumClass = r'''

class Validated {
  Foo some;
  Validated({
    required this.some,
  });
  @override
  String toString() =>
    'Validated{'
    'some: $some'
    '}';
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Validated &&
    runtimeType == other.runtimeType &&
    some == other.some;
  @override
  int get hashCode =>
    some.hashCode;
}
enum Foo {
  foo,
  BAR,
  ;
  static Foo from(String s) => switch(s) {
    'foo' => foo,
    'bar' => BAR,
    _ => throw ValidationException(['value not allowed for Foo: "$s"']),
  };
}
''';

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

const validatableObjectSchema = Objects('Validated', {
  'some': Property(
      type: Validatable(
          Strings(), EnumValidator('Foo', {'foo': null, 'bar': 'BAR'}))),
});

void main() {
  group('Schemake Dart class gen', () {
    test('can write simple Dart class', () {
      expect(generateDartClasses([personSchema]).toString(),
          equals(_imports + _generatedPersonClass));
    });

    test('can write Dart class with array', () {
      expect(
          generateDartClasses([stringItemsSchema]).toString(),
          equals('$_imports'
              'import \'package:collection/collection.dart\';\n\n'
              'class StringItems {\n'
              '  List<String> items;\n'
              '  StringItems({\n'
              '    required this.items,\n'
              '  });\n'
              '  @override\n'
              '  String toString() =>\n'
              "    'StringItems{'\n"
              "    'items: \$items'\n"
              "    '}';\n"
              '  @override\n'
              '  bool operator ==(Object other) =>\n'
              "    identical(this, other) ||\n"
              "    other is StringItems &&\n"
              "    runtimeType == other.runtimeType &&\n"
              "    const ListEquality<String>().equals(items, other.items);\n"
              '  @override\n'
              '  int get hashCode =>\n'
              "    items.hashCode;\n"
              '}\n'));
    });

    test('can write Dart class with nested Objects and Enum', () {
      expect(
          generateDartClasses([nestedObjectSchema, validatableObjectSchema])
              .toString(),
          equals('$_imports'
              '$_generatedEnumClass\n'
              'class Nested {\n'
              '  Person inner;\n'
              '  Nested({\n'
              '    required this.inner,\n'
              '  });\n'
              '  @override\n'
              '  String toString() =>\n'
              "    'Nested{'\n"
              "    'inner: \$inner'\n"
              "    '}';\n"
              '  @override\n'
              '  bool operator ==(Object other) =>\n'
              "    identical(this, other) ||\n"
              "    other is Nested &&\n"
              "    runtimeType == other.runtimeType &&\n"
              "    inner == other.inner;\n"
              '  @override\n'
              '  int get hashCode =>\n'
              "    inner.hashCode;\n"
              '}\n'
              '$_generatedPersonClass'));
    });
  });
}
