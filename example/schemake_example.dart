import 'dart:io';

import 'package:schemake/dart_gen.dart';
import 'package:schemake/schemake.dart';
import 'package:yaml/yaml.dart';

/// this defines a schema that can be used for code generation.
const personSchema = Objects('Person', {
  'name': Property<String>(type: Strings()),
  'age': Property<int?>(type: Nullable(Ints())),
  'friends': Property(type: Arrays<String, Strings>(Strings()))
});

void main() {
  final yaml = loadYaml('''
  name: Joe Doe
  age: 42
  friends: [ "Mary", "Fred" ]
  ''');

  // when used directly, Objects simply verifies the schema and makes sure
  // to get rid of YAML types.
  Map<String, Object?> joe = personSchema.convert(yaml);
  print('// Full name: ${joe['name']}');
  print('// Age:       ${joe['age']}');
  // you get a List<String>, not a YamlList!
  final friends = joe['friends'] as List<String>;
  print('// Friends:   ${friends.join(', ')}');

  // if the schema does not validate, an Exception gets thrown!
  try {
    // missing "friends", which is mandatory
    personSchema.convert(loadYaml('name: Fred'));
  } on MissingPropertyException catch (e) {
    stderr.writeln('Missing properties: ${e.missingProperties}');
  }

  // now to the interesting bits...

  // generate a Dart class from the schema... by default, it generates a
  // simple Dart class with toString, equals and hashCode implemented,
  // but we can also add JSON methods.
  print(generateDartClasses([personSchema],
      options: const DartGeneratorOptions(methodGenerators: [
        ...DartGeneratorOptions.defaultMethodGenerators,
        ToJsonMethodGenerator(),
        FromJsonMethodGenerator(),
      ])));

  // execute this example by piping its output to a ".dart" file, then run
  // that file!
  print(r'''
void main() {
  final person = Person(name: 'Joe Doe', age: 42, friends: ['Mary']);
  print(jsonEncode(person));
  final otherPerson = jsonDecode('{"name": "Mary Jane", "friends": ["Joe"]}',
      reviver: const PersonJsonReviver()) as Person;
  print('Other person is called ${otherPerson.name}');
}
  ''');
}
