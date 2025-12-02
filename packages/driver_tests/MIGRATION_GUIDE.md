# Migration Guide: Updating to TestSchemaManager

This guide helps you migrate existing driver tests from the old manual `MigrationRunner` pattern to the new `TestSchemaManager` approach.

## Overview of Changes

The driver_tests package has been updated to use the new `TestSchemaManager` from the core ormed testing subsystem. This brings several benefits:

- **Simpler API**: High-level methods instead of manual migration runner setup
- **Integrated Seeding**: Built-in support for database seeders
- **Better Cleanup**: Automatic teardown and purge capabilities
- **Debugging Tools**: Pretend mode for inspecting queries
- **Consistency**: Same patterns used across ormed ecosystem

## Before and After

### Old Pattern (Manual MigrationRunner)

```dart
import 'package:ormed/ormed.dart';
import 'package:driver_tests/driver_tests.dart';

void main() {
  group('Driver tests', () {
    late MigrationRunner runner;
    late SchemaDriver driver;
    
    setUpAll(() async {
      // Manual runner setup
      runner = MigrationRunner(
        schemaDriver: driver,
        ledger: SqlMigrationLedger(driver as DriverAdapter),
        migrations: driverTestMigrations,
      );
      await runner.applyAll();
      
      // Manual seeding using harness
      await seedGraph(harness);
    });
    
    tearDownAll(() async {
      // Manual cleanup
      final status = await runner.status();
      final appliedCount = status.where((m) => m.applied).length;
      if (appliedCount > 0) {
        await runner.rollback(steps: appliedCount);
      }
      await _purgeDriverTestSchema(driver);
    });
    
    test('my test', () async {
      // test code
    });
  });
}
```

### New Pattern (TestSchemaManager)

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed/testing.dart';
import 'package:driver_tests/driver_tests.dart';

void main() {
  group('Driver tests', () {
    late TestSchemaManager manager;
    late OrmConnection connection;
    
    setUpAll(() async {
      // Simple manager creation
      manager = createDriverTestSchemaManager(driver);
      await manager.setup();
      
      // Use new seeder classes
      await seedDriverTestGraph(manager, connection);
    });
    
    tearDownAll() async {
      // Automatic cleanup
      await manager.teardown();
    });
    
    test('my test', () async {
      // test code
    });
  });
}
```

## Step-by-Step Migration

### Step 1: Update Imports

**Before:**
```dart
import 'package:ormed/ormed.dart';
import 'package:driver_tests/driver_tests.dart';
```

**After:**
```dart
import 'package:ormed/ormed.dart';
import 'package:ormed/testing.dart';  // Add this
import 'package:driver_tests/driver_tests.dart';
```

### Step 2: Replace MigrationRunner with TestSchemaManager

**Before:**
```dart
late MigrationRunner runner;

setUpAll(() async {
  runner = MigrationRunner(
    schemaDriver: driver,
    ledger: SqlMigrationLedger(driver as DriverAdapter),
    migrations: driverTestMigrations,
  );
  await runner.applyAll();
});
```

**After:**
```dart
late TestSchemaManager manager;

setUpAll(() async {
  manager = createDriverTestSchemaManager(driver);
  await manager.setup();
});
```

### Step 3: Update Seeding

**Before:**
```dart
await seedGraph(harness);
```

**After:**
```dart
// Option 1: Seed entire graph
await seedDriverTestGraph(manager, connection);

// Option 2: Seed specific models
await manager.seed(connection, [
  UserSeeder.new,
  PostSeeder.new,
]);

