# Testing with Ormed - Complete Example

This guide demonstrates the recommended approach for writing tests with Ormed using the consolidated testing utilities.

## Quick Start

Ormed provides a unified testing API with just one entry point: `setUpOrmed()`. This function configures your test environment with automatic database setup, transaction handling, and cleanup.

### Basic Setup

```dart
import 'package:test/test.dart';
import 'package:ormed/testing.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

// Your entities
import 'entities/user.dart';
import 'entities/post.dart';

// Your migrations and seeds
import 'database/migrations/registry.dart';
import 'database/seeds/database_seeder.dart';

void main() {
  // Single setup call - configures everything!
  setUpOrmed(
    driver: SqliteDriver.memory(),
    entities: [User, Post],
    migrations: buildMigrations(), // From your migration registry
    seeders: [DatabaseSeeder()],
  );

  // Write your tests as normal
  test('user can create post', () async {
    final db = getTestDatabase();
    final userRepo = db.repository<User>();
    final postRepo = db.repository<Post>();
    
    final user = User(
      id: 1,
      name: 'Alice',
      email: 'alice@example.com',
    );
    await userRepo.insert(user);
    
    final post = Post(
      id: 1,
      userId: user.id,
      title: 'My First Post',
      content: 'Hello World',
    );
    await postRepo.insert(post);
    
    final found = await postRepo.findOneOrFail(1);
    expect(found.title, equals('My First Post'));
  });
}
```

## What setUpOrmed() Does

The `setUpOrmed()` function handles everything you need for testing:

1. **Database Creation**: Creates a test database (in-memory for SQLite, temporary for PostgreSQL/MySQL)
2. **Schema Setup**: Runs migrations or loads a schema dump if available
3. **Seeding**: Optionally runs seeders before each test
4. **Transaction Wrapping**: Each test runs in a transaction that's automatically rolled back
5. **Cleanup**: Proper cleanup after all tests complete

## Configuration Options

### Refresh Strategy

Control how the database is reset between tests:

```dart
setUpOrmed(
  driver: SqliteDriver.memory(),
  entities: [User, Post],
  migrations: buildMigrations(),
  refreshStrategy: DatabaseRefreshStrategy.rollback, // Default
);
```

Available strategies:
- `DatabaseRefreshStrategy.rollback`: Fastest - wraps each test in a transaction and rolls back (default)
- `DatabaseRefreshStrategy.migrate`: Drops all tables and re-runs migrations before each test
- `DatabaseRefreshStrategy.schemaDump`: Loads from schema dump before each test (if available)

### Running Seeders

Run seeders before tests to set up common data:

```dart
setUpOrmed(
  driver: SqliteDriver.memory(),
  entities: [User, Post],
  migrations: buildMigrations(),
  seeders: [DatabaseSeeder()], // Run before each test
);
```

### Custom Database Configuration

Use different drivers for different test scenarios:

```dart
// SQLite in-memory (fastest)
setUpOrmed(
  driver: SqliteDriver.memory(),
  entities: [User, Post],
  migrations: buildMigrations(),
);

// SQLite file-based
setUpOrmed(
  driver: SqliteDriver.file('test_database.db'),
  entities: [User, Post],
  migrations: buildMigrations(),
);

// PostgreSQL
setUpOrmed(
  driver: PostgresDriver(
    host: 'localhost',
    database: 'ormed_test',
    username: 'test',
    password: 'test',
  ),
  entities: [User, Post],
  migrations: buildMigrations(),
);
```

## Using Schema Dumps for Faster Tests

For large applications with many migrations, schema dumps significantly speed up test execution:

```bash
# Create schema dump from your current database
dart run orm schema:dump

# This creates database/schema.sql
```

Then in your tests, Ormed will automatically use the schema dump:

```dart
setUpOrmed(
  driver: SqliteDriver.memory(),
  entities: [User, Post],
  migrations: buildMigrations(),
  refreshStrategy: DatabaseRefreshStrategy.schemaDump, // Use dump
);
```

When using schema dumps:
1. On the first test, the schema is loaded from the dump file
2. Any migrations created after the dump are applied
3. Tests run much faster than running hundreds of migrations

## Advanced: Per-Test Customization

Use the `ormedTest()` helper for fine-grained control over individual tests:

```dart
void main() {
  setUpOrmed(
    driver: SqliteDriver.memory(),
    entities: [User, Post],
    migrations: buildMigrations(),
  );

  ormedTest('test with custom setup', () async {
    final db = getTestDatabase();
    
    // This test has access to the configured database
    final repo = db.repository<User>();
    // ... test code
  });

  ormedTest('another test', () async {
    final db = getTestDatabase();
    
    // Fresh database state - previous test was rolled back
    final repo = db.repository<Post>();
    // ... test code
  });
}
```

