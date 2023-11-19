import 'package:schemake/schemake.dart';
import 'package:yaml/yaml.dart';

const person = Objects('Person', {
  'name': Property<String>(type: Strings()),
  'age': Property<int?>(type: Nullable(Ints())),
});

void main() {
  final yaml = loadYaml('''
  name: Joe Doe
  age: 42
  ''');
  final joe = person.convertToDart(yaml);
  print('Full name: ${joe['name']}');
  print('Age:       ${joe['age']}');
}
