# Test Schema Manager - Enhanced Testing Capabilities

This document describes the new `TestSchemaManager` class and related testing enhancements added to the ormed package.

## Overview

The `TestSchemaManager` brings migration runner and seeding capabilities from `driver_tests` and `ormed_cli` into the core `ormed` package, making these powerful testing tools available to all users.

## What's New

### 1. TestSchemaManager Class

A driver-agnostic schema management system for tests that provides:

- **Migration Management**: Run migrations using `MigrationRunner` under the hood
- **Seeding Support**: Execute database seeders to populate test data
- **Schema Reset**: Tear down and rebuild schema between tests
- **Pretend Mode**: Debug seeders by viewing queries without execution
- **Status Inspection**: Check which migrations have been applied

**Location**: `lib/src/testing/test_schema_manager.dart`

### 2. DatabaseSeeder Base Class

A refined base class for test seeders (already existed, now enhanced):

- `seed<T>(records)` - Bulk insert records for a model
- `call(factories)` - Compose seeders together
- Full integration with `TestSchemaManager`

**Location**: `lib/src/testing/test_schema_manager.dart`

### 3. Seeder Registry System

Register and run seeders by name, useful for CLI tools and flexible test setup:

- `SeederRegistration` - Register seeders with names and factories
- `runSeederRegistry()` - Execute registered seeders with logging and pretend mode

**Location**: `lib/src/testing/test_schema_manager.dart`

## Key Features

### Driver Agnostic

All functionality works with any driver that implements `SchemaDriver`:
- PostgreSQL
- MySQL/MariaDB  
- SQLite
- Custom drivers

No driver-specific code in the testing subsystem.

### Based on Proven Patterns

The implementation is inspired by and consolidates patterns from:

1. **driver_tests** - Migration runner usage pattern
2. **ormed_cli/runtime.dart** - Seeding registry and pretend mode
3. **orm_playground** - Seeder composition patterns

### Flexible Integration

Works with existing test frameworks:
- Can be used with `ormedTest` helper
- Compatible with standard `test` package
- Supports `setUp`/`tearDown` lifecycle hooks

## Basic Usage

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed/testing.dart';

void main() async {
  late TestSchemaManager manager;
  late OrmConnection connection;
  
  setUpAll(() async {
    connection = await createTestConnection();
    
    // Create manager with migrations
    manager = TestSchemaManager(
      schemaDriver: connection.driver as SchemaDriver,
      migrations: [
        MigrationDescriptor.fromMigration(
          id: MigrationId(DateTime.utc(2024, 1, 1), 'create_users'),
          migration: CreateUsersTable(),
        ),
      ],
    );
    
    // Set up schema
    await manager.setup();
    
    // Seed initial data
    await manager.seed(connection, [UserSeeder.new]);
  });
  
  tearDownAll(() async {
    await manager.teardown();
    await connection.close();
  });
  
  test('creates user', () async {
    final user = await User.create(
      {'name': 'Test'},
      connection: connection.name,
    );
    expect(user.id, isNotNull);
  });
}
```

## Seeder Example

```dart
class UserSeeder extends DatabaseSeeder {
  UserSeeder(super.connection);
  
  @override
  Future<void> run() async {
    await seed<User>([
      {'name': 'John Doe', 'email': 'john@example.com'},
      {'name': 'Jane Smith', 'email': 'jane@example.com'},
    ]);
  }
}

class DatabaseSeederMain extends DatabaseSeeder {
  DatabaseSeederMain(super.connection);
  
  @override
  Future<void> run() async {
    // Compose multiple seeders
    await call([
      UserSeeder.new,
      PostSeeder.new,
      CommentSeeder.new,
    ]);
  }
}
```

## API Reference

### TestSchemaManager

**Constructor:**
```dart
TestSchemaManager({
  required SchemaDriver schemaDriver,
  List<ModelDefinition>? modelDefinitions,
  List<MigrationDescriptor>? migrations,
  String ledgerTable = 'orm_migrations',
})
```

**Methods:**

- `Future<MigrationReport> setup()` - Apply all pending migrations
- `Future<void> teardown()` - Roll back all applied migrations  
- `Future<MigrationReport> reset()` - Tear down and set up again
- `Future<void> purge()` - Drop all tables forcefully (bypass migrations)
- `Future<List<MigrationStatus>> status()` - Get migration status
- `Future<void> seed(connection, seeders)` - Run seeders
- `Future<List<QueryLogEntry>> seedWithPretend(connection, seeders, {pretend})` - Debug seeders

### DatabaseSeeder

**Abstract class** for creating seeders:

```dart
abstract class DatabaseSeeder {
  DatabaseSeeder(this.connection);
  
  final OrmConnection connection;
  
  Future<void> run(); // Implement this
  
