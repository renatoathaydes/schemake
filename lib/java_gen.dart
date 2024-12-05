/// Java generation based on Schemake schemas.
///
/// From one or more [Objects] schemas, Java classes and types can be generated.
/// A class generated in this manner can have multiple features depending on
/// the [JavaGeneratorOptions] used, such as:
/// * `toString`
/// * `equals` and `hashCode`
/// * `toJson`
/// * `fromJson`
library java_gen;

export 'src/java_gen/gen_options.dart';
export 'src/java_gen/java_gen.dart';
export 'src/java_gen/json.dart';
