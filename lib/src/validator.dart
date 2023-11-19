import 'package:schemake/schemake.dart';

typedef ValidationResult = List<String>;

abstract class Validator<T> {
  void validate(T value);
}

class IntRange implements Validator<int> {
  final int min;
  final int max;

  const IntRange(this.min, this.max);

  const IntRange.maxExclusive(int min, int max) : this(min, max - 1);

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
}
