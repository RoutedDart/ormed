---
sidebar_position: 2
---

# Relationships

Ormed supports common relationship types between models using the `@OrmRelation` annotation.

## Relationship Types

### Has One

A one-to-one relationship where the related model has the foreign key:

```dart file=../../examples/lib/models/relations/has_one.dart#relation-has-one

```

### Has Many

A one-to-many relationship:

```dart file=../../examples/lib/models/relations/has_many.dart#relation-has-many

```

### Belongs To

The inverse of hasOne/hasMany - this model has the foreign key:

```dart file=../../examples/lib/models/relations/belongs_to.dart#relation-belongs-to

```

### Belongs To Many

A many-to-many relationship using a pivot table:

```dart file=../../examples/lib/models/relations/belongs_to_many.dart#relation-belongs-to-many

```

## Loading Relations

### Eager Loading

Load relations upfront with the query:

```dart file=../../examples/lib/relations/loading.dart#eager-basic

```

```dart file=../../examples/lib/relations/loading.dart#eager-multiple

```

```dart file=../../examples/lib/relations/loading.dart#eager-nested

```

### Lazy Loading

Load relations on-demand:

```dart file=../../examples/lib/relations/loading.dart#lazy-load

```

```dart file=../../examples/lib/relations/loading.dart#lazy-load-missing

```

### Checking Relation Status

```dart file=../../examples/lib/relations/loading.dart#check-loaded

```

## Relation Manipulation

### Setting Relations

```dart file=../../examples/lib/relations/loading.dart#relation-associate

```

### Many-to-Many Operations

```dart file=../../examples/lib/relations/loading.dart#relation-attach

```

```dart file=../../examples/lib/relations/loading.dart#relation-sync

```

## Aggregate Loading

Load aggregate values without fetching all related models:

```dart file=../../examples/lib/relations/loading.dart#relation-count

```

```dart file=../../examples/lib/relations/loading.dart#relation-sum

```

```dart file=../../examples/lib/relations/loading.dart#relation-exists

```

## Preventing N+1 Queries

Use `Model.preventLazyLoading()` in development to catch N+1 issues:

```dart file=../../examples/lib/relations/loading.dart#prevent-n-plus-one
```

This throws an exception when accessing relations that haven't been eager-loaded, helping you identify performance issues early.
