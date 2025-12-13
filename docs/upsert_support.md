# Upsert Support in Ormed

This document describes the comprehensive upsert (INSERT or UPDATE) functionality available in Ormed, including native database support and automatic fallback emulation.

## Overview

Upsert operations allow you to insert a new record or update an existing one in a single operation. Ormed provides upsert support at multiple levels:

1. **Query Builder API** - High-level fluent interface
2. **Repository API** - Model-centric operations
3. **Driver Layer** - Native database support with automatic fallback

## Quick Start

### Basic Upsert

```dart
// Insert or update a user by email
final user = await context.query<User>().upsert(
  {
    'email': 'john@example.com',
    'name': 'John Doe',
    'age': 30,
  },
  uniqueBy: ['email'],
);
```

### Batch Upsert

```dart
// Upsert multiple records at once
final users = await context.query<User>().upsertMany([
  {'email': 'john@example.com', 'name': 'John Doe'},
  {'email': 'jane@example.com', 'name': 'Jane Smith'},
], uniqueBy: ['email']);
```

## Query Builder API

The Query Builder provides two main methods:

### `upsert()`

Upserts a single record.

```dart
Future<T> upsert(
  Map<String, dynamic> attributes, {
  List<String>? uniqueBy,
  List<String>? updateColumns,
})
```

**Parameters:**
- `attributes` - The data to insert or update
- `uniqueBy` - Optional list of field names that form the unique key (defaults to primary key)
- `updateColumns` - Optional list of columns to update on conflict (defaults to all non-unique columns)

**Example:**

```dart
final product = await context.query<Product>().upsert(
  {
    'sku': 'PROD-001',
    'name': 'Widget',
    'price': 29.99,
    'stock': 100,
  },
  uniqueBy: ['sku'],
  updateColumns: ['price', 'stock'], // Only update these fields
);
```

### `upsertMany()`

Upserts multiple records in a batch operation.

```dart
Future<List<T>> upsertMany(
  List<Map<String, dynamic>> records, {
  List<String>? uniqueBy,
  List<String>? updateColumns,
})
```

**Parameters:**
- `records` - List of attribute maps to upsert
- `uniqueBy` - Optional list of field names that form the unique key
- `updateColumns` - Optional list of columns to update on conflict

**Example:**

```dart
final products = await context.query<Product>().upsertMany([
  {'sku': 'PROD-001', 'name': 'Widget', 'price': 29.99},
  {'sku': 'PROD-002', 'name': 'Gadget', 'price': 49.99},
  {'sku': 'PROD-003', 'name': 'Doohickey', 'price': 19.99},
], uniqueBy: ['sku']);
```

## Repository API

The Repository layer provides similar functionality:

```dart
final repo = Repository<User>(
  definition: definition,
  driverName: adapter.metadata.name,
  codecs: codecRegistry,
  runMutation: context.runMutation,
  describeMutation: context.describeMutation,
  attachRuntimeMetadata: (_) {},
);

final users = await repo.upsertMany(
  [user1, user2, user3],
  uniqueBy: ['email'],
  updateColumns: ['name', 'age'],
  ,
);
```

**Repository Methods:**
- `upsertMany()` - Upserts multiple model instances
- Supports `JsonUpdateBuilder` for JSON field updates
- Returns hydrated models with database-generated values

## Native Database Support

Ormed uses native upsert capabilities when available:

### SQLite

```sql
INSERT INTO users (email, name, age) 
VALUES (?, ?, ?)
ON CONFLICT(email) DO UPDATE SET 
  name = excluded.name,
  age = excluded.age
```

**Features:**
- Uses `ON CONFLICT` clause
- Supports `DO UPDATE` and `DO NOTHING`
- Available in SQLite 3.24.0+

### PostgreSQL

```sql
INSERT INTO users (email, name, age)
VALUES ($1, $2, $3)
ON CONFLICT (email) DO UPDATE SET
  name = EXCLUDED.name,
  age = EXCLUDED.age
RETURNING *
```

**Features:**
- Uses `ON CONFLICT` clause with `EXCLUDED` pseudo-table
- Supports `RETURNING` clause for getting updated rows
- Can specify constraint names or column lists

### MySQL/MariaDB

```sql
INSERT INTO users (email, name, age)
VALUES (?, ?, ?)
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  age = VALUES(age)
```

