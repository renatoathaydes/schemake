abstract class SchemakeException implements Exception {}

mixin PropertyException on SchemakeException {
  List<String> get propertyPath;

  PropertyException prependPath(String property);
}

mixin ToPropertyException on SchemakeException {
  PropertyException toPropertyException(String property, Object objectType);
}

class TypeException implements SchemakeException, ToPropertyException {
  final Type targetType;
  final Object? actualValue;
  final String? message;

  const TypeException(this.targetType, this.actualValue, [this.message]);

  @override
  PropertyTypeException toPropertyException(
      String property, Object objectType) {
    return PropertyTypeException(
        targetType, actualValue, [property], objectType);
  }

  @override
  String toString() {
    final suffix = message == null ? '' : ' ($message)';
    return 'TypeException{cannot cast $actualValue '
        '(type ${actualValue.runtimeType}) to $targetType}$suffix';
  }
}

class PropertyTypeException extends TypeException with PropertyException {
  @override
  final List<String> propertyPath;
  final Object objectType;

  const PropertyTypeException(
      super.targetType, super.actualValue, this.propertyPath, this.objectType);

  @override
  PropertyTypeException prependPath(String property) {
    return PropertyTypeException(
        targetType, actualValue, [property, ...propertyPath], objectType);
  }

  @override
  String toString() {
    return 'PropertyTypeException{propertyPath: $propertyPath, '
        'cannot cast $actualValue (type ${actualValue.runtimeType}) '
        'to $targetType}, objectType: $objectType}';
  }
}

class UnknownPropertyException implements SchemakeException, PropertyException {
  @override
  final List<String> propertyPath;
  final Object objectType;

  const UnknownPropertyException(this.propertyPath, this.objectType);

  @override
  UnknownPropertyException prependPath(String property) {
    return UnknownPropertyException([property, ...propertyPath], objectType);
  }

  @override
  String toString() {
    return 'UnknownPropertyException{propertyPath: $propertyPath}';
  }
}

class MissingPropertyException implements SchemakeException, PropertyException {
  @override
  final List<String> propertyPath;
  final Object objectType;
  final List<String> missingProperties;

  const MissingPropertyException(
      this.propertyPath, this.objectType, this.missingProperties);

  @override
  MissingPropertyException prependPath(String property) {
    return MissingPropertyException(
        [property, ...propertyPath], objectType, missingProperties);
  }

  @override
  String toString() {
    return 'MissingPropertyException{missingProperties: $missingProperties}';
  }
}

class ValidationException implements SchemakeException, ToPropertyException {
  final List<String> errors;

  const ValidationException(this.errors);

  @override
  PropertyValidationException toPropertyException(
      String property, Object objectType) {
    return PropertyValidationException([property], objectType, errors);
  }

  @override
  String toString() {
    return 'ValidationException{errors: $errors}';
  }
}

class PropertyValidationException extends ValidationException
    with PropertyException {
  @override
  final List<String> propertyPath;
  final Object objectType;

  const PropertyValidationException(
      this.propertyPath, this.objectType, super.errors);

  @override
  PropertyException prependPath(String property) {
    return PropertyValidationException(
        [property, ...propertyPath], objectType, errors);
  }

  @override
  String toString() {
    return 'PropertyValidationException{propertyPath: $propertyPath, '
        'objectType: $objectType}';
  }
}
