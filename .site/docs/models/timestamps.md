---
sidebar_position: 3
---

# Timestamps

Ormed provides automatic timestamp management for `created_at` and `updated_at` columns.

## Enabling Timestamps

Add the `Timestamps` marker mixin to your model:

```dart
import 'package:ormed/ormed.dart';

part 'post.orm.dart';

@OrmModel(table: 'posts')
class Post extends Model<Post> with Timestamps {
  const Post({
    required this.id,
    required this.title,
  });

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String title;
}
```

The code generator detects this mixin and:
- Adds virtual `createdAt` and `updatedAt` fields if not explicitly defined
- Applies timestamp implementation to the generated tracked class
- Automatically sets timestamps on insert/update operations

## Timezone-Aware Timestamps

For timestamps stored in UTC, use `TimestampsTZ`:

```dart
@OrmModel(table: 'posts')
class Post extends Model<Post> with TimestampsTZ {
  // ...
}
```

This ensures:
- All timestamps are converted to UTC before storage
- Timestamps remain in UTC when retrieved
- Your application handles timezone conversion for display

## Migration Setup

Add timestamp columns in your migration:

```dart
schema.create('posts', (table) {
  table.id();
  table.string('title');

  // Non-timezone aware (stored as-is)
  table.timestamps();

  // OR timezone aware (UTC storage)
  table.timestampsTz();

  // OR nullable timestamps
  table.nullableTimestamps();
  table.nullableTimestampsTz();
});
```

## Custom Column Names

By default, Ormed uses `created_at` and `updated_at`. These can be customized via model configuration if needed.

## Behavior

### On Insert

- `created_at` is set to the current timestamp
- `updated_at` is set to the current timestamp

### On Update

- `updated_at` is automatically updated
- `created_at` remains unchanged

### Manual Control

You can manually set timestamps if needed:

```dart
final post = $Post(
  id: 0,
  title: 'My Post',
  createdAt: DateTime(2024, 1, 1),  // Override
);
```

## Without Timestamps

If you don't need automatic timestamps, simply don't include the mixin:

```dart
@OrmModel(table: 'logs')
class Log extends Model<Log> {
  // No timestamps mixin - manual control
  const Log({
    required this.id,
    required this.message,
    this.timestamp,
  });

  @OrmField(isPrimaryKey: true)
  final int id;

  final String message;
  final DateTime? timestamp;
}
```
