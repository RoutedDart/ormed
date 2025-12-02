# Ormed Testing Guide

This guide shows you how to write tests for applications using Ormed. Ormed provides several approaches to database testing, from simple declarative patterns to advanced custom setups.

## Quick Start: Recommended Approach

The simplest and most declarative approach is using `ormedGroup()`:

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:test/test.dart';

void main() {
  late DataSource dataSource;

  setUpAll(() async {
    dataSource = DataSource(
      DataSourceOptions(
        name: 'test',
        driver: SqliteDriverAdapter.inMemory(),
        entities: [UserOrmDefinition.definition],
      ),
    );
    await dataSource.init();
  });

  tearDownAll(() async {
    await dataSource.dispose();
  });

  ormedGroup(
    'User tests',
    dataSource: dataSource,
    migrations: [CreateUsersTable()],
    refreshStrategy: DatabaseRefreshStrategy.migrate,
    () {
      ormedTest('can create user', () async {
        final user = User(name: 'Alice', email: 'alice@example.com');
        await user.save();
        expect(user.id, isNotNull);
      });

      ormedTest('can query users', () async {
        // Database is automatically refreshed between tests
        final users = await UserOrmDefinition.query().get();
        expect(users, isEmpty);
      });
    },
  );
}

class CreateUsersTable extends Migration {
  @override
  Future<void> up(SchemaBuilder schema) async {
    schema.create('users', (table) {
      table.id();
      table.string('name');
      table.string('email').unique();
      table.timestamps();
    });
  }

  @override
  Future<void> down(SchemaBuilder schema) async {
    schema.drop('users');
  }
}
```

## Three Approaches to Testing

### 1. `ormedGroup()` - Simple and Declarative (RECOMMENDED)

**Best for:** Most testing scenarios, quick setup, readable tests

```dart
ormedGroup(
  'Feature tests',
  dataSource: dataSource,
  migrations: [CreateUsersTable(), CreatePostsTable()],
  refreshStrategy: DatabaseRefreshStrategy.migrate,
  () {
    ormedTest('test 1', () async { /* ... */ });
    ormedTest('test 2', () async { /* ... */ });
  },
);
```

**Pros:**
- Minimal boilerplate
- Declarative migration setup
- Automatic cleanup
- Self-contained test groups

**Cons:**
- Less flexibility for complex scenarios

### 2. `setUpOrmed()` + `ormedTest()` - Advanced Control

**Best for:** Complex test suites, custom isolation strategies, parallel execution

```dart
void main() {
  setUpOrmed(
    dataSource: myDataSource,
    runMigrations: (ds) async {
      // Custom migration logic
      await runCustomMigrations(ds);
    },
    strategy: DatabaseIsolationStrategy.transaction,
    parallel: true, // Run tests in parallel
  );

  ormedTest('test with isolation', () async {
    // Database is automatically isolated
    final user = User(name: 'Test');
    await user.save();
  });
}
```

**Pros:**
- Fine-grained control over database lifecycle
- Support for parallel test execution
- Custom migration runners
- Flexible isolation strategies

**Cons:**
- More setup code
- Requires understanding of TestDatabaseManager

### 3. Manual Setup - Complete Control

**Best for:** Special cases, integration with existing test infrastructure

```dart
void main() {
  late DataSource dataSource;

  setUpAll(() async {
    dataSource = DataSource(DataSourceOptions(
      driver: SqliteDriverAdapter.inMemory(),
      entities: [UserOrmDefinition.definition],
    ));
    await dataSource.init();
    
    // Run migrations manually
    final migration = CreateUsersTable();
    final plan = migration.plan(MigrationDirection.up);
    final schemaDriver = dataSource.connection.driver as SchemaDriver;
    await schemaDriver.applySchemaPlan(plan);
  });

  tearDownAll(() async {
    await dataSource.dispose();
  });

  test('standard test', () async {
    final user = User(name: 'Alice', email: 'alice@example.com');
    await dataSource.repo<User>().insert(user);
    
    final users = await dataSource.query<User>().get();
    expect(users.length, 1);
  });
}
```

**Pros:**
- Complete control
- No magic or hidden behavior
- Easy to debug

**Cons:**
- Most verbose
- Manual cleanup required
- No automatic isolation

## Database Refresh Strategies

When using `ormedGroup()`, you can choose how the database is refreshed between tests:

### `DatabaseRefreshStrategy.migrate`

Runs migrations once before the group, data persists across tests.

```dart
ormedGroup(
  'Tests with shared data',
  refreshStrategy: DatabaseRefreshStrategy.migrate,
  () {
    ormedTest('creates data', () async {
      await user.save(); // Data created here...
    });
    
    ormedTest('sees previous data', () async {
      final users = await User.query().get();
      expect(users.length, 1); // ...is visible here
    });
  },
);
```

### `DatabaseRefreshStrategy.migrateWithTransactions`

Uses transactions for isolation (fast, but not fully implemented yet).

```dart
refreshStrategy: DatabaseRefreshStrategy.migrateWithTransactions,
```

### `DatabaseRefreshStrategy.truncate`

Deletes all data between tests, keeps schema.

```dart
refreshStrategy: DatabaseRefreshStrategy.truncate,
```

### `DatabaseRefreshStrategy.recreate`

Drops and recreates entire schema between tests (slowest, most thorough).

```dart
refreshStrategy: DatabaseRefreshStrategy.recreate,
```

## Using TestDatabase Directly

For complete control without using `ormedGroup()` or `setUpOrmed()`, use `TestDatabase`:

```dart
import 'package:ormed/testing.dart';

