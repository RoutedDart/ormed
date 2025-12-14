---
sidebar_position: 1
---

# Testing

Ormed provides comprehensive testing facilities for isolated, reliable database tests.

## Basic Test Setup

Create a fresh DataSource for each test suite:

```dart
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  late DataSource dataSource;

  setUp(() async {
    dataSource = DataSource(
      DataSourceOptions(
        name: 'test_db',
        driver: InMemoryQueryExecutor(),
        entities: generatedOrmModelDefinitions,
      ),
    );
    await dataSource.init();
  });

  tearDown(() async {
    await dataSource.dispose();
  });

  test('can create and query users', () async {
    final user = $User(id: 0, name: 'Test', email: 'test@example.com');
    await dataSource.repo<$User>().insert(user);

    final found = await dataSource.query<$User>()
        .whereEquals('email', 'test@example.com')
        .first();
    expect(found?.name, equals('Test'));
  });
}
```

## Using InMemoryQueryExecutor

For fast, isolated tests:

```dart
final dataSource = DataSource(
  DataSourceOptions(
    name: 'test',
    driver: InMemoryQueryExecutor(),
    entities: generatedOrmModelDefinitions,
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

Define a seeder class for consistent test data:

```dart
class UserSeeder extends Seeder {
  @override
  Future<void> run(DataSource dataSource) async {
    final users = [
      $User(id: 0, name: 'Admin', email: 'admin@example.com'),
      $User(id: 0, name: 'User', email: 'user@example.com'),
    ];

    for (final user in users) {
      await dataSource.repo<$User>().insert(user);
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
```

## Testing with Real Databases

For integration tests with SQLite:

```dart
import 'package:ormed_sqlite/ormed_sqlite.dart';

late String testDbPath;

setUp(() async {
  testDbPath = 'test_${DateTime.now().millisecondsSinceEpoch}.db';
  
  dataSource = DataSource(
    DataSourceOptions(
      name: 'integration_test',
      driver: SqliteDriverAdapter.file(testDbPath),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await dataSource.init();
});

tearDown(() async {
  await dataSource.dispose();
  final file = File(testDbPath);
  if (await file.exists()) {
    await file.delete();
  }
});
```

## Migration-Aware Test Harness

For Laravel-style workflows with migrations and FK-safe cleanup:

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
    parallel: true,
  );

  ormedTest('creates a user', () async {
    final user = $User(id: 0, name: 'Ada', email: 'ada@test.com');
    await dataSource.repo<$User>().insert(user);
    expect(user.id, isNotNull);
  });
}
```

Key behaviors:
- Uses `MigrationRunner` so migrations run once
- Handles FK toggling per driver for truncate/recreate strategies
- In parallel mode, provisions isolated schemas or databases

## Static Helpers in Tests

Set a default DataSource for `Model` static helpers:

```dart
setUp(() async {
  dataSource = DataSource(DataSourceOptions(...));
  await dataSource.init();
  
  // First DataSource initialized becomes default, or:
  dataSource.setAsDefault();
  
  // Now static helpers work
  await User.query().get();
});
```

## Testing Relations

Ensure all related entities are registered:

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
});

test('can load relations', () async {
  final user = $User(id: 0, name: 'Author', email: 'author@example.com');
  await dataSource.repo<$User>().insert(user);
  
  final post = $Post(id: 0, title: 'Test Post', userId: user.id);
  await dataSource.repo<$Post>().insert(post);
  
  // Test eager loading
  final users = await dataSource.query<$User>().with_(['posts']).get();
  expect(users.first.posts?.length, equals(1));
});
```

## Parallel Testing

For parallel test execution without conflicts:

1. **Use in-memory databases** - Each test gets isolated database
2. **Use unique database names** - Include timestamps or random IDs
3. **Clean up properly** - Always clean up in `tearDown`

```dart
setUp(() async {
  // Unique name per test suite
  dataSource = DataSource(
    DataSourceOptions(
      name: 'test_${DateTime.now().microsecondsSinceEpoch}',
      driver: InMemoryQueryExecutor(),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await dataSource.init();
});
```

## Best Practices

### Use In-Memory for Unit Tests

```dart
driver: InMemoryQueryExecutor()  // Fast and isolated
```

### Use Real Databases for Integration Tests

```dart
driver: SqliteDriverAdapter.memory()  // More realistic
```

### Keep Tests Isolated

```dart
setUp(() async {
  // Fresh database for each test
  dataSource = DataSource(DataSourceOptions(...));
  await dataSource.init();
});

test('test 1', () async {
  // This test's data won't affect test 2
});

test('test 2', () async {
  // Starts with clean database
});
```

### Use Factories for Test Data

```dart
test('bulk operations', () async {
  for (var i = 0; i < 100; i++) {
    await Model.factory<User>()
        .seed(i)
        .withField('email', 'user_$i@test.com')
        .create(context: dataSource.context);
  }

  final count = await dataSource.query<$User>().count();
  expect(count, equals(100));
});
```

### Test Both Success and Failure Cases

```dart
test('throws on duplicate email', () async {
  await dataSource.repo<$User>().insert(
    $User(id: 0, email: 'test@example.com'),
  );
  
  expect(
    () => dataSource.repo<$User>().insert(
      $User(id: 0, email: 'test@example.com'),
    ),
    throwsException,
  );
});
```

## Example Test Suite

```dart
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';
import 'orm_registry.g.dart';

void main() {
  late DataSource dataSource;

  setUp(() async {
    dataSource = DataSource(
      DataSourceOptions(
        name: 'test_${DateTime.now().microsecondsSinceEpoch}',
        driver: InMemoryQueryExecutor(),
        entities: generatedOrmModelDefinitions,
      ),
    );
    await dataSource.init();
  });

  tearDown(() async {
    await dataSource.dispose();
  });

  group('User model', () {
    test('can create user', () async {
      final user = $User(id: 0, email: 'test@example.com');
      await dataSource.repo<$User>().insert(user);
      expect(user.id, isNotNull);
    });

    test('can find user by id', () async {
      final user = $User(id: 0, email: 'test@example.com');
      await dataSource.repo<$User>().insert(user);
      
      final found = await dataSource.query<$User>().find(user.id);
      expect(found?.email, equals('test@example.com'));
    });

    test('can update user', () async {
      final user = $User(id: 0, email: 'test@example.com');
      await dataSource.repo<$User>().insert(user);
      
      user.setAttribute('email', 'updated@example.com');
      await dataSource.repo<$User>().update(user);
      
      final found = await dataSource.query<$User>().find(user.id);
      expect(found?.email, equals('updated@example.com'));
    });

    test('can delete user', () async {
      final user = $User(id: 0, email: 'test@example.com');
      await dataSource.repo<$User>().insert(user);
      
      await dataSource.repo<$User>().delete(user);
      
      final found = await dataSource.query<$User>().find(user.id);
      expect(found, isNull);
    });
  });
}
```
