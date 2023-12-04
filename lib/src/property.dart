import 'types.dart';

/// A property of a structured data object.
class Property<T> {
  final SchemaType<T> type;
  final T? defaultValue;
  final String description;

  const Property(this.type, {this.defaultValue, this.description = ''});

  /// Return `true` if this property is required
  /// (i.e. it doesn't have a default value, and it's type is not nullable).
  bool get isRequired => defaultValue != null || type is Nullable;

  @override
  String toString() {
    return 'Property{type: $type, '
        'defaultValue: $defaultValue, '
        'description: $description}';
  }
}