void main() {
  late TestDatabase testDb;

  setUpAll(() async {
    testDb = TestDatabase(
      TestDatabaseConfig(
        driver: SqliteDriverAdapter.inMemory(),
        migrations: [CreateUsersTable()],
        seeders: [UserSeeder()],
        entities: [UserOrmDefinition.definition],
      ),
    );
    await testDb.setUp();
  });

  tearDownAll(() async {
    await testDb.tearDown();
  });

  test('can query seeded data', () async {
    final users = await testDb.dataSource.query<User>().get();
    expect(users.length, 2);
  });
}
```

## Best Practices

### 1. Use In-Memory Databases

For fast tests, use in-memory SQLite:

```dart
driver: SqliteDriverAdapter.inMemory()
```

### 2. Group Related Tests

Use `ormedGroup()` to group related tests with their own migrations:

```dart
ormedGroup('User CRUD', migrations: [CreateUsersTable()], () {
  // All user tests
});

ormedGroup('Post CRUD', migrations: [CreatePostsTable()], () {
  // All post tests
});
```

### 3. Keep Tests Independent

Each test should be independent and not rely on data from other tests:

```dart
ormedTest('creates user', () async {
  // Set up test data here
  final user = User(name: 'Test');
  await user.save();
  
  // Test and verify
  expect(user.id, isNotNull);
});
```

### 4. Use Seeders for Common Test Data

When multiple tests need the same data:

```dart
class UserSeeder extends Seeder {
  @override
  Future<void> run(DataSource dataSource) async {
    await dataSource.repo<User>().insertMany([
      User(name: 'Alice', email: 'alice@example.com'),
      User(name: 'Bob', email: 'bob@example.com'),
    ]);
  }
}

testDb = TestDatabase(
  TestDatabaseConfig(
    seeders: [UserSeeder()],
    // ...
  ),
);
```

### 5. Clean Up Resources

Always dispose of DataSources:

```dart
tearDownAll(() async {
  await dataSource.dispose();
});
```

## Common Patterns

### Testing with Factories

```dart
ormedTest('creates multiple users', () async {
  final users = [
    User(name: 'User 1', email: 'user1@example.com'),
    User(name: 'User 2', email: 'user2@example.com'),
  ];
  
  await dataSource.repo<User>().insertMany(users);
  
  final count = await dataSource.query<User>().count();
  expect(count, 2);
});
```

### Testing Relationships

```dart
ormedTest('creates user with posts', () async {
  final user = User(name: 'Alice', email: 'alice@example.com');
  await user.save();
  
  final post = Post(userId: user.id!, title: 'Hello World');
  await post.save();
  
  final posts = await dataSource.query<Post>()
      .whereEquals('userId', user.id)
      .get();
  expect(posts.length, 1);
});
```

### Testing Transactions

```dart
ormedTest('rolls back on error', () async {
  try {
    await dataSource.transaction(() async {
      final user = User(name: 'Test', email: 'test@example.com');
      await user.save();
      
      throw Exception('Simulated error');
    });
  } catch (e) {
    // Expected
  }
  
  final count = await dataSource.query<User>().count();
  expect(count, 0); // Transaction was rolled back
});
```

## Troubleshooting

### "TestDatabase not initialized"

Make sure to call `setUp()` before using `testDb.dataSource`:

```dart
await testDb.setUp();
```

### "Ormed test environment not initialized"

When using `ormedTest()`, make sure to call `setUpOrmed()` first:

```dart
void main() {
  setUpOrmed(/* ... */);
  
  ormedTest('my test', () async { /* ... */ });
}
```

### Tests are not isolated

Choose an appropriate refresh strategy:

```dart
refreshStrategy: DatabaseRefreshStrategy.truncate, // or .recreate
```

### Migrations not running

Check that migrations are passed to the config:

```dart
migrations: [CreateUsersTable(), CreatePostsTable()],
```

## Summary

- **Start with `ormedGroup()`** - It's the simplest and covers most use cases
- **Use `setUpOrmed()`** when you need advanced features like parallel execution
- **Fall back to manual setup** only when you need complete control
- **Keep tests independent** and use appropriate isolation strategies
- **Use in-memory databases** for fast test execution
- **Always clean up resources** in `tearDownAll()`

For more examples, see the test files in `test/testing/`.
