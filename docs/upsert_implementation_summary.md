# Upsert Implementation Summary

This document summarizes the comprehensive upsert support that has been added to Ormed.

## Overview

Upsert (INSERT or UPDATE) functionality has been implemented across all layers of the ORM:
- Query Builder API
- Repository API  
- Driver adapters (SQLite, PostgreSQL, MySQL)
- Comprehensive test coverage

## What Was Added

### 1. Query Builder Methods (`packages/ormed/lib/src/query/builder/crud.dart`)

Added two new public methods to the `CrudExtension`:

#### `upsert()`
```dart
Future<T> upsert(
  Map<String, dynamic> attributes, {
  List<String>? uniqueBy,
  List<String>? updateColumns,
})
```
Upserts a single record. If a record with the same unique key exists, it will be updated; otherwise, a new record is inserted.

#### `upsertMany()`
```dart
Future<List<T>> upsertMany(
  List<Map<String, dynamic>> records, {
  List<String>? uniqueBy,
  List<String>? updateColumns,
})
```
Batch upsert operation for multiple records.

#### Helper Method
```dart
Repository<T> _buildRepository()
```
Internal helper to construct Repository instances for the query builder.

### 2. Native Database Support

All three SQL drivers already had native upsert support implemented:

#### SQLite (`packages/ormed_sqlite/lib/src/sqlite_adapter.dart`)
- Uses `INSERT ... ON CONFLICT(...) DO UPDATE` syntax
- Method: `_buildUpsertShape()` at line 1130
- Supports both native and emulated paths

#### PostgreSQL
- Uses `INSERT ... ON CONFLICT(...) DO UPDATE` with `EXCLUDED` pseudo-table
- Supports `RETURNING` clause for retrieving updated rows
- Already implemented in postgres adapter

#### MySQL/MariaDB  
- Uses `INSERT ... ON DUPLICATE KEY UPDATE` syntax
- Works with any unique index or primary key
- Already implemented in mysql adapter

### 3. Automatic Fallback Emulation

Each driver implements intelligent fallback:

```dart
bool _usesPrimaryKeyUpsert(MutationPlan plan) {
  final pk = plan.definition.primaryKeyField?.columnName;
  return pk != null &&
      plan.upsertUniqueColumns.length == 1 &&
      plan.upsertUniqueColumns.first == pk;
}

Future<MutationResult> _runManualUpsert(MutationPlan plan) async {
  // Falls back to SELECT + INSERT/UPDATE pattern
  // when native upsert is not optimal
}
```

**When emulation is used:**
- Complex composite unique keys
- Multi-column unique constraints on some databases
- Fallback ensures consistency across all scenarios

### 4. Test Coverage

#### Query Builder Tests (`packages/driver_tests/lib/src/tests/query_builder/upsert_operations_tests.dart`)

New test file with 20+ comprehensive tests:
- Basic upsert inserts and updates
- Custom `uniqueBy` column specification
- Selective `updateColumns` updates
- Batch upsert operations
- Mix of inserts and updates
- Large batch handling (50+ records)
- Data integrity verification
- Edge cases and validation
- Cross-model tests (User, Post, Author)

#### Repository Tests (`packages/driver_tests/lib/src/tests/repository_tests.dart`)

Enhanced existing upsert test group with 10+ new tests:
- Insert new records via upsert
- Update existing records  
- Custom `uniqueBy` handling
- Restricted `updateColumns`
- Mixed insert/update batches
- Large batch operations (10+ records)
- Data integrity across multiple operations
- Tests with and without `returning` parameter

### 5. Documentation

#### Example Code (`examples/upsert/upsert_example.dart`)
Comprehensive example demonstrating:
- Basic upsert operations
- Custom unique keys
- Selective column updates
- Batch operations
- Repository API usage
- Native vs emulated behavior notes

#### Comprehensive Guide (`docs/upsert_support.md`)
500+ line documentation covering:
- Quick start examples
- API reference for both Query Builder and Repository
- Native database support details for each driver
- Emulation strategy explanation
- Performance considerations
- Use cases and best practices
- Comparison with other methods
- Troubleshooting guide
- Testing examples

#### Implementation Summary (`docs/upsert_implementation_summary.md`)
This document - complete overview of all changes.

## Key Features

### 1. Flexible Unique Key Specification
```dart
// Use primary key (default)
await query.upsert(data);

// Use custom unique column(s)
await query.upsert(data, uniqueBy: ['email']);

// Composite unique key
await query.upsert(data, uniqueBy: ['email', 'tenant_id']);
```

### 2. Selective Column Updates
```dart
// Update only specific columns on conflict
await query.upsert(
  data,
  uniqueBy: ['email'],
  updateColumns: ['name', 'age'], // Don't update createdAt, etc.
);
```

### 3. Batch Operations
```dart
// Efficient batch upsert
final users = await query.upsertMany(records, uniqueBy: ['email']);
```

### 4. Automatic Strategy Selection

The drivers automatically choose the best strategy:

**Native Upsert (Preferred):**
- Single atomic database operation
- Better performance
- No race conditions
- Used when database supports it

**Emulated Upsert (Fallback):**
- SELECT + INSERT/UPDATE pattern
- Additional network round trips
- Still safe within transactions
- Used when native not available

## Usage Examples

### Basic Insert or Update
```dart
final user = await context.query<User>().upsert({
  'email': 'john@example.com',
  'name': 'John Doe',
  'age': 30,
}, uniqueBy: ['email']);
```

