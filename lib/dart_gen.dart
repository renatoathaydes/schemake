/// Dart generation based on Schemake schemas.
///
/// From one or more [Objects] schemas, Dart classes and types can be generated.
/// A class generated in this manner can have multiple features depending on
/// the [DartGeneratorOptions] used, such as:
/// * `toString`
/// * `==` operator
/// * `hashCode`
/// * `toJson`
/// * `fromJson`
library;

export 'src/dart_gen/dart_gen.dart';
export 'src/dart_gen/gen_options.dart';
export 'src/dart_gen/json.dart';
