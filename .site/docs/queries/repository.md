---
sidebar_position: 2
---

# Repository

Repositories provide CRUD operations with flexible input handling, accepting tracked models, DTOs, or raw maps.

## Getting a Repository

```dart
final userRepo = dataSource.repo<$User>();
```

## Insert Operations

### Insert Single

```dart
// With tracked model
final user = await userRepo.insert(
  $User(id: 0, email: 'john@example.com', name: 'John'),
);

// With insert DTO
final user = await userRepo.insert(
  UserInsertDto(email: 'john@example.com', name: 'John'),
);

// With raw map
final user = await userRepo.insert({
  'email': 'john@example.com',
  'name': 'John',
});
```

### Insert Many

```dart
final users = await userRepo.insertMany([
  $User(id: 0, email: 'user1@example.com'),
  $User(id: 0, email: 'user2@example.com'),
]);
```

### Upsert (Insert or Update)

```dart
// Insert if not exists, update if exists
final user = await userRepo.upsert(
  $User(id: 1, email: 'john@example.com', name: 'Updated Name'),
);
```

## Find Operations

### Find by Primary Key

```dart
final user = await userRepo.find(1);           // Returns null if not found
final user = await userRepo.findOrFail(1);     // Throws if not found
final users = await userRepo.findMany([1, 2, 3]);
```

### Get All

```dart
final users = await userRepo.all();
```

### First Record

```dart
final user = await userRepo.first();
final user = await userRepo.first(where: {'active': true});
```

### Count & Exists

```dart
final count = await userRepo.count();
final count = await userRepo.count(where: {'active': true});

final hasActive = await userRepo.exists({'active': true});
```

## Update Operations

### Update Single

```dart
// With tracked model (uses primary key)
user.name = 'Updated Name';
final updated = await userRepo.update(user);

// With DTO and where clause
final updated = await userRepo.update(
  UserUpdateDto(name: 'Updated Name'),
  where: {'id': 1},
);

// With Query callback
final updated = await userRepo.update(
  UserUpdateDto(name: 'Updated Name'),
  where: (Query<$User> q) => q.whereEquals('email', 'john@example.com'),
);
```

### Update Many

```dart
final updated = await userRepo.updateMany([
  $User(id: 1, email: 'user1@example.com', name: 'Name 1'),
  $User(id: 2, email: 'user2@example.com', name: 'Name 2'),
]);
```

### Where Parameter Types

The `where` parameter accepts various input types:

```dart
// Map
where: {'id': 1}

// Partial entity
where: $UserPartial(id: 1)

// DTO
where: UserUpdateDto(email: 'john@example.com')

// Tracked model (uses PK)
where: existingUser

// Query instance
where: dataSource.query<$User>().whereEquals('role', 'guest')

// Query callback (must type the parameter!)
where: (Query<$User> q) => q.whereEquals('email', 'john@example.com')
```

:::caution Important
When using a callback function for `where`, you **must** explicitly type the parameter:
```dart
// ✅ Correct - parameter is typed
where: (Query<$User> q) => q.whereEquals('email', 'test@example.com')

// ❌ Wrong - untyped parameter won't work with extension methods
where: (q) => q.whereEquals('email', 'test@example.com')
```
:::

## Delete Operations

### Delete Single

```dart
// By primary key
await userRepo.delete(1);

// By tracked model
await userRepo.delete(user);

// By where clause
await userRepo.delete({'email': 'john@example.com'});

// By Query callback
await userRepo.delete(
  (Query<$User> q) => q.whereEquals('role', 'guest'),
);
```

### Delete Many

```dart
await userRepo.deleteByIds([1, 2, 3]);

await userRepo.deleteMany([
  {'id': 1},
  (Query<$User> q) => q.whereEquals('role', 'guest'),
]);
```

## Soft Delete Operations

For models with `SoftDeletes`:

### Trash (Soft Delete)

```dart
await userRepo.delete(user);  // Sets deleted_at
```

### Restore

```dart
await userRepo.restore(user);
await userRepo.restore({'id': userId});
await userRepo.restore(
  (Query<$User> q) => q.whereEquals('role', 'guest'),
);
```

### Force Delete

```dart
await userRepo.forceDelete(user);  // Permanently removes
```

## Working with Relations

### Load Relations

```dart
final user = await userRepo.find(1);
await user.load(['posts', 'profile']);
```

### Save with Relations

```dart
// Associate belongsTo
post.associate('author', user);
await postRepo.update(post);

// Attach many-to-many
await post.attach('tags', [tag1.id, tag2.id]);

// Sync many-to-many
await post.sync('tags', [tag1.id, tag2.id, tag3.id]);
```

## Error Handling

```dart
try {
  final user = await userRepo.findOrFail(999);
} on ModelNotFoundException catch (e) {
  print('User not found: ${e.key}');
}

try {
  await userRepo.update(dto, where: {'id': 999});
} on NoRowsAffectedException {
  print('No rows were updated');
}
```
