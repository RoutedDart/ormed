# Testing with Ormed

Ormed provides comprehensive testing facilities to make it easy to write isolated, reliable database tests. This guide covers best practices for testing applications that use Ormed.

## Overview

Testing database-driven applications requires careful handling of test isolation, data setup, and cleanup. Ormed provides tools to:

- Create isolated test databases
- Run migrations before tests
- Seed test data
- Clean up after tests
- Support parallel test execution
- Reuse migration-aware helpers (`setUpOrmed`, `ormedTest`, `TestDatabaseManager`) that respect database management and foreign-key controls

## Basic Test Setup

The simplest way to test with Ormed is to create a fresh DataSource for each test suite:

```dart
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  late DataSource dataSource;

  setUp(() async {
    // Create an in-memory database for testing
    dataSource = DataSource(
      DataSourceOptions(
        name: 'test_db',
        driver: InMemoryQueryExecutor(),
        entities: [UserOrmDefinition.definition],
      ),
    );
    await dataSource.init();
  });

  tearDown(() async {
    // Clean up is automatic with in-memory databases
  });

  test('can create and query users', () async {
    final user = User(name: 'Test', email: 'test@example.com');
    await user.save();

    final found = await Model.query<User>().where('email', 'test@example.com').first();
    expect(found?.name, equals('Test'));
  });
}
```

## Using the InMemoryQueryExecutor

For fast, isolated tests, use the `InMemoryQueryExecutor`. It provides a lightweight in-memory database that doesn't require external dependencies:

```dart
final dataSource = DataSource(
  DataSourceOptions(
    name: 'test',
    driver: InMemoryQueryExecutor(),
    entities: [UserOrmDefinition.definition, PostOrmDefinition.definition],
  ),
);
await dataSource.init();
```

The in-memory executor automatically:
- Generates auto-increment IDs
- Maintains referential integrity
- Resets between test runs
- Supports basic query operations

## Test Data with Seeders

Seeders help you create consistent test data. Define a seeder class and use it in your tests:

```dart
class UserSeeder extends Seeder {
  @override
  Future<void> run(DataSource dataSource) async {
    // Set the DataSource as default so Model.save() works
    DataSource.setDefault(dataSource);
    
    final users = [
      User(name: 'Admin', email: 'admin@example.com'),
      User(name: 'User', email: 'user@example.com'),
    ];

    for (final user in users) {
      await user.save();
    }
  }
}

// In your test
setUp(() async {
  dataSource = DataSource(DataSourceOptions(...));
  await dataSource.init();
  
  final seeder = UserSeeder();
  await seeder.run(dataSource);
});

test('seeded data is available', () async {
  final users = await Model.query<User>().all();
  expect(users.length, equals(2));
});
```

## Testing with Real Databases

For integration tests, you may want to use real database drivers:

```dart
import 'package:ormed_sqlite/ormed_sqlite.dart';

setUp(() async {
  // Use a test-specific database file
  final testDbPath = 'test_${DateTime.now().millisecondsSinceEpoch}.db';
  
  dataSource = DataSource(
    DataSourceOptions(
      name: 'integration_test',
      driver: SqliteDriverAdapter.file(testDbPath),
      entities: [/* your entities */],
    ),
  );
  await dataSource.init();
});

tearDown() async {
  // Clean up the test database file
  final file = File(testDbPath);
  if (await file.exists()) {
    await file.delete();
  }
});
```

## Migration-aware test harness

When you want Laravel-style workflows (migrations + FK-safe cleanup) use the testing harness from `package:ormed/src/testing`:

```dart
import 'package:ormed/testing.dart';

void main() {
  setUpOrmed(
    dataSource: myDataSource,
    migrationDescriptors: [
      MigrationDescriptor.fromMigration(
        id: MigrationId(DateTime.utc(2024, 1, 1), 'create_users'),
        migration: CreateUsersTable(),
      ),
    ],
    seeders: [UserSeeder.new],
    strategy: DatabaseIsolationStrategy.migrateWithTransactions,
    parallel: true, // creates per-test schemas/databases using driver capabilities
  );

  ormedTest('creates a user', () async {
    final user = User(name: 'Ada');
    await user.save();
    expect(user.id, isNotNull);
  });
}
```