  Future<List<T>> seed<T>(List<Map<String, dynamic>> records);
  Future<void> call(List<DatabaseSeeder Function(OrmConnection)> factories);
}
```

### SeederRegistration

```dart
class SeederRegistration {
  const SeederRegistration({
    required String name,
    required DatabaseSeeder Function(OrmConnection) factory,
  });
}
```

### runSeederRegistry

```dart
Future<void> runSeederRegistry(
  OrmConnection connection,
  List<SeederRegistration> seeders, {
  List<String>? names,
  bool pretend = false,
  void Function(String message)? log,
})
```

## Test Isolation Strategies

### Strategy 1: Reset Between Tests
```dart
test('test 1', () async {
  await manager.reset();
  // Fresh schema
});
```

### Strategy 2: Transaction Rollback
```dart
setUp(() async {
  await connection.beginTransaction();
});

tearDown(() async {
  await connection.rollback();
});
```

### Strategy 3: Seed Once
```dart
setUpAll(() async {
  await manager.setup();
  await manager.seed(connection, [UserSeeder.new]);
});
```

## Pretend Mode

Debug seeders without executing queries:

```dart
final statements = await manager.seedWithPretend(
  connection,
  [UserSeeder.new],
  pretend: true,
);

for (final entry in statements) {
  print('Query: ${entry.preview.normalized.command}');
  print('Params: ${entry.preview.normalized.parameters}');
}
```

## Migration Status

Check migration state:

```dart
final status = await manager.status();
for (final migration in status) {
  print('${migration.descriptor.id.slug}: ${migration.applied}');
  if (migration.applied) {
    print('  Applied at: ${migration.appliedAt}');
  }
}
```

## Files Added/Modified

### New Files
- `lib/src/testing/test_schema_manager.dart` - Main implementation
- `docs/testing_with_schema_manager.md` - Comprehensive guide
- `example/test_schema_manager_example.dart` - Usage examples
- `TEST_SCHEMA_MANAGER_README.md` - This file

### Modified Files
- `lib/testing.dart` - Export new test schema manager

## Design Principles

### 1. Driver Agnostic
No references to specific drivers (PostgreSQL, MySQL, SQLite). All operations use the `SchemaDriver` interface.

### 2. No Class Redefinition
Reuses existing classes from the ormed package:
- `MigrationRunner`
- `MigrationDescriptor`
- `SchemaBuilder`
- `SqlMigrationLedger`

### 3. Composable
Small, focused classes that work together:
- `TestSchemaManager` - Schema lifecycle
- `DatabaseSeeder` - Data insertion
- `SeederRegistration` - Registry pattern
- `runSeederRegistry` - Execution helper

### 4. Testable
Easy to use in tests with clear setup/teardown patterns.

## Benefits for Users

1. **Comprehensive Testing**: Users can now test with real schema migrations
2. **Data Seeding**: Populate test databases with realistic data
3. **Isolation**: Multiple strategies for test isolation
4. **Debugging**: Pretend mode helps debug seeding logic
5. **Reusability**: Share seeders between tests and CLI tools

## Comparison with driver_tests Pattern

**Before (driver_tests):**
```dart
final runner = MigrationRunner(
  schemaDriver: driver,
  ledger: SqlMigrationLedger(driver as DriverAdapter),
  migrations: driverTestMigrations,
);
await runner.applyAll();
// Manual cleanup...
```

**After (TestSchemaManager):**
```dart
final manager = TestSchemaManager(
  schemaDriver: driver,
  migrations: testMigrations,
);
await manager.setup();
await manager.seed(connection, [UserSeeder.new]);
await manager.teardown(); // Automatic cleanup
```

## Integration with ormed_cli

The seeder patterns are compatible with `ormed_cli`:

```dart
// In your seeders.dart file
import 'package:ormed/testing.dart';

final List<SeederRegistration> seeders = [
  SeederRegistration(name: 'UserSeeder', factory: UserSeeder.new),
  SeederRegistration(name: 'PostSeeder', factory: PostSeeder.new),
];
```

This allows you to:
- Use seeders in tests via `TestSchemaManager`
- Run seeders via CLI using `ormed_cli`
- Share seeder code between environments

## Future Enhancements

Potential additions for future versions:

1. **Automatic ModelDefinition Migrations**: Generate migrations from definitions
2. **Seeder Dependencies**: Declare seeder ordering requirements
3. **Parallel Seeding**: Run independent seeders concurrently
4. **Seeder Transactions**: Wrap seeder execution in transactions
5. **Schema Snapshots**: Save/restore schema state quickly

## Documentation

- **Quick Start**: See `example/test_schema_manager_example.dart`
- **Comprehensive Guide**: See `docs/testing_with_schema_manager.md`
- **API Reference**: See inline documentation in source files

## Questions?

For questions or issues:
1. Check the comprehensive guide in `docs/testing_with_schema_manager.md`
2. Review examples in `example/test_schema_manager_example.dart`
3. Look at `driver_tests` package for advanced patterns
4. Examine `orm_playground` for real-world seeder usage

## Summary

The `TestSchemaManager` brings powerful, driver-agnostic schema management and seeding capabilities into the core ormed testing toolkit. It consolidates proven patterns from across the ormed ecosystem into a single, easy-to-use API that empowers users to write comprehensive database tests.