---
sidebar_position: 2
---

# Repository

Repositories provide CRUD operations with flexible input handling, accepting tracked models, DTOs, or raw maps.

:::note Snippet context
- Snippets focus on repository calls and omit full setup.
- Unless shown otherwise, assume you already have a `DataSource` named `dataSource` and you’re using generated tracked models (e.g., `$User`).
:::

## Getting a Repository

```dart file=../../examples/lib/repository.dart#repo-get

```

## Insert Operations

### Insert Single

```dart file=../../examples/lib/repository.dart#repo-insert

```

### Insert Many

```dart file=../../examples/lib/repository.dart#repo-insert-many

```

### Upsert (Insert or Update)

```dart file=../../examples/lib/repository.dart#repo-upsert

```

## Find Operations

### Find by Primary Key

```dart file=../../examples/lib/repository.dart#repo-find
```

### Get All

```dart file=../../examples/lib/repository.dart#repo-first-count
```

### Count & Exists

```dart file=../../examples/lib/repository.dart#repo-first-count
```

## Update Operations

### Update Single

```dart file=../../examples/lib/repository.dart#repo-update

```

### Update Many

```dart file=../../examples/lib/repository.dart#repo-update-many

```

### Where Parameter Types

The `where` parameter accepts various input types:

```dart file=../../examples/lib/repository.dart#repo-where-types

```

:::caution Important
When using a callback function for `where`, you **must** explicitly type the parameter:
```dart file=../../examples/lib/repository.dart#repo-where-typing-caution
```
:::

## Delete Operations

### Delete Single

```dart file=../../examples/lib/repository.dart#repo-delete

```

### Delete Many

```dart file=../../examples/lib/repository.dart#repo-delete-many

```

## Soft Delete Operations

For models with `SoftDeletes`:

```dart file=../../examples/lib/repository.dart#repo-soft-delete
```

## Working with Relations

```dart file=../../examples/lib/repository.dart#repo-relations
```

## Error Handling

```dart file=../../examples/lib/repository.dart#repo-errors

```
