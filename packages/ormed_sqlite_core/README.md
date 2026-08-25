# ormed_sqlite_core

Shared SQLite primitives for Ormed runtime adapters.

This package contains SQLite logic that is runtime-agnostic:

- SQL grammar compilation
- Schema dialect generation
- Type mapping and value codecs
- Migration blueprint extensions

Use this package when implementing a SQLite-compatible runtime driver (for example, local sqlite3, D1, or other remote SQLite services).

For the default local SQLite runtime adapter, use `package:ormed_sqlite/ormed_sqlite.dart`.

## Usage modes

### Indirect / application usage

Application code should normally use a runtime package such as
[`ormed_sqlite`](https://pub.dev/packages/ormed_sqlite) or
[`ormed_d1`](https://pub.dev/packages/ormed_d1), which depends on this package
indirectly. That keeps the adapter, transport, and platform choices together.

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

### Direct / adapter-author usage

Use `ormed_sqlite_core` directly when implementing a SQLite-compatible adapter
or tool that needs shared grammar, schema, and codec behavior. Most
applications should not construct these primitives themselves.

## Example

`ormed_sqlite_core` is most useful when building adapters/tools around SQLite SQL
generation. Run the example to preview generated SQLite DDL:

```bash
dart run example/main.dart
```

## Related packages

| Package | Use it for |
| --- | --- |
| [`ormed`](https://pub.dev/packages/ormed) | Core runtime and query APIs |
| [`ormed_sqlite`](https://pub.dev/packages/ormed_sqlite) | Default native and web SQLite adapter |
| [`ormed_sqlite_web`](https://pub.dev/packages/ormed_sqlite_web) | Browser SQLite transport |
| [`ormed_d1`](https://pub.dev/packages/ormed_d1) | Cloudflare D1 adapter |
