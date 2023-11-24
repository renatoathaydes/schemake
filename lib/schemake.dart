/// Schemake is a library to describe schemas for data.
/// These schemas are useful on their own as they allow validating JSON/YAML
/// objects and then using them safely dynamically or by manually writing types
/// to convert them without having to perform further validation.
///
/// Schemake schemas may also be used for code generation. The [dart_gen]
/// library of this package can generate Dart code, for example.
library schemake;

export 'src/errors.dart';
export 'src/property.dart';
export 'src/types.dart';
export 'src/validator.dart';
