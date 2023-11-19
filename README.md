# Schemake

Schemake (schema make) is a library for generating Dart code and schemas from a programmatic schema specification.

A Schemake specification is easy to write and is just Dart code:

```dart
import 'package:schemake/schemake.dart';

const person = Objects({
  'name': Property<String>(type: Strings()),
  'age': Property<int?>(type: Nullable(Ints())),
});
```