## Complete Example: Blog Application

Here's a complete example testing a blog application:

```dart
import 'package:test/test.dart';
import 'package:ormed/testing.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

import 'entities/user.dart';
import 'entities/post.dart';
import 'entities/comment.dart';
import 'database/migrations/registry.dart';
import 'database/seeds/test_data_seeder.dart';

void main() {
  setUpOrmed(
    driver: SqliteDriver.memory(),
    entities: [User, Post, Comment],
    migrations: buildMigrations(),
    seeders: [TestDataSeeder()],
  );

  group('Post creation', () {
    test('user can create post with title and content', () async {
      final db = getTestDatabase();
      final postRepo = db.repository<Post>();
      
      final post = Post(
        id: 100,
        userId: 1, // From seeder
        title: 'Test Post',
        content: 'Test content',
      );
      
      await postRepo.insert(post);
      
      final found = await postRepo.findOneOrFail(100);
      expect(found.title, equals('Test Post'));
      expect(found.content, equals('Test content'));
    });

    test('post requires title', () async {
      final db = getTestDatabase();
      final postRepo = db.repository<Post>();
      
      final post = Post(
        id: 101,
        userId: 1,
        title: '', // Invalid
        content: 'Test',
      );
      
      // This should throw a validation error
      expect(
        () => postRepo.insert(post),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('Comments', () {
    test('can add comment to post', () async {
      final db = getTestDatabase();
      final commentRepo = db.repository<Comment>();
      
      final comment = Comment(
        id: 1,
        postId: 1, // From seeder
        userId: 1, // From seeder
        content: 'Great post!',
      );
      
      await commentRepo.insert(comment);
      
      final comments = await commentRepo
          .query()
          .where((t) => t.postId.equals(1))
          .findMany();
      
      expect(comments, hasLength(1));
      expect(comments.first.content, equals('Great post!'));
    });

    test('can delete comment', () async {
      final db = getTestDatabase();
      final commentRepo = db.repository<Comment>();
      
      // Insert then delete
      final comment = Comment(
        id: 2,
        postId: 1,
        userId: 1,
        content: 'Test comment',
      );
      await commentRepo.insert(comment);
      
      await commentRepo.delete(comment);
      
      final found = await commentRepo.findOne(2);
      expect(found, isNull);
    });
  });

  group('Relationships', () {
    test('can load post with comments', () async {
      final db = getTestDatabase();
      final postRepo = db.repository<Post>();
      final commentRepo = db.repository<Comment>();
      
      // Create post
      final post = Post(
        id: 200,
        userId: 1,
        title: 'Post with comments',
        content: 'Content',
      );
      await postRepo.insert(post);
      
      // Add comments
      for (int i = 0; i < 3; i++) {
        await commentRepo.insert(Comment(
          id: 100 + i,
          postId: 200,
          userId: 1,
          content: 'Comment $i',
        ));
      }
      
      // Load with relationship
      final loaded = await postRepo
          .query()
          .where((t) => t.id.equals(200))
          .with_((t) => t.comments)
          .findOneOrFail();
      
      expect(loaded.comments, hasLength(3));
    });
  });
}
```

## Testing Best Practices

### 1. Use Seeders for Common Data

Create seeders for data that many tests need:

```dart
class TestDataSeeder extends Seeder {
  @override
  Future<void> run(DataSource dataSource) async {
    final userRepo = dataSource.repository<User>();
    
    await userRepo.insertMany([
      User(id: 1, name: 'Alice', email: 'alice@test.com'),
      User(id: 2, name: 'Bob', email: 'bob@test.com'),
    ]);
  }
}
```

### 2. Keep Tests Isolated

Each test should be independent and not rely on data from other tests. The automatic transaction rollback ensures this.

### 3. Use In-Memory Databases for Speed

For unit tests, use in-memory SQLite for maximum speed:

```dart
setUpOrmed(
  driver: SqliteDriver.memory(), // Fastest option
  // ...
);
```

### 4. Test Against Real Databases for Integration Tests

For integration tests, use the actual database you'll use in production:

```dart
setUpOrmed(
  driver: PostgresDriver(/* ... */), // Match production
  // ...
);
```

### 5. Use Schema Dumps in CI/CD

In your CI pipeline, use schema dumps to speed up test execution:

```yaml
# .github/workflows/test.yml
- name: Create schema dump
  run: dart run orm schema:dump
  
- name: Run tests
  run: dart test
```

## Conclusion

Ormed's unified testing API makes it simple to write fast, isolated tests. With a single `setUpOrmed()` call, you get automatic database setup, transaction wrapping, and cleanup - letting you focus on writing great tests instead of managing test infrastructure.
