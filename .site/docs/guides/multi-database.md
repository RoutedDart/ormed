---
sidebar_position: 4
---

# Multi-Database Support

Ormed supports connecting to multiple databases simultaneously for read replicas, tenant databases, or different database systems.

## Configuring Multiple Connections

### Define Multiple DataSources

```dart file=../../examples/lib/multi_db/multi_database.dart#multi-db-setup
```

## Using Named Connections

```dart file=../../examples/lib/multi_db/multi_database.dart#multi-db-named
```

## Transaction Caveat

Transactions cannot span multiple databases:

```dart file=../../examples/lib/multi_db/multi_database.dart#multi-db-transaction-caveat
```

### Coordinating Across Databases

Use compensating transactions for cross-database operations:

```dart file=../../examples/lib/multi_db/multi_database.dart#multi-db-coordinating
```

## Multi-Tenant Architecture

### Separate Databases per Tenant

```dart file=../../examples/lib/multi_db/multi_database.dart#multi-db-tenant
```

### Using Tenant Scopes

```dart file=../../examples/lib/multi_db/multi_database.dart#multi-db-tenant-scope
```

## Connection Factory

```dart file=../../examples/lib/multi_db/multi_database.dart#multi-db-factory
```

## ConnectionManager

```dart file=../../examples/lib/multi_db/multi_database.dart#multi-db-manager
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
