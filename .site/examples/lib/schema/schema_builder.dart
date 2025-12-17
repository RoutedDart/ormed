// Schema builder examples for documentation
// ignore_for_file: unused_local_variable

import 'package:ormed/migrations.dart';

// #region schema-create
class CreateTableExample extends Migration {
  const CreateTableExample();

  @override
  void up(SchemaBuilder schema) {
    schema.create('users', (table) {
      table.increments('id');
      table.string('email').unique();
      table.string('name').nullable();
      table.boolean('active').defaultValue(true);
      table.timestamps();
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('users');
  }
}
// #endregion schema-create

// #region schema-primary-keys
void primaryKeyExamples(TableBuilder table) {
  table.id(); // bigIncrements('id')
  table.increments('id'); // Auto-incrementing integer
  table.bigIncrements('id'); // Auto-incrementing bigint
  table.uuid('id'); // UUID column
  table.ulid('id'); // ULID column
}
// #endregion schema-primary-keys

// #region schema-strings
void stringExamples(TableBuilder table) {
  table.string('name'); // VARCHAR(255)
  table.string('code', length: 50); // VARCHAR(50)
  table.char('code', length: 8); // CHAR(8)
  table.text('body'); // TEXT
  table.mediumText('content'); // MEDIUMTEXT
  table.longText('data'); // LONGTEXT
}
// #endregion schema-strings

// #region schema-numbers
void numberExamples(TableBuilder table) {
  table.integer('count');
  table.bigInteger('views');
  table.smallInteger('level');
  table.tinyInteger('status');
  table.decimal('price', precision: 10, scale: 2);
  table.float('rating');
  table.double('latitude');
}
// #endregion schema-numbers

// #region schema-dates
void dateExamples(TableBuilder table) {
  table.date('birth_date');
  table.dateTime('published_at');
  table.dateTimeTz('scheduled_at'); // Timezone-aware
  table.timestamp('logged_at');
  table.timestampTz('synced_at'); // Timezone-aware
  table.time('start_time');
  table.timeTz('end_time'); // Timezone-aware
}
// #endregion schema-dates

// #region schema-bool-binary
void boolBinaryExamples(TableBuilder table) {
  table.boolean('active');
  table.binary('data');
}
// #endregion schema-bool-binary

// #region schema-json
void jsonExamples(TableBuilder table) {
  table.json('metadata');
  table.jsonb('settings'); // PostgreSQL JSONB
}
// #endregion schema-json

// #region schema-modifiers
void modifierExamples(TableBuilder table) {
  table
      .string('email')
      .nullable() // Allow NULL
      .unique() // Unique constraint
      .defaultValue('default@example.com');

  table.integer('id').primaryKey().autoIncrement().unsigned();

  table
      .timestamp('created_at')
      .useCurrentTimestamp() // DEFAULT CURRENT_TIMESTAMP
      .useCurrentOnUpdate(); // ON UPDATE CURRENT_TIMESTAMP

  table.string('slug').comment('URL-friendly identifier');
}
// #endregion schema-modifiers

// #region schema-timestamps
void timestampExamples(TableBuilder table) {
  // Add created_at and updated_at
  table.timestamps(); // Non-timezone aware
  table.timestampsTz(); // Timezone aware (UTC)
  table.nullableTimestamps(); // Nullable, no defaults
  table.nullableTimestampsTz(); // Nullable, timezone aware

  // Add soft delete column
  table.softDeletes(); // Non-timezone aware
  table.softDeletesTz(); // Timezone aware (UTC)
}
// #endregion schema-timestamps

// #region schema-indexes
void indexExamples(TableBuilder table) {
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
}
// #endregion schema-indexes

// #region schema-foreign-keys
void foreignKeyExamples(TableBuilder table) {
  // Basic foreign key
  table.foreign(
    ['user_id'],
    references: 'users',
    referencedColumns: ['id'],
    onDelete: ReferenceAction.cascade,
    onUpdate: ReferenceAction.restrict,
  );

  // Foreign key with fluent builder
  table
      .foreign(['post_id'], references: 'posts', referencedColumns: ['id'])
      .onDelete(ReferenceAction.cascade);

  // Foreign key shortcut
  table
      .foreignId('user_id')
      .constrained('users')
      .onDelete(ReferenceAction.cascade);
}
// #endregion schema-foreign-keys

// #region schema-alter
class AlterTableExample extends Migration {
  const AlterTableExample();

  @override
  void up(SchemaBuilder schema) {
    // #region schema-alter-up
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
    // #endregion schema-alter-up
  }

  @override
  void down(SchemaBuilder schema) {
    // #region schema-alter-down
    schema.table('users', (table) {
      table.dropColumn('avatar_url');
      table.string('old_field').nullable();
      table.renameColumn('primary_email', 'email');
    });
    // #endregion schema-alter-down
  }
}
// #endregion schema-alter

// #region schema-drop-rename
void dropRenameExamples(SchemaBuilder schema) {
  schema.drop('users');
  schema.drop('users', ifExists: true);
  schema.dropIfExists('users');
  schema.rename('old_name', 'new_name');
}
// #endregion schema-drop-rename

// #region schema-driver-overrides
class DriverOverrideExample extends Migration {
  const DriverOverrideExample();

  @override
  void up(SchemaBuilder schema) {
    schema.create('events', (table) {
      table.increments('id');

      // Use JSONB on PostgreSQL, JSON elsewhere
      table.json('metadata').driverType('postgres', const ColumnType.jsonb());

      // PostgreSQL-specific collation
      table
          .string('locale')
          .driverOverride('postgres', collation: '"und-x-icu"');

      // Driver-specific default expression
      table
          .timestamp('synced_at', timezoneAware: true)
          .driverDefault('postgres', expression: "timezone('UTC', now())");
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('events');
  }
}

// #endregion schema-driver-overrides
