# Testing with Schema Manager

The `TestSchemaManager` provides a driver-agnostic way to manage database schema and seeding in your tests. It brings together migration management and data seeding capabilities to empower you to write comprehensive database tests.

## Overview

`TestSchemaManager` helps you:

- Run migrations from `MigrationDescriptor` lists
- Seed test data using `DatabaseSeeder` classes
- Reset schema between tests for isolation
- Debug seeders with pretend mode
- Check migration status

## Basic Usage

### 1. Set Up Test Schema

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed/testing.dart';

// Define your migrations
final testMigrations = [
  MigrationDescriptor.fromMigration(
    id: MigrationId(DateTime.utc(2024, 1, 1, 0, 0, 1), 'create_users_table'),
    migration: CreateUsersTable(),
  ),
  MigrationDescriptor.fromMigration(
    id: MigrationId(DateTime.utc(2024, 1, 1, 0, 0, 2), 'create_posts_table'),
    migration: CreatePostsTable(),
  ),
];

void main() async {
  final connection = await createTestConnection();
  final schemaDriver = connection.driver as SchemaDriver;
  
  // Create the manager
  final manager = TestSchemaManager(
    schemaDriver: schemaDriver,
    migrations: testMigrations,
  );
  
  // Run migrations
  await manager.setup();
  
  // Your tests here
  
  // Clean up
  await manager.teardown();
}
```

### 2. Seed Test Data

```dart
// Define a seeder
class UserSeeder extends DatabaseSeeder {
  UserSeeder(super.connection);
  
  @override
  Future<void> run() async {
    await seed<User>([
      {'name': 'John Doe', 'email': 'john@example.com'},
      {'name': 'Jane Smith', 'email': 'jane@example.com'},
    ]);
  }
}

// Use the seeder
await manager.setup();
await manager.seed(connection, [UserSeeder.new]);
```

## Working with Model Definitions

You can pass `ModelDefinition` lists to the manager for reference, though migrations are the primary way to define schema:

```dart
final manager = TestSchemaManager(
  schemaDriver: schemaDriver,
  modelDefinitions: [
    UserOrmDefinition.definition,
    PostOrmDefinition.definition,
  ],
  migrations: testMigrations,
);
```

This is useful when you need to use `purge()` to drop all tables without going through migrations.

## Seeding Strategies

### Basic Seeding

```dart
class UserSeeder extends DatabaseSeeder {
  UserSeeder(super.connection);
  
  @override
  Future<void> run() async {
    await seed<User>([
      {'name': 'Alice', 'email': 'alice@example.com'},
      {'name': 'Bob', 'email': 'bob@example.com'},
    ]);
  }
}
```

### Composite Seeders

Seeders can call other seeders to manage dependencies:

```dart
class DatabaseSeederMain extends DatabaseSeeder {
  DatabaseSeederMain(super.connection);
  
  @override
  Future<void> run() async {
    // Run seeders in order
    await call([
      UserSeeder.new,
      PostSeeder.new,
      CommentSeeder.new,
    ]);
  }
}
```

### Seeder Registry

For more control, use `SeederRegistration` and `runSeederRegistry`:

```dart
final seeders = [
  SeederRegistration(name: 'UserSeeder', factory: UserSeeder.new),
  SeederRegistration(name: 'PostSeeder', factory: PostSeeder.new),
];

// Run specific seeders by name
await runSeederRegistry(
  connection,
  seeders,
  names: ['UserSeeder'],
  log: (message) => print(message),
);

// Run all seeders (defaults to first if no names provided)
await runSeederRegistry(connection, seeders);
```

## Test Isolation Strategies

### Strategy 1: Reset Between Tests

```dart
test('user creation', () async {
  await manager.reset(); // Tear down and set up
  
  final user = await User.create({'name': 'Test'}, connection: conn.name);
  expect(user.id, isNotNull);
});

test('post creation', () async {
  await manager.reset(); // Fresh schema for each test
  
  final post = await Post.create({'title': 'Test'}, connection: conn.name);
  expect(post.id, isNotNull);
});
```

### Strategy 2: Seed Once, Transaction Rollback

This is more efficient when combined with transaction-based test isolation:

```dart
setUpAll(() async {
  await manager.setup();
  await manager.seed(connection, [UserSeeder.new]);
});

