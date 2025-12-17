/// Database migrations and schema management for Ormed.
///
/// This library provides a complete schema migration system with:
/// - Fluent API for defining table structures
/// - Reversible migrations with `up()` and `down()` methods
/// - Driver-agnostic schema operations
/// - Migration tracking and execution
///
/// ## Creating Migrations
///
/// Extend the [Migration] class and implement `up()` and `down()` methods:
///
/// ```dart
/// import 'package:ormed/migrations.dart';
///
/// class CreateUsersTable extends Migration {
///   const CreateUsersTable();
///
///   @override
///   void up(SchemaBuilder schema) {
///     schema.create('users', (table) {
///       table.increments('id');              // Auto-incrementing primary key
///       table.string('email').unique();      // VARCHAR with unique constraint
///       table.string('name').nullable();     // Nullable string
///       table.boolean('active').defaultValue(true);
///       table.timestamps();                  // created_at, updated_at
///     });
///   }
///
///   @override
///   void down(SchemaBuilder schema) {
///     schema.drop('users', ifExists: true);
///   }
/// }
/// ```
///
/// ## Column Types
///
/// The [TableBlueprint] provides methods for all common column types:
///
/// ```dart
/// schema.create('posts', (table) {
///   // Primary keys
///   table.id();                     // bigIncrements('id')
///   table.increments('id');         // Auto-incrementing integer PK
///   table.bigIncrements('id');      // Auto-incrementing bigint PK
///   table.uuid('id');               // UUID primary key
///
///   // Strings
///   table.string('title');          // VARCHAR(255)
///   table.string('code', length: 50); // VARCHAR(50)
///   table.text('body');             // TEXT
///   table.longText('content');      // LONGTEXT
///
///   // Numbers
///   table.integer('count');
///   table.bigInteger('views');
///   table.decimal('price', precision: 10, scale: 2);
///   table.float('rating');
///   table.double('latitude');
///
///   // Dates & Times
///   table.dateTime('published_at');
///   table.dateTimeTz('scheduled_at');  // Timezone-aware
///   table.timestamp('logged_at');
///   table.timestampTz('synced_at');    // Timezone-aware
///   table.date('birth_date');
///   table.time('start_time');
///
///   // Special types
///   table.boolean('is_active');
///   table.json('metadata');
///   table.jsonb('settings');         // PostgreSQL JSONB
///   table.binary('data');
///   table.enum_('status', ['draft', 'published', 'archived']);
/// });
/// ```
///
/// ## Column Modifiers
///
/// Chain modifiers to customize columns:
///
/// ```dart
/// schema.create('products', (table) {
///   table.string('sku')
///       .unique()                    // Add unique constraint
///       .comment('Stock keeping unit');
///
///   table.string('name')
///       .nullable()                  // Allow NULL values
///       .collation('utf8mb4_unicode_ci');
///
///   table.decimal('price')
///       .defaultValue(0.00)            // Static default value
///       .unsigned();                 // No negative values
///
///   table.timestamp('created_at')
///       .useCurrentTimestamp()       // DEFAULT CURRENT_TIMESTAMP
///       .useCurrentOnUpdate();       // ON UPDATE CURRENT_TIMESTAMP
/// });
/// ```
///
/// ## Timestamps & Soft Deletes
///
/// Convenience methods for common patterns:
///
/// ```dart
/// schema.create('posts', (table) {
///   table.id();
///   table.string('title');
///
///   // Add created_at and updated_at columns
///   table.timestamps();              // Non-timezone aware
///   table.timestampsTz();            // Timezone aware (UTC)
///   table.nullableTimestamps();      // Nullable, no defaults
///   table.nullableTimestampsTz();    // Nullable, timezone aware
///
///   // Add soft delete column (deleted_at)
///   table.softDeletes();             // Non-timezone aware
///   table.softDeletesTz();           // Timezone aware (UTC)
/// });
/// ```
///
/// ## Indexes & Foreign Keys
///
/// ```dart
/// schema.create('posts', (table) {
///   table.id();
///   table.integer('author_id');
///   table.string('slug');
///   table.string('category');
///
///   // Simple index
///   table.index(['slug']);
///
///   // Composite index
///   table.index(['category', 'created_at']);
///
///   // Unique constraint
///   table.unique(['slug']);
///
///   // Full-text search index
///   table.fullText(['title', 'body']);
///
///   // Foreign key
///   table.foreign(['author_id'])
///       .references('users', ['id'])
///       .onDelete(ReferenceAction.cascade)
///       .onUpdate(ReferenceAction.cascade);
/// });
/// ```
///
/// ## Foreign Key Shortcuts
///
/// ```dart
/// schema.create('posts', (table) {
///   table.id();
///
///   // Creates integer column + foreign key constraint
///   table.foreignId('user_id')
///       .constrained('users')        // References users.id
///       .onDelete(ReferenceAction.cascade);
///
///   // UUID foreign key
///   table.foreignUuid('category_id')
///       .constrained('categories');
/// });
/// ```
///
/// ## Altering Tables
///
/// Use `schema.table()` to modify existing tables:
///
/// ```dart
/// class AddAvatarToUsers extends Migration {
///   const AddAvatarToUsers();
///
///   @override
///   void up(SchemaBuilder schema) {
///     schema.table('users', (table) {
///       table.string('avatar_url').nullable();
///       table.index(['avatar_url']);
///     });
///   }
///
///   @override
///   void down(SchemaBuilder schema) {
///     schema.table('users', (table) {
///       table.dropColumn('avatar_url');
///       table.dropIndex(['avatar_url']);
///     });
///   }
/// }
/// ```
///
/// ## Renaming & Dropping
///
/// ```dart
/// // Rename table
/// schema.rename('old_name', 'new_name');
///
/// // Drop table
/// schema.drop('table_name');
/// schema.drop('table_name', ifExists: true);
///
/// // Drop if exists
/// schema.dropIfExists('table_name');
/// ```
///
/// ## Migration Registry
///
/// Register migrations using [MigrationEntry] for proper ordering:
///
/// ```dart
/// final entries = [
///   MigrationEntry(
///     id: MigrationId.parse('m_20251115014501_create_users_table'),
///     migration: const CreateUsersTable(),
///   ),
///   MigrationEntry(
///     id: MigrationId.parse('m_20251115015021_create_posts_table'),
///     migration: const CreatePostsTable(),
///   ),
/// ];
///
/// // Build descriptors sorted by timestamp
/// final descriptors = MigrationEntry.buildDescriptors(entries);
/// ```
///
/// ## Running Migrations
///
/// Use [MigrationRunner] to execute migrations:
///
/// ```dart
/// final runner = MigrationRunner(
///   schemaDriver: schemaDriver,
///   migrations: descriptors,
///   ledger: SqlMigrationLedger(driver: schemaDriver),
/// );
///
/// // Run all pending migrations
/// await runner.applyAll();
///
/// // Rollback last batch
/// await runner.rollback();
///
/// // Get migration status
/// final status = await runner.status();
/// ```
///
/// ## Driver-Specific Overrides
///
/// Customize schema for different databases:
///
/// ```dart
/// schema.create('events', (table) {
///   table.json('metadata')
///       .driverType('postgres', const ColumnType.jsonb());
///
///   table.string('locale')
///       .driverOverride('postgres', collation: '"und-x-icu"');
///
///   table.timestamp('synced_at', timezoneAware: true)
///       .driverDefault('postgres', expression: "timezone('UTC', now())");
/// });
/// ```
///
/// ## Key Classes
///
/// - [Migration] - Base class for database migrations
/// - [SchemaBuilder] - Builder for schema operations (create, alter, drop)
/// - [TableBlueprint] - Fluent API for defining table structure
/// - [ColumnBuilder] - Builder for column definitions with modifiers
/// - [MigrationRunner] - Executes migrations up/down
/// - [MigrationLedger] - Tracks applied migrations
/// - [MigrationEntry] - Links migration ID to migration instance
/// - [MigrationDescriptor] - Compiled migration with checksums
library;

export 'src/blueprint/migration.dart';
export 'src/blueprint/model_snapshot.dart';
export 'src/blueprint/schema_builder.dart';
export 'src/blueprint/schema_compiler.dart';
export 'src/blueprint/schema_driver.dart';
export 'src/blueprint/schema_plan.dart';
export 'src/blueprint/schema_snapshot.dart';
export 'src/blueprint/table_blueprint.dart';
export 'src/migrations/ledger.dart';
export 'src/migrations/migration_runner.dart';
export 'src/migrations/migration_status.dart';
export 'src/migrations/models/orm_migration_record.dart';
export 'src/migrations/seeder.dart';
export 'src/migrations/sql_migration_ledger.dart';
