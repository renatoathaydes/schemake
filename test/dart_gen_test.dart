import 'package:schemake/schemake.dart';
import 'package:test/test.dart';

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
    'name = "$name",'
    'age = $age,'
    '}';
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

void main() {
  group('Schemake Dart class gen', () {
    test('can write simple Dart class', () {
      expect(
          generateDart([personSchema]).toString(),
          equals(_generatedPersonClass));
    });

    test('can write Dart class with array', () {
      expect(
          generateDart([stringItemsSchema]).toString(),
          equals('\n'
              'class StringItems {\n'
              '  List<String> items;\n'
              '  StringItems({\n'
              '    required this.items,\n'
              '  });\n'
              '  @override\n'
              '  String toString() =>\n'
              "    'StringItems{'\n"
              "    'items = \$items,'\n"
              "    '}';\n"
              '}\n'));
    });

    test('can write Dart class with nested Objects', () {
      expect(
          generateDart([nestedObjectSchema]).toString(),
          equals('\n'
              'class Nested {\n'
              '  Person inner;\n'
              '  Nested({\n'
              '    required this.inner,\n'
              '  });\n'
              '  @override\n'
              '  String toString() =>\n'
              "    'Nested{'\n"
              "    'inner = \$inner,'\n"
              "    '}';\n"
              '}\n'
              '$_generatedPersonClass'));
    });
  });
}
