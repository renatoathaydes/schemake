import 'package:schemake/schemake.dart';
import 'package:yaml/yaml.dart';

/// this defines a schema that can be used for code generation.
const personSchema = Objects('Person', {
  'name': Property<String>(type: Strings()),
  'age': Property<int?>(type: Nullable(Ints())),
});

void main() {
  final yaml = loadYaml('''
  name: Joe Doe
  age: 42
  ''');

  // when used directly, Objects simply verifies the schema and makes sure
  // to get rid of YAML types.
  Map<String, Object?> joe = personSchema.convert(yaml);
  print('// Full name: ${joe['name']}');
  print('// Age:       ${joe['age']}');

  // now to the interesting bits...

  // generate a Dart class from the schema... by default, it generates a
  // simple Dart class with toString, equals and hashCode implemented:
  //
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
  //
  // In this example, we include some of them:
  print(generateDartClasses([personSchema],
      options: const DartGeneratorOptions(methodGenerators: [
        EqualsAndHashCodeMethodGenerator(),
        ToJsonMethodGenerator(),
        FromJsonMethodGenerator(),
      ])));

  // execute this example by piping its output to a ".dart" file, then run
  // that file!
  print(r'''
void main() {
  final person = Person(name: 'Joe Doe', age: 42);
  print(jsonEncode(person));
  final otherPerson = jsonDecode('{"name": "Mary Jane"}',
      reviver: const PersonJsonReviver()) as Person;
  print('Other person is called ${otherPerson.name}');
}
  ''');
}
