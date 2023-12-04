import '../_text.dart';

extension DartValueWriter on StringBuffer {
  void writeValue(final Object? value, {bool consted = false}) {
    final _ = switch (value) {
      null => write('null'),
      int() || bool() || double() => write(value.toString()),
      String() => writeStringLiteral(value),
      List<Object?>() => writeListValue(value, consted: consted),
      Map<String, Object?>() => writeMapValue(value, consted: consted),
      _ => throw UnsupportedError(
          'Cannot write default value of type ${value.runtimeType}'),
    };
  }

  void writeMapValue(Map<String, Object?> map, {bool consted = false}) {
    if (consted) write('const ');
    write('{');
    final lastIndex = map.length - 1;
    for (final (i, entry) in map.entries.indexed) {
      writeStringLiteral(entry.key);
      write(': ');
      writeValue(entry.value);
      if (i != lastIndex) write(', ');
    }
    write('}');
  }

  void writeListValue(List<Object?> value, {bool consted = false}) {
    if (consted) write('const ');
    write('[');
    final lastIndex = value.length - 1;
    for (var i = 0; i <= lastIndex; i++) {
      writeValue(value[i]);
      if (i != lastIndex) write(', ');
    }
    write(']');
  }

  void writeStringLiteral(String value) {
    write(quote(value.replaceAll("'", "\\'")));
  }
}
