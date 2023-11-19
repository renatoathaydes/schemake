import 'package:schemake/schemake.dart';
import 'package:schemake/src/dart_gen.dart';
import 'package:test/test.dart';

const myObject = Objects('Person', {
  'name': Property<String>(type: Strings()),
  'age': Property<int?>(type: Nullable(Ints())),
});

void main() {
  group('Schemake Dart class gen', () {
    test('can write simple Dart class', () {
      final classCode = generateDart(myObject).toString();
      expect(
          classCode,
          equals('class Person {\n'
              '  String name;\n'
              '  int? age;\n'
              '}\n'));
    });
  });
}
