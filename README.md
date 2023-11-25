# Schemake

![Schemake CI](https://github.com/renatoathaydes/schemake/workflows/Schemake%20CI/badge.svg)
[![pub package](https://img.shields.io/pub/v/schemake.svg)](https://pub.dev/packages/schemake)

Schemake (schema make) is a library for generating Dart code and schemas from a programmatic schema specification.

A Schemake specification is easy to write and is just Dart code:

```dart
import 'package:schemake/schemake.dart';

const person = Objects('Person', {
  'name': Property<String>(type: Strings()),
  'age': Property<int?>(type: Nullable(Ints())),
});
```

With such a schema specification, you can now validate data from JSON or YAML:

```dart
import 'package:schemake/schemake.dart';
import 'dart:convert';

void main() {
  // joe has type Map<String, Object?>, but its "properties", or keys,
  // are guaranteed to follow the "person" schema above.
  final joe = person.convert(jsonDecode('{"name": "Joe"}'));
  print(joe['name']); // prints "Joe"
  print(joe['age']); // prints "null"

  // this will throw (because age has type int, not String):
  // PropertyTypeException{propertyPath: [age], 
  //   cannot cast foo (type String) to int, 
  //   objectType: schemake.Objects ...
  person.convert(jsonDecode('{"name": "Joe", "age": "foo"}'));
}
```

## Dart code generation

If you don't want to manually wrap `Map`s into data classes, you can generate them automatically from `Objects`
schemas using the `dart_gen` library:

```dart
import 'package:schemake/dart_gen.dart' as dg;
import 'package:schemake/schemake.dart';

const person = Objects('Person', {
  'name': Property<String>(type: Strings()),
  'age': Property<int?>(type: Nullable(Ints())),
});

void main() {
  print(dg.generateDartClasses([person]));
}
```

The following basic Dart class is generated:

```dart
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
          'name: "$name",'
          'age: $age'
          '}';
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Person &&
              runtimeType == other.runtimeType &&
              name == other.name &&
              age == other.age;
  @override
  int get hashCode =>
      name.hashCode ^ age.hashCode;
}
```

## JSON and YAML

To include `toJson`, `fromJson` and other methods, you need to configure the Dart generator:

```dart
void main() {
  print(dg.generateDartClasses([person],
      options: const dg.DartGeneratorOptions(methodGenerators: [
        ...dg.DartGeneratorOptions.defaultMethodGenerators,
        dg.ToJsonMethodGenerator(),
        dg.FromJsonMethodGenerator(),
      ])));
}
```

Now, in addition to `toString`, `hashCode` and the `==` operator, the `Person` class will also have
the JSON methods:

```dart
class Person {
  ...;
  
  static Person fromJson(Object? value) => ...;

  Map<String, Object?> toJson() => ...;
}
```

The `toJson` method returns a `Map` in the tradition of Dart, as the `dart:core`'s `jsonEncode` function automatically
calls `toJson` on any type implementing it... which means serializing `Person` is as easy as:

```dart
void main() {
  // prints {"name": "Joe", "age": 42}
  print(jsonEncode(Person(name: 'Joe', age: 42)));
}
```

The `fromJson` method accepts either a:

* JSON `String` (in which case `jsonEncode` is invoked first).
* `List<int>` (treated as UTF-8 byte array).
* `Map`

The `Map` can be produced by, for example, `jsonDecode` or `loadYaml`:

```dart
import 'package:yaml/yaml.dart';

void main() {
  Person aPerson = Person.fromJson(loadYaml('name: Mary'));
  
  // Prints: Person{name: "Mary",age: null}
  print(aPerson);
}
```

## Custom generators

Schemake was designed to make it easy to add more generators.

Currently, only Dart code generation is supported, but **JSON Schema** will be added soon.
I might add a Java generator as well, and hopefully others can contribute more!

TODO show how to create a generator.
