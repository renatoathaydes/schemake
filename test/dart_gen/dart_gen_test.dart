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
  Person copyWith({
    String? name = null,
    int? age = null,
    bool unsetAge = false,
  }) {
    return Person(
      name: name ?? this.name,
      age: unsetAge ? null : age ?? this.age,
    );
  }
}
''';

const _generatedEnumClass = r'''
enum Foo {
  foo,
  bar,
  ;
  String get name => switch(this) {
    foo => 'foo',
    bar => 'bar',
  };
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
  /// Array of non-empty strings.
  final List<String> nonEmpty;
  final int? more;
  final double other;
  const Validated({
    required this.some,
    this.nonEmpty = const [],
    this.more = 4,
    this.other = 0.4,
  });
  @override
  String toString() =>
    'Validated{'
    'some: $some, '
    'nonEmpty: $nonEmpty, '
    'more: $more, '
    'other: $other'
    '}';
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Validated &&
    runtimeType == other.runtimeType &&
    some == other.some &&
    const ListEquality<String>().equals(nonEmpty, other.nonEmpty) &&
    more == other.more &&
    other == other.other;
  @override
  int get hashCode =>
    some.hashCode ^ const ListEquality<String>().hash(nonEmpty) ^ more.hashCode ^ other.hashCode;
  Validated copyWith({
    Foo? some = null,
    List<String>? nonEmpty = null,
    int? more = null,
    double? other = null,
    bool unsetMore = false,
  }) {
    return Validated(
      some: some ?? this.some,
      nonEmpty: nonEmpty ?? [...this.nonEmpty],
      more: unsetMore ? null : more ?? this.more,
      other: other ?? this.other,
    );
  }
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
  Nested copyWith({
    Person? inner = null,
  }) {
    return Nested(
      inner: inner ?? this.inner.copyWith(),
    );
  }
}
''';

const _generatedNestedListClass = r'''
class NestedList {
  final List<Person> inners;
  final Person inner1;
  const NestedList({
    required this.inners,
    required this.inner1,
  });
  @override
  String toString() =>
    'NestedList{'
    'inners: $inners, '
    'inner1: $inner1'
    '}';
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is NestedList &&
    runtimeType == other.runtimeType &&
    const ListEquality<Person>().equals(inners, other.inners) &&
    inner1 == other.inner1;
  @override
  int get hashCode =>
    const ListEquality<Person>().hash(inners) ^ inner1.hashCode;
  NestedList copyWith({
    List<Person>? inners = null,
    Person? inner1 = null,
  }) {
    return NestedList(
      inners: inners ?? [...this.inners],
      inner1: inner1 ?? this.inner1.copyWith(),
    );
  }
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
  final Map<String, InMaps> objects;
  const HasMaps({
    required this.maps,
    required this.objects,
  });
  @override
  String toString() =>
    'HasMaps{'
    'maps: $maps, '
    'objects: $objects'
    '}';
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is HasMaps &&
    runtimeType == other.runtimeType &&
    const MapEquality<String, String>().equals(maps, other.maps) &&
    const MapEquality<String, InMaps>().equals(objects, other.objects);
  @override
  int get hashCode =>
    const MapEquality<String, String>().hash(maps) ^ const MapEquality<String, InMaps>().hash(objects);
  HasMaps copyWith({
    Map<String, String>? maps = null,
    Map<String, InMaps>? objects = null,
  }) {
    return HasMaps(
      maps: maps ?? {...this.maps},
      objects: objects ?? {...this.objects},
    );
  }
}

class InMaps {
  final String foo;
  const InMaps({
    required this.foo,
  });
  @override
  String toString() =>
    'InMaps{'
    'foo: "$foo"'
    '}';
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is InMaps &&
    runtimeType == other.runtimeType &&
    foo == other.foo;
  @override
  int get hashCode =>
    foo.hashCode;
  InMaps copyWith({
    String? foo = null,
  }) {
    return InMaps(
      foo: foo ?? this.foo,
    );
  }
}
''';

const _generatedClassWithNullableMaps = r'''
import 'package:collection/collection.dart';

