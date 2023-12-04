import 'package:collection/collection.dart';

import 'errors.dart';

typedef ValidationResult = List<String>;

/// A validator for values of type [T].
///
/// [Validator]s may be used to impose restrictions on Schemake types by
/// wrapping them into a [Validatable] type.
abstract class Validator<T> {
  const Validator();

  void validate(T value);

  List<ValidatorGenerationOptions> get generatorOptions;
}

mixin ValidatorGenerationOptions {}

class IntRangeValidator extends Validator<int> {
  final int min;
  final int max;
  @override
  final List<ValidatorGenerationOptions> generatorOptions;

  const IntRangeValidator(
    this.min,
    this.max, {
    this.generatorOptions = const [],
  });

  const IntRangeValidator.maxExclusive(int min, int max) : this(min, max - 1);

  @override
  void validate(int value) {
    bool tooLow = value < min, tooHigh = value > max;
    if (tooLow || tooHigh) {
      final errors = [
        if (tooLow) '$value < $min',
        if (tooHigh) '$value > $max',
      ];
      throw ValidationException(errors);
    }
  }

  @override
  String toString() {
    return 'IntRangeValidator{min: $min, max: $max}';
  }
}

class EnumValidator extends Validator<String> {
  final String name;
  final Set<String> values;
  @override
  final List<ValidatorGenerationOptions> generatorOptions;

  const EnumValidator(
    this.name,
    this.values, {
    this.generatorOptions = const [],
  });

  @override
  void validate(String value) {
    if (!values.contains(value)) {
      throw ValidationException(['"$value" not in $values']);
    }
  }

  @override
  String toString() {
    return 'EnumValidator{name: $name, values: $values}';
  }
}

/// Obtained by running Java `Character.isWhitespace(i)`
/// on each char up to Character.MAX_CODE_POINT.
const _whitespace = [
  9,
  10,
  11,
  12,
  13,
  28,
  29,
  30,
  31,
  32,
  5760,
  8192,
  8193,
  8194,
  8195,
  8196,
  8197,
  8198,
  8200,
  8201,
  8202,
  8232,
  8233,
  8287,
  12288
];

class NonBlankStringValidator extends Validator<String> {
  @override
  final List<ValidatorGenerationOptions> generatorOptions;

  const NonBlankStringValidator({
    this.generatorOptions = const [],
  });

  @override
  void validate(String value) {
    if (value.runes.none((c) => !_whitespace.contains(c))) {
      throw const ValidationException(['blank string']);
    }
  }
}
