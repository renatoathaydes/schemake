import 'types.dart';

class Property<T> {
  final SchemaType<T> type;
  final T? defaultValue;
  final String description;

  const Property(this.type, {this.defaultValue, this.description = ''});

  @override
  String toString() {
    return 'Property{type: $type, '
        'defaultValue: $defaultValue, '
        'description: $description}';
  }
}
