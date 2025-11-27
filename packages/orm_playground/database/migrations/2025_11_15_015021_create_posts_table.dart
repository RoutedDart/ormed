import 'package:ormed/migrations.dart';

class CreatePostsTable extends Migration {
  const CreatePostsTable();

  @override
  void up(SchemaBuilder schema) {
    schema.create('posts', (table) {
      table.increments('id');
      table.unsignedBigInteger('user_id');
      table.string('title');
      table.text('body').nullable();
      table.timestamp('published_at').nullable();
      table.boolean('published').defaultValue(false);
      table.timestamps();

      table
          .foreign(['user_id'], references: 'users', referencedColumns: ['id'])
          .onDelete(ReferenceAction.cascade);
      table.index(['user_id']);
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('posts', ifExists: true);
  }
}
