# Timestamp and Soft Delete Mixins Usage Guide

This document explains how to use the timezone-aware and non-timezone-aware timestamp and soft delete mixins in your ORM models.

## Overview

Ormed provides four mixins for managing timestamps and soft deletes:

| Mixin | Purpose | Timezone Handling |
|-------|---------|-------------------|
| `Timestamps` | Automatic created_at/updated_at tracking | No conversion (stores as-is) |
| `TimestampsTZ` | Automatic created_at/updated_at tracking | Converts to UTC for storage |
| `SoftDeletes` | Soft delete with deleted_at timestamp | No conversion (stores as-is) |
| `SoftDeletesTZ` | Soft delete with deleted_at timestamp | Converts to UTC for storage |

## Timestamps

### Non-Timezone Aware (Timestamps)

Use `Timestamps` when you want timestamps stored exactly as provided, without timezone conversion.

```dart
@OrmModel(table: 'posts')
class Post extends Model<Post> with Timestamps {
  const Post({
    this.id,
    required this.title,
    required this.content,
  });

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int? id;

  final String title;
  final String content;
  
  // createdAt and updatedAt are automatically added as virtual fields
  // No need to define them explicitly
}
```

**What happens:**
- Generator adds virtual `createdAt` and `updatedAt` fields
- Generated `_$PostModel` mixes in `TimestampsImpl`
- Timestamps are set automatically on insert/update
- Values are stored exactly as provided (no UTC conversion)

**Usage:**
```dart
final post = await Post.query().find(1);

// Returns Carbon instance for fluent manipulation
print(post.createdAt?.format('Y-m-d H:i:s')); // "2024-12-08 15:30:00"
print(post.createdAt?.diffForHumans()); // "2 hours ago"
print(post.createdAt?.isToday()); // true/false

// Carbon provides many helpful methods
print(post.updatedAt?.addDays(5).format('l, F jS Y')); // "Monday, December 13th 2024"
print(post.updatedAt?.startOfDay().toDateTime()); // DateTime at 00:00:00

post.touch(); // Updates updatedAt to Carbon.now()
await post.save();

// Convert to DateTime if needed
DateTime dateTime = post.createdAt!.toDateTime();
```

### Timezone Aware (TimestampsTZ)

Use `TimestampsTZ` when you want all timestamps automatically converted to UTC for storage. This is recommended for applications that need consistent timezone handling.

```dart
@OrmModel(table: 'posts')
class Post extends Model<Post> with TimestampsTZ {
  const Post({
    this.id,
    required this.title,
    required this.content,
  });

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int? id;

  final String title;
  final String content;
  
  // createdAt and updatedAt are automatically added as virtual fields
  // and will always be in UTC
}
```

**What happens:**
- Generator adds virtual `createdAt` and `updatedAt` fields
- Generated `_$PostModel` mixes in `TimestampsTZImpl`
- Timestamps are automatically converted to UTC before storage
- Values are always returned in UTC

**Usage:**
```dart
final post = await Post.query().find(1);

// Returns Carbon instance in UTC
print(post.createdAt?.isUtc); // true - always UTC
print(post.updatedAt?.isUtc); // true - always UTC

// Carbon fluent API with UTC timestamps
print(post.createdAt?.format('Y-m-d H:i:s e')); // "2024-12-08 15:30:00 UTC"
print(post.createdAt?.diffForHumans()); // "2 hours ago"
print(post.createdAt?.locale('fr').diffForHumans()); // "il y a 2 heures"

// Set timestamp - automatically converted to UTC
post.createdAt = DateTime.now(); // Converts to UTC
post.touch(); // Updates updatedAt to Carbon.now().toUtc()
await post.save();

// For display in user's timezone
final userTimezone = 'America/New_York';
print(post.createdAt?.tz(userTimezone).format('Y-m-d H:i:s'));
// "2024-12-08 10:30:00"

// Fluent comparisons
if (post.updatedAt?.isAfter(Carbon.now().subHours(24)) ?? false) {
  print('Updated within last 24 hours');
}
```

## Soft Deletes

### Non-Timezone Aware (SoftDeletes)

Use `SoftDeletes` for soft delete functionality without timezone conversion.

```dart
@OrmModel(table: 'users')
class User extends Model<User> with SoftDeletes {
  const User({
    this.id,
    required this.email,
    required this.name,
  });

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int? id;

  final String email;
  final String name;
  
  // deletedAt is automatically added as a virtual field
}
```

**Usage:**
```dart
final user = await User.query().find(1);

// Soft delete
await user.delete(); // Sets deletedAt to current time
print(user.trashed); // true

// Restore
await user.restore(); // Clears deletedAt
print(user.trashed); // false

// Force delete (permanent)
await user.forceDelete();

// Query including soft-deleted records
final allUsers = await User.query().withTrashed().get();
```

### Timezone Aware (SoftDeletesTZ)

Use `SoftDeletesTZ` when you want soft delete timestamps in UTC.

```dart
@OrmModel(table: 'users')
class User extends Model<User> with SoftDeletesTZ {
  const User({
    this.id,
    required this.email,
    required this.name,
  });

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int? id;

  final String email;
  final String name;
  
  // deletedAt is automatically added as a virtual field (UTC)
}
```

