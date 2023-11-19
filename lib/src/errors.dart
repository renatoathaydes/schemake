abstract class SchemakeException implements Exception {}

class TypeException implements SchemakeException {
  final Type targetType;
  final Object? actualValue;

  const TypeException(this.targetType, this.actualValue);

  @override
  String toString() {
    return 'TypeException{cannot cast $actualValue (type ${actualValue.runtimeType}) to $targetType}';
  }
}

class UnknownPropertyException implements SchemakeException {
  final List<String> fieldLocation;
  final Object objectType;

  const UnknownPropertyException(this.fieldLocation, this.objectType);
}

class MissingPropertyException implements SchemakeException {
  final List<String> fieldLocation;
  final Object objectType;
  final List<String> missingProperties;

  const MissingPropertyException(
      this.fieldLocation, this.objectType, this.missingProperties);
}

class ValidationException implements SchemakeException {
  final List<String> errors;

  const ValidationException(this.errors);
}

class PropertyValidationException extends ValidationException {
  final List<String> fieldLocation;
  final Object objectType;

  const PropertyValidationException(
      this.fieldLocation, this.objectType, super.errors);
}
