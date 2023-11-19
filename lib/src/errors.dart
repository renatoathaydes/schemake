abstract class SchemakeException implements Exception {}

class TypeException implements SchemakeException {
  final Type targetType;
  final Object? actualValue;

  TypeException(this.targetType, this.actualValue);

  @override
  String toString() {
    return 'TypeException{cannot cast $actualValue (type ${actualValue.runtimeType}) to $targetType}';
  }
}

class UnknownPropertyException implements SchemakeException {
  final List<String> fieldLocation;
  final Object objectType;

  UnknownPropertyException(this.fieldLocation, this.objectType);
}

class MissingPropertyException implements SchemakeException {
  final List<String> fieldLocation;
  final Object objectType;
  final List<String> missingProperties;

  MissingPropertyException(
      this.fieldLocation, this.objectType, this.missingProperties);
}
