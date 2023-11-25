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
  'mandatory': Property(type: Strings()),
  'optional': Property(type: Nullable(Floats())),
  'list': Property(type: Arrays<int, Ints>(Ints())),
});

const _someSchemaToJsonGeneration = r'''
import 'dart:convert';
import 'package:schemake/schemake.dart';

class SomeSchema {
  String mandatory;
  double? optional;
  List<int> list;
  SomeSchema({
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
    ignoreUnknownProperties: false,
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
}

class SomeSchema {
  String mandatory;
  double? optional;
  List<int> list;
  SomeSchema({
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
          schemaTypeString(Validatable(
              Strings(), EnumValidator('MyEnum', {'abc': null, 'def': 'DEF'}))),
          equals(
              "Validatable(Strings(), EnumValidator('MyEnum', {'abc': null, 'def': 'DEF'}))"));
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
  });

  group('generated classes', () {
    test('toJson works', () async {
      final (stdout, stderr) = await generateAndRunDartClass(
          Objects('Foo', {
            'bar': Property(type: Strings()),
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
                'count': Property(type: Nullable(Ints())),
              },
              ignoreUnknownProperties: true),
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
  });
}
