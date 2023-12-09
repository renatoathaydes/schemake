import 'dart:convert';

import 'package:schemake/dart_gen.dart';
import 'package:schemake/schemake.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

class _Testing {}

class _TestObject extends ObjectsBase<_Testing> {
  _TestObject() : super('Test');

  @override
  _Testing convert(Object? input) {
    throw UnimplementedError();
  }

  @override
  Converter<Object?, Object?>? getPropertyConverter(String name) {
    throw UnimplementedError();
  }

  @override
  Iterable<String> getRequiredProperties() {
    throw UnimplementedError();
  }
}

const _someSchema = Objects('SomeSchema', {
  'mandatory': Property(Strings()),
  'optional': Property(Nullable(Floats())),
  'list': Property(Arrays<int, Ints>(Ints())),
});

const _schemaWithDefaultValues = Objects('WithDefaults', {
  'a': Property(Strings(), defaultValue: 'foo'),
  'b': Property(Nullable(Floats()), defaultValue: 3.1415),
  'c': Property(Arrays<int, Ints>(Ints()), defaultValue: [1, 2]),
  'nullableWithDefault': Property(Nullable(Ints()), defaultValue: 2),
  'enum1': Property(Enums(EnumValidator('EnumValue', {'abc', 'def'})),
      defaultValue: 'def'),
  'mandatory': Property(Ints()),
});

const _schemaWithMaps = Objects(
    'HasMaps',
    {
      'maps': Property(
          Maps<String, Strings>('MapToStrings',
              valueType: Strings(), description: 'map with string values.'),
          description: 'Property with Map of Strings.'),
      'ints': Property(
          Maps<int?, Nullable<int?, Ints>>('Map', valueType: Nullable(Ints()))),
      'objectsMap': Property(Objects('SimpleMap', {},
          unknownPropertiesStrategy: UnknownPropertiesStrategy.keep)),
    },
    unknownPropertiesStrategy: UnknownPropertiesStrategy.ignore);

const _nestedListObjectsSchema = Objects(
    'NestedList',
    {
      'inners': Property(Arrays<Map<String, Object?>, Objects>(_someSchema)),
      'inner1': Property(_someSchema),
    },
    unknownPropertiesStrategy: UnknownPropertiesStrategy.ignore);

const _semiStructuredObjects = Objects(
    'SemiStructured',
    {
      'str': Property(Nullable(Strings())),
    },
    unknownPropertiesStrategy: UnknownPropertiesStrategy.keep);

const _lispCaseType = Objects('lisp-object', {
  'some-prop': Property(Bools()),
  'many-props': Property(Arrays<int, Ints>(Ints())),
});

const _someSchemaToJsonGeneration = r'''
class SomeSchema {
  final String mandatory;
  final double? optional;
  final List<int> list;
  const SomeSchema({
    required this.mandatory,
    this.optional,
    required this.list,
  });
  Map<String, Object?> toJson() => {
    'mandatory': mandatory,
    if (optional != null) 'optional': optional,
    'list': list,
  };
}
''';

const _someSchemaClassFromJsonGeneration = r'''
class SomeSchema {
  final String mandatory;
  final double? optional;
  final List<int> list;
  const SomeSchema({
    required this.mandatory,
    this.optional,
    required this.list,
  });
  static SomeSchema fromJson(Object? value) =>
    const _SomeSchemaJsonReviver().convert(switch(value) {
      String() => jsonDecode(value),
      List<int>() => jsonDecode(utf8.decode(value)),
      _ => value,
    });
}
''';

