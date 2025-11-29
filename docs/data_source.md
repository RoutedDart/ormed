# DataSource

The `DataSource` class provides a modern, declarative API for configuring and using the ORM. It simplifies the setup process by bundling driver configuration, entity registration, and connection management into a single, easy-to-use interface.

## Overview

`DataSource` is inspired by TypeORM's DataSource pattern, providing a clean and intuitive way to bootstrap your ORM:

```dart
final ds = DataSource(DataSourceOptions(
  driver: SqliteDriverAdapter.file('app.sqlite'),
  entities: [UserOrmDefinition.definition, PostOrmDefinition.definition],
));

await ds.init();

// Use the ORM
final users = await ds.query<User>().get();

await ds.dispose();
```

## DataSourceOptions

The `DataSourceOptions` class configures all aspects of your data source:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `driver` | `DriverAdapter` | **required** | The database driver adapter |
| `entities` | `List<ModelDefinition>` | **required** | List of model definitions to register |
| `name` | `String` | `'default'` | Logical name for the connection |
| `database` | `String?` | `null` | Database/catalog identifier for observability |
| `tablePrefix` | `String` | `''` | Prefix applied to table names |
| `defaultSchema` | `String?` | `null` | Default schema for ad-hoc queries |
| `codecs` | `Map<String, ValueCodec>` | `{}` | Custom value codecs to register |
| `synchronize` | `bool` | `false` | Auto-sync schema (not for production) |
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
  entities: [
    UserOrmDefinition.definition,
    PostOrmDefinition.definition,
    CommentOrmDefinition.definition,
  ],
  name: 'primary',
  database: 'myapp',
  tablePrefix: 'app_',
  defaultSchema: 'public',
  logging: true,
);
```

## Basic Usage

### Initialization

Always call `init()` before using the data source:

```dart
final ds = DataSource(options);
await ds.init(); // Automatically registers with ConnectionManager

// Now safe to use
```

The `init()` method:
- Is idempotent—calling it multiple times has no effect after the first successful initialization
- **Automatically registers** the DataSource with `ConnectionManager`
- **Automatically sets it as default** if it's the first DataSource initialized

### Using Static Model Helpers

Once initialized, the first DataSource automatically becomes the default, enabling static helpers:

```dart
final ds = DataSource(DataSourceOptions(
  name: 'myapp', // Can be any name
  driver: SqliteDriverAdapter.file('app.sqlite'),
  entities: [UserOrmDefinition.definition, PostOrmDefinition.definition],
));

await ds.init(); // Auto-registers and sets as default

// Static helpers now work automatically!
final users = await User.query().get();
final post = await Post.find(1);
```

**For multiple DataSources**, explicitly set your preferred default:

```dart
final primary = DataSource(DataSourceOptions(name: 'primary', ...));
final analytics = DataSource(DataSourceOptions(name: 'analytics', ...));

await primary.init();    // Becomes default (first initialized)
await analytics.init();  // Also registered

// To change default:
analytics.setAsDefault(); // Now User.query() uses analytics

// Or query specific DataSource:
final primaryUsers = await User.query(connection: 'primary').get();
```

This eliminates the need for manual binding or passing contexts around.
- No manual binding has been set up

You can also retrieve the default data source later:

```dart
final ds = DataSource.getDefault();
if (ds != null) {
  // Use the default data source
}
```

### Querying Data

Use `query<T>()` to create a typed query builder:

```dart
// Simple query
final allUsers = await ds.query<User>().get();

// With filters
final activeUsers = await ds.query<User>()
    .whereEquals('active', true)
    .orderBy('createdAt', descending: true)
    .limit(10)
    .get();

// With relations
final posts = await ds.query<Post>()
    .withRelation('author')
    .withRelation('comments')
    .get();
```

### Repository Operations

Use `repo<T>()` for CRUD operations:

```dart
final userRepo = ds.repo<User>();

// Insert
await userRepo.insert(
  const User(email: 'new@example.com', name: 'New User'),
);

// Insert many
await userRepo.insertMany([user1, user2, user3]);

// Update
await userRepo.updateMany([updatedUser]);

// Delete
await userRepo.deleteByKeys([{'id': userId}]);
```

### Transactions

Execute multiple operations atomically:

```dart
await ds.transaction(() async {
  final user = await ds.repo<User>().insert(
    const User(email: 'alice@example.com', name: 'Alice'),
  );
  
  await ds.repo<Post>().insert(
    Post(authorId: user.id, title: 'First Post'),
  );
  
  // If any operation fails, all changes are rolled back
});
```

Transactions return values:

```dart
final result = await ds.transaction(() async {
  final user = await ds.repo<User>().insert(newUser);
  await ds.repo<Profile>().insert(Profile(userId: user.id));
  return user;
});

print('Created user: ${result.id}');
```

### Ad-hoc Table Queries

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

Enable logging at initialization:

```dart
final ds = DataSource(DataSourceOptions(
  driver: driver,
  entities: entities,
  logging: true,  // Enables query logging
));
```

Or enable/disable at runtime:

```dart
ds.enableQueryLog(includeParameters: true);

// ... perform queries ...

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
  await ds.repo<User>().insert(
    const User(email: 'test@example.com'),
  );
});

for (final entry in statements) {
  print('Would execute: ${entry.sql}');
}

// No actual database changes occurred
```

### Execution Hooks

Intercept every SQL statement:

```dart
final unregister = ds.beforeExecuting((statement) {
  print('[SQL] ${statement.sqlWithBindings}');
});

// ... use the ORM ...

