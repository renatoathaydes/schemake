import 'dart:convert';

import '../errors.dart' show TypeException;
import '../types.dart' show SchemaType;
import '../validator.dart';

void generateEnum(
    Object validator, SchemaType<Object?> type, StringBuffer buffer) {
  if (validator is EnumValidator) {
    buffer.write(', "enum": ');
    buffer.write(jsonEncode(validator.values.toList()));
  } else {
    throw TypeException(EnumValidator, validator);
  }
}

void generateNonBlankString(
    Object validator, SchemaType<Object?> type, StringBuffer buffer) {
  if (validator is NonBlankStringValidator) {
    buffer.write(r', "pattern": ".*\\S.*"');
  } else {
    throw TypeException(EnumValidator, validator);
  }
}

void generateIntRange(
    Object validator, SchemaType<Object?> type, StringBuffer buffer) {
  if (validator is IntRangeValidator) {
    buffer.write(', "minimum": ${validator.min}, "maximum": ${validator.max}');
  } else {
    throw TypeException(IntRangeValidator, validator);
  }
}

void generateFloatRange(
    Object validator, SchemaType<Object?> type, StringBuffer buffer) {
  if (validator is FloatRangeValidator) {
    buffer.write(', "minimum": ${validator.min}, "maximum": ${validator.max}');
  } else {
    throw TypeException(FloatRangeValidator, validator);
  }
}
