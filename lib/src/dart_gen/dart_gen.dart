import 'package:collection/collection.dart';
import 'package:conveniently/conveniently.dart';

import '../_text.dart';
import '../property.dart';
import '../types.dart';
import '../validator.dart';
import '_utils.dart';

class GeneratorExtras {
  final Set<String> imports;
  final void Function(StringBuffer) topLevelWriter;

  const GeneratorExtras(this.imports, [this.topLevelWriter = _noOpWriter]);

  static void _noOpWriter(StringBuffer _) {}
}

mixin DartMethodGenerator {
  GeneratorExtras? generateMethod(
      StringBuffer buffer, Objects objects, DartGeneratorOptions options);
}

class DartToStringMethodGenerator with DartMethodGenerator {
  const DartToStringMethodGenerator();

  @override
  GeneratorExtras? generateMethod(
      StringBuffer buffer, Objects objects, DartGeneratorOptions options) {
    buffer.writeToString(objects, options);
    return null;
  }
}

class EqualsAndHashCodeMethodGenerator with DartMethodGenerator {
  const EqualsAndHashCodeMethodGenerator();

  @override
  GeneratorExtras? generateMethod(
      StringBuffer buffer, Objects objects, DartGeneratorOptions options) {
    final extras = buffer.writeEquals(objects, options);
    buffer.writeHashCode(objects, options);
    return extras;
  }
}

final class DartGeneratorOptions {
  static const defaultMethodGenerators = [
    DartToStringMethodGenerator(),
    EqualsAndHashCodeMethodGenerator(),
  ];

  static String _finalField(Property<Object?> _) => 'final ';

  static String _const() => 'const ';

  final String? insertBeforeClass;
  final String Function(String propertyName)? fieldName;
  final String Function(Property<Object?> property)? insertBeforeField;
  final String Function()? insertBeforeConstructor;
  final String Function(Property<Object?> property)? insertBeforeConstructorArg;
  final List<DartMethodGenerator> methodGenerators;
  final bool encodeNulls;

  const DartGeneratorOptions({
    this.insertBeforeClass,
    this.fieldName,
    this.insertBeforeField = _finalField,
    this.insertBeforeConstructor = _const,
    this.insertBeforeConstructorArg,
    this.methodGenerators = defaultMethodGenerators,
    this.encodeNulls = false,
  });
}

abstract class DartValidatorGenerationOptions<V extends Validator<dynamic>>
    implements ValidatorGenerationOptions {
  /// Returns Dart code that re-creates the Validatable instance
  /// or the equivalent [Converter] instance that can be used to convert
  /// properties of the type the validator validates.
  String selfCreateString(V validator);

  /// The Dart type name for the given validator type.
  String dartTypeFor(V validator);

  /// Return a Dart type generator for the validator type if necessary.
  ///
  /// The type should have the name given by [dartTypeFor] for any given
  /// [Validator].
  GeneratorExtras? getDartTypeGenerator(V validator);
}

/// Generates Dart code for the given schema types.
///
/// The generated code is written to the buffer provided in the argument,
/// or a new one is created if not provided, and then returned.
StringBuffer generateDartClasses(List<Objects> schemaTypes,
    {DartGeneratorOptions options = const DartGeneratorOptions()}) {
  final writer = StringBuffer();
  final generatorExtras = <GeneratorExtras>[];
  for (final type in schemaTypes) {
    writer.writeObjects(type, generatorExtras, options);
  }
  if (generatorExtras.isNotEmpty) {
    final withExtras = StringBuffer();
    // prepend the extras to the result
    withExtras.writeExtras(generatorExtras);
    withExtras.write(writer);
    return withExtras;
  }
  return writer;
}

extension on StringBuffer {
  StringBuffer acceptIfObjects(List<GeneratorExtras> extras,
      ObjectsBase<dynamic> objects, DartGeneratorOptions options) {
    if (objects is Objects) {
      extras.add(GeneratorExtras(
          const {}, (writer) => writer.writeObjects(objects, extras, options)));
    } else {
      throw UnsupportedError('The only subtype of ObjectsBase allowed to be '
          'used for code generation is Objects.');
    }
    return this;
  }

  void writeType(SchemaType<dynamic> schemaType,
      List<GeneratorExtras> generatorExtras, DartGeneratorOptions options,
      [String Function(String) typeWrapper = identityString]) {
    final _ = switch (schemaType) {
      Nullable<dynamic, NonNull>(type: var type) =>
        writeType(type, generatorExtras, options, nullable),
      Validatable() =>
        writeValidatableType(schemaType, generatorExtras, options),
      Ints() => write(typeWrapper('int')),
      Floats() => write(typeWrapper('double')),
      Strings() => write(typeWrapper('String')),
      Bools() => write(typeWrapper('bool')),
      Arrays<dynamic, SchemaType>(itemsType: var type) =>
        writeType(type, generatorExtras, options, array),
      ObjectsBase(name: var className) =>
        acceptIfObjects(generatorExtras, schemaType, options)
            .write(typeWrapper(className)),
    };
  }

