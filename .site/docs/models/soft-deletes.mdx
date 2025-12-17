---
sidebar_position: 4
---

# Soft Deletes

Soft deletes allow you to "delete" records by setting a timestamp rather than removing them from the database. This is useful for maintaining audit trails or implementing trash/restore functionality.

## Enabling Soft Deletes

Add the `SoftDeletes` marker mixin to your model:

```dart file=../../examples/lib/models/soft_delete_model.dart#soft-deletes-model

```

The code generator detects this mixin and:
- Adds a virtual `deletedAt` field if not explicitly defined
- Applies soft-delete implementation to the generated tracked class
- Enables soft-delete query scopes automatically

## Timezone-Aware Soft Deletes

For deletion timestamps stored in UTC, use `SoftDeletesTZ`:

```dart file=../../examples/lib/models/soft_delete_model.dart#soft-deletes-tz

```

## Migration Setup

Add the soft delete column in your migration:

```dart file=../../examples/lib/migrations/basic.dart#soft-deletes-migration

```

## Querying Soft Deleted Records

### Default Behavior

By default, soft-deleted records are excluded from queries:

```dart file=../../examples/lib/soft_deletes.dart#soft-delete-default

```

### Include Soft Deleted

Use `withTrashed()` to include soft-deleted records:

```dart file=../../examples/lib/soft_deletes.dart#soft-delete-with-trashed

```

### Only Soft Deleted

Use `onlyTrashed()` to get only soft-deleted records:

```dart file=../../examples/lib/soft_deletes.dart#soft-delete-only-trashed

```

## Soft Delete Operations

### Deleting Records

Standard delete operations soft-delete when the model has `SoftDeletes`:

```dart file=../../examples/lib/soft_deletes.dart#soft-delete-operations

```

### Restoring Records

Restore soft-deleted records:

```dart file=../../examples/lib/soft_deletes.dart#soft-delete-restore

```

### Force Delete

Permanently remove a record (bypass soft delete):

```dart file=../../examples/lib/soft_deletes.dart#soft-delete-force

```

## Checking Soft Delete Status

```dart file=../../examples/lib/soft_deletes.dart#soft-delete-status

```

## Combining with Timestamps

You can use both `Timestamps` and `SoftDeletes`:

```dart file=../../examples/lib/soft_deletes.dart#soft-delete-combined-mixins

```

Migration:

```dart file=../../examples/lib/soft_deletes.dart#soft-delete-migration-combined

```
