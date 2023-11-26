import 'package:dart_casing/dart_casing.dart' show Casing;

String identityString(String s) => s;

String quote(String s) => "'$s'";

String dollar(String s) => "\$$s";

String quoteAndDollar(String s) => '"\$$s"';

String nullable(String s) => "$s?";

String array(String s) => "List<$s>";

String toCamelCase(String s) {
  return Casing.camelCase(s);
}

String toPascalCase(String s) {
  return Casing.pascalCase(s);
}
