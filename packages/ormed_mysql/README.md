# ormed_mysql

MySQL/MariaDB adapter for the routed ORM driver interface. It implements the
`DriverAdapter` + `SchemaDriver` contracts and executes queries through
`package:mysql_client_plus`. The adapter plugs directly into `QueryContext` so
existing repositories work across SQLite/Postgres/MySQL/MariaDB with no code
changes.

> **Engine compatibility**: Tested against MySQL 8.0+ and MariaDB 10.5+. Most
> features should "just work" as long as the backend understands
> `ON DUPLICATE KEY UPDATE` and `JSON` columns.

## Usage

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_mysql/ormed_mysql.dart';

Future<void> main() async {
  final adapter = MySqlDriverAdapter.fromUrl(
    'mysql://root:secret@localhost:6604/orm_test',
  );
  final registry = ModelRegistry()..register(UserOrmDefinition.definition);
  final context = QueryContext(
    registry: registry,
    driver: adapter,
    codecRegistry: adapter.codecs,
  );

  await adapter.executeRaw(
    'CREATE TABLE IF NOT EXISTS users ('
    'id BIGINT PRIMARY KEY AUTO_INCREMENT,'
    'email VARCHAR(255) NOT NULL,'
    'active TINYINT(1) NOT NULL'
    ')',
  );

  await context.repository<User>().insert(
    const User(id: 1, email: 'alice@example.com', active: true),
  );

  final users = await context.query<User>().get();
  print(users.first.email);
  await adapter.close();
}
```

### Custom connection options

`MySqlDriverAdapter.custom`/`MariaDbDriverAdapter.custom` accept a
`DatabaseConfig` that mirrors Laravel's MySQL configuration keys. Supported
options include `url`, `host`, `port`, `database`, `username`, `password`,
`ssl`, `timeoutMs`, `charset`, `collation`, `timezone`, `sqlMode`, `session`,
and `init` (an array of SQL statements to run right after the connection is
established).

## Local MariaDB via Docker Compose

`packages/orm/ormed_mysql/docker-compose.yml` starts a disposable MariaDB 11.4
instance bound to port `6604`.

```bash
# Start MariaDB locally
cd packages/orm/ormed_mysql
MARIADB_ROOT_PASSWORD=secret docker compose up -d

# Run the adapter tests
export MARIADB_URL="mariadb://root:secret@localhost:6604/orm_test"
dart test packages/orm/ormed_mysql

# Tear everything down
docker compose down -v
```

## Local MySQL via Docker Compose

`packages/orm/ormed_mysql/docker-compose.mysql.yml` brings up a MySQL 8.4 server
bound to port `6605`.

```bash
# Start MySQL locally
cd packages/orm/ormed_mysql
MYSQL_ROOT_PASSWORD=secret docker compose -f docker-compose.mysql.yml up -d

# Run the adapter tests
export MYSQL_URL="mysql://root:secret@localhost:6605/orm_test"
dart test packages/orm/ormed_mysql/test/mysql_driver_shared_test.dart

# Tear everything down
docker compose -f docker-compose.mysql.yml down -v
```

## Testing Helpers

- `MariaDbTestHarness.connect()` (see `test/support/mariadb_harness.dart`)
  provisions a clean schema against MariaDB.
- `MySqlTestHarness.connect()` (see `test/support/mysql_harness.dart`) targets a
  vanilla MySQL instance.
- `executeRaw` makes it easy for tests to run schema DDL during set up/tear down
  without a migration runner, and both harnesses reuse the shared suites from
  `package:driver_tests`.