**What happens:**
- Generator adds virtual `deletedAt` field
- Generated `_$UserModel` mixes in `SoftDeletesTZImpl`
- Deletion timestamps are automatically converted to UTC
- Includes `trash()` and `untrash()` helper methods

**Usage:**
```dart
final user = await User.query().find(1);

// Soft delete with UTC timestamp - returns Carbon instance
await user.delete(); // Sets deletedAt to Carbon.now().toUtc()
print(user.deletedAt?.isUtc); // true
print(user.deletedAt?.diffForHumans()); // "3 days ago"

// Using helper methods
user.trash(); // Same as deletedAt = Carbon.now().toUtc()
await user.save();

user.untrash(); // Same as deletedAt = null
await user.save();

print(user.trashed); // false

// Carbon methods on deletedAt
if (user.deletedAt?.isToday() ?? false) {
  print('Deleted today!');
}

// Format for display
print(user.deletedAt?.locale('es').format('l, d \\d\\e F \\d\\e Y'));
// "lunes, 8 de diciembre de 2024"
```

## Combining Mixins

You can combine timestamps and soft deletes:

```dart
@OrmModel(table: 'posts')
class Post extends Model<Post> with TimestampsTZ, SoftDeletesTZ {
  const Post({
    this.id,
    required this.title,
  });

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int? id;

  final String title;
  
  // Virtual fields added automatically:
  // - createdAt (UTC)
  // - updatedAt (UTC)
  // - deletedAt (UTC)
}
```

## Custom Column Names

You can customize the column name for soft deletes:

```dart
@OrmModel(
  table: 'users',
  softDeletes: true,
  softDeletesColumn: 'removed_at', // Custom column name
)
class User extends Model<User> {
  // deletedAt field will use 'removed_at' column
}
```

## Explicit Field Definitions

If you want the timestamp/soft delete fields in your immutable model (e.g., for const constructors), define them explicitly:

```dart
@OrmModel(table: 'posts')
class Post extends Model<Post> with TimestampsTZ, SoftDeletesTZ {
  const Post({
    this.id,
    required this.title,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int? id;

  final String title;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
}
```

The generator will detect these fields and NOT create virtual ones. The tracked model will override the getters/setters to use the attribute store and handle UTC conversion.

## Best Practices

1. **Use TZ variants for multi-timezone applications**: If your application serves users in different timezones, use `TimestampsTZ` and `SoftDeletesTZ` to store everything in UTC and convert for display.

2. **Use non-TZ variants for simple applications**: If you're building a single-timezone application or don't need timezone handling, use `Timestamps` and `SoftDeletes` for simplicity.

3. **Be consistent**: Don't mix TZ and non-TZ variants for different timestamp fields on the same model - choose one approach.

4. **Display conversion**: For TZ variants, always convert to local time for display:
   ```dart
   final displayTime = post.createdAt?.toLocal();
   ```

5. **Virtual fields**: Unless you need the fields in your immutable model, let the generator create virtual fields automatically.

## Carbon Integration

All timestamp getters return `CarbonInterface` instances, providing a fluent API for date manipulation inspired by PHP's Carbon library.

### Key Carbon Features

```dart
final post = await Post.query().find(1);

// Formatting (170+ locales supported)
post.createdAt?.format('Y-m-d H:i:s');           // "2024-12-08 15:30:00"
post.createdAt?.format('l, F jS Y');              // "Monday, December 8th 2024"
post.createdAt?.locale('fr').format('l d F Y');   // "lundi 8 décembre 2024"

// Human-readable differences
post.createdAt?.diffForHumans();                  // "2 hours ago"
post.createdAt?.locale('es').diffForHumans();     // "hace 2 horas"

// Comparisons
post.createdAt?.isToday();                        // true/false
post.createdAt?.isYesterday();                    // true/false
post.createdAt?.isFuture();                       // true/false
post.createdAt?.isAfter(Carbon.parse('2024-01-01')); // true/false

// Manipulation (returns new instance, immutable)
post.createdAt?.addDays(5);
post.createdAt?.subHours(3);
post.createdAt?.startOfDay();
post.createdAt?.endOfMonth();

// Timezone conversion
post.createdAt?.tz('America/New_York');  // Convert to specific timezone
post.createdAt?.toLocal();                // Convert to local timezone
post.createdAt?.toUtc();                  // Convert to UTC

// Get underlying DateTime when needed
DateTime dt = post.createdAt!.toDateTime();
```

### Why Carbon?

1. **Intuitive API**: Fluent, readable methods like `diffForHumans()` and `isToday()`
2. **Localization**: Support for 170+ locales out of the box
3. **Timezone Safety**: Easy timezone conversion and handling
4. **Immutable**: Operations return new instances, no mutation
5. **Laravel Familiar**: Same API as PHP's Carbon library

## Laravel Comparison

These mixins provide similar functionality to Laravel's:
- `Timestamps` ≈ Laravel's `$timestamps = true` (with Carbon instances)
- `TimestampsTZ` ≈ Laravel's timestamps with database timezone settings (UTC storage)
- `SoftDeletes` ≈ Laravel's `SoftDeletes` trait (with Carbon instances)
- `SoftDeletesTZ` ≈ Laravel's `SoftDeletes` with UTC handling

All timestamp accessors return Carbon instances just like Laravel's Eloquent models!