  void writeValidatableType(Validatable<dynamic> schemaType,
      List<GeneratorExtras> generatorExtras, DartGeneratorOptions options) {
    final validator = schemaType.validator;
    final generator = schemaType.dartGenOption;
    if (generator == null) {
      writeType(schemaType.type, generatorExtras, options);
    } else {
      write(generator.dartTypeFor(validator));
      generator.getDartTypeGenerator(validator)?.vmap(generatorExtras.add);
    }
  }

  void writeObjects(Objects objects, List<GeneratorExtras> extras,
      DartGeneratorOptions options) {
    write(options.insertBeforeClass ?? '');
    writeln('\nclass ${objects.name} {');
    writeFields(objects, extras, options);
    writeConstructor(objects, options);
    options.methodGenerators
        .map((gen) => gen.generateMethod(this, objects, options))
        .whereNotNull()
        .forEach(extras.add);
    writeln('}');
  }

  void writeFields(Objects objects, List<GeneratorExtras> extras,
      DartGeneratorOptions options) {
    objects.properties.forEach((key, value) {
      write('  ');
      options.insertBeforeField?.vmap((get) => write(get(value)));
      writeType(value.type, extras, options);
      write(' ${options.fieldName?.vmap((name) => name(key)) ?? key}');
      writeln(';');
    });
  }

  void writeConstructor(Objects objects, DartGeneratorOptions options) {
    write('  ');
    options.insertBeforeConstructor?.vmap((get) => write(get()));
    writeln('${objects.name}({');
    objects.properties.forEach((key, value) {
      options.insertBeforeConstructorArg?.vmap((get) => get(value));
      write(value.type is Nullable ? '    ' : '    required ');
      write('this.');
      write(options.fieldName?.vmap((name) => name(key)) ?? key);
      writeln(',');
    });
    writeln('  });');
  }

  void writeToString(Objects objects, DartGeneratorOptions options) {
    write('  @override\n'
        '  String toString() =>\n'
        '    ');
    writeln(quote('${objects.name}{'));
    final lastIndex = objects.properties.length - 1;
    var index = 0;
    objects.properties.forEach((key, value) {
      write('    ');
      final fieldName = options.fieldName?.vmap((name) => name(key)) ?? key;
      final wrapValue = value.type.isStringOrNull() ? quoteAndDollar : dollar;
      writeln(quote(
          '$fieldName: ${wrapValue(fieldName)}${index++ == lastIndex ? '' : ','}'));
    });
    write('    ');
    write(quote('}'));
    writeln(';');
  }

  GeneratorExtras? writeEquals(Objects objects, DartGeneratorOptions options) {
    writeln('  @override\n'
        '  bool operator ==(Object other) =>\n'
        '    identical(this, other) ||');
    write('    other is ${objects.name} &&\n'
        '    runtimeType == other.runtimeType');
    GeneratorExtras? extras;
    if (objects.properties.isNotEmpty) {
      writeln(' &&');
      write(objects.properties.entries.map((entry) {
        final fieldName =
            options.fieldName?.vmap((f) => f(entry.key)) ?? entry.key;
        final type = entry.value.type;
        if (type is Arrays<Object?, Object?>) {
          extras =
              const GeneratorExtras({'package:collection/collection.dart'});
          return '    const ListEquality<'
              '${(type.itemsType as SchemaType<dynamic>).dartType()}>()'
              '.equals($fieldName, other.$fieldName)';
        }
        return '    $fieldName == other.$fieldName';
      }).join(' &&\n'));
    }
    writeln(';');
    return extras;
  }

  void writeHashCode(Objects objects, DartGeneratorOptions options) {
    writeln('  @override\n'
        '  int get hashCode =>');
    if (objects.properties.isEmpty) {
      write('    runtimeType.hashCode');
    } else {
      write('    ');
      write(objects.properties.entries.map((entry) {
        final fieldName =
            options.fieldName?.vmap((f) => f(entry.key)) ?? entry.key;
        return '$fieldName.hashCode';
      }).join(' ^ '));
    }
    writeln(';');
  }

  void writeExtras(Iterable<GeneratorExtras> extras) {
    for (final imp in extras.expand((e) => e.imports).toSet()) {
      writeln('import ${quote(imp)};');
    }
    for (final extra in extras) {
      extra.topLevelWriter(this);
    }
  }
}

extension on SchemaType<dynamic> {
  bool isStringOrNull() {
    final self = this;
    return self is Strings ||
        (self is Nullable<Object?, Object?> && self.type is Strings);
  }
}
