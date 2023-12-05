import 'package:conveniently/conveniently.dart';
import 'package:schemake/dart_gen.dart';
import 'package:schemake/schemake.dart';

import '../_text.dart';
import '_utils.dart';

extension DartValueWriter on StringBuffer {
  void writeValue(SchemaType<Object?> type, Object? value,
      {bool consted = false}) {
    if (value == null) return write('null');
    final _ = switch (type) {
      Ints() || Bools() || Floats() => write(value.toString()),
      Enums() => writeEnumValue(type, type.convert(value)),
      Strings() => writeStringLiteral(type.convert(value)),
      Nullable(type: var t) => writeValue(t, value, consted: consted),
      Arrays(itemsType: var t) =>
        writeListValue(t, type.convert(value), consted: consted),
      Maps(valueType: var t) =>
        writeMapValue(t, type.convert(value), consted: consted),
      Objects() => writeAnyMapValue(type.convert(value), consted: consted),
      _ => throw UnsupportedError(
          'Cannot write default value of type ${value.runtimeType}'),
    };
  }

  void writeAnyValue(Object? value, {bool consted = false}) {
    final _ = switch (value) {
      null => write('null'),
      int() || bool() || double() => write(value.toString()),
      String() => writeStringLiteral(value),
      List<Object?>() => writeAnyListValue(value, consted: consted),
      Map<String, Object?>() => writeAnyMapValue(value, consted: consted),
      _ => throw UnsupportedError(
          'Cannot write default value of type ${value.runtimeType}'),
    };
  }

  void writeMapValue(SchemaType<Object?> type, Map<String, Object?> map,
      {bool consted = false}) {
    if (consted) write('const ');
    write('{');
    final lastIndex = map.length - 1;
    for (final (i, entry) in map.entries.indexed) {
      writeStringLiteral(entry.key);
      write(': ');
      writeValue(type, entry.value);
      if (i != lastIndex) write(', ');
    }
    write('}');
  }

  void writeAnyMapValue(Map<String, Object?> map, {bool consted = false}) {
    if (consted) write('const ');
    write('{');
    final lastIndex = map.length - 1;
    for (final (i, entry) in map.entries.indexed) {
      writeStringLiteral(entry.key);
      write(': ');
      final value = entry.value;
      if (value is String) {}
      write(value is String ? quote(value) : value);
      if (i != lastIndex) write(', ');
    }
    write('}');
  }

  void writeListValue(SchemaType<Object?> type, List<Object?> value,
      {bool consted = false}) {
    if (consted) write('const ');
    write('[');
    final lastIndex = value.length - 1;
    for (var i = 0; i <= lastIndex; i++) {
      writeValue(type, value[i]);
      if (i != lastIndex) write(', ');
    }
    write(']');
  }

  void writeAnyListValue(List<Object?> value, {required bool consted}) {
    if (consted) write('const ');
    write('[');
    final lastIndex = value.length - 1;
    for (var i = 0; i <= lastIndex; i++) {
      writeAnyValue(value[i]);
      if (i != lastIndex) write(', ');
    }
    write(']');
  }

  void writeStringLiteral(String value) {
    write(quote(value.replaceAll("'", "\\'")));
  }

  void writeEnumValue(Enums type, String value) {
    final genOption = type.dartGenOption
        .orThrow(() => StateError('cannot write default value for $type: '
            'no DartValidatorGenerationOptions provided.'));
    final typeName = genOption.dartTypeFor(type.validator);
    final variant = (genOption is DartEnumGeneratorOptions)
        ? genOption.dartVariantName(value)
        : value;
    write('$typeName.$variant');
  }
}