### Batch Synchronization
```dart
// Sync users from external API
final externalUsers = await fetchFromAPI();
await context.query<User>().upsertMany(
  externalUsers,
  uniqueBy: ['externalId'],
  updateColumns: ['name', 'email', 'lastSynced'],
);
```

### Inventory Management
```dart
await context.query<Product>().upsertMany([
  {'sku': 'PROD-001', 'stock': 50},
  {'sku': 'PROD-002', 'stock': 75},
], uniqueBy: ['sku'], updateColumns: ['stock']);
```

### Configuration Settings
```dart
await context.query<Setting>().upsert(
  {'key': 'theme', 'value': 'dark'},
  uniqueBy: ['key'],
);
```

## Architecture

### Data Flow

```
Query Builder (upsert/upsertMany)
    ↓
Repository (buildUpsertPlan)
    ↓
MutationPlan (with upsertUniqueColumns, upsertUpdateColumns)
    ↓
Driver Adapter (_runUpsert)
    ↓
    ├─→ Native Path (_buildUpsertShape) [PREFERRED]
    │   └─→ Single SQL statement with conflict handling
    │
    └─→ Emulated Path (_runManualUpsert) [FALLBACK]
        └─→ SELECT + INSERT/UPDATE pattern
```

### Resolution Logic

**Unique Columns:**
1. Use `uniqueBy` if specified
2. Otherwise, use primary key
3. Throw error if neither available

**Update Columns:**
1. Use `updateColumns` if specified
2. Otherwise, use all columns except unique constraint columns
3. Validate specified columns exist

## Testing

All tests pass across SQLite, PostgreSQL, and MySQL drivers:

```bash
# Run all driver tests
dart test packages/driver_tests/test/

# Run specific upsert tests
dart test packages/driver_tests/test/ -n "Upsert"
```

## Performance

### Native Upsert
- ✅ Single database round trip
- ✅ Atomic operation
- ✅ Database-level conflict detection
- ✅ Best performance

### Emulated Upsert
- ⚠️ Multiple database round trips (SELECT + INSERT/UPDATE)
- ⚠️ Application-level conflict detection
- ✅ Still safe with transactions
- ⚠️ Slightly slower but still good

### Batch Operations
Always prefer batch over loops:

```dart
// ✅ Good - Single batch operation
await query.upsertMany(records, uniqueBy: ['email']);

// ❌ Bad - Multiple round trips
for (final record in records) {
  await query.upsert(record, uniqueBy: ['email']);
}
```

## Compatibility

### Database Support Matrix

| Database   | Native Support | Syntax                          | Returning |
|------------|----------------|---------------------------------|-----------|
| SQLite     | ✅ Yes         | ON CONFLICT ... DO UPDATE       | ✅ Yes    |
| PostgreSQL | ✅ Yes         | ON CONFLICT ... DO UPDATE       | ✅ Yes    |
| MySQL      | ✅ Yes         | ON DUPLICATE KEY UPDATE         | ⚠️ Limited|
| MariaDB    | ✅ Yes         | ON DUPLICATE KEY UPDATE         | ⚠️ Limited|

All databases support emulated fallback when needed.

## Migration Notes

If you were previously using `updateOrCreate()` or manual insert/update patterns, you can now use `upsert()`:

### Before
```dart
final existing = await query.where('email', email).first();
if (existing != null) {
  await query.where('id', existing.id).update(data);
  return await query.find(existing.id);
} else {
  return await query.create(data);
}
```

### After
```dart
return await query.upsert(data, uniqueBy: ['email']);
```

Benefits:
- Simpler code
- Single atomic operation (when native)
- No race conditions
- Better performance

## Future Enhancements

Potential improvements:
1. **Conditional Upserts** - Only update if conditions met
2. **Partial Updates** - Update only changed fields
3. **Conflict Resolution Strategies** - Custom conflict handling
4. **Optimistic Locking** - Version-based updates
5. **Audit Logging** - Track insert vs update operations

## Related Files

### Implementation
- `packages/ormed/lib/src/query/builder/crud.dart` - Query builder methods
- `packages/ormed/lib/src/repository/repository_upsert_mixin.dart` - Repository methods
- `packages/ormed/lib/src/repository/repository_helpers_mixin.dart` - Plan building
- `packages/ormed/lib/src/driver/mutation_plan.dart` - MutationPlan support
- `packages/ormed_sqlite/lib/src/sqlite_adapter.dart` - SQLite implementation
- Similar files in `ormed_postgres` and `ormed_mysql` packages

### Tests
- `packages/driver_tests/lib/src/tests/query_builder/upsert_operations_tests.dart` - New query builder tests
- `packages/driver_tests/lib/src/tests/repository_tests.dart` - Enhanced repository tests
- `packages/driver_tests/lib/src/tests/query_builder_tests.dart` - Test registration

### Documentation
- `examples/upsert/upsert_example.dart` - Working example code
- `docs/upsert_support.md` - Comprehensive guide
- `docs/upsert_implementation_summary.md` - This document

## Conclusion

Upsert support is now fully implemented across Ormed with:
- ✅ Intuitive Query Builder and Repository APIs
- ✅ Native database support for all major SQL databases
- ✅ Automatic fallback emulation when needed
- ✅ Comprehensive test coverage (30+ tests)
- ✅ Complete documentation and examples
- ✅ Production-ready performance

The implementation follows Laravel's approach while adapting to Dart's type system and Ormed's architecture. Users can now perform efficient insert-or-update operations with confidence across all supported databases.