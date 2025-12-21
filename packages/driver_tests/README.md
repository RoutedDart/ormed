# driver_tests

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/docs-ormed.vercel.app-blue)](https://ormed.vercel.app/)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow?logo=buy-me-a-coffee)](https://www.buymeacoffee.com/kingwill101)

Shared, driver-agnostic integration test suite for the ormed ORM. These test suites assert baseline query, mutation, and transaction behaviors that every database driver must satisfy.

## Purpose

Individual driver packages (`ormed_sqlite`, `ormed_postgres`, `ormed_mysql`) include this package as a `dev_dependency`, supply their own test harness, and run the shared suites. This ensures consistent behavior across all supported databases.

## Installation

```yaml
dev_dependencies:
  driver_tests:
    path: ../driver_tests  # or workspace resolution
```

## Usage

### 1. Create a Test Harness

Each driver package creates a harness that bootstraps the ORM:

```dart
import 'package:driver_tests/driver_tests.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

Future<void> createSqliteTestHarness() async {
  final adapter = SqliteDriverAdapter.inMemory();
  
  await setUpOrmed(
    adapter: adapter,
    migrations: allMigrationDescriptors,
    isolationStrategy: DatabaseIsolationStrategy.migrateWithTransactions,
  );
}
```

### 2. Run Shared Tests

```dart
import 'package:driver_tests/driver_tests.dart';
import 'package:test/scaffolding.dart';

Future<void> main() async {
  final harness = await createSqliteTestHarness();
  tearDownAll(() => harness.dispose());
  
  // Run all shared test suites
  runAllDriverTests();
}
```

## Test Suites

The package provides 13 main test suites via `runAllDriverTests()`:

| Suite | Description |
|-------|-------------|
| **Query Tests** | Filtering, ordering, pagination, statement previews |
| **Join Tests** | Inner/outer joins, join builders, relation aliases |
| **Advanced Query Tests** | Between, in/notIn, null predicates |
| **Mutation Tests** | Insert/update/delete round trips, upsert |
| **Transaction Tests** | Rollback on exception, commit on completion |
| **Repository Tests** | Full repository operations (CRUD, DTOs, Maps) |
| **Driver Override Tests** | Custom codec/driver behavior overrides |
| **Model Event Cancel Tests** | Event cancellation during model lifecycle |
| **Factory Inheritance Tests** | Model factory inheritance patterns |
| **Partial Entity Tests** | Partial class validation, `toEntity()` |

### Query Builder Tests (29 sub-suites)

| Category | Tests |
|----------|-------|
| **Clauses** | WHERE, ORDER BY, LIMIT/OFFSET, SELECT, JOIN |
| **Aggregation** | count, sum, avg, min, max |
| **Relations** | Lazy loading, aggregates, mutations, caching |
| **CRUD** | Create, read, update, delete, upsert, batch |
| **Refresh/Sync** | refresh, fresh, queryrow sync, replication |
| **Advanced** | JSON queries, date/time, subqueries, scopes |
| **Utilities** | Raw queries, chunking/streaming, caching, timestamps |

## Test Models

The package includes 20+ test models with migrations:

| Model | Purpose |
|-------|---------|
| `User`, `UserProfile` | Basic user with hasOne relationship |
| `Author`, `Post`, `Tag`, `PostTag` | Blog-style relations (hasMany, belongsToMany) |
| `Article` | Rich model with ratings, status, nullable fields |
| `Comment` | Soft-delete enabled model |
| `Photo`, `Image` | Polymorphic relationships |
| `ScopedUser`, `UniqueUser` | Scopes and unique constraints |
| `CustomSoftDelete`, `EventModel` | Lifecycle events |

## Driver Configuration

Drivers declare capabilities via `DriverTestConfig`:

```dart
final config = DriverTestConfig(
  supportsReturning: true,
  supportsJoins: true,
  supportsRightJoin: true,
  supportsDistinctOn: false,  // SQLite doesn't support DISTINCT ON
  supportsTransactions: true,
);
```

Tests automatically skip when a capability is not supported:

```dart
if (!metadata.supportsCapability(DriverCapability.transactions)) {
  return; // Skip transaction tests
}
```

## Database Isolation

Tests use `ormedGroup()` for per-test database isolation:

```dart
ormedGroup('My feature tests', () {
  test('should work correctly', () async {
    final ds = await getDataSource();
    // Each test gets a clean database state
  });
});
```

Isolation strategies:
- `migrate` - Run migrations for each test
- `migrateWithTransactions` - Migrations + transaction rollback
- `truncate` - Truncate tables between tests
- `recreate` - Drop and recreate database

## Seeders

Pre-built seeders for test data:

```dart
import 'package:driver_tests/seeders.dart';

await UserSeeder().run();
await AuthorSeeder().run();
```

## Directory Structure

```
lib/
├── driver_tests.dart      # Main exports
├── models.dart            # Model exports
├── seeders.dart           # Seeder exports
├── orm_registry.g.dart    # Generated registry
└── src/
    ├── config.dart        # DriverTestConfig
    ├── migrations/        # 19 table migrations
    ├── models/            # 20+ model definitions
    ├── support/           # Schema/seeder helpers
    └── tests/             # Test suites
        ├── all_tests.dart
        └── query_builder/ # 29 QB test files
```
