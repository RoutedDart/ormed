# Model Instance Methods

Laravel-inspired convenience methods for working with model instances. These methods provide an intuitive API for common model operations like cloning, comparing, and refreshing data.

## Table of Contents

- [Overview](#overview)
- [Model Replication](#model-replication)
- [Model Comparison](#model-comparison)
- [Refreshing Models](#refreshing-models)
- [Model State](#model-state)
- [Complete Examples](#complete-examples)
- [Comparison with Laravel](#comparison-with-laravel)

---

## Overview

Model instance methods provide convenient ways to:
- **Clone models** without primary keys or timestamps
- **Compare models** to check if they represent the same database record
- **Refresh data** from the database
- **Track model state** (persisted, recently created, etc.)

These methods are available on all model instances and follow Laravel's conventions where applicable.

---

## Model Replication

### replicate()

Clone a model without primary key or timestamps:

```dart
import 'package:ormed/ormed.dart';

// Get an existing model
final original = await User.query().find(1);

// Create a replica
final duplicate = original.replicate();

// Modify the replica
duplicate.setAttribute('email', 'new@example.com');
duplicate.setAttribute('name', 'New User');

// Save as a new record
await duplicate.save();
```

**What gets excluded:**
- Primary key (automatically)
- Timestamps: `created_at`, `updated_at`, `createdAt`, `updatedAt`
- Any fields specified in the `except` parameter

**What gets copied:**
- All other field values
- Relationships are NOT copied (use eager loading if needed)

### Excluding Specific Fields

Use the `except` parameter to exclude additional fields:

```dart
final post = await Post.query().find(1);

// Exclude slug and view count
final duplicate = post.replicate(except: ['slug', 'viewCount']);

// Set new values for excluded fields
duplicate.setAttribute('slug', 'new-unique-slug');
duplicate.setAttribute('viewCount', 0);

await duplicate.save();
```

### Important Notes

⚠️ **Cannot exclude required non-nullable fields**

```dart
// User has a required 'email' field
final user = await User.query().find(1);

// BAD - email is required!
final replica = user.replicate(except: ['email']);
// This will fail because email cannot be null

// GOOD - exclude nullable fields only
final replica = user.replicate(except: ['name']); // name is nullable
```

✅ **Works with final fields**

```dart
// Even if your model uses final fields
class User extends Model<User> {
  const User({
    required this.id,
    required this.email,
    this.name,
  });
  
  final int id;
  final String email;
  final String? name;
}

// replicate() still works!
final replica = original.replicate();
```

### Use Cases

#### 1. Testing - Create Fixtures

```dart
// Create a template
final template = User(
  name: 'Test User',
  role: 'admin',
  active: true,
);

// Create variations easily
final user1 = template.replicate();
user1.setAttribute('email', 'user1@test.com');

final user2 = template.replicate();
user2.setAttribute('email', 'user2@test.com');

await dataSource.repo<User>().insertMany([user1, user2]);
```

#### 2. Duplicating Records

```dart
// Duplicate a product
final product = await Product.query().find(productId);
final duplicate = product.replicate(except: ['sku', 'barcode']);

duplicate.setAttribute('sku', generateUniqueSKU());
duplicate.setAttribute('barcode', generateBarcode());
duplicate.setAttribute('name', '${product.name} (Copy)');

await duplicate.save();
```

#### 3. Templates

```dart
// Use a model as a template
final template = await EmailTemplate.query()
    .where('type', 'welcome_email')
    .first();

final customized = template.replicate();
customized.setAttribute('recipientEmail', customer.email);
customized.setAttribute('subject', 'Welcome ${customer.name}!');

await customized.save();
```

---

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

Returns `true` only if all match.

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

#### 1. Deduplication

```dart
// Remove duplicate models from a list
final users = await User.query().get();
final unique = <User>[];

for (final user in users) {
  if (!unique.any((u) => u.isSameAs(user))) {
    unique.add(user);
  }
}
```

#### 2. Change Detection

```dart
// Check if a model was modified elsewhere
final user = await User.query().find(1);

// ... some time passes ...

final fresh = await user.fresh();
if (user.isDifferentFrom(fresh)) {
  print('User was modified by someone else!');
}
```

#### 3. Validation

```dart
// Ensure two references point to the same record
void processTransfer(Account from, Account to) {
  if (from.isSameAs(to)) {
    throw ArgumentError('Cannot transfer to the same account');
  }
  
  // Process transfer...
}
```

#### 4. Relationship Integrity

```dart
final post = await Post.query().with('author').find(1);
final author = await User.query().find(post.authorId);

if (post.author.isSameAs(author)) {
  print('Relationship is correct');
}
```

---

## Refreshing Models

### fresh()

Get a new instance from the database without modifying the current instance:

```dart
final user = await User.query().find(1);

// Make local changes
user.setAttribute('name', 'Changed locally');

// Get fresh data from database
final fresh = await user.fresh();

print(user.name); // 'Changed locally' (original unchanged)
print(fresh.name); // Original value from database
```

**Key points:**
- Returns a NEW instance
- Original instance unchanged
- Queries the database
- Useful for comparisons

### refresh()

Reload the current instance from the database, discarding local changes:

```dart
final user = await User.query().find(1);

// Make local changes
user.setAttribute('name', 'Changed locally');
user.setAttribute('email', 'new@example.com');

// Discard changes and reload from database
await user.refresh();

print(user.name); // Original value from database (changes lost)
```

**Key points:**
- Modifies the CURRENT instance
- Discards local changes
- Queries the database
- Use when you want to reset state

### When to Use Which

| Scenario | Use | Reason |
|----------|-----|--------|
| Compare before/after | `fresh()` | Need both versions |
| Discard local changes | `refresh()` | Want to reset state |
| Check for external changes | `fresh()` | Compare instances |
| Reload after failed save | `refresh()` | Reset to DB state |
| Implement optimistic locking | `fresh()` | Compare versions |

### With Eager Loading

Both methods support eager loading:

```dart
// Load relationships when refreshing
final user = await User.query().find(1);

// Fresh with relations
final fresh = await user.fresh(withRelations: ['posts', 'comments']);

// Refresh with relations
await user.refresh(withRelations: ['posts', 'comments']);
```

### With Soft Deletes

Handle trashed records:

```dart
// Include soft-deleted records
final user = await User.query().find(1);

final fresh = await user.fresh(withTrashed: true);
await user.refresh(withTrashed: true);
```

### Use Cases

#### 1. Optimistic Locking

```dart
// Check for concurrent modifications
final user = await User.query().find(1);
final originalUpdatedAt = user.updatedAt;

// Make changes
user.setAttribute('name', 'New Name');

// Before saving, check if someone else modified it
final fresh = await user.fresh();
if (fresh.updatedAt != originalUpdatedAt) {
  throw ConcurrentModificationException(
    'Record was modified by another user',
  );
}

await user.save();
```

#### 2. Discarding Failed Edits

```dart
final user = await User.query().find(1);

try {
  user.setAttribute('email', newEmail);
  await user.save();
} catch (e) {
  // Validation failed, restore original state
  await user.refresh();
  logger.error('Save failed, state restored', e);
}
```

#### 3. Polling for Changes

```dart
// Monitor for external changes
final order = await Order.query().find(orderId);

Timer.periodic(Duration(seconds: 5), (timer) async {
  final fresh = await order.fresh();
  
  if (order.status != fresh.status) {
    print('Order status changed to: ${fresh.status}');
    order.refresh(); // Update to latest
  }
});
```

#### 4. Compare Versions

```dart
// Show what changed
final user = await User.query().find(1);
user.setAttribute('name', 'Modified Name');
user.setAttribute('email', 'modified@example.com');

final fresh = await user.fresh();

if (user.name != fresh.name) {
  print('Name changed: ${fresh.name} -> ${user.name}');
}
if (user.email != fresh.email) {
  print('Email changed: ${fresh.email} -> ${user.email}');
}
```

---

## Model State

### exists

Check if a model is persisted in the database:

```dart
final user = User(
  email: 'new@example.com',
  active: true,
);

print(user.exists); // false (not saved yet)

await user.save();
print(user.exists); // true (now persisted)
```

**Use cases:**
- Check if model needs insert vs update
- Validate model state before operations
- Conditional logic based on persistence

### wasRecentlyCreated

> ⚠️ **Note:** This feature is planned but not yet fully implemented.

Check if a model was just inserted in the current request:

```dart
final user = User(
  email: 'new@example.com',
  active: true,
);

await user.save();

if (user.wasRecentlyCreated) {
  // Send welcome email only for new users
  await sendWelcomeEmail(user);
} else {
  // Send update notification for existing users
  await sendUpdateNotification(user);
}
```

**Use cases:**
- Different logic for insert vs update
- Send welcome emails only to new users
- Track creation in analytics
- Trigger workflows based on creation

---

## Complete Examples

### Example 1: Duplicate an Order

```dart
// Get existing order
final order = await Order.query()
    .with('items')
    .find(orderId);

// Create a duplicate order
final reorder = order.replicate(except: ['orderNumber', 'status']);

// Set new values for excluded fields
reorder.setAttribute('orderNumber', generateOrderNumber());
reorder.setAttribute('status', 'pending');
reorder.setAttribute('createdAt', DateTime.now());

// Save the new order
await reorder.save();

// Duplicate order items separately (relations not copied)
for (final item in order.items) {
  final newItem = item.replicate();
  newItem.setAttribute('orderId', reorder.id);
  await newItem.save();
}

print('Order duplicated: ${reorder.orderNumber}');
```

### Example 2: Conflict Detection

```dart
// Load user for editing
final user = await User.query().find(userId);
final originalVersion = user.updatedAt;

// User makes changes in UI...
await Future.delayed(Duration(seconds: 30));

// Before saving, check for conflicts
final fresh = await user.fresh();
if (fresh.updatedAt != originalVersion) {
  // Someone else modified the record
  print('Conflict detected!');
  print('Your name: ${user.name}');
  print('Current name: ${fresh.name}');
  
  // Let user decide: keep changes or reload?
  final keepChanges = await askUser('Keep your changes?');
  
  if (!keepChanges) {
    await user.refresh();
  }
} else {
  // No conflict, safe to save
  await user.save();
}
```

### Example 3: Test Fixtures

```dart
// In your test file
void main() {
  late DataSource dataSource;
  
  setUp(() async {
    dataSource = await setupTestDatabase();
  });
  
  test('user operations', () async {
    // Create a base template
    final template = User(
      name: 'Test User',
      role: 'user',
      active: true,
    );
    
    // Create test users with variations
    final admin = template.replicate();
    admin.setAttribute('email', 'admin@test.com');
    admin.setAttribute('role', 'admin');
    
    final moderator = template.replicate();
    moderator.setAttribute('email', 'mod@test.com');
    moderator.setAttribute('role', 'moderator');
    
    final normalUser = template.replicate();
    normalUser.setAttribute('email', 'user@test.com');
    
    // Save all at once
    await dataSource.repo<User>().insertMany([
      admin,
      moderator,
      normalUser,
    ]);
    
    // Run tests...
    expect(admin.role, 'admin');
    expect(moderator.role, 'moderator');
    expect(normalUser.role, 'user');
  });
}
```

### Example 4: Product Templates

```dart
class ProductService {
  Future<Product> createFromTemplate(
    String templateName,
    Map<String, dynamic> customizations,
  ) async {
    // Load template
    final template = await Product.query()
        .where('name', templateName)
        .where('isTemplate', true)
        .first();
    
    if (template == null) {
      throw ArgumentError('Template not found: $templateName');
    }
    
    // Create new product from template
    final product = template.replicate(except: ['isTemplate']);
    
    // Apply customizations
    for (final entry in customizations.entries) {
      product.setAttribute(entry.key, entry.value);
    }
    
    // Mark as not a template
    product.setAttribute('isTemplate', false);
    
    // Save
    await product.save();
    
    return product;
  }
}

// Usage
final service = ProductService();
final product = await service.createFromTemplate(
  'Standard Widget',
  {
    'name': 'Custom Widget',
    'sku': 'WIDGET-001',
    'price': 29.99,
  },
);
```

---

## Comparison with Laravel

### Feature Parity Matrix

| Method | Laravel | This ORM | Notes |
|--------|---------|----------|-------|
| `replicate()` | ✅ | ✅ | Same behavior |
| `is()` | ✅ | ✅ `isSameAs()` | Better naming |
| `isNot()` | ✅ | ✅ `isDifferentFrom()` | Better naming |
| `fresh()` | ✅ | ✅ | Same behavior |
| `refresh()` | ✅ | ✅ | Same behavior |
| `wasRecentlyCreated` | ✅ | ⏳ | Coming soon |

### API Comparison

**Laravel:**
```php
// Replicate
$replica = $user->replicate(['email']);

// Compare
if ($user1->is($user2)) { }

// Refresh
$fresh = $user->fresh();
$user->refresh();
```

**This ORM:**
```dart
// Replicate
final replica = user.replicate(except: ['email']);

// Compare (better naming!)
if (user1.isSameAs(user2)) { }

// Refresh
final fresh = await user.fresh();
await user.refresh();
```

### What's Better

✅ **Better method naming**
- `isSameAs()` is more explicit than `is()`
- `isDifferentFrom()` is clearer than `isNot()`

✅ **Type safety**
- Full compile-time type checking
- Better IDE autocomplete
- Catch errors at compile time

✅ **Explicit async**
- Clear when database queries occur
- Better performance awareness
- Easier to reason about

### Migration from Laravel

The API is nearly identical:

**Replication:**
```php
// Laravel
$copy = $user->replicate(['email', 'verified']);
```
```dart
// This ORM
final copy = user.replicate(except: ['email', 'verified']);
```

**Comparison:**
```php
// Laravel
if ($user1->is($user2)) { }
```
```dart
// This ORM
if (user1.isSameAs(user2)) { }
```

**Refreshing:**
```php
// Laravel
$fresh = $user->fresh();
$user->refresh();
```
```dart
// This ORM
final fresh = await user.fresh();
await user.refresh();
```

---

## See Also

- [Models Guide](models.md) - Defining models
- [Query Builder](query_builder.md) - Building queries
- [Testing Guide](testing.md#model-replication) - Testing with replicate()
- [Best Practices](best_practices.md#model-patterns) - Model patterns

---

## Summary

Model instance methods provide:

✅ **Replication** - Clone models without PK/timestamps  
✅ **Comparison** - Check if models are the same record  
✅ **Refreshing** - Reload data from database  
✅ **State tracking** - Monitor model persistence  
✅ **Laravel compatibility** - Familiar API for Laravel devs  
✅ **Better naming** - More explicit method names  

Use these methods to write cleaner, more maintainable code! 🚀

