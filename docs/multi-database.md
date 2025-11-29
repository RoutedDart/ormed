# Multi-Database Support

Ormed supports connecting to multiple databases simultaneously, making it easy to work with read replicas, tenant databases, or completely different database systems.

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
  // Or explicitly set default connection by name
  ConnectionManager.instance.setDefaultConnection('primary');
}
```

## Using Named Connections

### Specify Connection on Queries

```dart
// Use default connection
final users = await User.all();

// Use specific connection
final analyticsEvents = await AnalyticsEvent.all(connection: 'analytics');

// Query with connection
final events = await AnalyticsEvent.query(connection: 'analytics')
    .where('type', '=', 'page_view')
    .get();
```

### Specify Connection on Model Instances

```dart
// Save to specific database
final event = AnalyticsEvent(type: 'click', data: {...});
await event.setConnection('analytics').save();

// Update on specific connection
final user = await User.find(1);
await user.setConnection('primary').save();
```

### Using Connection in Relationships

```dart
// Load relations from same connection as parent
final user = await User.query(connection: 'primary')
    .with_('posts')
    .first();

// Load relations from different connection
final post = await Post.find(1);
await post.load('analytics', connection: 'analytics');
```

## Read/Write Splitting

> **Note**: Read replica support is planned for a future release. For now, configure separate DataSources for read and write operations.

## Cross-Database Queries

### Transaction Caveat

Note that transactions cannot span multiple databases:

```dart
// ✅ This works - single database transaction
final primaryConn = ConnectionManager.instance.getConnection('primary');
await primaryConn.transaction((tx) async {
  final user = await User.query(connection: 'primary').first();
  await user.update({'credits': user.credits! + 10});
  await Post.query(connection: 'primary').create({'user_id': user.id, ...});
});

// ❌ This doesn't work - cannot span databases
await primaryConn.transaction((tx) async {
  final user = await User.query(connection: 'primary').first();
  // This will fail - can't use different connection in same transaction
  await AnalyticsEvent.query(connection: 'analytics').create({...});
});
```

### Coordinating Across Databases

Use a pattern like Saga or 2PC for cross-database coordination:

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
      entities: [UserOrmDefinition.definition, PostOrmDefinition.definition],
    ));
    
    await ds.init();
    _dataSources[tenantId] = ds;
  }

  static String connectionForTenant(String tenantId) => tenantId;
}

// Usage
await TenantManager.registerTenant('tenant_123');

final users = await User.all(connection: TenantManager.connectionForTenant('tenant_123'));
```

### Shared Database with Tenant Column

```dart
@Orm(table: 'users')
class User extends Model<User> {
  @PrimaryKey()
  int? id;

  @Column()
  String tenantId;

  @Column()
  String name;

  // Global scope to auto-filter by tenant
  static String? _currentTenant;

  static void setCurrentTenant(String tenantId) {
    _currentTenant = tenantId;
  }

  @override
  Query<User> newQuery() {
    final query = super.newQuery();
    if (_currentTenant != null) {
      query.where('tenant_id', '=', _currentTenant);
    }
    return query;
  }

  @override
  Future<User> save() async {
    if (_currentTenant != null && tenantId.isEmpty) {
      tenantId = _currentTenant!;
    }
    return super.save();
  }
}

// Usage
User.setCurrentTenant('tenant_123');

// All queries automatically filtered
final users = await User.all(); // WHERE tenant_id = 'tenant_123'
```

## Connection Pooling

> **Note**: Connection pooling configuration is driver-specific. Refer to your driver's documentation for connection pool settings.

## Monitoring Connections

```dart
// Get specific connection
final primary = ConnectionManager.instance.getConnection('primary');
if (primary != null) {
  print('Connection: primary');
  print('  Driver: ${primary.driver.runtimeType}');
}
```

## Best Practices

1. **Name connections clearly** - Use descriptive names like 'primary', 'analytics', 'cache'
2. **Set a default connection** - Makes API cleaner for the most common case
3. **Use read replicas** - Distribute read load across multiple servers
4. **Avoid cross-database transactions** - They're complex and often not supported
5. **Close connections properly** - Use `await dataSource.close()` when shutting down
6. **Pool connections appropriately** - Configure pool sizes based on load
7. **Monitor connection health** - Track active connections and query times

## Driver Compatibility

| Feature | SQLite | PostgreSQL | MySQL | MongoDB |
|---------|--------|------------|-------|---------|
| Multiple connections | ✅ | ✅ | ✅ | ✅ |
| Read replicas | 🔜 | 🔜 | 🔜 | 🔜 |
| Connection pooling | Driver-specific | Driver-specific | Driver-specific | Driver-specific |
| Cross-DB queries | ❌ | ❌ | ❌ | ❌ |

🔜 = Planned for future release

## See Also

- [Getting Started](getting-started.md)
- [Connection Management](connections.md)
- [Transactions](transactions.md)
- [Performance Optimization](performance.md)