class NullableMaps {
  /// Property with Map of Strings.
  final Map<String, String>? map;
  final Map<String, Object?>? objectMap;
  const NullableMaps({
    this.map,
    this.objectMap,
  });
  @override
  String toString() =>
    'NullableMaps{'
    'map: $map, '
    'objectMap: $objectMap'
    '}';
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is NullableMaps &&
    runtimeType == other.runtimeType &&
    const MapEquality<String, String>().equals(map, other.map) &&
    const MapEquality<String, Object?>().equals(objectMap, other.objectMap);
  @override
  int get hashCode =>
    const MapEquality<String, String>().hash(map) ^ const MapEquality<String, Object?>().hash(objectMap);
  NullableMaps copyWith({
    Map<String, String>? map = null,
    Map<String, Object?>? objectMap = null,
    bool unsetMap = false,
    bool unsetObjectMap = false,
  }) {
    return NullableMaps(
      map: unsetMap ? null : map ?? this.map == null ? null : {...this.map},
      objectMap: unsetObjectMap ? null : objectMap ?? this.objectMap == null ? null : {...this.objectMap},
    );
  }
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
    'str: ${str == null ? "null" : '"$str"'}, '
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
  SemiStructured copyWith({
    String? str = null,
    Map<String, Object?>? extras = null,
    bool unsetStr = false,
  }) {
    return SemiStructured(
      str: unsetStr ? null : str ?? this.str,
      extras: extras ?? {...this.extras},
    );
  }
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

const _nestedListObjectsSchema = Objects('NestedList', {
  'inners': Property(Arrays<Map<String, Object?>, Objects>(_personSchema)),
  'inner1': Property(_personSchema),
});

const _validatableObjectSchema = Objects('Validated', {
  'some':
      Property(Validatable(Strings(), EnumValidator('Foo', {'foo', 'bar'}))),
  'nonEmpty': Property(
      Arrays<String, Validatable<String>>(
          Validatable(Strings(), NonBlankStringValidator())),
      defaultValue: [],
      description: 'Array of non-empty strings.'),
  'more': Property(Nullable(Validatable(Ints(), IntRangeValidator(1, 5))),
      defaultValue: 4),
  'other': Property(Validatable(Floats(), FloatRangeValidator(0.0, 1.0)),
      defaultValue: 0.4)
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
  'objects': Property(Maps<Map<String, Object?>, Objects>('Map',
      valueType: Objects('InMaps', {
        'foo': Property(Strings()),
      })))
});

const _schemaWithNullableMaps = Objects('NullableMaps', {
  'map': Property(
      Nullable(Maps<String, Strings>('MapToStrings', valueType: Strings())),
      description: 'Property with Map of Strings.'),
  'objectMap': Property(Nullable(Objects('Map', {},
      unknownPropertiesStrategy: UnknownPropertiesStrategy.keep)))
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
          equals('\n$_generatedPersonClass'));
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
              '  StringItems copyWith({\n'
              '    List<String>? items = null,\n'
              '  }) {\n'
              '    return StringItems(\n'
              '      items: items ?? [...this.items],\n'
              '    );\n'
              '  }\n'
              '}\n'));
    });

    test('can write Dart class with nested Objects and Enum', () {
      expect(
          generateDartClasses([_nestedObjectSchema, _validatableObjectSchema])
              .toString(),
          equals('import \'dart:convert\';\n'
              'import \'package:schemake/schemake.dart\';\n'
              'import \'package:collection/collection.dart\';\n'
              '\n'
              '$_generatedNestedClass\n'
              '$_generatedValidatedClass\n'
              '$_generatedPersonClass'
              '$_generatedEnumClass'));
    });

    test('can write Dart class with nested Objects in List', () {
      expect(
          generateDartClasses([_nestedListObjectsSchema]).toString(),
          equals('import \'package:collection/collection.dart\';\n'
              '\n'
              '$_generatedNestedListClass\n'
              '$_generatedPersonClass'));
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
                  methodGenerators: [],
                  insertBeforeClass: (_) => 'final ')).toString(),
          equals(_generatedWithMetadata));
    });

    test('can write Maps', () {
      expect(generateDartClasses([_schemaWithMaps]).toString(),
          equals(_generatedClassWithMaps));
    });

    test('can write Nullable Maps', () {
      expect(generateDartClasses([_schemaWithNullableMaps]).toString(),
          equals(_generatedClassWithNullableMaps));
    });

    test('can generate semi-structured Dart class toString, == and hashCode',
        () {
      expect(generateDartClasses([_semiStructuredObjects]).toString(),
          equals(_generatedSemiStructuredClass));
    });
  });
}
