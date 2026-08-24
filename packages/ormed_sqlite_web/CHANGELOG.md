# Changelog

## 0.2.0

- **Breaking**: Requires Dart 3.12 or newer.
- **Fixed**: Update the web transport for `sqlite3_web 0.9.x` worker URL and OPFS implementation APIs.
- **Updated**: Widened the Ormed and SQLite-core support ranges to `<1.0.0`.

## 0.1.0

- Initial browser SQLite package release.
- Added a `sqlite3_web`-backed Ormed adapter using `ormed_sqlite_core`.
- Added worker-based `DataSource` helpers for explicit browser configuration.
- Added transaction support using `sqlite3_web` exclusive locks and SQLite savepoints.
- Added a default worker entrypoint helper for browser apps.
