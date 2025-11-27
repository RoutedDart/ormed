# ormed_sqlite

SQLite adapter for the routed ORM driver interface. It implements the
`DriverAdapter` contract, compiling `QueryPlan`s into SQL and executing them via
`package:sqlite3`.

## Usage

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

void main() async {
  final adapter = SqliteDriverAdapter.inMemory();
  final registry = ModelRegistry()..register(UserOrmDefinition.definition);
  final context = QueryContext(registry: registry, driver: adapter);

  await adapter.executeRaw(
    'CREATE TABLE users (id INTEGER PRIMARY KEY, email TEXT)',
  );
  await context.repository<User>().insert(
        const User(id: 1, email: 'alice@example.com', active: true),
      );

  final users = await context.query<User>().get();
  print(users.first.email);
  await adapter.close();
}
```

## Testing Helpers

- `executeRaw` lets tests run schema/migration statements during setup.
- `QueryContext.repository<T>()` provides insert helpers so fixtures can be
  created without handwritten SQL.
