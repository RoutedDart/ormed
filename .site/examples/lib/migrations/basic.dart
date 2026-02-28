// Migration examples for documentation
import 'package:ormed/ormed.dart';

// #region create-users-migration
class CreateUsersTable extends Migration {
  const CreateUsersTable();

  @override
  void up(SchemaBuilder schema) {
    schema.create('users', (table) {
      table.increments('id');
      table.string('email').unique();
      table.string('name').nullable();
      table.boolean('active').defaultValue(false);
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('users', ifExists: true);
  }
}
// #endregion create-users-migration

// #region migration-basic
class CreatePostsTableBasic extends Migration {
  const CreatePostsTableBasic();

  @override
  void up(SchemaBuilder schema) {
    schema.create('users', (table) {
      table.integer('id').primaryKey();
      table.string('email').unique();
      table.string('name');
      table.timestamp('created_at').nullable();
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('users', ifExists: true);
  }
}
// #endregion migration-basic

// #region migration-create-table
class CreatePostsTable extends Migration {
  const CreatePostsTable();

  @override
  void up(SchemaBuilder schema) {
    schema.create('posts', (table) {
      table.integer('id').primaryKey().autoIncrement();
      table.string('title');
      table.text('content');
      table.integer('author_id');
      table.boolean('published').defaultValue(false);
      table.timestamp('created_at').nullable();

      table.foreign(
        ['author_id'],
        references: 'users',
        referencedColumns: ['id'],
        onDelete: ReferenceAction.cascade,
      );

      table.index(['author_id', 'published']);
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('posts', ifExists: true);
  }
}
// #endregion migration-create-table

// #region migration-alter-table
class AddSlugToPosts extends Migration {
  const AddSlugToPosts();

  @override
  void up(SchemaBuilder schema) {
    schema.table('posts', (table) {
      table.string('slug').nullable();
      table.integer('view_count').defaultValue(0);
      table.index(['slug']).unique();
      table.renameColumn('content', 'body');
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.table('posts', (table) {
      table.renameColumn('body', 'content');
      table.dropColumn('view_count');
      table.dropColumn('slug');
    });
  }
}
// #endregion migration-alter-table

// #region soft-deletes-migration
class AddSoftDeletesToPosts extends Migration {
  const AddSoftDeletesToPosts();

  @override
  void up(SchemaBuilder schema) {
    schema.table('posts', (table) {
      // Non-timezone aware
      table.softDeletes();

      // OR timezone aware (UTC storage)
      // table.softDeletesTz();
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.table('posts', (table) {
      table.dropColumn('deleted_at');
    });
  }
}
// #endregion soft-deletes-migration

// #region timestamps-migration
class AddTimestampsToPosts extends Migration {
  const AddTimestampsToPosts();

  @override
  void up(SchemaBuilder schema) {
    schema.table('posts', (table) {
      // Non-timezone aware (stored as-is)
      table.timestamps();

      // OR timezone aware (UTC storage)
      // table.timestampsTz();

      // OR nullable timestamps
      // table.nullableTimestamps();
      // table.nullableTimestampsTz();
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.table('posts', (table) {
      table.dropColumn('created_at');
      table.dropColumn('updated_at');
    });
  }
}

// #endregion timestamps-migration
