import 'package:conveniently/conveniently.dart';

import '../_text.dart';
import '../types.dart';
import '_utils.dart';
import 'gen_options.dart';

extension JavaValueWriter on StringBuffer {
  void writeValue(SchemaType<Object?> type, Object? value) {
    if (value == null) return write('null');
    final _ = switch (type) {
      Ints() || Bools() || Floats() => write(value.toString()),
      Enums() => writeEnumValue(type, type.convert(value)),
      Strings() => writeStringLiteral(type.convert(value)),
      Nullable(type: var t) => writeValue(t, value),
      Arrays(itemsType: var t) => writeListValue(t, type.convert(value)),
      Maps(valueType: var t) => writeMapValue(t, type.convert(value)),
      Objects() => writeAnyMapValue(type.convert(value)),
      Validatable(type: var vtype) => writeValue(vtype, value),
      _ => throw UnsupportedError(
          'Cannot write default value of type ${value.runtimeType}'),
    };
  }

  void writeAnyValue(Object? value) {
    final _ = switch (value) {
      null => write('null'),
      int() || bool() || double() => write(value.toString()),
      String() => writeStringLiteral(value),
      List<Object?>() => writeAnyListValue(value),
      Map<String, Object?>() => writeAnyMapValue(value),
      _ => throw UnsupportedError(
          'Cannot write default value of type ${value.runtimeType}'),
    };
  }

  void writeMapValue(SchemaType<Object?> type, Map<String, Object?> map) {
    write('Map.of(');
    final lastIndex = map.length - 1;
    for (final (i, entry) in map.entries.indexed) {
      writeStringLiteral(entry.key);
      write(', ');
      writeValue(type, entry.value);
      if (i != lastIndex) write(', ');
    }
    write(')');
  }

  void writeAnyMapValue(Map<String, Object?> map) {
    write('Map.of(');
    final lastIndex = map.length - 1;
    for (final (i, entry) in map.entries.indexed) {
      writeStringLiteral(entry.key);
      write(', ');
      final value = entry.value;
      write(value is String ? dquote(value) : value);
      if (i != lastIndex) write(', ');
    }
    write(')');
  }

  void writeListValue(SchemaType<Object?> type, List<Object?> value) {
    write('List.of(');
    final lastIndex = value.length - 1;
    for (var i = 0; i <= lastIndex; i++) {
      writeValue(type, value[i]);
      if (i != lastIndex) write(', ');
    }
    write(')');
  }

  void writeAnyListValue(List<Object?> value) {
    write('List.of(');
    final lastIndex = value.length - 1;
    for (var i = 0; i <= lastIndex; i++) {
      writeAnyValue(value[i]);
      if (i != lastIndex) write(', ');
    }
    write(')');
  }

  void writeStringLiteral(String value) {
    write(dquote(value.replaceAll('"', '\\"')));
  }

  void writeEnumValue(Enums type, String value) {
    final genOption = type.javaGenOption
        .orThrow(() => StateError('cannot write default value for $type: '
            'no JavaValidatorGenerationOptions provided.'));
    final typeName = genOption.javaTypeFor(type.validator);
    final variant = (genOption is JavaEnumGeneratorOptions)
        ? genOption.dartVariantName(value)
        : value;
    write('$typeName.$variant');
  }
}