// Later, unregister if needed
unregister();
```

## Multi-Tenant / Multi-Database

Create separate data sources for different databases:

```dart
// Main database
final mainDs = DataSource(DataSourceOptions(
  name: 'main',
  driver: SqliteDriverAdapter.file('main.sqlite'),
  entities: [UserOrmDefinition.definition, PostOrmDefinition.definition],
));

// Analytics database
final analyticsDs = DataSource(DataSourceOptions(
  name: 'analytics',
  driver: SqliteDriverAdapter.file('analytics.sqlite'),
  entities: [EventOrmDefinition.definition, MetricOrmDefinition.definition],
));

await mainDs.init();
await analyticsDs.init();

// Set main as default for convenience
mainDs.setAsDefault();

// Query specific databases
final users = await mainDs.query<User>().get();
final events = await analyticsDs.query<Event>().get();

// Use static helpers (routes to 'main' via default)
final allUsers = await User.query().get();

// Or explicitly specify a connection
final analyticsUsers = await User.query(connection: 'analytics').get();

// Cleanup
await mainDs.dispose();
await analyticsDs.dispose();
```

### Named Connections with Static Helpers

Static model helpers support the `connection` parameter to target specific data sources:

```dart
// Setup multiple data sources
final primary = DataSource(DataSourceOptions(
  name: 'primary',
  driver: SqliteDriverAdapter.file('primary.sqlite'),
  entities: [UserOrmDefinition.definition],
));

final replica = DataSource(DataSourceOptions(
  name: 'replica',
  driver: SqliteDriverAdapter.file('replica.sqlite'),
  entities: [UserOrmDefinition.definition],
));

await primary.init();
await replica.init();
primary.setAsDefault();

// Uses 'primary' (default)
final user1 = await User.find(1);

// Explicitly use 'replica'
final user2 = await User.find(1, connection: 'replica');

// Query builder also supports connection parameter
final users = await User.query(connection: 'replica')
    .whereEquals('active', true)
    .get();
```

### Integration with ConnectionManager

Register data sources with `ConnectionManager` for centralized access:

```dart
final ds = DataSource(DataSourceOptions(
  name: 'myapp',
  driver: SqliteDriverAdapter.file('app.sqlite'),
  entities: [UserOrmDefinition.definition],
));
await ds.init();

ConnectionManager.defaultManager.registerDataSource(ds);

// Later, retrieve by name
final connection = ConnectionManager.defaultManager.connection('myapp');

// Or use static helpers that automatically resolve connections
final users = await User.query().get(); // Uses default connection
final user = await User.find(1, connection: 'myapp'); // Uses named connection
```

## Lifecycle Management

### Initialization State

Check if a data source is ready:

```dart
if (!ds.isInitialized) {
  await ds.init();
}
```

### Cleanup

Always dispose when done:

```dart
await ds.dispose();
```

After disposal, the data source can be re-initialized if needed:

```dart
await ds.dispose();
// ... later ...
await ds.init();  // Works again
```

### Access Underlying Components

For advanced use cases, access the underlying ORM components:

```dart
// Underlying ORM connection
final conn = ds.connection;

// Query context
final ctx = ds.context;

// Model registry
final registry = ds.registry;

// Codec registry
final codecs = ds.codecRegistry;
```

## Custom Codecs

Register custom value codecs for type conversion:

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
  codecs: {
    'JsonMap': JsonCodec(),
  },
));
```

## Complete Example

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

Future<void> main() async {
  // 1. Configure the data source
  final ds = DataSource(DataSourceOptions(
    driver: SqliteDriverAdapter.file('blog.sqlite'),
    entities: [
      UserOrmDefinition.definition,
      PostOrmDefinition.definition,
      CommentOrmDefinition.definition,
    ],
    name: 'blog',
    logging: true,
  ));

  // 2. Initialize
  await ds.init();

  try {
    // 3. Create a user
    await ds.repo<User>().insert(
      const User(email: 'author@example.com', name: 'Alice'),
    );

    // 4. Create a post with a transaction
    await ds.transaction(() async {
      final author = await ds.query<User>()
          .whereEquals('email', 'author@example.com')
          .firstOrFail();

      await ds.repo<Post>().insert(
        Post(
          authorId: author.id,
          title: 'My First Post',
          body: 'Hello, world!',
        ),
      );
    });

    // 5. Query with relations
    final posts = await ds.query<Post>()
        .withRelation('author')
        .orderBy('createdAt', descending: true)
        .get();

    for (final post in posts) {
      print('${post.title} by ${post.author?.name}');
    }

    // 6. Print query log
    print('\nExecuted queries:');
    for (final entry in ds.queryLog) {
      print('- ${entry.sql}');
    }
  } finally {
    // 7. Cleanup
    await ds.dispose();
  }
}
```

## Migration from Manual Setup

If you're currently using manual setup with `ModelRegistry` and `QueryContext`, migrating to `DataSource` is straightforward:

**Before:**
```dart
final registry = ModelRegistry()
  ..register(UserOrmDefinition.definition)
  ..register(PostOrmDefinition.definition);

final adapter = SqliteDriverAdapter.file('app.sqlite');
final context = QueryContext(registry: registry, driver: adapter);

final users = await context.query<User>().get();
```

**After:**
```dart
final ds = DataSource(DataSourceOptions(
  driver: SqliteDriverAdapter.file('app.sqlite'),
  entities: [UserOrmDefinition.definition, PostOrmDefinition.definition],
));
await ds.init();

final users = await ds.query<User>().get();
```

The `DataSource` handles registry creation, codec setup, and connection configuration internally, reducing boilerplate and potential misconfiguration.