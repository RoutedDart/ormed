# ormed_mysql

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/docs-ormed.vercel.app-blue)](https://ormed.vercel.app/)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow?logo=buy-me-a-coffee)](https://www.buymeacoffee.com/kingwill101)

MySQL and MariaDB driver adapter for the ormed ORM. Implements the `DriverAdapter` and `SchemaDriver` contracts, executing queries through `package:mysql_client_plus`.

## Features

- MySQL 8.0+ and MariaDB 10.5+ support
- Full JSON column support
- Transaction support with nested savepoints
- Schema introspection and migration support
- SET, ENUM, and spatial type support
- Connection configuration mirroring Laravel's MySQL options

## Installation

```yaml
dependencies:
  ormed: ^0.1.0-dev+1
  ormed_mysql: ^0.1.0-dev+1
```

## Quick Start

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_mysql/ormed_mysql.dart';

Future<void> main() async {
  final adapter = MySqlDriverAdapter.fromUrl(
    'mysql://root:secret@localhost:3306/mydb',
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

  await context.repository<\$User>().insert(
    \$User(email: 'alice@example.com', active: true),
  );

  final users = await context.query<\$User>().get();
  print(users.first.email);
  
  await adapter.close();
}
```

## Adapter Constructors

```dart
// MySQL from URL
MySqlDriverAdapter.fromUrl('mysql://user:pass@host:port/database')

// MariaDB from URL
MariaDbDriverAdapter.fromUrl('mariadb://user:pass@host:port/database')

// With SSL
MySqlDriverAdapter.fromUrl('mysqls://user:pass@host:port/database')

// Local development (insecure)
MySqlDriverAdapter.insecureLocal(
  database: 'mydb',
  username: 'root',
  password: 'secret',
  port: 3306,
)

// Custom configuration
MySqlDriverAdapter.custom(config: DatabaseConfig(
  driver: 'mysql',
  options: {
    'host': 'localhost',
    'port': 3306,
    'database': 'mydb',
    'username': 'root',
    'password': 'secret',
    'ssl': true,
    'timeoutMs': 30000,
    'charset': 'utf8mb4',
    'collation': 'utf8mb4_unicode_ci',
    'timezone': '+00:00',
    'sqlMode': 'STRICT_TRANS_TABLES',
    'session': {'wait_timeout': 28800},
    'init': ['SET NAMES utf8mb4'],
  },
))
```

## Driver Capabilities

| Capability | Supported |
|------------|-----------|
| Joins (inner, left, right, cross) | ✅ |
| Lateral joins | ✅ |
| Transactions with savepoints | ✅ |
| Schema introspection | ✅ |
| Raw SQL execution | ✅ |
| JSON operations | ✅ |
| Index hints | ✅ |
| FOR UPDATE / LOCK IN SHARE MODE | ✅ |
| Database management | ✅ |
| Foreign key constraints | ✅ |

> **Note**: MySQL doesn't support native RETURNING. Insert operations return `lastInsertID` instead.

## Type Mappings

| Dart Type | MySQL Type |
|-----------|------------|
| `bool` | TINYINT(1) |
| `int` | INT / BIGINT |
| `double` | DOUBLE |
| `Decimal` | DECIMAL / NUMERIC |
| `String` | VARCHAR / TEXT |
| `DateTime` | DATETIME / TIMESTAMP |
| `Duration` | TIME |
| `UuidValue` | CHAR(36) |
| `Set<String>` | SET |
| `MySqlBitString` | BIT |
| `MySqlGeometry` | GEOMETRY / POINT / POLYGON |
| `Uint8List` | BLOB / BINARY |
| `Map` | JSON |

## MySQL-Specific Types

```dart
// Value classes for MySQL-specific types
import 'package:ormed_mysql/ormed_mysql.dart';

MySqlBitString   // BIT column values
MySqlGeometry    // Spatial/geometry values (WKB format)
```

## Connection URL Schemes

| Scheme | Description |
|--------|-------------|
| `mysql://` | Standard MySQL connection |
| `mariadb://` | Standard MariaDB connection |
| `mysqls://` | MySQL with SSL |
| `mariadbs://` | MariaDB with SSL |
| `mysql+ssl://` | MySQL with SSL (alternative) |

Query parameters: `?ssl=true`, `?secure=true`

## Docker Setup

### MariaDB (docker-compose.yml)

```bash
cd packages/ormed_mysql
MARIADB_ROOT_PASSWORD=secret docker compose up -d

export MARIADB_URL="mariadb://root:secret@localhost:6604/orm_test"
dart test packages/ormed_mysql

docker compose down -v
```

### MySQL (docker-compose.mysql.yml)

```bash
cd packages/ormed_mysql
MYSQL_ROOT_PASSWORD=secret docker compose -f docker-compose.mysql.yml up -d

export MYSQL_URL="mysql://root:secret@localhost:6605/orm_test"
dart test packages/ormed_mysql/test/mysql_driver_shared_test.dart

docker compose -f docker-compose.mysql.yml down -v
```

## JSON Operations

```dart
// Query JSON columns
final users = await ds.query<\$User>()
    .whereJson('settings', '$.theme', 'dark')
    .get();

// Uses MySQL JSON functions: JSON_EXTRACT, JSON_UNQUOTE, JSON_TYPE
```

## Index Hints

```dart
// MySQL-specific index hints
final results = await adapter.queryRaw(
  'SELECT * FROM users USE INDEX (idx_email) WHERE email = ?',
  ['test@example.com'],
);
```

## Upsert Operations

MySQL uses `ON DUPLICATE KEY UPDATE`:

```dart
await repo.upsert(
  \$UserInsertDto(email: 'test@example.com', name: 'Test'),
  uniqueBy: ['email'],
);
```

## Related Packages

| Package | Description |
|---------|-------------|
| `ormed` | Core ORM library |
| `ormed_sqlite` | SQLite driver |
| `ormed_postgres` | PostgreSQL driver |
| `ormed_cli` | CLI tool for migrations |
