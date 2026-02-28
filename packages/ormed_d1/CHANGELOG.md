# Changelog

## 0.1.0

- Initial D1 package release.
- Added D1 HTTP transport abstraction.
- Added D1 driver registration and adapter baseline using `ormed_sqlite_core` grammar/dialect.
- Added `DataSourceOptions.d1(...)`, `DataSourceOptions.d1FromEnvironment(...)`, and `ModelRegistry.d1DataSource(...)` helpers for code-first D1 setup.
- Added configurable HTTP retry/backoff and request timeout controls for D1 transport.
- Added optional D1 debug logging for request/response troubleshooting.
- Added verification examples for direct adapter use and DataSource-based configuration.
- Changed D1 adapter to reuse `ormed_sqlite_core` SQL compilation behavior.
