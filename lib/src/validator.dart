import 'package:collection/collection.dart';
import 'package:conveniently/conveniently.dart';

import '_text.dart';
import 'dart_gen/enum.dart';
import 'errors.dart';

typedef ValidationResult = List<String>;

abstract class Validator<T> {
  const Validator();

  void validate(T value);

  /// For code generation, create a representation of the arguments necessary
  /// to re-create this validator instance.
  String get ownArgumentsString;

  List<ValidatorGenerationOptions> get generatorOptions => const [];
}

mixin ValidatorGenerationOptions {}

class IntRangeValidator extends Validator<int> {
  final int min;
  final int max;

  const IntRangeValidator(this.min, this.max);

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
  String get ownArgumentsString => '$min, $max';

  @override
  String get dartType => 'int';

  @override
  String toString() {
    return 'IntRangeValidator{min: $min, max: $max}';
  }
}

class EnumValidator extends Validator<String> {
  final String name;
  final Map<String, String?> values;

  @override
  final List<ValidatorGenerationOptions> generatorOptions;

  const EnumValidator(this.name, this.values,
      {this.generatorOptions = const [DartEnumGeneratorOptions()]});

  @override
  void validate(String value) {
    if (!values.keys.contains(value)) {
      throw ValidationException(['"$value" not in ${values.keys}']);
    }
  }

  @override
  String get ownArgumentsString =>
      "'$name', {${values.entries.map((e) => '${quote(e.key)}: '
          '${e.value.vmapOr(quote, () => 'null')}').join(", ")}}";

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
  const NonBlankStringValidator();

  @override
  void validate(String value) {
    if (value.runes.none((c) => !_whitespace.contains(c))) {
      throw const ValidationException(['blank string']);
    }
  }

  @override
  String get ownArgumentsString => '';

  @override
  String get dartType => 'String';
}
