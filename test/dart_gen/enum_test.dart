import 'dart:convert';

import 'package:schemake/dart_gen.dart';
import 'package:schemake/schemake.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

const _simpleEnum = r'''
import 'dart:convert';
import 'package:schemake/schemake.dart';

class MyObject {
  final MyEnum prop;
  const MyObject({
    required this.prop,
  });
}
enum MyEnum {
  foo,
  ;
  String get name => switch(this) {
    foo => 'foo',
  };
  static MyEnum from(String s) => switch(s) {
    'foo' => foo,
    _ => throw ValidationException(['value not allowed for MyEnum: "$s" - should be one of {foo}']),
  };
}
class _MyEnumConverter extends Converter<Object?, MyEnum> {
  const _MyEnumConverter();
  @override
  MyEnum convert(Object? input) {
    return MyEnum.from(const Strings().convert(input));
  }
}
''';
//some-prop', 'other-thing
const _lispCaseEnum = r'''
import 'dart:convert';
import 'package:schemake/schemake.dart';

class MyObject {
  final LispCaseEnum prop;
  const MyObject({
    required this.prop,
  });
}
enum LispCaseEnum {
  someProp,
  otherThing,
  ;
  String get string => switch(this) {
    someProp => 'some-prop',
    otherThing => 'other-thing',
  };
  static LispCaseEnum from(String s) => switch(s) {
    'some-prop' => someProp,
    'other-thing' => otherThing,
    _ => throw ValidationException(['value not allowed for LispCaseEnum: "$s" - should be one of {some-prop, other-thing}']),
  };
}
class _LispCaseEnumConverter extends Converter<Object?, LispCaseEnum> {
  const _LispCaseEnumConverter();
  @override
  LispCaseEnum convert(Object? input) {
    return LispCaseEnum.from(const Strings().convert(input));
  }
}
''';

void main() {
  group('Enums basics', () {
    test('simple enum', () {
      expect(
          generateDartClasses([
            Objects('MyObject', {
              'prop': Property(Enums(EnumValidator('MyEnum', {'foo'})))
            })
          ], options: DartGeneratorOptions(methodGenerators: const []))
              .toString(),
          equals(_simpleEnum));
    });
    test('lisp case enum', () {
      expect(
          generateDartClasses([
            Objects('MyObject', {
              'prop': Property(Enums(EnumValidator('lisp-case-enum', {
                'some-prop',
                'other-thing'
              }, generatorOptions: [
                DartEnumGeneratorOptions(nameProperty: 'string')
              ])))
            })
          ], options: DartGeneratorOptions(methodGenerators: const []))
              .toString(),
          equals(_lispCaseEnum));
    });
  });

  group('Enums runner', () {
    test('toJson works', () async {
      final json1 = jsonEncode({'prop': 'bar'});
      final json2 = jsonEncode({'prop': 'zort'});
      final (stdout, stderr) = await generateAndRunDartClass(
          Objects('Foo', {
            'prop': Property(Enums(EnumValidator('Bar', {'bar', 'zort'}))),
          }),
          '''
      void main() {
        print(jsonEncode(Foo(prop: Bar.bar)));
        print(jsonEncode(Foo(prop: Bar.zort)));
      }''',
          DartGeneratorOptions(methodGenerators: [
            DelegateMethodGenerator(DartToJsonMethodGenerator(),
                extraImports: {'dart:convert'}),
          ]));
      expect(stderr, isEmpty);
      expect(stdout, equals([json1, json2]));
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
            DartFromJsonMethodGenerator(),
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
            DartFromJsonMethodGenerator(),
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

class DelegateMethodGenerator with DartMethodGenerator {
  final DartMethodGenerator delegate;
  final Set<String> extraImports;

  const DelegateMethodGenerator(this.delegate, {required this.extraImports});

  @override
  GeneratorExtras? generateMethod(
      StringBuffer buffer, Objects objects, DartGeneratorOptions options) {
    final result = delegate.generateMethod(buffer, objects, options);
    if (result == null) {
      return GeneratorExtras(extraImports);
    }
    return GeneratorExtras(
        Set.unmodifiable(result.imports.followedBy(extraImports)),
        result.types,
        result.writeTypes);
  }
}
