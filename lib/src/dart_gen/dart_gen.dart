import 'package:conveniently/conveniently.dart';

import '../_text.dart';
import '../property.dart';
import '../types.dart';
import '../validator.dart';

class GeneratorExtras {
  final Set<String> imports;
  final void Function(StringBuffer) topLevelWriter;

  const GeneratorExtras(this.imports, this.topLevelWriter);
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
    buffer.writeEquals(objects, options);
    buffer.writeHashCode(objects, options);
    return null;
  }
}

final class DartGeneratorOptions {
  final String? insertBeforeClass;
  final String Function(String propertyName)? fieldName;
  final String Function(Property<Object?> property)? insertBeforeField;
  final String Function(Property<Object?> property)? insertBeforeConstructorArg;
  final List<DartMethodGenerator> methodGenerators;

  const DartGeneratorOptions({
    this.insertBeforeClass,
    this.fieldName,
    this.insertBeforeField,
    this.insertBeforeConstructorArg,
    this.methodGenerators = const [
      DartToStringMethodGenerator(),
      EqualsAndHashCodeMethodGenerator()
    ],
  });
}

abstract class DartValidatorGenerationOptions<V extends Validator<dynamic>>
    implements ValidatorGenerationOptions {
  Type get validatorType => V;

  String dartTypeFor(V type);

  /// Generates a Dart type representing the validator type.
  void generateDartType(StringBuffer buffer, V type);
}

sealed class _Remaining {}

class _ObjectsRemaining implements _Remaining {
  final Objects objects;

  _ObjectsRemaining(this.objects);
}

class _Writer implements _Remaining {
  final void Function(StringBuffer) write;

  _Writer(this.write);
}

/// Generates Dart code for the given schema types.
///
/// The generated code is written to the buffer provided in the argument,
/// or a new one is created if not provided, and then returned.
StringBuffer generateDartClasses(List<Objects> schemaTypes,
    {DartGeneratorOptions options = const DartGeneratorOptions()}) {
  final writer = StringBuffer();
  final remaining = <_Remaining>[
    for (var s in schemaTypes) _ObjectsRemaining(s)
  ];
  final generatorExtras = <GeneratorExtras>[
    GeneratorExtras({'dart:convert', 'package:schemake/schemake.dart'}, (_) {})
  ];
  while (remaining.isNotEmpty) {
    switch (remaining.removeLast()) {
      case _ObjectsRemaining(objects: var objects):
        generatorExtras
            .addAll(writer.writeObjects(objects, remaining, options));
      case _Writer(write: var write):
        write(writer);
    }
  }
  if (generatorExtras.isNotEmpty) {
    final extras = StringBuffer();
    // prepend the extras to the result
    extras.writeExtras(generatorExtras);
    extras.write(writer);
    return extras;
  }
  return writer;
}

extension on StringBuffer {
  StringBuffer acceptIfObjects(
      List<_Remaining> list, ObjectsBase<dynamic> objects) {
    if (objects is Objects) {
      list.add(_ObjectsRemaining(objects));
    } else {
      throw UnsupportedError('The only subtype of ObjectsBase allowed to be '
          'used for code generation is Objects.');
    }
    return this;
  }

  void writeType(SchemaType<dynamic> schemaType, List<_Remaining> remaining,
      [String Function(String) typeWrapper = identityString]) {
    final _ = switch (schemaType) {
      Nullable<dynamic, NonNull>(type: var type) =>
        writeType(type, remaining, nullable),
      Validatable() => writeValidatableType(schemaType, remaining),
      Ints() => write(typeWrapper('int')),
      Floats() => write(typeWrapper('double')),
      Strings() => write(typeWrapper('String')),
      Bools() => write(typeWrapper('bool')),
      Arrays<dynamic, SchemaType>(itemsType: var type) =>
        writeType(type, remaining, array),
      ObjectsBase(name: var className) =>
        acceptIfObjects(remaining, schemaType).write(typeWrapper(className)),
    };
  }

  void writeValidatableType(
      Validatable<dynamic> schemaType, List<_Remaining> remaining) {
    final validator = schemaType.validator;
    final generator = validator.generatorOptions
        .whereType<DartValidatorGenerationOptions<dynamic>>()
        .where((options) =>
            options.validatorType == schemaType.validator.runtimeType)
        .firstOrNull;
    if (generator == null) {
      writeType(schemaType.type, remaining);
    } else {
      write(generator.dartTypeFor(validator));
      remaining.add(_Writer((w) => generator.generateDartType(w, validator)));
    }
  }

  List<GeneratorExtras> writeObjects(Objects objects,
      List<_Remaining> remaining, DartGeneratorOptions options) {
    write(options.insertBeforeClass ?? '');
    writeln('\nclass ${objects.name} {');
    writeFields(objects, options, remaining);
    // constructor
    writeConstructor(objects, options);
    final generatorExtras = options.methodGenerators
        .map((gen) => gen.generateMethod(this, objects, options))
        .whereType<GeneratorExtras>()
        .toList(growable: false);
    writeln('}');
    return generatorExtras;
  }

  void writeFields(Objects objects, DartGeneratorOptions options,
      List<_Remaining> remaining) {
    objects.properties.forEach((key, value) {
      write('  ');
      options.insertBeforeField?.vmap((insert) => insert(value));
      writeType(value.type, remaining);
      write(' ${options.fieldName?.vmap((f) => f(key)) ?? key}');
      writeln(';');
    });
  }

  void writeConstructor(Objects objects, DartGeneratorOptions options) {
    writeln('  ${objects.name}({');
    objects.properties.forEach((key, value) {
      options.insertBeforeConstructorArg?.vmap((insert) => insert(value));
      write(value.type is Nullable ? '    ' : '    required ');
      write('this.');
      write(options.fieldName?.vmap((f) => f(key)) ?? key);
      writeln(',');
    });
    writeln('  });');
  }

  void writeToString(Objects objects, DartGeneratorOptions options) {
    write('  @override\n'
        '  String toString() =>\n'
        '    ');
    writeln(quote('${objects.name}{'));
    objects.properties.forEach((key, value) {
      write('    ');
      final fieldName = options.fieldName?.vmap((f) => f(key)) ?? key;
      final wrapValue = value.type.isStringOrNull() ? quoteAndDollar : dollar;
      writeln(quote('$fieldName = ${wrapValue(fieldName)},'));
    });
    write('    ');
    write(quote('}'));
    writeln(';');
  }

  void writeEquals(Objects objects, DartGeneratorOptions options) {
    writeln('  @override\n'
        '  bool operator ==(Object other) =>\n'
        '    identical(this, other) ||');
    write('    other is ${objects.name} &&\n'
        '    runtimeType == other.runtimeType');
    if (objects.properties.isNotEmpty) {
      writeln(' &&');
      write(objects.properties.entries.map((entry) {
        final fieldName =
            options.fieldName?.vmap((f) => f(entry.key)) ?? entry.key;
        final isList = entry.value.type is Arrays<Object?, Object?>;
        return isList
            ? '    const ListEquality().equals($fieldName, other.$fieldName)'
            : '    $fieldName == other.$fieldName';
      }).join(' &&\n'));
    }
    writeln(';');
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
