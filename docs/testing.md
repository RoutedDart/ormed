# Testing with Ormed

This guide covers best practices for testing applications that use Ormed.

## Test Database Setup

### Using In-Memory SQLite

The fastest option for tests:

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:test/test.dart';

DataSource? testDb;

Future<DataSource> setupTestDatabase() async {
  final ds = DataSource(DataSourceOptions(
    name: 'test',
    driver: SqliteDriverAdapter.memory(), // In-memory database
    entities: [
      UserOrmDefinition.definition,
      PostOrmDefinition.definition,
    ],
  ));

  await ds.init();
  // Note: Migration support coming soon
  
  return ds;
}

void main() {
  setUp(() async {
    testDb = await setupTestDatabase();
    DataSource.setDefault(testDb!);
  });

  tearDown(() async {
    await testDb?.close();
    testDb = null;
  });

  test('can create and retrieve users', () async {
    final user = await User.create({
      'name': 'Test User',
      'email': 'test@example.com',
    });

    final retrieved = await User.find(user.id!);
    expect(retrieved?.name, equals('Test User'));
  });
}
```

### Using Test Databases

For integration tests, use separate test databases:

```dart
Future<DataSource> setupTestDatabase() async {
  final ds = DataSource(DataSourceOptions(
    name: 'test',
    driver: PostgresDriverAdapter(
      host: 'localhost',
      port: 5432,
      database: 'app_test', // Separate test database
      username: 'test_user',
      password: 'test_pass',
    ),
    entities: [...],
  ));

  await ds.init();
  
  // Note: Migration support coming soon
  // For now, use driver-specific schema setup
  
  return ds;
}
```

## Database Transactions for Test Isolation

Roll back after each test to keep database clean:

```dart
void main() {
  late DataSource db;
  Transaction? tx;

  setUp(() async {
    db = await setupTestDatabase();
    DataSource.setDefault(db);
    
    // Start transaction
    tx = await db.beginTransaction();
  });

  tearDown(() async {
    // Roll back transaction - undoes all changes
    await tx?.rollback();
    await db.close();
  });

  test('user creation', () async {
    await User.create({'name': 'Alice', 'email': 'alice@example.com'});
    final count = await User.query().count();
    expect(count, equals(1));
    // Automatically rolled back after test
  });

  test('database is clean', () async {
    // Previous test's user doesn't exist
    final count = await User.query().count();
    expect(count, equals(0));
  });
}
```

## Factories and Seeders

Create test data easily with factories:

```dart
class UserFactory {
  static int _counter = 0;

  static Future<User> create({
    String? name,
    String? email,
    String? role,
  }) async {
    _counter++;
    
    return await User.create({
      'name': name ?? 'User $_counter',
      'email': email ?? 'user$_counter@example.com',
      'role': role ?? 'user',
      'created_at': DateTime.now(),
    });
  }

  static Future<List<User>> createMany(int count, {String? role}) async {
    return await Future.wait(
      List.generate(count, (_) => create(role: role))
    );
  }
}

// Usage in tests
test('can list users', () async {
  await UserFactory.createMany(5);
  
  final users = await User.all();
  expect(users.length, equals(5));
});
```

## Testing Relationships

```dart
test('user has many posts', () async {
  final user = await UserFactory.create();
  
  await Post.create({'user_id': user.id, 'title': 'Post 1'});
  await Post.create({'user_id': user.id, 'title': 'Post 2'});
  
  final userWithPosts = await User.query()
      .with_('posts')
      .find(user.id!);
  
  expect(userWithPosts?.posts.length, equals(2));
});

test('post belongs to user', () async {
  final user = await UserFactory.create(name: 'Author');
  final post = await Post.create({
    'user_id': user.id,
    'title': 'Test Post',
  });
  
  final postWithUser = await Post.query()
      .with_('user')
      .find(post.id!);
  
  expect(postWithUser?.user?.name, equals('Author'));
});
```

## Testing Queries

```dart
group('User queries', () {
  setUp(() async {
    await UserFactory.create(name: 'Alice', role: 'admin');
    await UserFactory.create(name: 'Bob', role: 'user');
    await UserFactory.create(name: 'Charlie', role: 'user');
  });

  test('filters by role', () async {
    final admins = await User.query()
        .where('role', '=', 'admin')
        .get();
    
    expect(admins.length, equals(1));
    expect(admins.first.name, equals('Alice'));
  });

  test('orders by name', () async {
    final users = await User.query()
        .orderBy('name')
        .get();
    
    expect(users.map((u) => u.name).toList(), 
           equals(['Alice', 'Bob', 'Charlie']));
  });

  test('paginates results', () async {
    final page1 = await User.query()
        .limit(2)
        .get();
    
    expect(page1.length, equals(2));
  });
});
```

## Testing Hooks and Events

```dart
test('user password is hashed on save', () async {
  final user = User(
    name: 'Test',
    email: 'test@example.com',
    password: 'plain_password',
  );
  
  await user.save();
  
  // Password should be hashed
  expect(user.password, isNot(equals('plain_password')));
  expect(user.password!.length, greaterThan(20));
});

