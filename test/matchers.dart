import 'package:schemake/schemake.dart';
import 'package:test/test.dart';

dynamic throwsTypeException(Object targetType, Object? value) {
  return throwsA(isA<TypeException>()
      .having((e) => e.targetType, 'targetType', equals(targetType))
      .having((e) => e.actualValue, 'actualValue', equals(value)));
}

dynamic throwsUnknownPropertyException(
    List<String> location, Object? objectType) {
  return throwsA(isA<UnknownPropertyException>()
      .having((e) => e.fieldLocation, 'fieldLocation', equals(location))
      .having((e) => e.objectType, 'objectType', equals(objectType)));
}

dynamic throwsMissingPropertyException(
    List<String> location, Object? objectType, List<String> missingProperties) {
  return throwsA(isA<MissingPropertyException>()
      .having((e) => e.fieldLocation, 'fieldLocation', equals(location))
      .having((e) => e.objectType, 'objectType', equals(objectType))
      .having(
          (e) => e.missingProperties, 'missingProperties', missingProperties));
}
