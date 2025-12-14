---
sidebar_position: 4
---

# Soft Deletes

Soft deletes allow you to "delete" records by setting a timestamp rather than removing them from the database. This is useful for maintaining audit trails or implementing trash/restore functionality.

## Enabling Soft Deletes

Add the `SoftDeletes` marker mixin to your model:

```dart
import 'package:ormed/ormed.dart';

part 'post.orm.dart';

@OrmModel(table: 'posts')
class Post extends Model<Post> with SoftDeletes {
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
- Adds a virtual `deletedAt` field if not explicitly defined
- Applies soft-delete implementation to the generated tracked class
- Enables soft-delete query scopes automatically

## Timezone-Aware Soft Deletes

For deletion timestamps stored in UTC, use `SoftDeletesTZ`:

```dart
@OrmModel(table: 'posts')
class Post extends Model<Post> with SoftDeletesTZ {
  // ...
}
```

## Migration Setup

Add the soft delete column in your migration:

```dart
schema.create('posts', (table) {
  table.id();
  table.string('title');

  // Non-timezone aware
  table.softDeletes();

  // OR timezone aware (UTC storage)
  table.softDeletesTz();
});
```

## Querying Soft Deleted Records

### Default Behavior

By default, soft-deleted records are excluded from queries:

```dart
// Only returns non-deleted posts
final posts = await dataSource.query<$Post>().get();
```

### Include Soft Deleted

Use `withTrashed()` to include soft-deleted records:

```dart
// Returns all posts including deleted
final allPosts = await dataSource.query<$Post>()
    .withTrashed()
    .get();
```

### Only Soft Deleted

Use `onlyTrashed()` to get only soft-deleted records:

```dart
// Returns only deleted posts
final trashedPosts = await dataSource.query<$Post>()
    .onlyTrashed()
    .get();
```

## Soft Delete Operations

### Deleting Records

Standard delete operations soft-delete when the model has `SoftDeletes`:

```dart
final repo = dataSource.repo<$Post>();

// Soft delete (sets deleted_at)
await repo.delete(post);
await repo.delete({'id': postId});
```

### Restoring Records

Restore soft-deleted records:

```dart
// Restore a single record
await repo.restore(post);
await repo.restore({'id': postId});

// Restore using query callback
await repo.restore(
  (Query<$Post> q) => q.whereEquals('author_id', userId),
);
```

### Force Delete

Permanently remove a record (bypass soft delete):

```dart
// Permanently delete
await repo.forceDelete(post);
await repo.forceDelete({'id': postId});
```

## Checking Soft Delete Status

```dart
final post = await dataSource.query<$Post>()
    .withTrashed()
    .find(postId);

if (post.trashed) {
  print('Post was deleted at: ${post.deletedAt}');
}
```

## Combining with Timestamps

You can use both `Timestamps` and `SoftDeletes`:

```dart
@OrmModel(table: 'posts')
class Post extends Model<Post> with Timestamps, SoftDeletes {
  // ...
}

// Or timezone-aware versions
@OrmModel(table: 'posts')
class Post extends Model<Post> with TimestampsTZ, SoftDeletesTZ {
  // ...
}
```

Migration:

```dart
schema.create('posts', (table) {
  table.id();
  table.string('title');
  table.timestampsTz();   // created_at, updated_at
  table.softDeletesTz();  // deleted_at
});
```
