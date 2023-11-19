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

  // generate a Dart class from the schema... by default, it prints:
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
  //   @override
  //   bool operator ==(Object other) =>
  //     identical(this, other) ||
  //     other is Person &&
  //     runtimeType == other.runtimeType &&
  //     name == other.name &&
  //     age == other.age;
  //   @override
  //   int get hashCode =>
  //     name.hashCode ^ age.hashCode;
  // }
  //
  // There are many options to generate more things, like toJson and fromJson.
  print(generateDart([personSchema]));
}
