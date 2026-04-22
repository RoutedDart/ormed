# Changelog

## 0.1.0

- Initial browser SQLite package release.
- Added a `sqlite3_web`-backed Ormed adapter using `ormed_sqlite_core`.
- Added worker-based `DataSource` helpers for explicit browser configuration.
- Added transaction support using `sqlite3_web` exclusive locks and SQLite savepoints.
- Added a default worker entrypoint helper for browser apps.
