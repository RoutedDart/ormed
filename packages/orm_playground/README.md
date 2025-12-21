# orm_playground

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/docs-ormed.vercel.app-blue)](https://ormed.vercel.app/)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow?logo=buy-me-a-coffee)](https://www.buymeacoffee.com/kingwill101)

A demonstration and sandbox package that exercises the ormed ORM end-to-end. Use it as a reference for ORM patterns and features.

## Features

- Pre-configured migrations and seeders
- Example models with relationships
- Multi-tenant/multi-database configuration
- Runnable demos showcasing the DataSource API

## Quick Start

### 1. Apply Migrations

```bash
cd packages/orm_playground

# Apply migrations to default connection
dart run ormed_cli:orm migrate

# Check migration status
dart run ormed_cli:orm migrate:status

# Run seeders
dart run ormed_cli:orm seed
```

### 2. Run the Demo

```bash
# Run the main demo
dart run bin/orm_playground.dart

# Enable SQL logging
dart run bin/orm_playground.dart --sql

# Seed before running
dart run bin/orm_playground.dart --seed DemoContentSeeder
```

## Example Models

### User

```dart
@OrmModel(table: 'users')
class User {
  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;
  final String email;
  final String? name;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
```

### Post (with relationships)

```dart
@OrmModel(table: 'posts')
class Post {
  final int id;
  final int userId;
  final String title;
  final String? body;
  final bool published;
  final DateTime? publishedAt;

  @OrmRelation.belongsTo(related: User, foreignKey: 'user_id')
  final User? author;

  @OrmRelation.manyToMany(related: Tag, pivot: 'post_tags')
  final List<Tag> tags;

  @OrmRelation.hasMany(related: Comment, foreignKey: 'post_id')
  final List<Comment> comments;
}
```

## DataSource API

```dart
import 'package:ormed/ormed.dart';
import 'package:orm_playground/orm_playground.dart';

void main() async {
  final database = PlaygroundDatabase();
  final ds = await database.dataSource();

  // Query with relations
  final posts = await ds.query<\$Post>()
      .withRelation('author')
      .withRelation('tags')
      .orderByDesc('created_at')
      .limit(10)
      .get();

  // Aggregate queries
  final postCount = await ds.query<\$Post>()
      .withCount('comments')
      .get();

  // Repository operations
  await ds.repo<\$User>().insert(
    \$UserInsertDto(email: 'new@example.com', name: 'New User'),
  );

  // Transactions
  await ds.transaction(() async {
    await ds.repo<\$User>().insert(userDto);
    await ds.repo<\$Post>().insert(postDto);
  });

  // Ad-hoc table queries
  final logs = await ds.table('audit_logs')
      .whereEquals('action', 'login')
      .get();

  // SQL preview without execution
  final plan = await ds.pretend(() async {
    await ds.query<\$Post>().get();
  });
  print(plan.statements);

  await database.dispose();
}
```

## Configuration (orm.yaml)

```yaml
default_connection: default

connections:
  default:
    driver:
      type: sqlite
      options:
        database: database.sqlite
    migrations:
      directory: lib/src/database/migrations
      registry: lib/src/database/migrations.dart
      ledger_table: orm_migrations
    seeds:
      directory: lib/src/database/seeders
      registry: lib/src/database/seeders.dart

  analytics:
    driver:
      type: sqlite
      options:
        database: database.analytics.sqlite
```

### Multi-Database Operations

```bash
# Migrate specific connection
dart run ormed_cli:orm migrate --connection analytics

# Seed specific connection
dart run ormed_cli:orm seed --connection analytics
```

## Directory Structure

```
orm_playground/
├── orm.yaml                 # ORM configuration
├── bin/
│   ├── orm_playground.dart  # Main demo
│   └── multi_tenant_demo.dart
└── lib/
    ├── orm_playground.dart
    ├── orm_registry.g.dart
    └── src/
        ├── database.dart    # PlaygroundDatabase helper
        ├── database/
        │   ├── migrations/
        │   ├── migrations.dart
        │   ├── seeders/
        │   └── seeders.dart
        └── models/
            ├── user.dart
            ├── post.dart
            ├── tag.dart
            └── comment.dart
```

## Demo Features

The main demo showcases:

1. **Post Summaries** - Fetching posts with eager-loaded relations
2. **Query Builder** - withCount, table queries, ordering
3. **Table Helpers** - Ad-hoc joins on pivot tables
4. **SQL Preview** - Pretend mode for SQL capture
5. **Model CRUD** - Insert, update, delete via repositories
6. **Relation Queries** - whereHas, withExists, orderByRelation
7. **Pagination** - Paginated results
8. **Chunking** - Processing large result sets
9. **Transactions** - Atomic multi-model operations

## Environment Variables

| Variable | Description |
|----------|-------------|
| `PLAYGROUND_DB` | Override database path |
| `PLAYGROUND_LOG_SQL` | Enable SQL logging (`true`) |

## Related Packages

| Package | Description |
|---------|-------------|
| `ormed` | Core ORM library |
| `ormed_sqlite` | SQLite driver |
| `ormed_cli` | CLI tool for migrations |
