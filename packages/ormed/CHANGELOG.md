# Changelog

## 0.1.0-dev+3

- Refactored `Timestamps` and `SoftDeletes` mixins to use `CarbonInterface` for getters and `Object?` for setters.
- Exported `carbonized` package directly from `ormed.dart`.
- Improved `DateTimeCodec` to handle `Carbon` instances during decoding.
- Fixed mass assignment to handle both field and column names for excluded attributes.

## 0.1.0-dev+2

- Synchronized release with ormed_cli rebranding.

## 0.1.0-dev+1

- Added automatic `snake_case` column name inference for model fields.
- Fixed `DatabaseSeeder.seed<T>()` to use repositories for correct data encoding.
- Fixed `bootstrapOrm()` to ensure model registration in existing registries.
- Improved documentation for naming conventions and CLI-first workflow.

## 0.1.0-dev

- Initial release.
