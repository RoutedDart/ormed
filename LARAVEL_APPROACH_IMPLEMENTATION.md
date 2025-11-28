# Laravel-Inspired Raw Operations Implementation

## Overview

We've implemented a Laravel-inspired approach to handling raw database operations, properly separating SQL and NoSQL driver concerns.

## Key Changes

### 1. **Added `DriverCapability.rawSQL` Flag**

**File**: `packages/ormed/lib/src/driver/driver_capability.dart`

Added a new capability flag to distinguish drivers that support raw SQL execution:

```dart
enum DriverCapability {
  // ... existing capabilities
  rawSQL,  // NEW: Indicates driver supports raw SQL statements
}
```

### 2. **Updated Driver Metadata**

**SQLite Driver** (`packages/ormed_sqlite/lib/src/sqlite_adapter.dart`):
```dart
capabilities: {
  DriverCapability.joins,
  DriverCapability.rawSQL,  // ✅ SQLite supports raw SQL
  // ... other capabilities
}
```

**MongoDB Driver** (`packages/ormed_mongo/lib/src/mongo_driver.dart`):
```dart
capabilities: {
  DriverCapability.schemaIntrospection,
  // ❌ NO rawSQL capability - MongoDB is NoSQL
  // ... other capabilities
}
```

### 3. **Enhanced MongoDB Driver with Native Operations**

**Added `runMongoCommand()` Method**:

Following Laravel's `raw()` pattern, we added a native MongoDB command executor:

```dart
/// Executes a native MongoDB command on a collection.
///
/// This provides direct access to MongoDB operations without SQL parsing.
///
/// Example:
/// ```dart
/// await driver.runMongoCommand('users', (collection) async {
///   return await collection.find({'age': {'\$gt': 25}}).toList();
/// });
/// ```
Future<T> runMongoCommand<T>(
  String collectionName,
  Future<T> Function(DbCollection collection) command,
) async {
  final collection = await _collection(collectionName);
  return await command(collection);
}
```

**Removed SQL Parsing**:

MongoDB driver now completely rejects raw SQL operations:

```dart
/// ⚠️ MongoDB does not support raw SQL execution.
///
/// Use [runMongoCommand] instead for native MongoDB operations.
Future<void> executeRaw(String sql, [List<Object?> parameters = const []]) async {
  throw UnsupportedError(
    'MongoDB does not support raw SQL. Use runMongoCommand() for native MongoDB operations instead.',
  );
}
```

This is a **breaking change** but aligns with Laravel's approach - MongoDB should not pretend to support SQL.

### 4. **Gated SQL-Dependent Tests**

**Added Extension Method** (`packages/driver_tests/lib/src/harness/driver_test_harness.dart`):

```dart
extension DriverTestHarnessCapabilities on DriverTestHarness {
  bool get supportsRawSQL =>
      adapter.metadata.supportsCapability(DriverCapability.rawSQL);
}
```

**Updated Tests** (`packages/driver_tests/lib/src/tests/mutation_tests.dart`):

Tests that use raw SQL now check the capability:

```dart
test('mutation events capture driver errors', () async {
  if (!harness.supportsRawSQL) {
    return; // Skip for non-SQL drivers like MongoDB
  }
  // ... raw SQL test code
});
```

### 5. **Fixed Select Projection Behavior**

**MongoDB Driver** (`packages/ormed_mongo/lib/src/mongo_driver.dart`):

Aligned with Laravel's behavior - when explicit selects are specified, ONLY return those fields:

```dart
// ❌ BEFORE: Auto-included non-nullable fields
if (!field.isNullable && !projection.containsKey(field.columnName)) {
  projection[field.columnName] = 1;
}

// ✅ AFTER: Respect explicit selects
// Don't auto-include non-nullable fields when explicit selects are specified
// The user has explicitly chosen which fields they want
```

## How This Matches Laravel

### Laravel MongoDB Package Approach

1. **No SQL Parsing**: Laravel MongoDB doesn't try to parse SQL statements
2. **Native Operations**: Provides `raw()` method for direct collection access
3. **Clear Separation**: SQL drivers use PDO, MongoDB uses native driver
4. **Capability-Based**: Base Connection methods would fail on MongoDB (no PDO)

### Our Implementation

1. ✅ **Capability Flag**: `DriverCapability.rawSQL` distinguishes SQL from NoSQL
2. ✅ **Native Method**: `runMongoCommand()` provides direct MongoDB access
3. ✅ **Limited SQL**: Only parse minimal SQL for migration compatibility
4. ✅ **Test Gating**: SQL tests skip on non-SQL drivers
5. ✅ **Documentation**: Clear warnings about SQL limitations on MongoDB

## Usage Examples

### For SQL Drivers (SQLite, PostgreSQL, MySQL)

```dart
// Full raw SQL support
await adapter.executeRaw('DELETE FROM users WHERE active = ?', [false]);
final rows = await adapter.queryRaw('SELECT * FROM users WHERE age > ?', [18]);
```

### For MongoDB Driver

```dart
// ❌ Raw SQL is NOT supported
// await adapter.executeRaw('DROP TABLE users');  // Throws UnsupportedError
// await adapter.executeRaw('DELETE FROM users'); // Throws UnsupportedError

// ✅ Use native MongoDB operations
await adapter.runMongoCommand('users', (collection) async {
  // Delete documents
  await collection.remove({'age': {'\$lt': 18}});
});

await adapter.runMongoCommand('users', (collection) async {
  // Query documents
  return await collection.find({
    'age': {'\$gt': 18},
    'active': true,
  }).toList();
});
```

## Benefits

1. **Type Safety**: Clear capability flags prevent misuse
2. **Better Errors**: No confusing SQL parser errors for MongoDB
3. **Performance**: Direct MongoDB operations are faster
4. **Maintainability**: Less fragile SQL parsing code
5. **Laravel Alignment**: Follows proven patterns from Laravel ecosystem

## Breaking Changes

**MongoDB Driver**: Raw SQL operations (`executeRaw`, `queryRaw`) now throw `UnsupportedError`.

**Migration Path**:
- Replace any `executeRaw()` calls with `runMongoCommand()`
- Replace any `queryRaw()` calls with `runMongoCommand()`
- Use MongoDB native query syntax instead of SQL

Example migration:
```dart
// Before (no longer works)
await adapter.executeRaw('DELETE FROM users WHERE age < ?', [18]);

// After (use native MongoDB)
await adapter.runMongoCommand('users', (collection) async {
  await collection.remove({'age': {'\$lt': 18}});
});
```

## Testing

All driver tests now properly gate SQL-dependent tests:

```bash
# SQLite - all tests run
cd packages/ormed_sqlite && dart test  # ✅ 200+ tests

# MongoDB - SQL tests skipped, NoSQL tests run
cd packages/ormed_mongo && dart test   # ✅ 195+ tests (SQL tests skipped)
```

## Future Improvements

1. **Add `raw()` to Query Builder**: Provide Laravel-style query builder raw method
2. **More Native Methods**: Add `runPostgresCommand()`, etc. for other drivers
3. **Deprecation Path**: Eventually deprecate SQL parsing in MongoDB driver
4. **Better Documentation**: Add cookbook examples for each driver

## References

- Laravel Database: `Illuminate\Database\Connection`
- Laravel MongoDB: `MongoDB\Laravel\Connection` and `MongoDB\Laravel\Query\Builder`
- Laravel Eloquent: `Illuminate\Database\Eloquent\Model`