Key behaviors:
- Uses `TestSchemaManager` + `MigrationRunner` so migrations/seeders run once and ledger is kept in-sync.
- For truncate/recreate strategies it calls `SchemaDriver.dropAllTables`, which handles FK toggling per driver.
- In parallel mode it provisions isolated schemas (Postgres/MySQL/MariaDB) or databases/files (SQLite) to avoid cross-test collisions.
- `seedTestData`/`previewTestSeed` let you apply or dry-run seeders against the current test connection.

## Multiple DataSources

You can test applications that use multiple databases by creating separate DataSources:

```dart
late DataSource mainDb;
late DataSource analyticsDb;

setUp(() async {
  mainDb = DataSource(
    DataSourceOptions(
      name: 'main',
      driver: InMemoryQueryExecutor(),
      entities: [UserOrmDefinition.definition],
    ),
  );
  await mainDb.init();

  analyticsDb = DataSource(
    DataSourceOptions(
      name: 'analytics',
      driver: InMemoryQueryExecutor(),
      entities: [EventOrmDefinition.definition],
    ),
  );
  await analyticsDb.init();
});

test('can use multiple databases', () async {
  // Use named connections
  final user = User(name: 'Test', email: 'test@example.com');
  await user.save(); // Uses default connection

  final event = Event(name: 'login');
  await event.on('analytics').save(); // Uses analytics connection
});
```

## Static Helpers in Tests

When using Model static helpers like `User.query()`, you need to set a default DataSource:

```dart
setUp(() async {
  dataSource = DataSource(DataSourceOptions(...));
  await dataSource.init();
  
  // First DataSource initialized automatically becomes default
  // Or explicitly set it:
  DataSource.setDefault(dataSource);
  
  // Now static helpers work
  await User.query().delete(); // Clear any existing data
});

test('static helpers work', () async {
  final user = User(name: 'Test', email: 'test@example.com');
  await user.save();
  
  // Use static helpers
  final found = await User.find(user.id);
  expect(found, isNotNull);
  
  final all = await User.all();
  expect(all.length, equals(1));
});
```

## Testing Relations

When testing models with relations, ensure all related entities are registered:

```dart
setUp(() async {
  dataSource = DataSource(
    DataSourceOptions(
      name: 'test',
      driver: InMemoryQueryExecutor(),
      entities: [
        UserOrmDefinition.definition,
        PostOrmDefinition.definition,
        CommentOrmDefinition.definition,
      ],
    ),
  );
  await dataSource.init();
  DataSource.setDefault(dataSource);
});

test('can load relations', () async {
  final user = User(name: 'Author', email: 'author@example.com');
  await user.save();
  
  final post = Post(title: 'Test Post', userId: user.id);
  await post.save();
  
  // Test eager loading
  final users = await User.query().with_('posts').get();
  expect(users.first.posts?.length, equals(1));
  
  // Test lazy loading
  final foundUser = await User.find(user.id);
  final posts = await foundUser?.posts;
  expect(posts?.length, equals(1));
});
```

## Parallel Testing

Dart's test runner supports parallel test execution. To avoid conflicts:

1. **Use in-memory databases** - Each test gets its own isolated database
2. **Use unique database names** - Include timestamps or random IDs
3. **Clean up properly** - Always clean up resources in `tearDown`

```dart
// Each test file creates isolated databases
void main() {
  late DataSource dataSource;
  
  setUp(() async {
    // Unique name per test suite
    dataSource = DataSource(
      DataSourceOptions(
        name: 'test_${DateTime.now().microsecondsSinceEpoch}',
        driver: InMemoryQueryExecutor(),
        entities: [...],
      ),
    );
    await dataSource.init();
  });
  
  // Tests run in parallel without conflicts
}
```

## Best Practices

### 1. Use In-Memory for Unit Tests

For fast unit tests, prefer `InMemoryQueryExecutor`:

