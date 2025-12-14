---
sidebar_position: 1
slug: /
---

# Introduction

Ormed is a **strongly-typed ORM for Dart** inspired by Eloquent, GORM, SQLAlchemy, and ActiveRecord. It combines compile-time code generation with runtime flexibility to deliver type-safe database operations.

## Features

- **Type-safe queries** - Fluent query builder with compile-time type checking
- **Code generation** - Automatic generation of model definitions, codecs, and helpers
- **Flexible input handling** - Accept tracked models, DTOs, or raw maps for CRUD operations
- **Relationship support** - hasOne, hasMany, belongsTo, belongsToMany with eager/lazy loading
- **Soft deletes** - Built-in support for soft delete patterns
- **Timestamps** - Automatic timestamp management for created_at/updated_at
- **Migrations** - Fluent schema builder with reversible migrations
- **Multi-database** - Support for SQLite, PostgreSQL, MySQL (planned)
- **Value codecs** - Custom type serialization between Dart and database

## Quick Example

```dart
import 'package:ormed/ormed.dart';

part 'user.orm.dart';

@OrmModel(table: 'users')
class User extends Model<User> {
  const User({required this.id, required this.email, this.name});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String email;
  final String? name;
}

// Query with fluent API
final users = await dataSource.query<$User>()
    .whereEquals('active', true)
    .orderBy('createdAt', descending: true)
    .limit(10)
    .get();

// Repository operations
final repo = dataSource.repo<$User>();
final user = await repo.find(1);
await repo.update(user..name = 'John');
```

## Installation

Add Ormed to your `pubspec.yaml`:

```yaml
dependencies:
  ormed: ^latest
  ormed_sqlite: ^latest

dev_dependencies:
  build_runner: ^2.4.0
```

Then run:

```bash
dart pub get
dart run build_runner build
```

## Next Steps

- [Quick Start Guide](/docs/getting-started/quick-start) - Get up and running in 5 minutes
- [Defining Models](/docs/models/defining-models) - Learn how to create ORM models
- [Query Builder](/docs/queries/query-builder) - Master the fluent query API
- [Migrations](/docs/migrations/overview) - Manage your database schema
