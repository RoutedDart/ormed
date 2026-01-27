# ormed_postgres

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/docs-ormed.vercel.app-blue)](https://ormed.vercel.app/)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow?logo=buy-me-a-coffee)](https://www.buymeacoffee.com/kingwill101)

PostgreSQL driver adapter for the ormed ORM. Implements the `DriverAdapter` contract, compiling query plans into SQL and executing them via `package:postgres` (v3).

## Features

- Full PostgreSQL type support (UUID, JSONB, arrays, geometric types, etc.)
- Native RETURNING clause support
- Full-text search with tsvector/tsquery
- Range types (int4range, daterange, tsrange, etc.)
- Transaction support with nested savepoints
- Schema introspection and migration support
- Connection pooling with role-based handles

## Installation

```yaml
dependencies:
  ormed: ^0.1.0
  ormed_postgres: ^0.1.0
```

## Quick Start

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/ormed_postgres.dart';

Future<void> main() async {
  final adapter = PostgresDriverAdapter.fromUrl(
    'postgres://postgres:postgres@localhost:5432/mydb',
  );
  
  final registry = ModelRegistry()..register(UserOrmDefinition.definition);
  final context = QueryContext(
    registry: registry,
    driver: adapter,
    codecRegistry: adapter.codecs,
  );

  await adapter.executeRaw(
    'CREATE TABLE IF NOT EXISTS users '
    '(id SERIAL PRIMARY KEY, email TEXT NOT NULL)',
  );

  await context.repository<\$User>().insert(
    \$User(email: 'alice@example.com'),
  );

  final users = await context.query<\$User>().get();
  print(users.first.email);
  
  await adapter.close();
}
```

## Adapter Constructors

```dart
// From connection URL
PostgresDriverAdapter.fromUrl('postgres://user:pass@host:port/database')

// Local development (insecure)
PostgresDriverAdapter.insecureLocal(
  database: 'mydb',
  username: 'postgres',
  password: 'postgres',
)

// Custom configuration
PostgresDriverAdapter.custom(config: DatabaseConfig(
  driver: 'postgres',
  options: {
    'host': 'localhost',
    'port': 5432,
    'database': 'mydb',
    'username': 'user',
    'password': 'secret',
    'sslmode': 'require',
    'timezone': 'UTC',
    'connectTimeout': 30000,
    'applicationName': 'my_app',
  },
))
```

## Driver Capabilities

| Capability | Supported |
|------------|-----------|
| All join types (inner, left, right, cross, lateral) | ✅ |
| RETURNING clause | ✅ |
| Transactions with savepoints | ✅ |
| DISTINCT ON | ✅ |
| Schema introspection | ✅ |
| Raw SQL execution | ✅ |
| JSON/JSONB operations | ✅ |
| Full-text search | ✅ |
| FOR UPDATE / FOR SHARE locking | ✅ |
| Database management | ✅ |

## PostgreSQL-Specific Types

The adapter includes value types and codecs for PostgreSQL-specific data:

| Dart Type | PostgreSQL Type |
|-----------|-----------------|
| `UuidValue` | UUID |
| `Decimal` | NUMERIC/DECIMAL |
| `Duration` | INTERVAL |
| `PgInet` | INET |
| `PgCidr` | CIDR |
| `PgMacAddress` | MACADDR/MACADDR8 |
| `PgVector` | VECTOR (pgvector) |
| `PgBitString` | BIT/VARBIT |
| `PgMoney` | MONEY |
| `TsVector` | TSVECTOR |
| `TsQuery` | TSQUERY |
| `IntRange` | INT4RANGE/INT8RANGE |
| `DateRange` | DATERANGE |
| `DateTimeRange` | TSRANGE/TSTZRANGE |
| `Point`, `Line`, `Box`, etc. | Geometric types |

### Array Types

```dart
List<String>    → TEXT[]
List<int>       → INTEGER[]
List<double>    → DOUBLE PRECISION[]
List<bool>      → BOOLEAN[]
List<DateTime>  → TIMESTAMPTZ[]
List<UuidValue> → UUID[]
```

## Migration Extensions

```dart
import 'package:ormed_postgres/migrations.dart';

schema.create('documents', (table) {
  table.id();
  
  // Network types
  table.inet('ip_address');
  table.cidr('network');
  table.macaddr('mac');
  
  // Full-text search
  table.tsvector('search_vector');
  table.tsquery('search_query');
  
  // Temporal
  table.interval('duration');
  table.timetz('event_time');
  
  // Range types
  table.int4range('quantity_range');
  table.daterange('validity_period');
  table.tstzrange('booking_window');
  
  // Other
  table.money('price');
  table.xml('config');
  table.bit('flags', length: 8);
  
  // Geometric
  table.point('location');
  table.polygon('area');
  table.circle('radius');
});
```

## Full-Text Search

```dart
// Query with full-text search
final results = await ds.query<\$Article>()
    .whereRaw("search_vector @@ plainto_tsquery('english', ?)", ['dart orm'])
    .get();

// Create search index
schema.create('articles', (table) {
  table.id();
  table.string('title');
  table.text('body');
  table.tsvector('search_vector');
  
  table.index(['search_vector'], type: IndexType.gin);
});
```

## JSON/JSONB Operations

```dart
// Query JSONB fields
final users = await ds.query<\$User>()
    .whereJson('settings', '$.theme', 'dark')
    .whereJsonContains('tags', ['premium'])
    .get();

// Update JSONB
await ds.query<\$User>()
    .whereEquals('id', 1)
    .jsonSet('settings', '$.notifications', false);
```

## Docker Setup for Testing

```bash
# Start PostgreSQL container
docker compose -f packages/ormed_postgres/docker-compose.yml up -d

# Set connection URL
export POSTGRES_URL="postgres://postgres:postgres@localhost:6543/orm_test"

# Run tests
dart test packages/ormed_postgres

# Cleanup
docker compose -f packages/ormed_postgres/docker-compose.yml down -v
```

**docker-compose.yml:**
```yaml
services:
  postgres:
    image: postgres:16-alpine
    ports:
      - "6543:5432"
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: orm_test
```

## Schema Operations

```dart
// Dump schema using pg_dump
await adapter.dumpSchema(File('schema.sql'));

// Load schema using psql
await adapter.loadSchema(File('schema.sql'));

// Introspection
final schemas = await adapter.listSchemas();
final tables = await adapter.listTables(schema: 'public');
final columns = await adapter.listColumns('users');
final indexes = await adapter.listIndexes('users');
final foreignKeys = await adapter.listForeignKeys('posts');
```

## Related Packages

| Package | Description |
|---------|-------------|
| `ormed` | Core ORM library |
| `ormed_sqlite` | SQLite driver |
| `ormed_mysql` | MySQL/MariaDB driver |
| `ormed_cli` | CLI tool for migrations |
