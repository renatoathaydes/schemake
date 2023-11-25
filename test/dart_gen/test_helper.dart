import 'dart:io';
import 'dart:math';

import 'package:conveniently/conveniently.dart';
import 'package:dartle/dartle.dart' show dir, deleteAll, execRead;
import 'package:path/path.dart' as p;
import 'package:schemake/dart_gen.dart';
import 'package:schemake/schemake.dart';

Future<(List<String> stdout, List<String> stderr)> generateAndRunDartClass(
    Objects objects, String mainFunction, DartGeneratorOptions options) async {
  final rand = Random();
  final rootDir = Directory('temp-${rand.nextInt(4096)}');
  try {
    await rootDir.create();
    final file =
        await _generateDartClass(objects, rootDir, mainFunction, options);
    final result = await execRead(Process.start('dart', ['run', file.path]),
        isCodeSuccessful: alwaysTrue);
    return (result.stdout, result.stderr);
  } finally {
    await deleteAll(dir(rootDir.path));
  }
}

Future<File> _generateDartClass(Objects objects, Directory rootDir,
    String mainFunction, DartGeneratorOptions options) {
  final file = File(p.join(rootDir.path, 'testing.dart'));
  return file.writeAsString(generateDartClasses([objects], options: options)
      .vmap((b) => b..writeln(mainFunction))
      .toString());
}