const _someSchemaJsonReviverGeneration = r'''
class _SomeSchemaJsonReviver extends ObjectsBase<SomeSchema> {
  const _SomeSchemaJsonReviver(): super("SomeSchema",
    unknownPropertiesStrategy: UnknownPropertiesStrategy.forbid);

  @override
  SomeSchema convert(Object? value) {
    if (value is! Map) throw TypeException(SomeSchema, value);
    final keys = value.keys.map((key) {
      if (key is! String) {
        throw TypeException(String, key, "object key is not a String");
      }
      return key;
    }).toSet();
    checkRequiredProperties(keys);
    const knownProperties = {'mandatory', 'optional', 'list'};
    final unknownKey = keys.where((k) => !knownProperties.contains(k)).firstOrNull;
    if (unknownKey != null) {
      throw UnknownPropertyException([unknownKey], SomeSchema);
    }
    return SomeSchema(
      mandatory: convertProperty(const Strings(), 'mandatory', value),
      optional: convertProperty(const Nullable<double, Floats>(Floats()), 'optional', value),
      list: convertProperty(const Arrays<int, Ints>(Ints()), 'list', value),
    );
  }

  @override
  Converter<Object?, Object?>? getPropertyConverter(String property) {
    switch(property) {
      case 'mandatory': return const Strings();
      case 'optional': return const Nullable<double, Floats>(Floats());
      case 'list': return const Arrays<int, Ints>(Ints());
      default: return null;
    }
  }
  @override
  Iterable<String> getRequiredProperties() {
    return const {'mandatory', 'list'};
  }
  @override
  String toString() => 'SomeSchema';
}
''';

const _nestedListObjectsClassFromJsonGeneration = r'''
class NestedList {
  final List<SomeSchema> inners;
  final SomeSchema inner1;
  const NestedList({
    required this.inners,
    required this.inner1,
  });
  static NestedList fromJson(Object? value) =>
    const _NestedListJsonReviver().convert(switch(value) {
      String() => jsonDecode(value),
      List<int>() => jsonDecode(utf8.decode(value)),
      _ => value,
    });
}
''';

const _nestedListObjectsClassToJsonGeneration = r'''
class NestedList {
  final List<SomeSchema> inners;
  final SomeSchema inner1;
  const NestedList({
    required this.inners,
    required this.inner1,
  });
  Map<String, Object?> toJson() => {
    'inners': inners,
    'inner1': inner1,
  };
}
''';

const _nestedListObjectsReviverFromJsonGeneration = r'''
class _NestedListJsonReviver extends ObjectsBase<NestedList> {
  const _NestedListJsonReviver(): super("NestedList",
    unknownPropertiesStrategy: UnknownPropertiesStrategy.ignore);

  @override
  NestedList convert(Object? value) {
    if (value is! Map) throw TypeException(NestedList, value);
    final keys = value.keys.map((key) {
      if (key is! String) {
        throw TypeException(String, key, "object key is not a String");
      }
      return key;
    }).toSet();
    checkRequiredProperties(keys);
    return NestedList(
      inners: convertProperty(const Arrays<SomeSchema, _SomeSchemaJsonReviver>(_SomeSchemaJsonReviver()), 'inners', value),
      inner1: convertProperty(const _SomeSchemaJsonReviver(), 'inner1', value),
    );
  }

  @override
  Converter<Object?, Object?>? getPropertyConverter(String property) {
    switch(property) {
      case 'inners': return const Arrays<SomeSchema, _SomeSchemaJsonReviver>(_SomeSchemaJsonReviver());
      case 'inner1': return const _SomeSchemaJsonReviver();
      default: return null;
    }
  }
  @override
  Iterable<String> getRequiredProperties() {
    return const {'inners', 'inner1'};
  }
  @override
  String toString() => 'NestedList';
}
''';

