---
sidebar_position: 2
---

# Schema Builder

The Schema Builder provides a fluent API for defining table structures in a database-agnostic way.

## Creating Tables

Use `schema.create()` to define a new table:

```dart
schema.create('users', (table) {
  table.increments('id');
  table.string('email').unique();
  table.string('name').nullable();
  table.boolean('active').defaultValue(true);
  table.timestamps();
});
```

## Column Types

### Primary Keys

```dart
table.id();                     // bigIncrements('id')
table.increments('id');         // Auto-incrementing integer
table.bigIncrements('id');      // Auto-incrementing bigint
table.uuid('id');               // UUID column
table.ulid('id');               // ULID column
```

### Strings

```dart
table.string('name');           // VARCHAR(255)
table.string('code', length: 50); // VARCHAR(50)
table.char('code', length: 8);  // CHAR(8)
table.text('body');             // TEXT
table.mediumText('content');    // MEDIUMTEXT
table.longText('data');         // LONGTEXT
```

### Numbers

```dart
table.integer('count');
table.bigInteger('views');
table.smallInteger('level');
table.tinyInteger('status');
table.decimal('price', precision: 10, scale: 2);
table.float('rating');
table.double('latitude');
```

### Dates & Times

```dart
table.date('birth_date');
table.dateTime('published_at');
table.dateTimeTz('scheduled_at');    // Timezone-aware
table.timestamp('logged_at');
table.timestampTz('synced_at');      // Timezone-aware
table.time('start_time');
table.timeTz('end_time');            // Timezone-aware
```

### Boolean & Binary

```dart
table.boolean('active');
table.binary('data');
```

### JSON

```dart
table.json('metadata');
table.jsonb('settings');        // PostgreSQL JSONB
```

## Column Modifiers

Chain modifiers to customize column behavior:

```dart
table.string('email')
    .nullable()                 // Allow NULL
    .unique()                   // Unique constraint
    .defaultValue('default@example.com');

table.integer('id')
    .primaryKey()
    .autoIncrement()
    .unsigned();

table.timestamp('created_at')
    .useCurrentTimestamp()      // DEFAULT CURRENT_TIMESTAMP
    .useCurrentOnUpdate();      // ON UPDATE CURRENT_TIMESTAMP

table.string('slug')
    .comment('URL-friendly identifier');
```

## Timestamps & Soft Deletes

```dart
// Add created_at and updated_at
table.timestamps();              // Non-timezone aware
table.timestampsTz();            // Timezone aware (UTC)
table.nullableTimestamps();      // Nullable, no defaults
table.nullableTimestampsTz();    // Nullable, timezone aware

// Add soft delete column
table.softDeletes();             // Non-timezone aware
table.softDeletesTz();           // Timezone aware (UTC)
```

## Indexes

```dart
// Simple index
table.index(['email']);

// Composite index
table.index(['user_id', 'created_at']);

// Unique index
table.unique(['slug']);

// Full-text search
table.fullText(['title', 'body']);

// Spatial index
table.spatialIndex(['location']);

// Named index
table.index(['email']).name('idx_users_email');
```

## Foreign Keys

```dart
// Basic foreign key
table.foreign(
  ['user_id'],
  references: 'users',
  referencedColumns: ['id'],
  onDelete: ReferenceAction.cascade,
  onUpdate: ReferenceAction.restrict,
);

// Foreign key with fluent builder
table.foreign(
  ['post_id'],
  references: 'posts',
  referencedColumns: ['id'],
).onDelete(ReferenceAction.cascade);

// Foreign key shortcut
table.foreignId('user_id')
    .constrained('users')
    .onDelete(ReferenceAction.cascade);
```

### Reference Actions

- `ReferenceAction.cascade` - Delete/update child rows
- `ReferenceAction.restrict` - Prevent if children exist
- `ReferenceAction.setNull` - Set foreign key to NULL
- `ReferenceAction.noAction` - No action (check deferred)

## Altering Tables

Use `schema.table()` to modify existing tables:

```dart
schema.table('users', (table) {
  // Add columns
  table.string('avatar_url').nullable();

  // Drop columns
  table.dropColumn('old_field');

  // Rename columns
  table.renameColumn('email', 'primary_email');

  // Add indexes
  table.index(['avatar_url']);

  // Drop indexes
  table.dropIndex('idx_old_index');
});
```

## Dropping Tables

```dart
schema.drop('users');
schema.drop('users', ifExists: true);
schema.dropIfExists('users');
```

## Renaming Tables

```dart
schema.rename('old_name', 'new_name');
```

## Driver-Specific Overrides

Customize schema for different databases:

```dart
schema.create('events', (table) {
  // Use JSONB on PostgreSQL, JSON elsewhere
  table.json('metadata')
      .driverType('postgres', const ColumnType.jsonb());

  // PostgreSQL-specific collation
  table.string('locale')
      .driverOverride('postgres', collation: '"und-x-icu"');

  // Driver-specific default expression
  table.timestamp('synced_at', timezoneAware: true)
      .driverDefault('postgres', expression: "timezone('UTC', now())");
});
```
