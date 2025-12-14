---
sidebar_position: 4
---

# Multi-Database Support

Ormed supports connecting to multiple databases simultaneously for read replicas, tenant databases, or different database systems.

## Configuring Multiple Connections

### Define Multiple DataSources

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:ormed_postgres/ormed_postgres.dart';

Future<void> setupConnections() async {
  // Primary database (SQLite)
  final primary = DataSource(DataSourceOptions(
    name: 'primary',
    driver: SqliteDriverAdapter.file('app.sqlite'),
    entities: [UserOrmDefinition.definition, PostOrmDefinition.definition],
  ));
  await primary.init();

  // Analytics database (PostgreSQL)
  final analytics = DataSource(DataSourceOptions(
    name: 'analytics',
    driver: PostgresDriverAdapter(
      host: 'analytics.example.com',
      port: 5432,
      database: 'analytics_db',
      username: 'user',
      password: 'pass',
    ),
    entities: [AnalyticsEventOrmDefinition.definition],
  ));
  await analytics.init();

  // First initialized DataSource becomes default automatically
  // Or explicitly set default
  ConnectionManager.instance.setDefaultConnection('primary');
}
```

## Using Named Connections

### Specify Connection on Queries

```dart
// Use default connection
final users = await User.all();

// Use specific connection
final events = await AnalyticsEvent.all(connection: 'analytics');

// Query with connection
final pageViews = await AnalyticsEvent.query(connection: 'analytics')
    .whereEquals('type', 'page_view')
    .get();
```

### Using Connection in Relationships

```dart
// Load relations from same connection as parent
final user = await User.query(connection: 'primary')
    .with_(['posts'])
    .first();

// Load relations from different connection
final post = await Post.find(1);
await post.load(['analytics'], connection: 'analytics');
```

## Transaction Caveat

Transactions cannot span multiple databases:

```dart
// ✅ This works - single database transaction
final primaryDs = ConnectionManager.instance.getConnection('primary');
await primaryDs.transaction(() async {
  final user = await User.query(connection: 'primary').first();
  await user.update({'credits': user.credits + 10});
  await Post.query(connection: 'primary').create({'user_id': user.id, ...});
});

// ❌ This doesn't work - cannot span databases
await primaryDs.transaction(() async {
  final user = await User.query(connection: 'primary').first();
  // This will fail - different connection
  await AnalyticsEvent.query(connection: 'analytics').create({...});
});
```

### Coordinating Across Databases

Use compensating transactions for cross-database operations:

```dart
Future<void> createUserWithAnalytics(Map<String, dynamic> userData) async {
  User? user;
  AnalyticsEvent? event;
  
  try {
    // Create user in primary DB
    user = await User.query(connection: 'primary').create(userData);
    
    // Create analytics event
    event = await AnalyticsEvent.query(connection: 'analytics').create({
      'type': 'user_created',
      'user_id': user.id,
      'timestamp': DateTime.now(),
    });
  } catch (e) {
    // Rollback: clean up created records
    if (user != null) {
      await user.setConnection('primary').delete();
    }
    if (event != null) {
      await event.setConnection('analytics').delete();
    }
    rethrow;
  }
}
```

## Multi-Tenant Architecture

### Separate Databases per Tenant

```dart
class TenantManager {
  static final _dataSources = <String, DataSource>{};

  static Future<void> registerTenant(String tenantId) async {
    if (_dataSources.containsKey(tenantId)) return;

    final ds = DataSource(DataSourceOptions(
      name: tenantId,
      driver: SqliteDriverAdapter.file('tenant_$tenantId.sqlite'),
      entities: generatedOrmModelDefinitions,
    ));
    
    await ds.init();
    _dataSources[tenantId] = ds;
  }

  static String connectionForTenant(String tenantId) => tenantId;
}

// Usage
await TenantManager.registerTenant('tenant_123');

final users = await User.all(
  connection: TenantManager.connectionForTenant('tenant_123'),
);
```

### Shared Database with Tenant Column

Use scopes to automatically filter by tenant:

```dart
// Register global scope
context.scopeRegistry.registerScope<$Post>((query) {
  query.whereEquals('tenant_id', currentTenantId);
});

// All queries automatically filtered
final posts = await dataSource.query<$Post>().get();
// SQL: SELECT * FROM posts WHERE tenant_id = ?
```

## Connection Factory & Connectors

For advanced connection management:

```dart
final registry = ModelRegistry()..register(UserOrmDefinition.definition);
final factory = OrmConnectionFactory();

final handle = factory.register(
  name: 'primary',
  connection: const ConnectionConfig(name: 'primary'),
  builder: (_) {
    final adapter = SqliteDriverAdapter.custom(
      config: const DatabaseConfig(
        driver: 'sqlite',
        options: {'path': 'database.sqlite'},
      ),
    );
    return OrmConnection(
      config: const ConnectionConfig(name: 'primary'),
      driver: adapter,
      registry: registry,
    );
  },
);

// When done
await handle.dispose();
```

## ConnectionManager

For apps with multiple databases:

```dart
final manager = ConnectionManager();

manager.register(
  'analytics',
  ConnectionConfig(name: 'analytics'),
  (config) => OrmConnection(
    config: config,
    driver: sqliteAdapter,
    registry: registry,
  ),
);

final analytics = manager.connection('analytics');

await manager.use('analytics', (conn) async {
  await conn.query<$Event>().get();
});
```

## Driver Registration Helpers

Each driver package exposes helpers:

```dart
final handle = registerSqliteOrmConnection(
  name: 'analytics-sqlite',
  database: const DatabaseConfig(driver: 'sqlite', options: {'memory': true}),
  registry: registry,
);

registerPostgresOrmConnection(...);
registerMySqlOrmConnection(...);

final conn = OrmConnection.fromManager('analytics-sqlite');
await handle.dispose();
```

## Best Practices

1. **Name connections clearly** - Use descriptive names like 'primary', 'analytics', 'cache'
2. **Set a default connection** - Makes API cleaner for the most common case
3. **Avoid cross-database transactions** - They're complex and often not supported
4. **Close connections properly** - Use `await dataSource.dispose()` when shutting down
5. **Monitor connection health** - Track active connections and query times

## Driver Compatibility

| Feature | SQLite | PostgreSQL | MySQL |
|---------|--------|------------|-------|
| Multiple connections | ✅ | ✅ | ✅ |
| Read replicas | 🔜 | 🔜 | 🔜 |
| Connection pooling | Driver-specific | Driver-specific | Driver-specific |
| Cross-DB queries | ❌ | ❌ | ❌ |

🔜 = Planned for future release
