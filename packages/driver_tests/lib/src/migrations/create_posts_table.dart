import 'package:ormed/migrations.dart';

class CreatePostsTable extends Migration {
  const CreatePostsTable() : super();

  @override
  void up(SchemaBuilder schema) {
    schema.create('posts', (table) {
      table.integer('id').primaryKey();
      table.integer('author_id');
      table.string('title');
      table.dateTime('published_at');
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('posts', ifExists: true);
  }
}
