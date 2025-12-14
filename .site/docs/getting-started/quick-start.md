---
sidebar_position: 2
---

# Quick Start

This guide will walk you through creating a simple Ormed application with a User model.

## 1. Create Your Model

Create `lib/src/models/user.dart`:

```dart file=../../examples/lib/models/user.dart#basic-model
```

## 2. Generate ORM Code

Run the build runner:

```bash
dart run build_runner build
```

This creates `user.orm.dart` with the generated `$User` class and helpers.

## 3. Create a Migration

Create `lib/src/database/migrations/m_20241201000000_create_users_table.dart`:

```dart file=../../examples/lib/migrations/basic.dart#create-users-migration
```

## 4. Set Up the Database

```dart file=../../examples/lib/setup.dart#quickstart-setup
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