```dart
// Fast and isolated
driver: InMemoryQueryExecutor()
```

### 2. Use Real Databases for Integration Tests

For integration tests, use actual database drivers to catch database-specific issues:

```dart
// More realistic but slower
driver: SqliteDriverAdapter.memory()  // or .file() for persistence
```

### 3. Keep Tests Isolated

Each test should be independent and not rely on other tests:

```dart
setUp() async {
  // Fresh database for each test
  dataSource = DataSource(DataSourceOptions(...));
  await dataSource.init();
});

test('test 1', () async {
  // This test's data won't affect test 2
});

test('test 2', () async {
  // This test starts with clean database
});
```

### 4. Use Seeders for Complex Data

For complex test scenarios, use seeders to set up consistent test data:

```dart
class CompleteDataSeeder extends Seeder {
  @override
  Future<void> run(DataSource dataSource) async {
    DataSource.setDefault(dataSource);
    
    // Create users
    final admin = User(name: 'Admin', email: 'admin@example.com');
    await admin.save();
    
    // Create posts
    final post = Post(title: 'Post 1', userId: admin.id);
    await post.save();
    
    // Create comments
    final comment = Comment(body: 'Comment 1', postId: post.id);
    await comment.save();
  }
}
```

### 5. Test Both Success and Failure Cases

Test not only successful operations but also error conditions:

```dart
test('throws on duplicate email', () async {
  final user1 = User(name: 'User', email: 'test@example.com');
  await user1.save();
  
  final user2 = User(name: 'User2', email: 'test@example.com');
  
  // Expect the save to fail due to unique constraint
  expect(() => user2.save(), throwsException);
});
```

### 6. Clean Up Resources

Always clean up in `tearDown` to prevent resource leaks:

```dart
tearDown(() async {
  // For file-based databases
  if (testDbFile.existsSync()) {
    testDbFile.deleteSync();
  }
});
```

## Example Test Suite

Here's a complete example of a well-structured test suite:

```dart
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  late DataSource dataSource;

  setUp(() async {
    dataSource = DataSource(
      DataSourceOptions(
        name: 'test_${DateTime.now().microsecondsSinceEpoch}',
        driver: InMemoryQueryExecutor(),
        entities: [
          UserOrmDefinition.definition,
          PostOrmDefinition.definition,
        ],
      ),
    );
    await dataSource.init();
    DataSource.setDefault(dataSource);
  });

  group('User model', () {
    test('can create user', () async {
      final user = User(name: 'Test', email: 'test@example.com');
      await user.save();
      
      expect(user.id, isNotNull);
    });

    test('can find user by id', () async {
      final user = User(name: 'Test', email: 'test@example.com');
      await user.save();
      
      final found = await User.find(user.id);
      expect(found?.email, equals('test@example.com'));
    });

    test('can update user', () async {
      final user = User(name: 'Test', email: 'test@example.com');
      await user.save();
      
      user.name = 'Updated';
      await user.save();
      
      final found = await User.find(user.id);
      expect(found?.name, equals('Updated'));
    });

    test('can delete user', () async {
      final user = User(name: 'Test', email: 'test@example.com');
      await user.save();
      
      await user.delete();
      
      final found = await User.find(user.id);
      expect(found, isNull);
    });
  });

  group('User relations', () {
    test('user has many posts', () async {
      final user = User(name: 'Author', email: 'author@example.com');
      await user.save();
      
      final post1 = Post(title: 'Post 1', userId: user.id);
      final post2 = Post(title: 'Post 2', userId: user.id);
      await post1.save();
      await post2.save();
      
      final posts = await user.posts;
      expect(posts?.length, equals(2));
    });
  });
}
```

## Summary

Ormed provides flexible testing tools that work with various testing strategies:

- **InMemoryQueryExecutor** for fast, isolated unit tests
- **Real database drivers** for integration tests  
- **Seeders** for consistent test data setup
- **Multiple DataSources** for testing multi-database scenarios
- **Static helpers** with proper DataSource registration

Choose the approach that best fits your testing needs, keeping tests fast, isolated, and reliable.
