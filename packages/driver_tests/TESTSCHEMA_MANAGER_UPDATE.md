# TestSchemaManager Integration - driver_tests Package Updates

This document summarizes the updates made to the `driver_tests` package to integrate the new `TestSchemaManager` from the core ormed testing subsystem.

## Overview

The `driver_tests` package has been enhanced to leverage the new `TestSchemaManager` facilities introduced in the ormed core package. This update brings powerful migration management and seeding capabilities to driver tests while maintaining backward compatibility.

## What Changed

### 1. Updated `driver_schema.dart`

**Location**: `lib/src/support/driver_schema.dart`

The file was refactored to use `TestSchemaManager` internally:

**New Functions:**
- `createDriverTestSchemaManager(SchemaDriver)` - Creates a configured TestSchemaManager
- Enhanced documentation for existing functions

**Updated Functions:**
- `resetDriverTestSchema()` - Now uses TestSchemaManager internally
- `dropDriverTestSchema()` - Now uses TestSchemaManager internally
- `registerDriverTestFactories()` - Enhanced documentation

**Removed:**
- Internal `_createRunner()` function (replaced by TestSchemaManager)
- Internal `_purgeDriverTestSchema()` function (replaced by TestSchemaManager.purge)

### 2. New `driver_test_seeders.dart`

**Location**: `lib/src/support/driver_test_seeders.dart`

A comprehensive set of seeder classes following the `DatabaseSeeder` pattern:

**Individual Seeders:**
- `UserSeeder` - Seeds users with optional suffix parameter
- `AuthorSeeder` - Seeds authors
- `PostSeeder` - Seeds posts
- `TagSeeder` - Seeds tags
- `PostTagSeeder` - Seeds post-tag relationships
- `ImageSeeder` - Seeds images
- `PhotoSeeder` - Seeds photos (polymorphic)
- `CommentSeeder` - Seeds comments (with soft deletes)
- `ArticleSeeder` - Seeds articles

**Composite Seeder:**
- `DriverTestGraphSeeder` - Seeds complete test graph in correct order

**Registry:**
- `driverTestSeederRegistry` - All seeders registered by name

**Helper Function:**
- `seedDriverTestGraph()` - Convenience function to seed the entire graph

### 3. Updated Exports

**Location**: `lib/driver_tests.dart`

Added exports for new seeder facilities:
- All seeder classes
- `driverTestSeederRegistry`
- `seedDriverTestGraph()`
- `createDriverTestSchemaManager()`

### 4. New Documentation

**Files Created:**
- `MIGRATION_GUIDE.md` - Comprehensive guide for migrating existing tests
- `TESTSCHEMA_MANAGER_UPDATE.md` - This summary document
- `example/using_test_schema_manager.dart` - 10 complete examples

## Key Features

### 1. Simplified Schema Management

**Before:**
```dart
final runner = MigrationRunner(
  schemaDriver: driver,
  ledger: SqlMigrationLedger(driver as DriverAdapter),
  migrations: driverTestMigrations,
);
await runner.applyAll();
// Manual cleanup required
```

**After:**
```dart
final manager = createDriverTestSchemaManager(driver);
await manager.setup();
// Automatic cleanup with manager.teardown()
```

### 2. Integrated Seeding

**Before:**
```dart
await harness.seedUsers(users);
await harness.seedAuthors(authors);
await harness.seedPosts(posts);
// ... manual seeding for each model
```

**After:**
```dart
// Option 1: Seed everything
await seedDriverTestGraph(manager, connection);

// Option 2: Selective seeding
await manager.seed(connection, [UserSeeder.new, PostSeeder.new]);

// Option 3: Registry-based
await runSeederRegistry(
  connection,
  driverTestSeederRegistry,
  names: ['UserSeeder'],
);
```

### 3. Pretend Mode for Debugging

```dart
final statements = await manager.seedWithPretend(
  connection,
  [UserSeeder.new],
  pretend: true,
);

for (final entry in statements) {
  print('Query: ${entry.preview.normalized.command}');
}
```

### 4. Migration Status Inspection

```dart
final status = await manager.status();
for (final migration in status) {
  print('${migration.descriptor.id.slug}: ${migration.applied}');
}
```

### 5. Easy Schema Reset

```dart
await manager.reset(); // Tear down and set up in one call
```

## Backward Compatibility

All existing functions remain available and work as before:

- `driverTestModelDefinitions` - Unchanged
- `driverTestMigrations` - Unchanged
- `registerDriverTestFactories()` - Unchanged
- `resetDriverTestSchema()` - Internally updated but API unchanged
- `dropDriverTestSchema()` - Internally updated but API unchanged
- `seedGraph()` - Still available for harness-based seeding

Existing tests will continue to work without modification.

## Migration Path

For teams wanting to adopt the new pattern:

1. **No Breaking Changes**: Existing code continues to work
2. **Gradual Migration**: Update tests incrementally
3. **New Tests**: Use the new pattern for all new tests
4. **See Guide**: `MIGRATION_GUIDE.md` has step-by-step instructions

