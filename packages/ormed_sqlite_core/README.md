# ormed_sqlite_core

Shared SQLite primitives for Ormed runtime adapters.

This package contains SQLite logic that is runtime-agnostic:

- SQL grammar compilation
- Schema dialect generation
- Type mapping and value codecs
- Migration blueprint extensions

Use this package when implementing a SQLite-compatible runtime driver (for example, local sqlite3, D1, or other remote SQLite services).

For the default local SQLite runtime adapter, use `package:ormed_sqlite/ormed_sqlite.dart`.