const _schemaWithDefaultsFromJsonGeneration = r'''
import 'dart:convert';
import 'package:schemake/schemake.dart';

class WithDefaults {
  final String a;
  final double? b;
  final List<int> c;
  final int? nullableWithDefault;
  final EnumValue enum1;
  final int mandatory;
  const WithDefaults({
    this.a = 'foo',
    this.b = 3.1415,
    this.c = const [1, 2],
    this.nullableWithDefault = 2,
    this.enum1 = EnumValue.def,
    required this.mandatory,
  });
  static WithDefaults fromJson(Object? value) =>
    const _WithDefaultsJsonReviver().convert(switch(value) {
      String() => jsonDecode(value),
      List<int>() => jsonDecode(utf8.decode(value)),
      _ => value,
    });
}
enum EnumValue {
  abc,
  def,
  ;
  static EnumValue from(String s) => switch(s) {
    'abc' => abc,
    'def' => def,
    _ => throw ValidationException(['value not allowed for EnumValue: "$s" - should be one of {abc, def}']),
  };
}
class _EnumValueConverter extends Converter<Object?, EnumValue> {
  const _EnumValueConverter();
  @override
  EnumValue convert(Object? input) {
    return EnumValue.from(const Strings().convert(input));
  }
}
class _WithDefaultsJsonReviver extends ObjectsBase<WithDefaults> {
  const _WithDefaultsJsonReviver(): super("WithDefaults",
    unknownPropertiesStrategy: UnknownPropertiesStrategy.forbid);

  @override
  WithDefaults convert(Object? value) {
    if (value is! Map) throw TypeException(WithDefaults, value);
    final keys = value.keys.map((key) {
      if (key is! String) {
        throw TypeException(String, key, "object key is not a String");
      }
      return key;
    }).toSet();
    checkRequiredProperties(keys);
    const knownProperties = {'a', 'b', 'c', 'nullableWithDefault', 'enum1', 'mandatory'};
    final unknownKey = keys.where((k) => !knownProperties.contains(k)).firstOrNull;
    if (unknownKey != null) {
      throw UnknownPropertyException([unknownKey], WithDefaults);
    }
    return WithDefaults(
      a: convertPropertyOrDefault(const Strings(), 'a', value, 'foo'),
      b: convertPropertyOrDefault(const Nullable<double, Floats>(Floats()), 'b', value, 3.1415),
      c: convertPropertyOrDefault(const Arrays<int, Ints>(Ints()), 'c', value, const [1, 2]),
      nullableWithDefault: convertPropertyOrDefault(const Nullable<int, Ints>(Ints()), 'nullableWithDefault', value, 2),
      enum1: convertPropertyOrDefault(const _EnumValueConverter(), 'enum1', value, EnumValue.def),
      mandatory: convertProperty(const Ints(), 'mandatory', value),
    );
  }

  @override
  Converter<Object?, Object?>? getPropertyConverter(String property) {
    switch(property) {
      case 'a': return const Strings();
      case 'b': return const Nullable<double, Floats>(Floats());
      case 'c': return const Arrays<int, Ints>(Ints());
      case 'nullableWithDefault': return const Nullable<int, Ints>(Ints());
      case 'enum1': return const _EnumValueConverter();
      case 'mandatory': return const Ints();
      default: return null;
    }
  }
  @override
  Iterable<String> getRequiredProperties() {
    return const {'mandatory'};
  }
  @override
  String toString() => 'WithDefaults';
}
''';