setUp(() async {
  await connection.beginTransaction();
});

tearDown(() async {
  await connection.rollback();
});

tearDownAll(() async {
  await manager.teardown();
});
```

### Strategy 3: Manual Cleanup

```dart
setUp(() async {
  await manager.setup();
});

tearDown(() async {
  // Clear data but keep schema
  await connection.repository<Post>().query().delete();
  await connection.repository<User>().query().delete();
});

tearDownAll(() async {
  await manager.teardown();
});
```

## Pretend Mode

Debug your seeders by seeing what queries would be executed without actually running them:

```dart
final statements = await manager.seedWithPretend(
  connection,
  [UserSeeder.new],
  pretend: true,
);

for (final entry in statements) {
  final normalized = entry.preview.normalized;
  print('${normalized.command}');
  print('Parameters: ${normalized.parameters}');
}
```

## Migration Status

Check which migrations have been applied:

```dart
final status = await manager.status();

for (final migration in status) {
  print('${migration.descriptor.id.slug}: ${migration.applied}');
  if (migration.applied) {
    print('  Applied at: ${migration.appliedAt}');
    print('  Batch: ${migration.batch}');
  }
}
```

## Advanced Patterns

### Per-Test Schema Variations

```dart
group('user tests', () {
  late TestSchemaManager manager;
  
  setUp(() async {
    manager = TestSchemaManager(
      schemaDriver: schemaDriver,
      migrations: [userMigration],
    );
    await manager.setup();
  });
  
  tearDown(() async {
    await manager.teardown();
  });
  
  test('creates user', () async {
    // Test with user schema only
  });
});

group('full schema tests', () {
  late TestSchemaManager manager;
  
  setUp(() async {
    manager = TestSchemaManager(
      schemaDriver: schemaDriver,
      migrations: allMigrations,
    );
    await manager.setup();
  });
  
  tearDown(() async {
    await manager.teardown();
  });
  
  test('creates user with posts', () async {
    // Test with full schema
  });
});
```

### Conditional Seeding

```dart
class ConditionalSeeder extends DatabaseSeeder {
  ConditionalSeeder(super.connection, {required this.count});
  
  final int count;
  
  @override
  Future<void> run() async {
    final records = List.generate(
      count,
      (i) => {'name': 'User $i', 'email': 'user$i@example.com'},
    );
    await seed<User>(records);
  }
}

// Use it
await manager.seed(
  connection,
  [(_) => ConditionalSeeder(connection, count: 100)],
);
```

### Factory-Based Seeding

For more complex scenarios, use factories with seeders:

```dart
class UserFactorySeeder extends DatabaseSeeder {
  UserFactorySeeder(super.connection);
  
  @override
  Future<void> run() async {
    // Assuming you have ModelFactory set up
    final users = await ModelFactory.createMany<User>(10);
    
    for (final user in users) {
      await connection.repository<User>().insert(user);
    }
  }
}
```

## Purging Schema

If migrations fail or you need to forcefully clean up:

```dart
// Drop all tables without rolling back migrations
await manager.purge();
```

This is useful in emergency cleanup scenarios but should generally be avoided in favor of proper migration rollback.

## Driver Agnostic Design

`TestSchemaManager` works with any driver that implements `SchemaDriver`:

- PostgreSQL
- MySQL/MariaDB
- SQLite
- Custom drivers

All operations use the schema builder API, ensuring compatibility across drivers:

```dart
// Works with any driver
final manager = schemaDriver.testManager(
  migrations: testMigrations,
);
```

## Best Practices

### 1. Use Synthetic Timestamps

Keep migration timestamps consistent for tests:

```dart
final testMigrations = [
  MigrationDescriptor.fromMigration(
    id: MigrationId(DateTime.utc(2024, 1, 1, 0, 0, 1), 'first_migration'),
    migration: FirstMigration(),
  ),
  MigrationDescriptor.fromMigration(
    id: MigrationId(DateTime.utc(2024, 1, 1, 0, 0, 2), 'second_migration'),
    migration: SecondMigration(),
  ),
];
```

### 2. Share Migration Definitions

Define migrations once and reuse:

```dart
// In test/support/test_migrations.dart
final List<MigrationDescriptor> testMigrations = [
  // Your migrations
];

