# Changelog

## 0.2.1

- **Fixed**: D1 HTTP mutations now retry transient `database is locked` and
  `database is busy` responses.

## 0.2.0

- **Added**: `D1Database.connect` for direct Cloudflare D1 access without a
  generated model registry.
- **Added**: Interceptor support on `D1Database.connect` for direct execution
  tracing and policy checks.
- **Breaking**: Requires Dart 3.12 or newer.
- **Updated**: Widened the Ormed and SQLite-core support ranges to `<1.0.0`.
- **Updated**: Synced the D1 driver with the Analyzer 14 workspace release.

## 0.1.0

- Initial D1 package release.
- Added D1 HTTP transport abstraction.
- Added D1 driver registration and adapter baseline using `ormed_sqlite_core` grammar/dialect.
- Added `DataSourceOptions.d1(...)`, `DataSourceOptions.d1FromEnvironment(...)`, and `ModelRegistry.d1DataSource(...)` helpers for code-first D1 setup.
- Added configurable HTTP retry/backoff and request timeout controls for D1 transport.
- Added optional D1 debug logging for request/response troubleshooting.
- Added verification examples for direct adapter use and DataSource-based configuration.
- Changed D1 adapter to reuse `ormed_sqlite_core` SQL compilation behavior.
