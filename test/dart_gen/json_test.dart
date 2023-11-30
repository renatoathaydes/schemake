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

const _schemaWithMaps = Objects('HasMaps', {
  'maps': Property(
      Maps<String, Strings>('MapToStrings',
          valueType: Strings(), description: 'map with string values.'),
      description: 'Property with Map of Strings.'),
  'objectsMap': Property(Objects('SimpleMap', {},
      unknownPropertiesStrategy: UnknownPropertiesStrategy.keep)),
});

const _semiStructuredObjects = Objects(
    'SemiStructured',
    {
      'str': Property(Nullable(Strings())),
    },
    unknownPropertiesStrategy: UnknownPropertiesStrategy.keep);

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

const _someSchemaFromJsonGeneration = r'''
import 'dart:convert';
import 'package:schemake/schemake.dart';
class _SomeSchemaJsonReviver extends ObjectsBase<SomeSchema> {
  const _SomeSchemaJsonReviver(): super("SomeSchema",
    unknownPropertiesStrategy: UnknownPropertiesStrategy.forbid,
    location: const []);

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

const _schemaWithMapsToAndFromJsonGeneration = r'''
import 'dart:convert';
import 'package:schemake/schemake.dart';
class _HasMapsJsonReviver extends ObjectsBase<HasMaps> {
  const _HasMapsJsonReviver(): super("HasMaps",
    unknownPropertiesStrategy: UnknownPropertiesStrategy.forbid,
    location: const []);

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
      objectsMap: convertProperty(const Objects('SimpleMap', {}, unknownPropertiesStrategy: UnknownPropertiesStrategy.keep), 'objectsMap', value),
    );
  }

  @override
  Converter<Object?, Object?>? getPropertyConverter(String property) {
    switch(property) {
      case 'maps': return const Maps('MapToStrings', valueType: Strings());
      case 'objectsMap': return const Objects('SimpleMap', {}, unknownPropertiesStrategy: UnknownPropertiesStrategy.keep);
      default: return null;
    }
  }
  @override
  Iterable<String> getRequiredProperties() {
    return const {'maps', 'objectsMap'};
  }
  @override
  String toString() => 'HasMaps';
}

