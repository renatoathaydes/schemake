import 'types.dart';

extension ListExtension<T> on List<T> {
  List<T> drain() {
    final lastIndex = length - 1;
    return List.generate(length, (i) => removeAt(lastIndex - i));
  }
}

extension ObjectsExtension on ObjectsBase<Object?> {
  bool get isSimpleMap {
    final self = this;
    return self is Maps ||
        (self is Objects &&
            self.unknownPropertiesStrategy == UnknownPropertiesStrategy.keep &&
            self.properties.isEmpty);
  }
}

extension DynamicSchameTypeExtension on SchemaType<dynamic> {
  bool isStringOrNull() {
    final self = this;
    return self is Strings ||
        (self is Nullable<Object?, Object?> && self.type is Strings);
  }
}
