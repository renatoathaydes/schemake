## 0.6.3 (11-Jan-2025)

- fixed Dart 'toJson' for objects containing enum types.

## 0.6.2 (14-Dec-2024)

- fixed Dart `toString` generation for `Nullable(Strings())` which was quoting even null values.

## 0.6.1 (25-Nov-2024)

- fixed handling of `Nullable` and `Validatable` types in Dart generation code.

## 0.6.0 (24-Nov-2024)

- added `DartCopyWithMethodGenerator` (generates `copyWith` method).

## 0.5.0 (06-May-2024)

- added `FloatRangeValidator`.

## 0.4.1 (05-May-2024)

- fixed Dart generation of nullable/validatable field with default value.

## 0.4.0 (09-Dec-2023)

- allow `unknownPropertyStrategy` to be chosen for `Objects`.
- actually enforce `unknownPropertyStrategy` in Dart-generated `fromJson` method.
- improved `message` property of `TypeException`.

## 0.3.0 (07-Dec-2023)

- support default value for `Enums` in Dart code generation.
- removed `location` field from `ObjectBase` and its subtypes as it was not used.
- allow `Maps` value type to be `Nullable`.

## 0.2.0 (04-Dec-2023)

- improved `Floats` to accept any `num`.
- fixed handling of default values in fromJson Dart generator.

## 0.1.0 (03-Dec-2023)

- Initial version.