// Option 3: Use seeder registry
await runSeederRegistry(
  connection,
  driverTestSeederRegistry,
  names: ['UserSeeder', 'PostSeeder'],
);
```

### Step 4: Update Teardown

**Before:**
```dart
tearDownAll(() async {
  final status = await runner.status();
  final appliedCount = status.where((m) => m.applied).length;
  if (appliedCount > 0) {
    await runner.rollback(steps: appliedCount);
  }
  await _purgeDriverTestSchema(driver);
});
```

**After:**
```dart
tearDownAll(() async {
  await manager.teardown();
});
```

### Step 5: Update Reset Logic (if applicable)

**Before:**
```dart
setUp(() async {
  await dropDriverTestSchema(driver);
  await resetDriverTestSchema(driver);
  await seedGraph(harness);
});
```

**After:**
```dart
setUp(() async {
  await manager.reset();
  await seedDriverTestGraph(manager, connection);
});
```

## New Features Available

### 1. Pretend Mode for Debugging

```dart
test('debug seeder queries', () async {
  final statements = await manager.seedWithPretend(
    connection,
    [UserSeeder.new],
    pretend: true,
  );
  
  for (final entry in statements) {
    print('Query: ${entry.preview.normalized.command}');
  }
});
```

### 2. Migration Status Inspection

```dart
test('check migration status', () async {
  final status = await manager.status();
  for (final migration in status) {
    print('${migration.descriptor.id.slug}: ${migration.applied}');
  }
});
```

### 3. Selective Seeding

```dart
// Seed only what you need for specific tests
await manager.seed(connection, [UserSeeder.new]);
```

### 4. Custom User Suffixes

```dart
// Useful for parallel test execution
await manager.seed(connection, [
  (_) => UserSeeder(connection, suffix: 'unique_123'),
]);
```

### 5. Schema Purge

```dart
// Force drop all tables (emergency cleanup)
await manager.purge();
```

## Common Migration Scenarios

### Scenario 1: Simple Test Suite

**Before:**
```dart
void runMyDriverTests(DriverHarnessBuilder<DriverTestHarness> createHarness) {
  group('My tests', () {
    late DriverTestHarness harness;
    
    setUp(() async {
      harness = await createHarness();
      await seedGraph(harness);
    });
    
    tearDown(() async {
      await harness.dispose();
    });
    
    test('test 1', () async {
      // test code
    });
  });
}
```

**After:**
```dart
void runMyDriverTests(DriverHarnessBuilder<DriverTestHarness> createHarness) {
  group('My tests', () {
    late DriverTestHarness harness;
    late TestSchemaManager manager;
    
    setUpAll(() async {
      harness = await createHarness();
      manager = createDriverTestSchemaManager(harness.adapter as SchemaDriver);
      await manager.setup();
    });
    
    setUp(() async {
      await harness.context.connection.beginTransaction();
      await seedDriverTestGraph(manager, harness.context.connection);
    });
    
    tearDown(() async {
      await harness.context.connection.rollback();
    });
    
    tearDownAll(() async {
      await manager.teardown();
      await harness.dispose();
    });
    
    test('test 1', () async {
      // test code
    });
  });
}
```

### Scenario 2: Tests with Custom Seeding

**Before:**
```dart
setUp(() async {
  harness = await createHarness();
  await harness.seedUsers(customUsers);
  await harness.seedPosts(customPosts);
});
```

**After:**
```dart
setUpAll(() async {
  harness = await createHarness();
  manager = createDriverTestSchemaManager(harness.adapter as SchemaDriver);
  await manager.setup();
});

setUp(() async {
  await harness.context.connection.beginTransaction();
  
  // Use seeders or direct seeding
  await manager.seed(connection, [UserSeeder.new, PostSeeder.new]);
  
  // Or for custom data:
  await harness.seedUsers(customUsers);
  await harness.seedPosts(customPosts);
});