// In each test file
import 'package:my_app/test/support/test_migrations.dart';

final manager = TestSchemaManager(
  schemaDriver: schemaDriver,
  migrations: testMigrations,
);
```

### 3. Create Test Helpers

```dart
// test/support/test_helpers.dart
Future<TestSchemaManager> setupTestSchema(SchemaDriver driver) async {
  final manager = TestSchemaManager(
    schemaDriver: driver,
    migrations: testMigrations,
  );
  await manager.setup();
  return manager;
}

Future<void> seedTestData(OrmConnection connection) async {
  final manager = connection.driver.testManager(migrations: []);
  await manager.seed(connection, [
    UserSeeder.new,
    PostSeeder.new,
  ]);
}
```

### 4. Use with ormedTest

Combine with the `ormedTest` helper for comprehensive test setup:

```dart
void main() {
  late TestSchemaManager manager;
  late OrmConnection connection;
  
  setUpAll(() async {
    connection = await createTestConnection();
    manager = TestSchemaManager(
      schemaDriver: connection.driver as SchemaDriver,
      migrations: testMigrations,
    );
    await manager.setup();
  });
  
  tearDownAll(() async {
    await manager.teardown();
    await connection.close();
  });
  
  ormedTest('creates user', () async {
    final user = await User.create(
      {'name': 'Test'},
      connection: connection.name,
    );
    expect(user.id, isNotNull);
  });
}
```

## Comparison with driver_tests Pattern

The `TestSchemaManager` is inspired by the pattern used in `driver_tests`:

**driver_tests approach:**
```dart
final runner = MigrationRunner(
  schemaDriver: driver,
  ledger: SqlMigrationLedger(driver),
  migrations: driverTestMigrations,
);
await runner.applyAll();
```

**TestSchemaManager approach:**
```dart
final manager = TestSchemaManager(
  schemaDriver: driver,
  migrations: testMigrations,
);
await manager.setup();
await manager.seed(connection, [UserSeeder.new]);
```

The manager provides:
- Higher-level API
- Integrated seeding support
- Easy reset/teardown
- Pretend mode for debugging
- Status inspection

## Troubleshooting

### Migrations Not Applied

Check that your driver supports schema operations:

```dart
if (connection.driver is! SchemaDriver) {
  throw StateError('Driver does not support schema operations');
}
```

### Checksum Mismatches

Ensure migration descriptors are consistent:

```dart
// Don't modify migrations after they've been applied
// Create new migrations for schema changes
```

### Seeder Errors

Use pretend mode to debug:

```dart
final statements = await manager.seedWithPretend(
  connection,
  [YourSeeder.new],
  pretend: true,
);
// Inspect the queries
```

### Foreign Key Constraints

Ensure seeders run in the correct order:

```dart
class DatabaseSeederMain extends DatabaseSeeder {
  DatabaseSeederMain(super.connection);
  
  @override
  Future<void> run() async {
    // Seed parents before children
    await call([
      UserSeeder.new,      // Parent
      PostSeeder.new,      // Child (has user_id FK)
      CommentSeeder.new,   // Child (has post_id FK)
    ]);
  }
}
```

## API Reference

### TestSchemaManager

- `setup()` - Run all pending migrations
- `teardown()` - Roll back all applied migrations
- `reset()` - Tear down and set up again
- `purge()` - Drop all tables forcefully
- `status()` - Get migration status
- `seed(connection, seeders)` - Run seeders
- `seedWithPretend(connection, seeders, pretend: true)` - Debug seeders

### DatabaseSeeder

- `run()` - Execute the seeder (abstract)
- `seed<T>(records)` - Insert multiple records
- `call(factories)` - Run other seeders

### SeederRegistration

- `name` - Seeder name for CLI/registry
- `factory` - Factory function to create seeder

### runSeederRegistry

Run registered seeders by name with optional pretend mode and logging.