test('sends email on user creation', () async {
  final emailsSent = <String>[];
  
  // Mock email service
  User.creating((user) {
    emailsSent.add(user.email);
  });
  
  await UserFactory.create(email: 'new@example.com');
  
  expect(emailsSent, contains('new@example.com'));
});
```

## Testing Migrations

```dart
// Note: Migration testing support coming soon
// For now, test schema setup directly with driver
```

## Mocking and Stubbing

### Mock Driver for Unit Tests

```dart
class MockDriver implements Driver {
  final _data = <String, List<Map<String, dynamic>>>{};

  @override
  Future<List<Map<String, dynamic>>> execute(Query query) async {
    final table = query.table;
    return _data[table] ?? [];
  }

  void addRows(String table, List<Map<String, dynamic>> rows) {
    _data[table] = [..._data[table] ?? [], ...rows];
  }
}

test('user query with mock driver', () async {
  final mockDriver = MockDriver();
  mockDriver.addRows('users', [
    {'id': 1, 'name': 'Alice', 'email': 'alice@example.com'},
    {'id': 2, 'name': 'Bob', 'email': 'bob@example.com'},
  ]);

  // Use mock in test...
});
```

## Testing Static Helpers

```dart
group('User static helpers', () {
  setUp(() async {
    testDb = await setupTestDatabase();
    DataSource.setDefault(testDb!);
  });

  test('User.all() returns all users', () async {
    await UserFactory.createMany(3);
    
    final users = await User.all();
    expect(users.length, equals(3));
  });

  test('User.find() retrieves by ID', () async {
    final user = await UserFactory.create(name: 'Alice');
    
    final found = await User.find(user.id!);
    expect(found?.name, equals('Alice'));
  });

  test('User.query() returns query builder', () async {
    await UserFactory.create(role: 'admin');
    await UserFactory.create(role: 'user');
    
    final admins = await User.query()
        .where('role', '=', 'admin')
        .get();
    
    expect(admins.length, equals(1));
  });
});
```

## Performance Testing

```dart
test('bulk insert performance', () async {
  final stopwatch = Stopwatch()..start();
  
  // Create 1000 users
  await UserFactory.createMany(1000);
  
  stopwatch.stop();
  
  print('Bulk insert took: ${stopwatch.elapsedMilliseconds}ms');
  expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should be under 5s
});

test('query performance with indexes', () async {
  await UserFactory.createMany(10000);
  
  final stopwatch = Stopwatch()..start();
  
  final users = await User.query()
      .where('email', '=', 'user5000@example.com')
      .get();
  
  stopwatch.stop();
  
  print('Indexed query took: ${stopwatch.elapsedMilliseconds}ms');
  expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be fast
});
```

## Best Practices

1. **Use in-memory databases for unit tests** - Fast and isolated
2. **Use transactions for test isolation** - Clean database between tests
3. **Create factories for test data** - Reusable and maintainable
4. **Test relationships explicitly** - Don't assume they work
5. **Test edge cases** - Empty results, null values, large datasets
6. **Mock external services** - Don't hit real APIs in tests
7. **Test migrations** - Both up and down
8. **Measure performance** - Catch regressions early
9. **Clean up after tests** - Close connections, reset state
10. **Use descriptive test names** - Make failures easy to understand

## Testing with Different Drivers

```dart
// Run same tests against multiple drivers
void runDriverTests(String driverName, Future<DataSource> Function() setup) {
  group('$driverName driver', () {
    late DataSource db;

    setUp(() async {
      db = await setup();
      DataSource.setDefault(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('basic CRUD operations', () async {
      final user = await User.create({'name': 'Test', 'email': 'test@example.com'});
      expect(user.id, isNotNull);

      final found = await User.find(user.id!);
      expect(found?.name, equals('Test'));

      await user.update({'name': 'Updated'});
      expect(user.name, equals('Updated'));

      await user.delete();
      final deleted = await User.find(user.id!);
      expect(deleted, isNull);
    });
  });
}

void main() {
  runDriverTests('SQLite', () => setupSqliteDb());
  runDriverTests('PostgreSQL', () => setupPostgresDb());
  runDriverTests('MySQL', () => setupMysqlDb());
}
```

## See Also

- [Getting Started](getting-started.md)
- [Factories Pattern](factories.md)
- [Continuous Integration](ci.md)
- [Driver Tests Package](../packages/driver_tests/README.md)
