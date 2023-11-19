import 'package:schemake/schemake.dart';
import 'package:yaml/yaml.dart';

const personSchema = Objects('Person', {
  'name': Property<String>(type: Strings()),
  'age': Property<int?>(type: Nullable(Ints())),
});

void main() {
  final yaml = loadYaml('''
  name: Joe Doe
  age: 42
  ''');

  // get a pure Dart value back (no YAML classes)
  Map<String, Object?> joe = personSchema.convertToDart(yaml);
  print('Full name: ${joe['name']}');
  print('Age:       ${joe['age']}');

  // generate a Dart class from the schema... prints:
  // class Person {
  //   String name;
  //   int? age;
  //   Person({
  //     required this.name,
  //     this.age,
  //   });
  //   @override
  //   String toString() =>
  //     'Person{'
  //     'name = "$name",'
  //     'age = $age,'
  //     '}';
  // }
  print(generateDart([personSchema]));
}
