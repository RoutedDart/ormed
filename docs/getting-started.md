# Getting Started with Ormed

## Installation

Add Ormed to your `pubspec.yaml`:

```yaml
dependencies:
  ormed: ^latest_version
  ormed_sqlite: ^latest_version  # or ormed_postgres, ormed_mysql, ormed_mongo

dev_dependencies:
  build_runner: ^latest_version
  ormed_generator: ^latest_version
```

Then run:

```bash
dart pub get
```

## Quick Start

### 1. Define Your Models

Create a model class and annotate it with `@Orm()`:

```dart
import 'package:ormed/ormed.dart';

part 'user.orm.dart';

@Orm(table: 'users')
class User extends Model<User> {
  @PrimaryKey(autoIncrement: true)
  int? id;

  @Column()
  String name;

  @Column()
  String email;

  @Column()
  DateTime? createdAt;

  User({
    this.id,
    required this.name,
    required this.email,
    this.createdAt,
  });
}
```

### 2. Generate ORM Code

Run the code generator:

```bash
dart run build_runner build
```

This creates `user.orm.dart` with all the ORM machinery.

### 3. Set Up Your Database Connection

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'user.dart';

Future<void> main() async {
  // Create a DataSource
  final dataSource = DataSource(DataSourceOptions(
    name: 'primary',
    driver: SqliteDriverAdapter.file('app.sqlite'),
    entities: [UserOrmDefinition.definition],
  ));

  // Initialize the connection
  await dataSource.init();

  // Now you can use your models!
  final user = User(name: 'Alice', email: 'alice@example.com');
  await user.save();

  print('User saved with ID: ${user.id}');
}
```

### 4. Using Static Helpers

Once initialized, you can use static helpers directly:

```dart
// After dataSource.init(), static helpers work automatically
final users = await User.all();
final alice = await User.find(1);
final active = await User.query().where('status', '=', 'active').get();
```

The DataSource automatically registers with ConnectionManager during init, making static helpers available immediately.

## Basic Operations

### Creating Records

```dart
// Create and save
final user = User(name: 'Bob', email: 'bob@example.com');
await user.save();

// Mass assignment
final user2 = User.make({'name': 'Charlie', 'email': 'charlie@example.com'});
await user2.save();
```

### Reading Records

```dart
// Find by primary key
final user = await User.find(1);

// Get all records
final users = await User.all();

// Query with conditions
final activeUsers = await User.query()
    .where('status', '=', 'active')
    .orderBy('name')
    .get();

// Get first matching record
final admin = await User.query()
    .where('role', '=', 'admin')
    .first();
```

### Updating Records

```dart
// Update and save
final user = await User.find(1);
user.name = 'Updated Name';
await user.save();

// Mass update
await User.query()
    .where('status', '=', 'pending')
    .update({'status': 'active'});
```

### Deleting Records

```dart
// Delete a model instance
final user = await User.find(1);
await user.delete();

// Delete by query
await User.query()
    .where('status', '=', 'inactive')
    .delete();
```

## Next Steps

- [Models Guide](models.md) - Learn about defining models, relationships, and hooks
- [Query Builder](query-builder.md) - Master the query builder API
- [Relationships](relationships.md) - Define and work with model relationships
- [Migrations](migrations.md) - Manage your database schema
- [Multi-Database](multi-database.md) - Work with multiple databases
- [Testing](testing.md) - Test your Ormed application

## Examples

Check out the example projects:

- [SQLite Example](../packages/ormed_sqlite/example/)
- [PostgreSQL Example](../packages/ormed_postgres/example/)
- [MySQL Example](../packages/ormed_mysql/example/)
- [MongoDB Example](../packages/ormed_mongo/example/)