**Features:**
- Uses `ON DUPLICATE KEY UPDATE` clause
- Works with any unique index or primary key
- Supports `VALUES()` function for referencing insert values

## Automatic Fallback Emulation

When native upsert is not available or not optimal, Ormed automatically falls back to emulation:

### Emulation Strategy

```dart
// 1. Try to find existing record
final existing = await query.where(uniqueConstraints).first();

if (existing != null) {
  // 2a. Update existing record
  await query.where(uniqueConstraints).update(values);
} else {
  // 2b. Insert new record
  await query.create(values);
}
```

**When Emulation is Used:**
- Complex composite unique keys
- Databases without native upsert support
- Fallback path when `_usesPrimaryKeyUpsert()` returns false

**Note:** Emulation is still safe when used within transactions.

## Driver Implementation

Each driver adapter implements upsert support:

### Core Methods

```dart
class DriverAdapter {
  Future<MutationResult> _runUpsert(MutationPlan plan) async {
    if (_usesPrimaryKeyUpsert(plan)) {
      // Use native SQL upsert
      final shape = _buildUpsertShape(plan);
      return _executeShape(shape);
    }
    // Fall back to manual emulation
    return _runManualUpsert(plan);
  }
  
  bool _usesPrimaryKeyUpsert(MutationPlan plan) {
    final pk = plan.definition.primaryKeyField?.columnName;
    return pk != null &&
        plan.upsertUniqueColumns.length == 1 &&
        plan.upsertUniqueColumns.first == pk;
  }
}
```

### Resolution Logic

The `_resolveUpsertUniqueColumns()` method determines which columns to use:

1. If `uniqueBy` is specified, use those columns
2. Otherwise, use the primary key
3. Throw error if neither is available

The `_resolveUpsertUpdateColumns()` method determines which columns to update:

1. If `updateColumns` is specified, use those columns
2. Otherwise, use all columns except the unique constraint columns
3. Validates that all specified columns exist in the insert data

## Performance Considerations

### Native Upsert (Best Performance)
- Single atomic database operation
- No network round trips
- Database handles conflict detection
- Transactional by nature

### Emulated Upsert (Good Performance)
- Two or three database operations (SELECT + INSERT/UPDATE)
- Additional network round trips
- Application-level conflict detection
- Should be wrapped in transaction for consistency

### Batch Operations

Always prefer `upsertMany()` over multiple `upsert()` calls:

```dart
// ✅ Good - Single batch operation
await query.upsertMany(records, uniqueBy: ['email']);

// ❌ Avoid - Multiple round trips
for (final record in records) {
  await query.upsert(record, uniqueBy: ['email']);
}
```

## Use Cases

### 1. User Profile Synchronization

```dart
// Sync user data from external API
final externalUsers = await fetchFromExternalAPI();
await context.query<User>().upsertMany(
  externalUsers.map((u) => u.toMap()).toList(),
  uniqueBy: ['externalId'],
  updateColumns: ['name', 'email', 'lastSynced'],
);
```

### 2. Inventory Management

```dart
// Update product stock levels
await context.query<Product>().upsertMany([
  {'sku': 'PROD-001', 'stock': 50, 'updatedAt': DateTime.now()},
  {'sku': 'PROD-002', 'stock': 75, 'updatedAt': DateTime.now()},
], uniqueBy: ['sku'], updateColumns: ['stock', 'updatedAt']);
```

### 3. Configuration Settings

```dart
// Save app settings
await context.query<Setting>().upsert(
  {'key': 'theme', 'value': 'dark'},
  uniqueBy: ['key'],
);
```

### 4. Time Series Data with Deduplication

```dart
// Insert metrics, updating if duplicate timestamp
await context.query<Metric>().upsert(
  {
    'deviceId': 'device-123',
    'timestamp': DateTime.now(),
    'temperature': 22.5,
    'humidity': 60,
  },
  uniqueBy: ['deviceId', 'timestamp'],
);
```

## Best Practices

### 1. Always Specify `uniqueBy` for Non-Primary Key Upserts

```dart
// ✅ Good - Explicit unique constraint
await query.upsert(data, uniqueBy: ['email']);

// ⚠️ Ambiguous - Will use primary key by default
await query.upsert(data);
```

### 2. Use `updateColumns` to Prevent Unintended Updates

