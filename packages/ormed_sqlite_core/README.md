# ormed_sqlite_core

Shared SQLite primitives for Ormed runtime adapters.

This package contains SQLite logic that is runtime-agnostic:

- SQL grammar compilation
- Schema dialect generation
- Type mapping and value codecs
- Migration blueprint extensions

Use this package when implementing a SQLite-compatible runtime driver (for example, local sqlite3, D1, or other remote SQLite services).

For the default local SQLite runtime adapter, use `package:ormed_sqlite/ormed_sqlite.dart`.

## Recommended app usage

Application code should use runtime package helpers (not `ormed_sqlite_core` directly):

```dart
import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:your_app/src/models/user.orm.dart';

DataSource createDataSource() {
  final env = OrmedEnvironment.fromDirectory(Directory.current);
  final registry = ModelRegistry()..register(UserOrmDefinition.definition);
  final path = env.string('DB_PATH', fallback: 'database/app.sqlite');
  return DataSource(
    registry.sqliteFileDataSourceOptions(path: path, name: 'default'),
  );
}
```

## Example

`ormed_sqlite_core` is most useful when building adapters/tools around SQLite SQL
generation. Run the example to preview generated SQLite DDL:

```bash
dart run example/main.dart
```
