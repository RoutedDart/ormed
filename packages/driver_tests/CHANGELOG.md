# Changelog

## 0.3.1

- **Added**: Shared driver coverage for codegen-free inserts with generated
  primary keys, mutation-only fields, and reusable `SELECT *` projections.

## 0.3.0

- **Breaking**: Requires Dart 3.12 or newer.
- **Updated**: Widened the Ormed support range to `>=0.2.0 <1.0.0`.
- **Updated**: Synced the shared driver test harness with the Analyzer 14 workspace release.

## 0.2.0

- **Release**: Version alignment for the 0.2.0 workspace release.

## 0.1.0

- **Release**: Promote driver_tests to the stable 0.1.0 line.

## 0.1.0-dev+10

- **Added**: Shared driver tests for cache invalidation on writes, preview SQL placeholder escaping, and warnings when using fallback row identifiers.

## 0.1.0-dev+9

- **Updated**: Synced release with ORMed dev+9.

## 0.1.0-dev+8

- **Updated**: Synced dependency versions for dev+8.

## 0.1.0-dev+7

- **Updated**: Synced dependency versions for dev+7.

## 0.1.0-dev+6

- **Updated**: Regenerated ORM registry output.
- **Maintenance**: Formatting updates to generated files.

## 0.1.0-dev+5

- **Added**: Insert defaults test coverage for timestamp columns.
- **Added**: InsertDto timestamp auto-fill test coverage.
- **Adjusted**: Touch timestamp assertions for MySQL/MariaDB clock jitter.
- **Added**: Upsert regression coverage for JSON casts across multiple field types.
- **Adjusted**: Pivot updated_at assertions to tolerate MySQL/MariaDB precision limits.

## 0.1.0-dev+4

- **Updated**: Test suites now cover advanced ORM features (relations, casting, pivots).
- **Enhanced**: Shared test fixtures for polymorphic relations and through relations.

## 0.1.0-dev+3

- Synchronized release.

## 0.1.0-dev+2

- Rebrand CLI to `ormed`.
- Bump version to match workspace.

## 0.1.0-dev

- Initial release.