const _schemaWithMapsToAndFromJsonGeneration = r'''
import 'dart:convert';
import 'package:schemake/schemake.dart';

class HasMaps {
  /// Property with Map of Strings.
  final Map<String, String> maps;
  final Map<String, int?> ints;
  final Map<String, Object?> objectsMap;
  const HasMaps({
    required this.maps,
    required this.ints,
    required this.objectsMap,
  });
  static HasMaps fromJson(Object? value) =>
    const _HasMapsJsonReviver().convert(switch(value) {
      String() => jsonDecode(value),
      List<int>() => jsonDecode(utf8.decode(value)),
      _ => value,
    });
  Map<String, Object?> toJson() => {
    'maps': maps,
    'ints': ints,
    'objectsMap': objectsMap,
  };
}
class _HasMapsJsonReviver extends ObjectsBase<HasMaps> {
  const _HasMapsJsonReviver(): super("HasMaps",
    unknownPropertiesStrategy: UnknownPropertiesStrategy.ignore);

  @override
  HasMaps convert(Object? value) {
    if (value is! Map) throw TypeException(HasMaps, value);
    final keys = value.keys.map((key) {
      if (key is! String) {
        throw TypeException(String, key, "object key is not a String");
      }
      return key;
    }).toSet();
    checkRequiredProperties(keys);
    return HasMaps(
      maps: convertProperty(const Maps('MapToStrings', valueType: Strings()), 'maps', value),
      ints: convertProperty(const Maps('Map', valueType: Nullable<int, Ints>(Ints())), 'ints', value),
      objectsMap: convertProperty(const Objects('SimpleMap', {}, unknownPropertiesStrategy: UnknownPropertiesStrategy.keep), 'objectsMap', value),
    );
  }

  @override
  Converter<Object?, Object?>? getPropertyConverter(String property) {
    switch(property) {
      case 'maps': return const Maps('MapToStrings', valueType: Strings());
      case 'ints': return const Maps('Map', valueType: Nullable<int, Ints>(Ints()));
      case 'objectsMap': return const Objects('SimpleMap', {}, unknownPropertiesStrategy: UnknownPropertiesStrategy.keep);
      default: return null;
    }
  }
  @override
  Iterable<String> getRequiredProperties() {
    return const {'maps', 'ints', 'objectsMap'};
  }
  @override
  String toString() => 'HasMaps';
}
''';

const _schemaSemiStructuredObjects = r'''
import 'dart:convert';
import 'package:schemake/schemake.dart';

class SemiStructured {
  final String? str;
  final Map<String, Object?> extras;
  const SemiStructured({
    this.str,
    this.extras = const {},
  });
  static SemiStructured fromJson(Object? value) =>
    const _SemiStructuredJsonReviver().convert(switch(value) {
      String() => jsonDecode(value),
      List<int>() => jsonDecode(utf8.decode(value)),
      _ => value,
    });
  Map<String, Object?> toJson() => {
    if (str != null) 'str': str,
    ...extras,
  };
}
class _SemiStructuredJsonReviver extends ObjectsBase<SemiStructured> {
  const _SemiStructuredJsonReviver(): super("SemiStructured",
    unknownPropertiesStrategy: UnknownPropertiesStrategy.keep);

  @override
  SemiStructured convert(Object? value) {
    if (value is! Map) throw TypeException(SemiStructured, value);
    final keys = value.keys.map((key) {
      if (key is! String) {
        throw TypeException(String, key, "object key is not a String");
      }
      return key;
    }).toSet();
    checkRequiredProperties(keys);
    return SemiStructured(
      str: convertProperty(const Nullable<String, Strings>(Strings()), 'str', value),
      extras: _unknownPropertiesMap(value),
    );
  }

  @override
  Converter<Object?, Object?>? getPropertyConverter(String property) {
    switch(property) {
      case 'str': return const Nullable<String, Strings>(Strings());
      default: return null;
    }
  }
  @override
  Iterable<String> getRequiredProperties() {
    return const {};
  }
  @override
  String toString() => 'SemiStructured';
  Map<String, Object?> _unknownPropertiesMap(Map<Object?, Object?> value) {
    final result = <String, Object?>{};
    const knownProperties = {'str'};
    for (final entry in value.entries) {
      final key = entry.key;
      if (!knownProperties.contains(key)) {
        if (key is! String) {
          throw TypeException(String, key, "object key is not a String");
        }
        result[key] = entry.value;
      }
    }
    return result;
  }
}
''';

const _options = DartGeneratorOptions();

