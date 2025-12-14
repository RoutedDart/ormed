---
sidebar_position: 5
---

# Model Methods

Laravel-inspired convenience methods for working with model instances.

## Model Replication

### replicate()

Clone a model without primary key or timestamps:

```dart
final original = await User.query().find(1);

// Create a replica
final duplicate = original.replicate();
duplicate.setAttribute('email', 'new@example.com');
await duplicate.save();
```

**What gets excluded:**
- Primary key (automatically)
- Timestamps: `created_at`, `updated_at`, `createdAt`, `updatedAt`
- Any fields specified in the `except` parameter

### Excluding Specific Fields

```dart
final post = await Post.query().find(1);
final duplicate = post.replicate(except: ['slug', 'viewCount']);

duplicate.setAttribute('slug', 'new-unique-slug');
duplicate.setAttribute('viewCount', 0);
await duplicate.save();
```

:::warning
Cannot exclude required non-nullable fields. Only exclude nullable fields or fields with defaults.
:::

### Use Cases

**Duplicating Records:**
```dart
final product = await Product.query().find(productId);
final duplicate = product.replicate(except: ['sku', 'barcode']);

duplicate.setAttribute('sku', generateUniqueSKU());
duplicate.setAttribute('name', '${product.name} (Copy)');
await duplicate.save();
```

**Test Fixtures:**
```dart
final template = User(name: 'Test User', role: 'admin', active: true);

final user1 = template.replicate();
user1.setAttribute('email', 'user1@test.com');

final user2 = template.replicate();
user2.setAttribute('email', 'user2@test.com');

await dataSource.repo<$User>().insertMany([user1, user2]);
```

## Model Comparison

### isSameAs()

Check if two models represent the same database record:

```dart
final user1 = await User.query().find(1);
final user2 = await User.query().find(1);

if (user1.isSameAs(user2)) {
  print('These are the same user');
}
```

**Comparison logic:**
1. Compares primary key values
2. Compares table names
3. Compares connection names (if available)

### isDifferentFrom()

Inverse of `isSameAs()`:

```dart
final user1 = await User.query().find(1);
final user2 = await User.query().find(2);

if (user1.isDifferentFrom(user2)) {
  print('These are different users');
}
```

### Use Cases

**Deduplication:**
```dart
final users = await User.query().get();
final unique = <User>[];

for (final user in users) {
  if (!unique.any((u) => u.isSameAs(user))) {
    unique.add(user);
  }
}
```

**Validation:**
```dart
void processTransfer(Account from, Account to) {
  if (from.isSameAs(to)) {
    throw ArgumentError('Cannot transfer to the same account');
  }
  // Process transfer...
}
```

## Refreshing Models

### fresh()

Get a new instance from the database without modifying the current instance:

```dart
final user = await User.query().find(1);
user.setAttribute('name', 'Changed locally');

// Get fresh data from database
final fresh = await user.fresh();

print(user.name); // 'Changed locally' (original unchanged)
print(fresh.name); // Original value from database
```

### refresh()

Reload the current instance, discarding local changes:

```dart
final user = await User.query().find(1);
user.setAttribute('name', 'Changed locally');

// Discard changes and reload
await user.refresh();

print(user.name); // Original value (changes lost)
```

### When to Use Which

| Scenario | Use | Reason |
|----------|-----|--------|
| Compare before/after | `fresh()` | Need both versions |
| Discard local changes | `refresh()` | Want to reset state |
| Check for external changes | `fresh()` | Compare instances |
| Reload after failed save | `refresh()` | Reset to DB state |

### With Eager Loading

```dart
// Load relationships when refreshing
final fresh = await user.fresh(withRelations: ['posts', 'comments']);
await user.refresh(withRelations: ['posts', 'comments']);
```

### With Soft Deletes

```dart
// Include soft-deleted records
final fresh = await user.fresh(withTrashed: true);
await user.refresh(withTrashed: true);
```

### Use Cases

**Optimistic Locking:**
```dart
final user = await User.query().find(1);
final originalUpdatedAt = user.updatedAt;

user.setAttribute('name', 'New Name');

// Check for concurrent modifications
final fresh = await user.fresh();
if (fresh.updatedAt != originalUpdatedAt) {
  throw ConcurrentModificationException('Record modified by another user');
}

await user.save();
```

**Discarding Failed Edits:**
```dart
final user = await User.query().find(1);

try {
  user.setAttribute('email', newEmail);
  await user.save();
} catch (e) {
  await user.refresh(); // Restore original state
  logger.error('Save failed, state restored', e);
}
```

## Model State

### exists

Check if a model is persisted in the database:

```dart
final user = User(email: 'new@example.com', active: true);
print(user.exists); // false

await user.save();
print(user.exists); // true
```

### wasRecentlyCreated

Check if a model was just inserted:

```dart
final user = User(email: 'new@example.com');
await user.save();

if (user.wasRecentlyCreated) {
  await sendWelcomeEmail(user);
} else {
  await sendUpdateNotification(user);
}
```

## save() Upsert Behavior

The `save()` method uses upsert semantics:

- **New models** (no primary key or not persisted): performs `INSERT`
- **Existing models** (primary key present and was hydrated): performs `UPSERT`

```dart
// Insert a new model
final user = $User(id: 100, email: 'assigned@example.com');
await user.save(); // Inserts

// Update an existing model
user.setAttribute('email', 'updated@example.com');
await user.save(); // Updates

// If externally deleted, save() will re-insert
await user.save(); // Falls back to insert if 0 rows affected
```

## Static Helpers

After binding a connection resolver, `Model<T>` provides Laravel-style helpers:

```dart
final registry = buildOrmRegistry();
final context = QueryContext(registry: registry, driver: adapter);

Model.bindConnectionResolver(resolveConnection: (_) => context);

// Now use static helpers
final user = await Model.create<User>($User(id: 0, email: 'hi@example.com'));
await user.refresh();
await user.delete();
await user.restore();

final emails = await Model.query<User>().orderBy('id').get();
```

Available methods:
- `Model.query<T>()` - Query builder
- `Model.all<T>()` - Get all records
- `Model.create<T>(model)` - Insert a model
- Instance: `save()`, `delete()`, `forceDelete()`, `restore()`, `refresh()`
