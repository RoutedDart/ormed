import 'package:ormed/migrations.dart';

class CreatePostTagsTable extends Migration {
  const CreatePostTagsTable() : super();

  @override
  void up(SchemaBuilder schema) {
    schema.create('post_tags', (table) {
      table.integer('post_id');
      table.integer('tag_id');
      table.primary(['post_id', 'tag_id']);
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('post_tags', ifExists: true);
  }
}
