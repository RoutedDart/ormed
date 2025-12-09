# Ormed Documentation

Welcome to Ormed - a powerful, flexible ORM for Dart that supports multiple database backends.

## Getting Started

- [Getting Started](getting-started.md) - Installation, quick start, and basic usage
- [Models](models.md) - Defining models, attributes, and model lifecycle
- [Query Builder](query_builder.md) - Building and executing database queries
- [Relationships](relations.md) - Defining and working with model relationships
- [Migrations](migrations.md) - Managing database schema changes
- [Code Generation](code_generation.md) - Using the ORM generator

## Advanced Topics

- [Query Caching](query-caching.md) - Cache query results with TTL and events (Better than Laravel!)
- [Model Methods](model-methods.md) - Laravel-inspired convenience methods (replicate, compare, refresh)
- [Multi-Database Support](multi-database.md) - Multiple connections, read replicas, and multi-tenancy
- [Data Sources](data_source.md) - Connection management and configuration
- [Testing](testing.md) - Testing strategies, factories, and best practices
- [CLI Tools](cli.md) - Command-line interface for migrations and code generation
- [Driver Capabilities](driver_capabilities.md) - Understanding database-specific features
- [Model Factories](model_factories.md) - Creating test data

## Database-Specific Guides

- [MongoDB](mongodb.md) - MongoDB-specific features and considerations
- [Connectors](connectors.md) - Database driver configuration

## Best Practices & Patterns

- [Best Practices](best_practices.md) - Recommended patterns and anti-patterns
- [Examples](examples.md) - Real-world usage examples
- [Observability](observability.md) - Monitoring, logging, and debugging

## Reference

- [Grammar Parity Matrix](grammar_parity_matrix.md) - Cross-database query support

## Quick Links

### Common Tasks

- **Creating a model**: See [Models Guide](models.md#defining-models)
- **Running queries**: See [Query Builder](query_builder.md)
- **Setting up relationships**: See [Relationships](relations.md)
- **Running migrations**: See [Migrations](migrations.md)
- **Testing your app**: See [Testing Guide](testing.md)
- **Using multiple databases**: See [Multi-Database Guide](multi-database.md)

### API Highlights

#### Static Model Helpers

```dart
// Query all records
final users = await User.all();

// Find by ID
final user = await User.find(1);

// Create new record
final user = await User.create({'name': 'Alice', 'email': 'alice@example.com'});

// Query builder
final admins = await User.query()
    .where('role', '=', 'admin')
    .orderBy('name')
    .get();

// First matching record
final admin = await User.query()
    .where('role', '=', 'admin')
    .first();
```

#### Relationships

```dart
// Eager loading
final user = await User.query()
    .with_('posts')
    .with_('comments')
    .find(1);

// Lazy loading
final user = await User.find(1);
await user.load('posts');

// Relationship queries
final users = await User.query()
    .has('posts')
    .whereHas('posts', (q) => q.where('published', '=', true))
    .get();

// Relation aggregates
final user = await User.query()
    .withCount('posts')
    .withSum('orders', 'total')
    .find(1);
```

#### Query Caching

```dart
// Cache for 5 minutes
final users = await User.query()
    .where('active', true)
    .remember(Duration(minutes: 5))
    .get();

// Cache forever
final countries = await Country.query()
    .rememberForever()
    .get();

// Cache events (unique to this ORM!)
context.queryCache.listen((event) {
  if (event is CacheHitEvent) {
    print('Cache hit: ${event.sql}');
  }
});
```

#### Model Methods

```dart
// Replicate a model
final duplicate = user.replicate();
duplicate.setAttribute('email', 'new@example.com');
await duplicate.save();

// Compare models
if (user1.isSameAs(user2)) {
  print('Same database record');
}

// Refresh from database
final fresh = await user.fresh(); // New instance
await user.refresh(); // Reload current instance

print('User has ${user.postsCount} posts');
print('Total orders: \$${user.ordersSum}');
```

#### Query Building

```dart
// Where clauses
query.where('age', '>', 18)
    .where('status', '=', 'active')
    .orWhere('role', '=', 'admin');

// Complex conditions
query.where((q) => q
    .where('age', '>', 18)
    .where('country', '=', 'US')
).orWhere((q) => q
    .where('role', '=', 'admin')
);

// Ordering and limiting
query.orderBy('created_at', 'desc')
    .limit(10)
    .offset(20);

// Aggregates
final count = await User.query().count();
final avg = await Order.query().avg('total');
final sum = await Order.query().sum('total');
```

#### Transactions

```dart
await DataSource.default_().transaction((tx) async {
  final user = await User.create({'name': 'Alice'});
  await Post.create({'user_id': user.id, 'title': 'First Post'});
  // Automatically committed or rolled back on exception
});
```

#### Multiple Connections

```dart
// Default connection
final users = await User.all();

// Named connection
final events = await AnalyticsEvent.all(connection: 'analytics');

// Query with specific connection
final data = await AnalyticsEvent.query(connection: 'analytics')
    .where('type', '=', 'page_view')
    .get();
```

## Database Support

| Database | Package | Status |
|----------|---------|--------|
| SQLite | `ormed_sqlite` | ✅ Stable |
| PostgreSQL | `ormed_postgres` | ✅ Stable |
| MySQL/MariaDB | `ormed_mysql` | ✅ Stable |
| MongoDB | `ormed_mongo` | ✅ Stable |

## Contributing

Contributions are welcome! Please see the [Contributing Guide](../CONTRIBUTING.md) for details.

## Support

- [GitHub Issues](https://github.com/your-org/ormed/issues)
- [Discussions](https://github.com/your-org/ormed/discussions)

## License

Ormed is open-source software licensed under the [MIT License](../LICENSE).
