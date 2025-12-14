---
sidebar_position: 1
---

# Defining Models

Models in Ormed are Dart classes annotated with `@OrmModel` that map to database tables.

## Basic Model

```dart file=../../examples/lib/models/user.dart#basic-model

```

After running `dart run build_runner build`, this generates:
- `$User` - Tracked model class with change tracking
- `UserOrmDefinition` - Model metadata and static helpers
- `$UserPartial` - Partial entity for projections
- `UserInsertDto` / `UserUpdateDto` - Data transfer objects

## Model Annotation Options

```dart file=../../examples/lib/models/admin.dart#model-with-options

```

## Field Annotations

### Primary Key

```dart file=../../examples/lib/models/field_examples.dart#primary-key-examples

```

### Column Options

```dart file=../../examples/lib/models/field_examples.dart#column-options

```

### Custom Codecs

For complex types, use value codecs:

```dart file=../../examples/lib/generated_code_usage.dart#custom-codecs-field

```

## Generated Code

### Tracked Model (`$User`)

The generated `$User` class is the "tracked" version of your model with:
- Change tracking for dirty fields
- Relationship accessors
- Model lifecycle methods

```dart file=../../examples/lib/generated_code_usage.dart#tracked-model-usage

```

### Definition (`UserOrmDefinition`)

Provides static helpers and model metadata:

```dart file=../../examples/lib/generated_code_usage.dart#definition-usage

```

### Partial Entity (`$UserPartial`)

For projecting specific columns:

```dart file=../../examples/lib/generated_code_usage.dart#partial-entity-usage

```

### DTOs

Data transfer objects for insert/update operations:

```dart file=../../examples/lib/generated_code_usage.dart#dto-usage

```

## Best Practices

1. **Use const constructors** - Helps with immutability and tree-shaking
2. **Define all fields as final** - Models are immutable by design
3. **Use nullable types** for optional fields - Clearer intent
4. **Keep models focused** - One model per table
5. **Use DTOs** for partial updates - More explicit than tracked models
