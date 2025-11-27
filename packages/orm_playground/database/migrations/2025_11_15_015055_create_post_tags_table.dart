import 'package:ormed/migrations.dart';

class CreatePostTagsTable extends Migration {
  const CreatePostTagsTable();

  @override
  void up(SchemaBuilder schema) {
    schema.create('post_tags', (table) {
      table.unsignedBigInteger('post_id');
      table.unsignedBigInteger('tag_id');
      table.primary(['post_id', 'tag_id']);

      table
          .foreign(['post_id'], references: 'posts', referencedColumns: ['id'])
          .onDelete(ReferenceAction.cascade);
      table
          .foreign(['tag_id'], references: 'tags', referencedColumns: ['id'])
          .onDelete(ReferenceAction.cascade);
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('post_tags', ifExists: true);
  }
}
