---
sidebar_position: 1
---

# Query Builder

The Query Builder provides a fluent, type-safe API for building database queries.

## Getting Started

Access the query builder through a `DataSource`:

```dart
final users = await dataSource.query<$User>().get();
```

## Selecting Data

### Get All Records

```dart
final users = await dataSource.query<$User>().get();
```

### Select Specific Columns

```dart
final users = await dataSource.query<$User>()
    .select(['id', 'email', 'name'])
    .get();
```

### First Record

```dart
// Returns null if not found
final user = await dataSource.query<$User>().first();

// Throws if not found
final user = await dataSource.query<$User>().firstOrFail();
```

### Find by Primary Key

```dart
final user = await dataSource.query<$User>().find(1);
final user = await dataSource.query<$User>().findOrFail(1);
```

## Where Clauses

### Basic Where

```dart
// Equals
final users = await dataSource.query<$User>()
    .whereEquals('active', true)
    .get();

// Not equals
final users = await dataSource.query<$User>()
    .whereNotEquals('status', 'banned')
    .get();
```

### Comparison Operators

```dart
final users = await dataSource.query<$User>()
    .where('age', '>', 18)
    .where('age', '<=', 65)
    .get();
```

### In / Not In

```dart
final users = await dataSource.query<$User>()
    .whereIn('role', ['admin', 'moderator'])
    .get();

final users = await dataSource.query<$User>()
    .whereNotIn('status', ['banned', 'suspended'])
    .get();
```

### Null Checks

```dart
final users = await dataSource.query<$User>()
    .whereNull('deleted_at')
    .get();

final users = await dataSource.query<$User>()
    .whereNotNull('verified_at')
    .get();
```

### Between

```dart
final users = await dataSource.query<$User>()
    .whereBetween('age', 18, 65)
    .get();
```

### Like / Contains

```dart
final users = await dataSource.query<$User>()
    .whereLike('email', '%@example.com')
    .get();
```

### Or Where

```dart
final users = await dataSource.query<$User>()
    .whereEquals('role', 'admin')
    .orWhere('role', '=', 'moderator')
    .get();
```

### Grouped Conditions

```dart
final users = await dataSource.query<$User>()
    .where('active', '=', true)
    .whereGroup((q) => q
        .where('role', '=', 'admin')
        .orWhere('role', '=', 'moderator'))
    .get();

// SQL: WHERE active = 1 AND (role = 'admin' OR role = 'moderator')
```

## Ordering

```dart
// Ascending (default)
final users = await dataSource.query<$User>()
    .orderBy('name')
    .get();

// Descending
final users = await dataSource.query<$User>()
    .orderBy('created_at', descending: true)
    .get();

// Multiple columns
final users = await dataSource.query<$User>()
    .orderBy('role')
    .orderBy('name')
    .get();
```

## Limiting & Pagination

```dart
// Limit
final users = await dataSource.query<$User>()
    .limit(10)
    .get();

// Offset
final users = await dataSource.query<$User>()
    .limit(10)
    .offset(20)
    .get();

// Paginate
final page = await dataSource.query<$User>()
    .paginate(page: 2, perPage: 15);

print(page.data);        // List<$User>
print(page.currentPage); // 2
print(page.lastPage);    // Total pages
print(page.total);       // Total records
```

## Aggregates

```dart
final count = await dataSource.query<$User>().count();
final sum = await dataSource.query<$User>().sum('balance');
final avg = await dataSource.query<$User>().avg('age');
final max = await dataSource.query<$User>().max('score');
final min = await dataSource.query<$User>().min('score');

// Exists check
final hasAdmins = await dataSource.query<$User>()
    .whereEquals('role', 'admin')
    .exists();
```

## Distinct

```dart
final roles = await dataSource.query<$User>()
    .distinct()
    .select(['role'])
    .get();
```

## Eager Loading Relations

```dart
// Load a single relation
final posts = await dataSource.query<$Post>()
    .with_(['author'])
    .get();

// Load multiple relations
final posts = await dataSource.query<$Post>()
    .with_(['author', 'tags', 'comments'])
    .get();

// Nested relations
final posts = await dataSource.query<$Post>()
    .with_(['author.profile', 'comments.user'])
    .get();
```

## Raw Expressions

When you need database-specific functionality:

```dart
final users = await dataSource.query<$User>()
    .whereRaw("LOWER(email) = ?", ['john@example.com'])
    .get();

final users = await dataSource.query<$User>()
    .selectRaw("*, CONCAT(first_name, ' ', last_name) AS full_name")
    .get();
```

## Partial Projections

Get partial entities with only selected columns:

```dart
final partial = await dataSource.query<$User>()
    .select(['id', 'email'])
    .firstPartial();

print(partial?.id);    // Available
print(partial?.email); // Available
// partial?.name is not available (not selected)
```

## Soft Delete Scopes

For models with soft deletes:

```dart
// Default: excludes soft-deleted
final posts = await dataSource.query<$Post>().get();

// Include soft-deleted
final allPosts = await dataSource.query<$Post>()
    .withTrashed()
    .get();

// Only soft-deleted
final trashedPosts = await dataSource.query<$Post>()
    .onlyTrashed()
    .get();
```

## Query Caching

Cache query results for improved performance:

```dart
// Cache for 5 minutes
final users = await dataSource.query<$User>()
    .remember(Duration(minutes: 5))
    .get();

// Cache forever (until manually cleared)
final settings = await dataSource.query<$Setting>()
    .rememberForever()
    .get();

// Disable caching for specific query
final freshData = await dataSource.query<$User>()
    .dontRemember()
    .get();

// Clear query cache
await dataSource.flushQueryCache();
```
