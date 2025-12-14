---
sidebar_position: 4
---

# DataSource

The `DataSource` class provides a modern, declarative API for configuring and using the ORM. It bundles driver configuration, entity registration, and connection management into a single interface.

## Overview

```dart
final ds = DataSource(DataSourceOptions(
  driver: SqliteDriverAdapter.file('app.sqlite'),
  entities: [UserOrmDefinition.definition, PostOrmDefinition.definition],
));

await ds.init();

// Use the ORM
final users = await ds.query<$User>().get();

await ds.dispose();
```

## DataSourceOptions

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `driver` | `DriverAdapter` | **required** | The database driver adapter |
| `entities` | `List<ModelDefinition>` | **required** | List of model definitions to register |
| `name` | `String` | `'default'` | Logical name for the connection |
| `database` | `String?` | `null` | Database/catalog identifier for observability |
| `tablePrefix` | `String` | `''` | Prefix applied to table names |
| `defaultSchema` | `String?` | `null` | Default schema for ad-hoc queries |
| `codecs` | `Map<String, ValueCodec>` | `{}` | Custom value codecs to register |
| `logging` | `bool` | `false` | Enable query logging |

### Example Configuration

```dart
final options = DataSourceOptions(
  driver: PostgresDriverAdapter(
    host: 'localhost',
    port: 5432,
    database: 'myapp',
    username: 'postgres',
    password: 'secret',
  ),
  entities: generatedOrmModelDefinitions, // From orm_registry.g.dart
  name: 'primary',
  database: 'myapp',
  tablePrefix: 'app_',
  defaultSchema: 'public',
  logging: true,
);
```

## Initialization

Always call `init()` before using the data source:

```dart
final ds = DataSource(options);
await ds.init();
```

The `init()` method:
- Is idempotent—calling it multiple times has no effect
- Automatically registers the DataSource with `ConnectionManager`
- Automatically sets it as default if it's the first DataSource initialized

## Using Static Model Helpers

Once initialized, the first DataSource automatically becomes the default:

```dart
final ds = DataSource(DataSourceOptions(
  name: 'myapp',
  driver: SqliteDriverAdapter.file('app.sqlite'),
  entities: generatedOrmModelDefinitions,
));

await ds.init(); // Auto-registers and sets as default

// Static helpers now work automatically!
final users = await User.query().get();
final post = await Post.find(1);
```

## Querying Data

Use `query<T>()` to create a typed query builder:

```dart
// Simple query
final allUsers = await ds.query<$User>().get();

// With filters
final activeUsers = await ds.query<$User>()
    .whereEquals('active', true)
    .orderBy('createdAt', descending: true)
    .limit(10)
    .get();

// With relations
final posts = await ds.query<$Post>()
    .with_(['author', 'comments'])
    .get();
```

## Repository Operations

Use `repo<T>()` for CRUD operations:

```dart
final userRepo = ds.repo<$User>();

// Insert
await userRepo.insert(
  $User(id: 0, email: 'new@example.com', name: 'New User'),
);

// Insert many
await userRepo.insertMany([user1, user2, user3]);

// Update
await userRepo.update(updatedUser);

// Delete
await userRepo.delete({'id': userId});
```

## Transactions

Execute multiple operations atomically:

```dart
await ds.transaction(() async {
  final user = await ds.repo<$User>().insert(
    $User(id: 0, email: 'alice@example.com', name: 'Alice'),
  );
  
  await ds.repo<$Post>().insert(
    $Post(id: 0, authorId: user.id, title: 'First Post'),
  );
  
  // If any operation fails, all changes are rolled back
});

// Transactions can return values
final result = await ds.transaction(() async {
  final user = await ds.repo<$User>().insert(newUser);
  return user;
});
```

## Ad-hoc Table Queries

Query tables without a model definition:

```dart
final logs = await ds.table('audit_logs')
    .whereEquals('action', 'login')
    .orderBy('timestamp', descending: true)
    .limit(100)
    .get();

for (final log in logs) {
  print('${log['user_id']} logged in at ${log['timestamp']}');
}
```

## Query Logging & Debugging

### Enable Logging

```dart
final ds = DataSource(DataSourceOptions(
  driver: driver,
  entities: entities,
  logging: true,
));

// Or enable at runtime
ds.enableQueryLog(includeParameters: true);
ds.disableQueryLog();
```

### Access Query Log

```dart
for (final entry in ds.queryLog) {
  print('SQL: ${entry.sql}');
  print('Bindings: ${entry.bindings}');
  print('Duration: ${entry.duration}');
}

ds.clearQueryLog();
```

### Pretend Mode

Preview SQL without executing:

```dart
final statements = await ds.pretend(() async {
  await ds.repo<$User>().insert(
    $User(id: 0, email: 'test@example.com'),
  );
});

for (final entry in statements) {
  print('Would execute: ${entry.sql}');
}
// No actual database changes occurred
```

### Execution Hooks

```dart
final unregister = ds.beforeExecuting((statement) {
  print('[SQL] ${statement.sqlWithBindings}');
});

// Later, unregister
unregister();
```

## Multiple DataSources

Create separate data sources for different databases:

```dart
final mainDs = DataSource(DataSourceOptions(
  name: 'main',
  driver: SqliteDriverAdapter.file('main.sqlite'),
  entities: generatedOrmModelDefinitions,
));

final analyticsDs = DataSource(DataSourceOptions(
  name: 'analytics',
  driver: SqliteDriverAdapter.file('analytics.sqlite'),
  entities: [EventOrmDefinition.definition],
));

await mainDs.init();
await analyticsDs.init();

// Set main as default
mainDs.setAsDefault();

// Query specific databases
final users = await mainDs.query<$User>().get();
final events = await analyticsDs.query<$Event>().get();

// Use static helpers with connection parameter
final analyticsUsers = await User.query(connection: 'analytics').get();
```

## Lifecycle Management

```dart
// Check initialization state
if (!ds.isInitialized) {
  await ds.init();
}

// Cleanup
await ds.dispose();

// Re-initialize if needed
await ds.init();
```

### Access Underlying Components

```dart
final conn = ds.connection;      // ORM connection
final ctx = ds.context;          // Query context
final registry = ds.registry;    // Model registry
final codecs = ds.codecRegistry; // Codec registry
```

## Custom Codecs

```dart
class JsonCodec extends ValueCodec<Map<String, dynamic>> {
  @override
  Object? encode(Map<String, dynamic>? value) => 
      value != null ? jsonEncode(value) : null;

  @override
  Map<String, dynamic>? decode(Object? value) =>
      value is String ? jsonDecode(value) : null;
}

final ds = DataSource(DataSourceOptions(
  driver: driver,
  entities: entities,
  codecs: {'JsonMap': JsonCodec()},
));
```