void main() {
  group('schemaTypeString', () {
    test('strings', () {
      expect(schemaTypeString(Strings(), _options), equals('Strings()'));
    });

    test('ints', () {
      expect(schemaTypeString(Ints(), _options), equals('Ints()'));
    });

    test('bools', () {
      expect(schemaTypeString(Bools(), _options), equals('Bools()'));
    });

    test('floats', () {
      expect(schemaTypeString(Floats(), _options), equals('Floats()'));
    });

    test('enums', () {
      expect(
          schemaTypeString(
              Validatable(Strings(), EnumValidator('MyEnum', {'abc', 'def'})),
              _options),
          equals("_MyEnumConverter()"));
    });

    test('int ranges', () {
      expect(
          schemaTypeString(
              Validatable(Ints(), IntRangeValidator(2, 3)), _options),
          equals('Validatable(Ints(), IntRangeValidator(2, 3))'));
    });

    test('non-blank strings', () {
      expect(
          schemaTypeString(
              Validatable(Strings(), NonBlankStringValidator()), _options),
          equals('Validatable(Strings(), NonBlankStringValidator())'));
    });

    test('custom objects', () {
      // the auto-generated name is assumed
      expect(schemaTypeString(_TestObject(), _options),
          equals('__TestingJsonReviver()'));
    });

    test('arrays', () {
      expect(schemaTypeString(Arrays<double, Floats>(Floats()), _options),
          equals('Arrays<double, Floats>(Floats())'));

      expect(schemaTypeString(Arrays<String, Strings>(Strings()), _options),
          equals('Arrays<String, Strings>(Strings())'));
    });

    test('nested arrays', () {
      expect(
          schemaTypeString(
              Arrays<List<double>, Arrays<double, Floats>>(
                  Arrays<double, Floats>(Floats())),
              _options),
          equals('Arrays<List<double>, Arrays<double, Floats>>('
              'Arrays<double, Floats>(Floats()))'));
    });

    test('arrays of custom objects', () {
      expect(
          schemaTypeString(
              Arrays<_Testing, _TestObject>(_TestObject()), _options),
          equals('Arrays<_Testing, _TestObject>(__TestingJsonReviver())'));
    });

    test('nullable', () {
      expect(schemaTypeString(Nullable<int, Ints>(Ints()), _options),
          equals('Nullable<int, Ints>(Ints())'));
    });

    test('nullable custom object', () {
      expect(
          schemaTypeString(
              Nullable<_Testing, _TestObject>(_TestObject()), _options),
          equals('Nullable<_Testing, _TestObject>(__TestingJsonReviver())'));
    });
  });

  group('Json methods', () {
    test('toJson', () {
      final result = generateDartClasses([_someSchema],
          options: DartGeneratorOptions(
            methodGenerators: [const DartToJsonMethodGenerator()],
          ));
      expect('$result', equals('\n$_someSchemaToJsonGeneration'));
    });

    test('fromJson', () {
      final result = generateDartClasses([_someSchema],
          options: DartGeneratorOptions(
            methodGenerators: [const DartFromJsonMethodGenerator()],
          ));
      expect(
          result.toString(),
          equals("import 'dart:convert';\n"
              "import 'package:schemake/schemake.dart';\n\n"
              '$_someSchemaClassFromJsonGeneration'
              '$_someSchemaJsonReviverGeneration'));
    });

    test('fromJson (nested object with List)', () {
      final result = generateDartClasses([_nestedListObjectsSchema],
          options: DartGeneratorOptions(
            methodGenerators: [const DartFromJsonMethodGenerator()],
          ));
      expect(
          result.toString(),
          equals("import 'dart:convert';\n"
              "import 'package:schemake/schemake.dart';\n\n"
              '$_nestedListObjectsClassFromJsonGeneration\n'
              '$_someSchemaClassFromJsonGeneration'
              '$_nestedListObjectsReviverFromJsonGeneration'
              '$_someSchemaJsonReviverGeneration'));
    });

    test('toJson (nested object with List)', () {
      final result = generateDartClasses([_nestedListObjectsSchema],
          options: DartGeneratorOptions(
            methodGenerators: [const DartToJsonMethodGenerator()],
          ));
      expect(
          result.toString(),
          equals('\n$_nestedListObjectsClassToJsonGeneration\n'
              '$_someSchemaToJsonGeneration'));
    });

    test('both toJson and fromJson for Map objects', () {
      final result = generateDartClasses([_schemaWithMaps],
          options: DartGeneratorOptions(
            methodGenerators: [
              const DartFromJsonMethodGenerator(),
              const DartToJsonMethodGenerator()
            ],
          ));
      expect(result.toString(), equals(_schemaWithMapsToAndFromJsonGeneration));
    });

    test('fromJson for objects with defaults', () {
      final result = generateDartClasses([_schemaWithDefaultValues],
          options: DartGeneratorOptions(
            methodGenerators: [
              const DartFromJsonMethodGenerator(),
            ],
          ));
      expect(result.toString(), equals(_schemaWithDefaultsFromJsonGeneration));
    });

    test('both toJson and fromJson for semi-structured objects', () {
      final result = generateDartClasses([_semiStructuredObjects],
          options: DartGeneratorOptions(
            methodGenerators: [
              const DartFromJsonMethodGenerator(),
              const DartToJsonMethodGenerator()
            ],
          ));
      expect(result.toString(), equals(_schemaSemiStructuredObjects));
    });
  });

  group('generated classes', () {
    test('toJson works', () async {
      final (stdout, stderr) = await generateAndRunDartClass(
          Objects('Foo', {
            'bar': Property(Strings()),
          }),
          '''
      void main() {
        print(Foo(bar: 'good').toJson());
      }''',
          DartGeneratorOptions(methodGenerators: [
            DartToJsonMethodGenerator(),
          ]));
      expect(stderr, isEmpty);
      expect(
          stdout,
          equals([
            {'bar': 'good'}.toString()
          ]));
    });

    test('fromJson and toString work', () async {
      final (stdout, stderr) = await generateAndRunDartClass(
          Objects(
              'Counter',
              {
                'count': Property(Nullable(Ints())),
              },
              unknownPropertiesStrategy: UnknownPropertiesStrategy.ignore),
          '''
      void main() {
        print(Counter.fromJson({'count': 42}));
        print(Counter.fromJson({'zort': 'ignored'}));
      }''',
          const DartGeneratorOptions(methodGenerators: [
            DartFromJsonMethodGenerator(),
            DartToStringMethodGenerator(),
          ]));
      expect(stderr, isEmpty);
      expect(stdout, equals(['Counter{count: 42}', 'Counter{count: null}']));
    });

    test('fromJson and toString work with default values', () async {
      final (stdout, stderr) = await generateAndRunDartClass(
          _schemaWithDefaultValues,
          '''
      void main() {
        print(WithDefaults.fromJson({'mandatory': 42}));
        print(WithDefaults.fromJson({'mandatory': 0, 'nullableWithDefault': null,
          'enum1': 'abc', 'a': 'bar', 'b': 20, 'c': []}));
      }''',
          const DartGeneratorOptions(methodGenerators: [
            DartFromJsonMethodGenerator(),
            DartToStringMethodGenerator(),
          ]));
      expect(stderr, isEmpty);
      expect(
          stdout,
          equals([
            'WithDefaults{a: "foo", b: 3.1415, c: [1, 2], '
                'nullableWithDefault: 2, enum1: EnumValue.def, mandatory: 42}',
            'WithDefaults{a: "bar", b: 20.0, c: [], '
                'nullableWithDefault: null, enum1: EnumValue.abc, mandatory: 0}'
          ]));
    });

    test('toJson and fromJson and toString work for Maps', () async {
      final (stdout, stderr) = await generateAndRunDartClass(
          _schemaWithMaps,
          '''
          void main() {
            final maps = HasMaps(
                maps: {'foo': 'bar'},
                ints: {'n': 1, 'm': null},
                objectsMap: {'one': 1});
            final jsonMaps = jsonEncode(maps);
            print(jsonMaps);
            print(HasMaps.fromJson(jsonMaps));
          }''',
          DartGeneratorOptions(
            methodGenerators: [
              const DartFromJsonMethodGenerator(),
              const DartToJsonMethodGenerator(),
              const DartToStringMethodGenerator(),
            ],
          ));
      expect(stderr, isEmpty);
      expect(
          stdout,
          equals([
            '{"maps":{"foo":"bar"},'
                '"ints":{"n":1,"m":null},'
                '"objectsMap":{"one":1}}',
            'HasMaps{maps: {foo: bar}, ints: {n: 1, m: null}, objectsMap: {one: 1}}'
          ]));
    });

    test('toJson and fromJson and toString work for semi-structured objects',
        () async {
      final (stdout, stderr) = await generateAndRunDartClass(
          _semiStructuredObjects,
          '''
          void main() {
            final data = SemiStructured.fromJson('{"str":"ab","cd":1,"d":"e"}');
            print(data);
            print(data.toJson());
          }''',
          DartGeneratorOptions(
            methodGenerators: [
              const DartFromJsonMethodGenerator(),
              const DartToJsonMethodGenerator(),
              const DartToStringMethodGenerator(),
            ],
          ));
      expect(stderr, isEmpty);
      expect(
          stdout,
          equals([
            'SemiStructured{str: "ab", extras: ${{"cd": 1, "d": "e"}}}',
            {"str": "ab", "cd": 1, "d": "e"}.toString(),
          ]));
    });

    test('toJson and fromJson and toString and == work for lisp-case objects',
        () async {
      final (stdout, stderr) = await generateAndRunDartClass(
          _lispCaseType,
          '''
          void main() {
            final data = LispObject.fromJson('{"some-prop":false,"many-props":[4,3]}');
            print(data);
            print(data.toJson());
            print(data == LispObject(someProp: false, manyProps: [4, 3]));
            print(data == LispObject(someProp: true, manyProps: [4, 3]));
            print(data == LispObject(someProp: false, manyProps: [4]));
          }''',
          DartGeneratorOptions(
            methodGenerators: [
              ...DartGeneratorOptions.defaultMethodGenerators,
              const DartFromJsonMethodGenerator(),
              const DartToJsonMethodGenerator(),
            ],
          ));
      expect(stderr, isEmpty);
      expect(
          stdout,
          equals([
            'LispObject{someProp: false, manyProps: ${[4, 3]}}',
            {
              "some-prop": false,
              "many-props": [4, 3]
            }.toString(),
            'true',
            'false',
            'false',
          ]));
    });

    test('error message on missing mandatory property', () async {
      final (stdout, stderr) = await generateAndRunDartClass(
          Objects('Counter', {
            'foo': Property(Bools()),
            'count': Property(Ints()),
          }),
          '''
      void main() {
        print(Counter.fromJson({'foo': true}));
      }''',
          const DartGeneratorOptions(methodGenerators: [
            DartFromJsonMethodGenerator(),
            DartToStringMethodGenerator(),
          ]));
      expect(stderr,
          contains('MissingPropertyException{missingProperties: [count]}'));
      expect(stdout, isEmpty);
    });

    test('error message on wrong type property', () async {
      final (stdout, stderr) = await generateAndRunDartClass(
          Objects('Foo', {
            'foo': Property(Bools()),
          }),
          '''
      void main() {
        print(Foo.fromJson({'foo': 'yes'}));
      }''',
          const DartGeneratorOptions(methodGenerators: [
            DartFromJsonMethodGenerator(),
            DartToStringMethodGenerator(),
          ]));
      expect(
          stderr,
          contains('PropertyTypeException{'
              'propertyPath: [foo], '
              'cannot cast yes (type String) to bool, '
              'objectType: Foo}'));
      expect(stdout, isEmpty);
    });
  });
}
