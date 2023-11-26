import 'package:schemake/dart_gen.dart';
import 'package:schemake/schemake.dart';
import 'package:test/test.dart';

const _generatedPersonClass = r'''

class Person {
  final String name;
  final int? age;
  const Person({
    required this.name,
    this.age,
  });
  @override
  String toString() =>
    'Person{'
    'name: "$name", '
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
enum Foo {
  foo,
  bar,
  ;
  static Foo from(String s) => switch(s) {
    'foo' => foo,
    'bar' => bar,
    _ => throw ValidationException(['value not allowed for Foo: "$s" - should be one of {foo, bar}']),
  };
}
class _FooConverter extends Converter<Object?, Foo> {
  const _FooConverter();
  @override
  Foo convert(Object? input) {
    return Foo.from(const Strings().convert(input));
  }
}
''';

const _generatedValidatedClass = r'''
class Validated {
  final Foo some;
  const Validated({
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
''';

const _generatedNestedClass = r'''
class Nested {
  final Person inner;
  const Nested({
    required this.inner,
  });
  @override
  String toString() =>
    'Nested{'
    'inner: $inner'
    '}';
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Nested &&
    runtimeType == other.runtimeType &&
    inner == other.inner;
  @override
  int get hashCode =>
    inner.hashCode;
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
      type: Validatable(Strings(), EnumValidator('Foo', {'foo', 'bar'}))),
});

void main() {
  group('Schemake Dart class gen', () {
    test('can write simple Dart class', () {
      expect(generateDartClasses([personSchema]).toString(),
          equals(_generatedPersonClass));
    });

    test('can write Dart class with array', () {
      expect(
          generateDartClasses([stringItemsSchema]).toString(),
          equals('import \'package:collection/collection.dart\';\n\n'
              'class StringItems {\n'
              '  final List<String> items;\n'
              '  const StringItems({\n'
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
          equals('import \'dart:convert\';\n'
              'import \'package:schemake/schemake.dart\';\n'
              '$_generatedPersonClass'
              '$_generatedEnumClass\n'
              '$_generatedNestedClass\n'
              '$_generatedValidatedClass'));
    });

    test(
        'can write Dart class without const constructor and final fields and default methods',
        () {
      expect(
          generateDartClasses([
            Objects('Example', {
              'field': Property(type: Bools()),
            })
          ],
                  options: DartGeneratorOptions(
                      methodGenerators: [],
                      insertBeforeField: null,
                      insertBeforeConstructor: null))
              .toString(),
          equals('\n'
              'class Example {\n'
              '  bool field;\n'
              '  Example({\n'
              '    required this.field,\n'
              '  });\n'
              '}\n'));
    });
  });
}