```dart
// ✅ Good - Only update specific fields
await query.upsert(
  data,
  uniqueBy: ['email'],
  updateColumns: ['name', 'age'], // Don't update createdAt, etc.
);
```

### 3. Batch When Possible

```dart
// ✅ Good - Single batch operation
await query.upsertMany(records, uniqueBy: ['email']);

// ❌ Bad - Multiple operations
for (final record in records) {
  await query.upsert(record, uniqueBy: ['email']);
}
```

### 4. Handle Timestamps Appropriately

```dart
// ✅ Good - Set updatedAt on every upsert
await query.upsert(
  {...data, 'updatedAt': DateTime.now()},
  uniqueBy: ['email'],
);
```

### 5. Use Transactions for Complex Operations

```dart
await context.transaction((txn) async {
  // Multiple related upserts in a transaction
  await txn.query<User>().upsert(userData, uniqueBy: ['email']);
  await txn.query<Profile>().upsert(profileData, uniqueBy: ['userId']);
});
```

## Comparison with Other Methods

### vs. `updateOrCreate()`

- `updateOrCreate()` - Queries first, then creates/updates (2 operations)
- `upsert()` - Single atomic operation (better performance)

```dart
// updateOrCreate - Uses SELECT + INSERT/UPDATE
final user = await query.updateOrCreate(
  {'email': 'john@example.com'},
  {'name': 'John Doe'},
);

// upsert - Single operation (when native support available)
final user = await query.upsert(
  {'email': 'john@example.com', 'name': 'John Doe'},
  uniqueBy: ['email'],
);
```

### vs. `insertOrIgnore()`

- `insertOrIgnore()` - Inserts or does nothing (no updates)
- `upsert()` - Inserts or updates

```dart
// insertOrIgnore - Only inserts, ignores conflicts
await repo.insertOrIgnore(model);

// upsert - Inserts or updates on conflict
await repo.upsertMany([model], uniqueBy: ['email']);
```

## Troubleshooting

### Error: "Upserts require a primary key or uniqueBy columns"

**Cause:** The model doesn't have a primary key and `uniqueBy` wasn't specified.

**Solution:** Either add a primary key to your model or specify `uniqueBy`:

```dart
await query.upsert(data, uniqueBy: ['email']);
```

### Error: "Unknown upsert update column"

**Cause:** A column specified in `updateColumns` doesn't exist in the data.

**Solution:** Ensure all `updateColumns` are present in the attributes:

```dart
await query.upsert(
  {'email': 'john@example.com', 'name': 'John', 'age': 30},
  uniqueBy: ['email'],
  updateColumns: ['name', 'age'], // Both must be in attributes
);
```

### Unexpected Behavior: Records Not Updating

**Cause:** The unique constraint doesn't match any existing records.

**Solution:** Verify the unique constraint columns are correct:

```dart
// Wrong - 'username' might not be unique
await query.upsert(data, uniqueBy: ['username']);

// Correct - 'email' is the unique field
await query.upsert(data, uniqueBy: ['email']);
```

## Testing

### Testing with In-Memory Database

```dart
test('upsert creates and updates records', () async {
  final adapter = SqliteDriverAdapter.inMemory();
  final context = QueryContext(driver: adapter);
  
  // Setup schema
  await adapter.execute('CREATE TABLE users (...)');
  
  // Test insert
  final user1 = await context.query<User>().upsert(
    {'email': 'test@example.com', 'name': 'Test User'},
    uniqueBy: ['email'],
  );
  expect(user1.name, 'Test User');
  
  // Test update
  final user2 = await context.query<User>().upsert(
    {'email': 'test@example.com', 'name': 'Updated User'},
    uniqueBy: ['email'],
  );
  expect(user2.name, 'Updated User');
  
  // Verify only one record exists
  final all = await context.query<User>().get();
  expect(all.length, 1);
  
  await adapter.close();
});
```

## Future Enhancements

Potential future improvements to upsert support:

1. **Conditional Upserts** - Only update if certain conditions are met
2. **Partial Updates** - Update only fields that have changed
3. **Conflict Resolution Strategies** - Custom logic for handling conflicts
4. **Optimistic Locking** - Version-based conflict detection
5. **Audit Logging** - Track what was inserted vs updated

## See Also

- [Query Builder CRUD Operations](./query_builder.md)
- [Repository Pattern](./repository.md)
- [Driver Architecture](./drivers.md)
- [Transactions](./transactions.md)