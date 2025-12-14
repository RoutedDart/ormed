---
sidebar_position: 1
---

# Migrations Overview

Migrations are version-controlled database schema changes. Each migration defines changes to apply in the `up` method and reverse operations in the `down` method.

## Introduction

Migrations solve a fundamental problem: how to evolve your database schema safely across different environments. Instead of manually running SQL, migrations provide a programmatic way to define schema changes that can be version-controlled, reviewed, and deployed consistently.

Ormed migrations support SQLite, PostgreSQL, and MySQL, providing a unified API for schema management.

## Basic Structure

Every migration extends the `Migration` base class:

```dart
import 'package:ormed/migrations.dart';

class CreateUsersTable extends Migration {
  const CreateUsersTable();

  @override
  void up(SchemaBuilder schema) {
    schema.create('users', (table) {
      table.integer('id').primaryKey();
      table.string('email').unique();
      table.string('name');
      table.timestamp('created_at').nullable();
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('users', ifExists: true);
  }
}
```

The `up` method runs when applying migrations, `down` runs during rollbacks. Always implement both to ensure migrations are reversible.

## Creating Tables

Use `schema.create()` to define a new table:

```dart
@override
void up(SchemaBuilder schema) {
  schema.create('posts', (table) {
    table.integer('id').primaryKey().autoIncrement();
    table.string('title');
    table.text('content');
    table.integer('author_id');
    table.boolean('published').defaultValue(false);
    table.timestamp('created_at').nullable();
    
    table.foreign(
      ['author_id'],
      references: 'users',
      referencedColumns: ['id'],
      onDelete: ReferenceAction.cascade,
    );
    
    table.index(['author_id', 'published']);
  });
}

@override
void down(SchemaBuilder schema) {
  schema.drop('posts', ifExists: true);
}
```

**Note:** Foreign key constraints require referenced tables to exist first. Create parent tables before child tables.

## Modifying Tables

Use `schema.table()` to alter existing tables:

```dart
@override
void up(SchemaBuilder schema) {
  schema.table('posts', (table) {
    table.string('slug').nullable();
    table.integer('view_count').defaultValue(0);
    table.index(['slug']).unique();
    table.renameColumn('content', 'body');
  });
}

@override
void down(SchemaBuilder schema) {
  schema.table('posts', (table) {
    table.renameColumn('body', 'content');
    table.dropColumn('view_count');
    table.dropColumn('slug');
  });
}
```

**When adding non-nullable columns** to tables with existing data:
- Make the column nullable: `table.string('slug').nullable()`
- Or provide a default: `table.string('status').defaultValue('draft')`

## Migration Naming

Migration files use timestamps for ordering: `m_YYYYMMDDHHMMSS_slug.dart`

Example: `m_20241129143052_create_users_table.dart`

Choose descriptive names:
- ✅ `create_users_table`
- ✅ `add_email_index_to_users`
- ✅ `remove_deprecated_status_column`
- ❌ `update_schema`
- ❌ `migration_v2`

## Runtime Concepts

| Concept | Description |
|---------|-------------|
| **Migration** | Dart class extending `Migration` with `up`/`down` methods |
| **MigrationDescriptor** | Stores migration ID, checksum, and compiled plans |
| **MigrationLedger** | Tracks applied migrations in the database |
| **MigrationRunner** | Applies/rolls back migrations and updates the ledger |

## Next Steps

- [Schema Builder](./schema-builder) - Complete API for defining columns, indexes, and constraints
- [Running Migrations](./running-migrations) - CLI and programmatic usage
- [CLI Commands](../cli/commands) - Full command reference
