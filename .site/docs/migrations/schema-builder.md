---
sidebar_position: 2
---

# Schema Builder

The Schema Builder provides a fluent API for defining table structures in a database-agnostic way.

## Creating Tables

Use `schema.create()` to define a new table:

```dart file=../../examples/lib/schema/schema_builder.dart#schema-create
```

## Column Types

### Primary Keys

```dart file=../../examples/lib/schema/schema_builder.dart#schema-primary-keys
```

### Strings

```dart file=../../examples/lib/schema/schema_builder.dart#schema-strings
```

### Numbers

```dart file=../../examples/lib/schema/schema_builder.dart#schema-numbers
```

### Dates & Times

```dart file=../../examples/lib/schema/schema_builder.dart#schema-dates
```

### Boolean & Binary

```dart file=../../examples/lib/schema/schema_builder.dart#schema-bool-binary
```

### JSON

```dart file=../../examples/lib/schema/schema_builder.dart#schema-json
```

## Column Modifiers

Chain modifiers to customize column behavior:

```dart file=../../examples/lib/schema/schema_builder.dart#schema-modifiers
```

## Timestamps & Soft Deletes

```dart file=../../examples/lib/schema/schema_builder.dart#schema-timestamps
```

## Indexes

```dart file=../../examples/lib/schema/schema_builder.dart#schema-indexes
```

## Foreign Keys

```dart file=../../examples/lib/schema/schema_builder.dart#schema-foreign-keys
```

### Reference Actions

- `ReferenceAction.cascade` - Delete/update child rows
- `ReferenceAction.restrict` - Prevent if children exist
- `ReferenceAction.setNull` - Set foreign key to NULL
- `ReferenceAction.noAction` - No action (check deferred)

## Altering Tables

Use `schema.table()` to modify existing tables:

```dart file=../../examples/lib/schema/schema_builder.dart#schema-alter
```

## Dropping Tables

```dart file=../../examples/lib/schema/schema_builder.dart#schema-drop-rename
```

## Driver-Specific Overrides

Customize schema for different databases:

```dart file=../../examples/lib/schema/schema_builder.dart#schema-driver-overrides
```
