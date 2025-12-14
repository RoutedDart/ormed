---
sidebar_position: 2
---

# Quick Start

This guide will walk you through creating a simple Ormed application with a User model.

## 1. Create Your Model

Create `lib/src/models/user.dart`:

```dart
import 'package:ormed/ormed.dart';

part 'user.orm.dart';

@OrmModel(table: 'users')
class User extends Model<User> {
  const User({
    required this.id,
    required this.email,
    this.name,
    this.active = false,
  });

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String email;
  final String? name;
  final bool active;
}
```

## 2. Generate ORM Code

Run the build runner:

```bash
dart run build_runner build
```

This creates `user.orm.dart` with the generated `$User` class and helpers.

## 3. Create a Migration

Create `lib/src/database/migrations/m_20241201000000_create_users_table.dart`:

```dart
import 'package:ormed/migrations.dart';

class CreateUsersTable extends Migration {
  const CreateUsersTable();

  @override
  void up(SchemaBuilder schema) {
    schema.create('users', (table) {
      table.increments('id');
      table.string('email').unique();
      table.string('name').nullable();
      table.boolean('active').defaultValue(false);
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('users', ifExists: true);
  }
}
```

## 4. Set Up the Database

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'orm_registry.g.dart';  // Generated registry

Future<void> main() async {
  // Create SQLite driver (in-memory for this example)
  final driver = SqliteDriverAdapter.inMemory();

  // Use the generated registry helper
  final registry = buildOrmRegistry();

  // Or with factory support for Model.factory<T>()
  // final registry = buildOrmRegistryWithFactories();

  // Create data source
  final dataSource = DataSource(
    context: QueryContext(driver: driver, registry: registry),
  );

  // Run migrations (in production, use MigrationRunner)
  await driver.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email TEXT UNIQUE NOT NULL,
      name TEXT,
      active INTEGER DEFAULT 0
    )
  ''');

  // Now use the ORM!
  await useOrm(dataSource);

  await driver.close();
}

Future<void> useOrm(DataSource dataSource) async {
  final userRepo = dataSource.repo<$User>();

  // Insert a user
  final user = await userRepo.insert(
    $User(id: 0, email: 'john@example.com', name: 'John Doe', active: true),
  );
  print('Created user: ${user.id}');

  // Query users
  final activeUsers = await dataSource.query<$User>()
      .whereEquals('active', true)
      .get();
  print('Active users: ${activeUsers.length}');

  // Update a user
  final updatedUser = await userRepo.update(
    UserUpdateDto(name: 'John Smith'),
    where: {'id': user.id},
  );
  print('Updated name: ${updatedUser.name}');

  // Delete a user
  await userRepo.delete({'id': user.id});
  print('User deleted');
}
```

## 5. Run Your App

```bash
dart run lib/main.dart
```

Output:
```
Created user: 1
Active users: 1
Updated name: John Smith
User deleted
```

## Next Steps

- [Defining Models](../models/defining-models) - Learn about model annotations and fields
- [Query Builder](../queries/query-builder) - Master the fluent query API
- [Repository Pattern](../queries/repository) - CRUD operations with flexible inputs
- [Migrations](../migrations/overview) - Schema management and versioning
