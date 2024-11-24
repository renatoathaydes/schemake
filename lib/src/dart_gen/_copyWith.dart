import '../_text.dart';
import '../types.dart'
    show
        Objects,
        ObjectsBase,
        Maps,
        Arrays,
        Nullable,
        UnknownPropertiesStrategy;
import '_utils.dart';
import 'dart_gen.dart';

class CopyWithOptions {
  /// Whether to copy Lists when no explicit value has been given.
  final bool copyLists;

  /// Whether to copy Maps when no explicit value has been given.
  final bool copyMaps;

  const CopyWithOptions({this.copyLists = true, this.copyMaps = true});
}

class DartCopyWithMethodGenerator with DartMethodGenerator {
  final CopyWithOptions copyWithOptions;

  const DartCopyWithMethodGenerator(
      {this.copyWithOptions = const CopyWithOptions()});

  @override
  GeneratorExtras? generateMethod(
      StringBuffer buffer, Objects objects, DartGeneratorOptions options) {
    // format the generated code to avoid making the 'analyse' task to run
    buffer.writeCopyWith(objects, options, copyWithOptions);
    return null;
  }
}

extension on StringBuffer {
  void writeCopyWith(Objects objects, DartGeneratorOptions options,
      CopyWithOptions copyWithOptions) {
    writeln('  ${options.className(objects.name)} copyWith({');
    _writeParameters(objects, options);
    writeln('  }) {');
    _writeImplementation(objects, options, copyWithOptions);
    writeln('  }');
  }

  void _writeParameters(Objects objects, DartGeneratorOptions options) {
    objects.properties.forEach((key, value) {
      write('    ');
      write(value.type.dartTypeString(options));
      if (value.type is! Nullable) {
        write('?');
      }
      write(' ');
      write(options.fieldName(key));
      writeln(' = null,');
    });
    if (objects.unknownPropertiesStrategy != UnknownPropertiesStrategy.forbid) {
      writeln('    Map<String, Object?>? extras = null,');
    }
    objects.properties.forEach((key, value) {
      if (value.type is Nullable) {
        writeln(
            '    bool unset${toPascalCase(options.fieldName(key))} = false,');
      }
    });
  }

  void _writeImplementation(Objects objects, DartGeneratorOptions options,
      CopyWithOptions copyWithOptions) {
    writeln('    return ${options.className(objects.name)}(');
    objects.properties.forEach((key, value) {
      final fName = options.fieldName(key);
      write('      $fName: ');
      if (value.type is Nullable) {
        write('unset${toPascalCase(fName)} ? null : ');
      }
      write('$fName ?? ');
      if (copyWithOptions.copyLists && value.type is Arrays) {
        writeln('[...this.$fName],');
      } else if (copyWithOptions.copyMaps && value.type is ObjectsBase) {
        if (value.type is Maps) {
          writeln('{...this.$fName},');
        } else {
          writeln('this.$fName.copyWith(),');
        }
      } else {
        writeln('this.$fName,');
      }
    });
    if (objects.unknownPropertiesStrategy != UnknownPropertiesStrategy.forbid) {
      final value =
          copyWithOptions.copyMaps ? '{...this.extras}' : 'this.extras';
      writeln('      extras: extras ?? $value,');
    }
    writeln('    );');
  }
}