## Usage Examples

### Example 1: Basic Setup

```dart
import 'package:ormed/testing.dart';
import 'package:driver_tests/driver_tests.dart';

void main() {
  group('My driver tests', () {
    late TestSchemaManager manager;
    late OrmConnection connection;
    
    setUpAll(() async {
      connection = await createTestConnection();
      manager = createDriverTestSchemaManager(
        connection.driver as SchemaDriver,
      );
      await manager.setup();
      await seedDriverTestGraph(manager, connection);
    });
    
    tearDownAll(() async {
      await manager.teardown();
      await connection.close();
    });
    
    test('queries work', () async {
      final users = await connection.repository<User>().findAll();
      expect(users, hasLength(3));
    });
  });
}
```

### Example 2: Transaction-Based Isolation

```dart
setUpAll(() async {
  manager = createDriverTestSchemaManager(driver);
  await manager.setup();
});

setUp(() async {
  await connection.beginTransaction();
  await seedDriverTestGraph(manager, connection);
});

tearDown(() async {
  await connection.rollback();
});

tearDownAll(() async {
  await manager.teardown();
});
```

### Example 3: Selective Seeding

```dart
test('only users and posts', () async {
  await manager.seed(connection, [
    UserSeeder.new,
    PostSeeder.new,
  ]);
  
  // Only users and posts are seeded
});
```

### Example 4: Custom User Suffix

```dart
test('parallel-safe seeding', () async {
  final suffix = 'test_${DateTime.now().millisecondsSinceEpoch}';
  
  await manager.seed(connection, [
    (_) => UserSeeder(connection, suffix: suffix),
  ]);
  
  final users = await connection.repository<User>().findAll();
  expect(users.first.email, contains(suffix));
});
```

## Benefits

1. **Less Boilerplate**: Simpler setup/teardown code
2. **Better Abstraction**: No need to understand MigrationRunner internals
3. **Integrated Seeding**: First-class seeder support
4. **Debugging Tools**: Pretend mode, status inspection
5. **Consistency**: Same patterns across ormed ecosystem
6. **Driver Agnostic**: Works with any SchemaDriver implementation
7. **Flexible**: Multiple seeding strategies available
8. **Composable**: Seeders can call other seeders

## Files Modified

### Core Changes
- `lib/src/support/driver_schema.dart` - Refactored to use TestSchemaManager
- `lib/driver_tests.dart` - Added new exports

### New Files
- `lib/src/support/driver_test_seeders.dart` - Seeder classes
- `MIGRATION_GUIDE.md` - Migration documentation
- `TESTSCHEMA_MANAGER_UPDATE.md` - This file
- `example/using_test_schema_manager.dart` - Usage examples

## Documentation

Comprehensive documentation is provided:

1. **Migration Guide** (`MIGRATION_GUIDE.md`)
   - Step-by-step migration instructions
   - Before/after comparisons
   - Common scenarios
   - Troubleshooting

2. **Examples** (`example/using_test_schema_manager.dart`)
   - 10 complete working examples
   - Different seeding strategies
   - Transaction-based isolation
   - Pretend mode usage
   - Migration status inspection

3. **API Documentation**
   - Inline documentation in all new classes
   - Examples in doc comments

## Testing

All existing driver tests continue to work without modification. The new facilities are available as opt-in enhancements.

## Design Principles

The update follows these principles:

1. **Backward Compatible**: No breaking changes
2. **Driver Agnostic**: No driver-specific code
3. **No Redefinition**: Reuses ormed core classes
4. **Well Documented**: Comprehensive guides and examples
5. **Best Practices**: Follows established ormed patterns

## Future Enhancements

Potential future additions:

1. Parallel seeding for independent tables
2. Seeder dependency management
3. Snapshot-based schema restoration
4. Automatic conflict resolution for parallel tests
5. Enhanced debugging with query analytics

## Related Changes

This update is part of the broader effort to bring migration and seeding capabilities into the ormed core testing subsystem. See:

- `ormed/packages/ormed/TEST_SCHEMA_MANAGER_README.md` - Core implementation
- `ormed/packages/ormed/docs/testing_with_schema_manager.md` - Full guide

## Questions?

For help or questions:

1. Check `MIGRATION_GUIDE.md` for migration steps
2. Review examples in `example/` directory
3. Read the ormed testing documentation
4. Look at the TestSchemaManager source code

## Summary

The driver_tests package now leverages the powerful `TestSchemaManager` from ormed core, providing:

- ✅ Simpler schema management
- ✅ Integrated seeding with DatabaseSeeder classes
- ✅ Debugging tools (pretend mode, status inspection)
- ✅ Multiple seeding strategies
- ✅ Backward compatibility
- ✅ Comprehensive documentation
- ✅ Driver-agnostic design

All existing code continues to work, while new tests can adopt the improved pattern incrementally.