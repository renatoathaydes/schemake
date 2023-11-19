import 'types.dart';

class Property<T> {
  final SchemaType<T> type;
  final String? dartProperty;
  final T? defaultValue;
  final String? description;

  const Property(
      {required this.type,
      this.dartProperty,
      this.defaultValue,
      this.description});

  void validate() {}

  @override
  String toString() {
    return 'Property{type: $type, '
        'dartProperty: $dartProperty, defaultValue: $defaultValue, '
        'description: $description}';
  }
}