class HasMaps {
  /// Property with Map of Strings.
  final Map<String, String> maps;
  final Map<String, Object?> objectsMap;
  const HasMaps({
    required this.maps,
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
    'objectsMap': objectsMap,
  };
}
''';

const _schemaSemiStructuredObjects = r'''
import 'dart:convert';
import 'package:schemake/schemake.dart';
class _SemiStructuredJsonReviver extends ObjectsBase<SemiStructured> {
  const _SemiStructuredJsonReviver(): super("SemiStructured",
    unknownPropertiesStrategy: UnknownPropertiesStrategy.keep,
    location: const []);

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
''';

void main() {
  group('schemaTypeString', () {
    test('strings', () {
      expect(schemaTypeString(Strings()), equals('Strings()'));
    });

    test('ints', () {
      expect(schemaTypeString(Ints()), equals('Ints()'));
    });

    test('bools', () {
      expect(schemaTypeString(Bools()), equals('Bools()'));
    });

    test('floats', () {
      expect(schemaTypeString(Floats()), equals('Floats()'));
    });

    test('enums', () {
      expect(
          schemaTypeString(
              Validatable(Strings(), EnumValidator('MyEnum', {'abc', 'def'}))),
          equals("_MyEnumConverter()"));
    });

    test('int ranges', () {
      expect(schemaTypeString(Validatable(Ints(), IntRangeValidator(2, 3))),
          equals('Validatable(Ints(), IntRangeValidator(2, 3))'));
    });

    test('non-blank strings', () {
      expect(
          schemaTypeString(Validatable(Strings(), NonBlankStringValidator())),
          equals('Validatable(Strings(), NonBlankStringValidator())'));
    });

    test('custom objects', () {
      // the auto-generated name is assumed
      expect(schemaTypeString(_TestObject()), equals('_TestObject()'));
    });

    test('arrays', () {
      expect(schemaTypeString(Arrays<double, Floats>(Floats())),
          equals('Arrays<double, Floats>(Floats())'));

      expect(schemaTypeString(Arrays<String, Strings>(Strings())),
          equals('Arrays<String, Strings>(Strings())'));
    });

    test('nested arrays', () {
      expect(
          schemaTypeString(Arrays<List<double>, Arrays<double, Floats>>(
              Arrays<double, Floats>(Floats()))),
          equals('Arrays<List<double>, Arrays<double, Floats>>('
              'Arrays<double, Floats>(Floats()))'));
    });

    test('arrays of custom objects', () {
      expect(schemaTypeString(Arrays<_Testing, _TestObject>(_TestObject())),
          equals('Arrays<_Testing, _TestObject>(_TestObject())'));
    });

    test('nullable', () {
      expect(schemaTypeString(Nullable<int, Ints>(Ints())),
          equals('Nullable<int, Ints>(Ints())'));
    });

    test('nullable custom object', () {
      expect(schemaTypeString(Nullable<_Testing, _TestObject>(_TestObject())),
          equals('Nullable<_Testing, _TestObject>(_TestObject())'));
    });
  });

  group('Json methods', () {
    test('toJson', () {
      final result = generateDartClasses([_someSchema],
          options: DartGeneratorOptions(
            methodGenerators: [const ToJsonMethodGenerator()],
          ));
      expect(result.toString(), equals(_someSchemaToJsonGeneration));
    });

    test('fromJson', () {
      final result = generateDartClasses([_someSchema],
          options: DartGeneratorOptions(
            methodGenerators: [const FromJsonMethodGenerator()],
          ));
      expect(result.toString(), equals(_someSchemaFromJsonGeneration));
    });

    test('both toJson and fromJson for Map objects', () {
      final result = generateDartClasses([_schemaWithMaps],
          options: DartGeneratorOptions(
            methodGenerators: [
              const FromJsonMethodGenerator(),
              const ToJsonMethodGenerator()
            ],
          ));
      expect(result.toString(), equals(_schemaWithMapsToAndFromJsonGeneration));
    });

    test('both toJson and fromJson for semi-structured objects', () {
      final result = generateDartClasses([_semiStructuredObjects],
          options: DartGeneratorOptions(
            methodGenerators: [
              const FromJsonMethodGenerator(),
              const ToJsonMethodGenerator()
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
            ToJsonMethodGenerator(),
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
            FromJsonMethodGenerator(),
            DartToStringMethodGenerator(),
          ]));
      expect(stderr, isEmpty);
      expect(stdout, equals(['Counter{count: 42}', 'Counter{count: null}']));
    });

    test('toJson and fromJson and toString work for Maps', () async {
      final (stdout, stderr) = await generateAndRunDartClass(
          _schemaWithMaps,
          '''
          void main() {
            final maps = HasMaps(
                maps: {'foo': 'bar'},
                objectsMap: {'one': 1});
            final jsonMaps = jsonEncode(maps);
            print(jsonMaps);
            print(HasMaps.fromJson(jsonMaps));
          }''',
          DartGeneratorOptions(
            methodGenerators: [
              const FromJsonMethodGenerator(),
              const ToJsonMethodGenerator(),
              const DartToStringMethodGenerator(),
            ],
          ));
      expect(stderr, isEmpty);
      expect(
          stdout,
          equals([
            '{"maps":{"foo":"bar"},'
                '"objectsMap":{"one":1}}',
            'HasMaps{maps: {foo: bar}, objectsMap: {one: 1}}'
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
              const FromJsonMethodGenerator(),
              const ToJsonMethodGenerator(),
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
            FromJsonMethodGenerator(),
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
            FromJsonMethodGenerator(),
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
