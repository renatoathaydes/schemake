import 'package:schemake/schemake.dart';
import 'package:test/test.dart';

dynamic throwsTypeException(Object targetType, Object? value) {
  return throwsA(isA<TypeException>()
      .having((e) => e.targetType, 'targetType', equals(targetType))
      .having((e) => e.actualValue, 'actualValue', equals(value)));
}

dynamic throwsPropertyTypeException(Object targetType, Object? value,
    List<String> fieldLocation, Object objectType) {
  return throwsA(isA<PropertyTypeException>()
      .having((e) => e.targetType, 'targetType', equals(targetType))
      .having((e) => e.actualValue, 'actualValue', equals(value))
      .having((e) => e.propertyPath, 'fieldLocation', equals(fieldLocation))
      .having((e) => e.objectType, 'objectType', equals(objectType)));
}

dynamic throwsUnknownPropertyException(
    List<String> location, Object? objectType) {
  return throwsA(isA<UnknownPropertyException>()
      .having((e) => e.propertyPath, 'propertyPath', equals(location))
      .having((e) => e.objectType, 'objectType', equals(objectType)));
}

dynamic throwsMissingPropertyException(
    List<String> location, Object? objectType, List<String> missingProperties) {
  return throwsA(isA<MissingPropertyException>()
      .having((e) => e.propertyPath, 'propertyPath', equals(location))
      .having((e) => e.objectType, 'objectType', equals(objectType))
      .having(
          (e) => e.missingProperties, 'missingProperties', missingProperties));
}

dynamic throwsValidationException(List<String> errors) {
  return throwsA(isA<ValidationException>()
      .having((e) => e.errors, 'errors', equals(errors)));
}

dynamic throwsPropertyValidationException(
    List<String> location, Object? objectType, List<String> errors) {
  return throwsA(isA<PropertyValidationException>()
      .having((e) => e.propertyPath, 'fieldLocation', equals(location))
      .having((e) => e.objectType, 'objectType', equals(objectType))
      .having((e) => e.errors, 'errors', equals(errors)));
}
