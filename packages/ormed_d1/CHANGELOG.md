# Changelog

## 0.2.0
- **Added**: `DataSourceOptions.d1(...)`, `DataSourceOptions.d1FromEnvironment(...)`, and `ModelRegistry.d1DataSource(...)` helpers for code-first D1 setup.
- **Added**: Configurable HTTP retry/backoff and request timeout controls for D1 transport.
- **Added**: Optional D1 debug logging for request/response troubleshooting.
- **Added**: Verification examples for direct adapter use and DataSource-based configuration.
- **Changed**: D1 adapter now reuses `ormed_sqlite_core` SQL compilation behavior.

## 0.1.0

- Initial D1 package scaffold.
- Added D1 HTTP transport abstraction.
- Added D1 driver registration and adapter baseline using `ormed_sqlite_core` grammar/dialect.
