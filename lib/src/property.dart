import 'types.dart';

class Property<T> {
  final SchemaType<T> type;
  final T? defaultValue;
  final String? description;

  const Property({required this.type, this.defaultValue, this.description});

  void validate() {}

  @override
  String toString() {
    return 'Property{type: $type, '
        'defaultValue: $defaultValue, '
        'description: $description}';
  }
}