tearDown(() async {
  await harness.context.connection.rollback();
});
```

### Scenario 3: Tests with Schema Reset

**Before:**
```dart
group('Tests requiring reset', () {
  setUp(() async {
    await resetDriverTestSchema(driver);
    await seedGraph(harness);
  });
  
  test('test 1', () async {
    // test code
  });
});
```

**After:**
```dart
group('Tests requiring reset', () {
  setUp(() async {
    await manager.reset();
    await seedDriverTestGraph(manager, connection);
  });
  
  test('test 1', () async {
    // test code
  });
});
```

## API Reference Changes

### Removed/Deprecated Functions

These are now replaced by `TestSchemaManager`:

- Manual `MigrationRunner` setup
- Manual `SqlMigrationLedger` creation
- Direct `runner.applyAll()` calls
- Manual rollback logic
- Custom purge functions

### New Functions Available

From `driver_tests` package:

- `createDriverTestSchemaManager(driver)` - Create configured manager
- `seedDriverTestGraph(manager, connection)` - Seed complete test graph
- `UserSeeder`, `PostSeeder`, etc. - Individual seeder classes
- `DriverTestGraphSeeder` - Composite seeder for all data
- `driverTestSeederRegistry` - Registry of all seeders

From `ormed/testing` package:

- `TestSchemaManager` - Main schema management class
- `DatabaseSeeder` - Base class for seeders
- `SeederRegistration` - Registry pattern for seeders
- `runSeederRegistry()` - Execute registered seeders

### Unchanged Functions

These still work as before:

- `driverTestModelDefinitions` - List of model definitions
- `driverTestMigrations` - List of migration descriptors
- `registerDriverTestFactories()` - Register model factories
- `resetDriverTestSchema(driver)` - Now uses `TestSchemaManager` internally
- `dropDriverTestSchema(driver)` - Now uses `TestSchemaManager` internally

## Benefits of Migration

1. **Less Boilerplate**: Simpler setup and teardown code
2. **Better Abstraction**: No need to understand migration runner internals
3. **Integrated Seeding**: Seeders are first-class citizens
4. **Debugging Tools**: Pretend mode, status inspection
5. **Consistency**: Same patterns across all ormed packages
6. **Future-Proof**: New features will be added to `TestSchemaManager`

## Troubleshooting

### Issue: "Cannot create TestSchemaManager"

**Error:**
```
Type 'MyDriver' is not a subtype of type 'SchemaDriver'
```

**Solution:**
Ensure your driver implements `SchemaDriver`:
```dart
final schemaDriver = driver as SchemaDriver;
final manager = createDriverTestSchemaManager(schemaDriver);
```

### Issue: "Seeders not inserting data"

**Error:**
Data is not appearing in the database.

**Solution:**
Ensure you're calling seeders on the connection, not just the manager:
```dart
// Correct:
await manager.seed(connection, [UserSeeder.new]);

// Incorrect:
await manager.seed(manager, [UserSeeder.new]);
```

### Issue: "Migration checksum mismatch"

**Error:**
```
Migration xyz checksum mismatch
```

**Solution:**
The ledger table has stale data. Drop and recreate:
```dart
await manager.teardown();
await manager.purge();
await manager.setup();
```

### Issue: "Foreign key constraint violations"

**Error:**
Foreign key errors during seeding.

**Solution:**
Use `DriverTestGraphSeeder` which seeds in correct order:
```dart
await seedDriverTestGraph(manager, connection);
```

Or manually order your seeders:
```dart
await manager.seed(connection, [
  UserSeeder.new,     // Parent
  PostSeeder.new,     // Child
  CommentSeeder.new,  // Grandchild
]);
```

## Examples

See `example/using_test_schema_manager.dart` for complete examples of:

- Basic setup and teardown
- Using seeders
- Selective seeding
- Seeder registry
- Reset between tests
- Pretend mode
- Migration status
- Custom user suffixes
- Complete test suite setup

## Need Help?

- Check the examples in `example/` directory
- Read the ormed testing documentation
- Review the `TestSchemaManager` source code
- Look at updated test files in the driver packages

## Summary

Migrating to `TestSchemaManager` is straightforward:

1. Add `import 'package:ormed/testing.dart';`
2. Replace `MigrationRunner` with `createDriverTestSchemaManager(driver)`
3. Replace `runner.applyAll()` with `manager.setup()`
4. Replace manual seeding with `seedDriverTestGraph()` or seeder classes
5. Replace manual teardown with `manager.teardown()`

The new pattern is simpler, more powerful, and consistent across the ormed ecosystem!