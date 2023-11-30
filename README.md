# Schemake

![Schemake CI](https://github.com/renatoathaydes/schemake/workflows/Schemake%20CI/badge.svg)
[![pub package](https://img.shields.io/pub/v/schemake.svg)](https://pub.dev/packages/schemake)

Schemake (schema make) is a package for describing schemas from a declarative specification.
Specifications can then be used for validating data, generating code or other schemas like JSON Schema and more.

A Schemake specification is easy to write and is just plain Dart code:

```dart
import 'package:schemake/schemake.dart';

const person = Objects('Person', {
  'name': Property(Strings()),
  'age': Property(Nullable(Ints())),
});
```

With such a schema specification, you can now validate data you receive, for example, from JSON or YAML:

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

## Data types

Supported data types:

| Schemake type    | Dart type              |
|------------------|------------------------|
| `Ints`           | `int`                  |
| `Floats`         | `double`               |
| `Bools`          | `bool`                 |
| `Strings`        | `String`               |
| `Arrays(T)`      | `List<S>`              |
| `ObjectsBase<C>` | `C`                    |
| `Objects`        | `Map<String, Object?>` |
| `Maps(T)`        | `Map<String, S>`       |
| `Nullable(T)`    | `S?`                   |
| `Validatable(T)` | `S`                    |

> In the table above, `T` stands for some other Schemake type, and `S` for the Dart type associated with `T`.
> `ObjectsBase<C>` is convertable to some Dart class `C`, as explained below.

`enum`s are also supported as a special-case of `Validatable(Strings)` (see the `Validatable` section).

Maps from `String` to some type `T` (for a given Dart type `S`) are supported with the `Maps` Schemake type,
which is a subtype of `ObjectsBase<Map<String, S>>`.

All Schemake types implement Dart's `Converter<Object?, S>` for some Dart type `S`.

Schemake types are normally declared with `const`, as they are, semantically, types.

### `Objects` and `ObjectsBase`

`Objects` are data structures with a known schema, similar to Dart classes.
We've seen an example of `Objects` earlier, the `Person` schema.

Calling `convert` on a `Map` will convert it to a "pure" data `Map<String, Object?>` which is guaranteed to match the
schema described by the `Objects` instance.

> By "pure data", we mean values whose Dart types are present in the types table shown earlier.

`Objects` extends `ObjectsBase`, which can also be used to create schema types that convert to arbitrary Dart data
classes
(which is normally done by code generation, as explained in the next section), which means that their `convert` method
returns instances of a specific Dart class instead of `Map`.

As an example, given a simple Dart class:

```dart
class MyType {
  final String example;

  const MyType({required this.example});
}
```

We could specify a Schemake type for it using `Objects`:

```dart
const myTypes = Objects('MyTypes', {
  'example': Property(Strings()),
});
```

We could also write a `ObjectsBase` subtype that converts directly to `MyType`:

```dart
class MyTypes extends ObjectsBase<MyType> {
  const MyTypes() : super('MyType');

  @override
  MyType convert(Object? input) {
    final map = input as Map<String, Object?>;
    checkRequiredProperties(map.keys);
    return MyType(
      example: convertProperty(const Strings(), 'example', map),
    );
  }

  @override
  Converter<Object?, Object?>? getPropertyConverter(String property) =>
      switch (property) {
        'example' => const Strings(),
        _ => null,
      };

  @override
  Iterable<String> getRequiredProperties() => const {'example'};
}
```

The above class can convert a `Map<String, Object?>` to an instance of `MyType` while validating its schema.

The `dart_gen` library (see next section) would produce something similar, but with more complete error handling
and functionality (i.e. `toString`, `==`, `hashCode`, `toString`, `fromString`, `toJson`, `fromJson` etc.).

To summarize:

```
Schema type     converts to
ObjectsBase<S>      --->         S
Maps<T>             --->         Map<String, T>
Objects             --->         Map<String, Object?>
   +---- can be used to generate some class S
         and a subclass of ObjectsBase<S> that converts between S and other Map
```

#### Semi structured objects

In a Schemake schema, you can represent any `Map<String, Object?>` (unstructured data)
using the following `Objects` schema:

```dart
const maps = Objects('Map', {},
    unknownPropertiesStrategy: UnknownPropertiesStrategy.keep);
```

With the above schema, the values of the unknown properties are not validated at all, but are kept in the converted
object.

`UnknownPropertiesStrategy` allows the following values:

* `forbid` - the default: forbids unknown properties (used for data whose structure is fully known).
* `keep`   - allow any properties besides the known ones, and keep them in the converted object.
* `ignore` - allow any properties besides the known ones, but discard them.

For cases where some properties are known, but not all (which is common in RFCs as this allows extensions to provide
meaning to additional properties), it's simple to define a _partial schema_:

```dart
const maps = Objects('PartialSchemaa', {
  'knownProperty': Property(String()),
}, unknownPropertiesStrategy: UnknownPropertiesStrategy.keep);
```

This schema determines that the `knownProperty` property must have type `String`, but allows any other properties with
any type to exist. So, the following would be both valid instances of this schema:

* `{'knownProperty': 'good'}`
* `{'knownProperty': 'good', 'whatever': true}`

But this value would NOT be valid:

* `{'knownProperty': false}` --> error: cannot cast `false` to `String`

### Validatable

`Validatable` wraps another Schemake type, adding further constraints to values that may be accepted.

For example:

```dart
import 'package:schemake/schemake.dart';

const nonBlankStrings = Validatable(Strings(), NonBlankStringValidator());

void main() {
  // OK! Prints "foo"
  print(nonBlankStrings.convert('foo'));

  // ValidationException{errors: [blank string]}
  print(nonBlankStrings.convert('  '));
}
```

You could now modify the `Person` schema mentioned earlier to only accept non-blank names:

```dart
import 'package:schemake/schemake.dart';

const nonBlankStrings = Validatable(Strings(), NonBlankStringValidator());

const person = Objects('Person', {
  'name': Property<String>(nonBlankStrings),
  'age': Property<int?>(Nullable(Ints())),
});
```

#### enums

A special case of `Strings` where the allowed values are all known at compile-time can be modelled as a
`Validatable(Strings(), EnumValidator(...))`, which ensures only certain String values are allowed.

Because this is such a common use case, Schemake provides the `Enums` type, which makes declaring enums
easier:

```dart
// the someEnum field is a String whose value must be one of
// "one", "two" or "three"
const typeWithEnumField = Objects('EnumExample', {
  'someEnum': Property(Enums(EnumValidator('SmallInt', {'one', 'two', 'three'}))),
});
```

The Dart code generator creates an actual Dart `enum` to represent enum properties, but their _serialized_ type is
still String.

## Dart code generation

You can generate data classes automatically from `Objects` schemas using the `dart_gen` library:

```dart
import 'package:schemake/dart_gen.dart' as dg;
import 'package:schemake/schemake.dart';

const person = Objects('Person', {
  'name': Property(Strings()),
  'age': Property(Nullable(Ints())),
});

void main() {
  print(dg.generateDartClasses([person]));
}
```

The following basic Dart class is generated:

```dart
class Person {
  final String name;
  final int? age;

  const Person({
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

Nearly everything can be customized. For example, to make the class' fields non-final and the constructor non-const,
and only generate the `toString` method, use the following options:

```dart
void main() {
  print(dg.generateDartClasses([someSchema],
      options: const dg.DartGeneratorOptions(
          methodGenerators: [dg.DartToStringMethodGenerator()],
          insertBeforeField: null,
          insertBeforeConstructor: null)));
}
```

You can also write your own implementations of `DartMethodGenerator` to generate any other methods.

### JSON and YAML

To include `toJson`, `fromJson` and other methods, you need to configure the Dart generator
with the appropriate `DartMethodGenerator`s:

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
