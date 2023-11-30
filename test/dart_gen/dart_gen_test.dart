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

const _generatedWithMetadata = '''
/// My metadata.
/// This should appear in the class.
final class Meta {
  /// A property.
  final String name;
  /// some
  /// integer
  /// values.
  final List<int> ints;
  final Map<String, Object?> noDescription;
  const Meta({
    this.name = 'foo',
    this.ints = const [1, 2, 3],
    this.noDescription = const {'a': 1, 'bc': [4]},
  });
}
''';

const _generatedClassWithMaps = r'''
import 'package:collection/collection.dart';

class HasMaps {
  /// Property with Map of Strings.
  final Map<String, String> maps;
  const HasMaps({
    required this.maps,
  });
  @override
  String toString() =>
    'HasMaps{'
    'maps: $maps'
    '}';
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is HasMaps &&
    runtimeType == other.runtimeType &&
    const MapEquality<String, String>().equals(maps, other.maps);
  @override
  int get hashCode =>
    const MapEquality<String, String>().hash(maps);
}
''';

const _generatedSemiStructuredClass = r'''
import 'package:collection/collection.dart';

class SemiStructured {
  final String? str;
  final Map<String, Object?> extras;
  const SemiStructured({
    this.str,
    this.extras = const {},
  });
  @override
  String toString() =>
    'SemiStructured{'
    'str: "$str", '
    'extras: $extras'
    '}';
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is SemiStructured &&
    runtimeType == other.runtimeType &&
    str == other.str &&
    const MapEquality<String, Object?>().equals(extras, other.extras);
  @override
  int get hashCode =>
    str.hashCode ^ const MapEquality<String, Object?>().hash(extras);
}
''';

const _personSchema = Objects('Person', {
  'name': Property<String>(Strings()),
  'age': Property<int?>(Nullable(Ints())),
});

const _stringItemsSchema = Objects('StringItems', {
  'items': Property(Arrays<String, Strings>(Strings())),
});

const _nestedObjectSchema = Objects('Nested', {
  'inner': Property(_personSchema),
});

const _validatableObjectSchema = Objects('Validated', {
  'some':
      Property(Validatable(Strings(), EnumValidator('Foo', {'foo', 'bar'}))),
});

const _schemaWithMetadata = Objects(
    'meta',
    {
      'name':
          Property(Strings(), defaultValue: 'foo', description: 'A property.'),
      'ints': Property(Arrays<int, Ints>(Ints()),
          defaultValue: [1, 2, 3], description: 'some\ninteger\nvalues.'),
      'no-description': Property(
          Objects('Map', {},
              unknownPropertiesStrategy: UnknownPropertiesStrategy.keep),
          defaultValue: {
            'a': 1,
            'bc': [4],
          })
    },
    description: 'My metadata.\n'
        'This should appear in the class.');

const _schemaWithMaps = Objects('HasMaps', {
  'maps': Property(
      Maps<String, Strings>('MapToStrings',
          valueType: Strings(), description: 'map with string values.'),
      description: 'Property with Map of Strings.'),
});

const _semiStructuredObjects = Objects(
    'SemiStructured',
    {
      'str': Property(Nullable(Strings())),
    },
    unknownPropertiesStrategy: UnknownPropertiesStrategy.keep);

void main() {
  group('Schemake Dart class gen', () {
    test('can write simple Dart class', () {
      expect(generateDartClasses([_personSchema]).toString(),
          equals(_generatedPersonClass));
    });

    test('can write Dart class with array', () {
      expect(
          generateDartClasses([_stringItemsSchema]).toString(),
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
              "    const ListEquality<String>().hash(items);\n"
              '}\n'));
    });

    test('can write Dart class with nested Objects and Enum', () {
      expect(
          generateDartClasses([_nestedObjectSchema, _validatableObjectSchema])
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
              'field': Property(Bools()),
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

    test('can generate description and default value', () {
      expect(
          generateDartClasses([_schemaWithMetadata],
                  options: DartGeneratorOptions(
                      methodGenerators: [], insertBeforeClass: 'final '))
              .toString(),
          equals(_generatedWithMetadata));
    });

    test('can write Maps', () {
      expect(generateDartClasses([_schemaWithMaps]).toString(),
          equals(_generatedClassWithMaps));
    });

    test('can generate semi-structured Dart class toString, == and hashCode',
        () {
      expect(generateDartClasses([_semiStructuredObjects]).toString(),
          equals(_generatedSemiStructuredClass));
    });
  });
}
