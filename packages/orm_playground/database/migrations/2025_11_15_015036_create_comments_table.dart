import 'package:ormed/migrations.dart';

class CreateCommentsTable extends Migration {
  const CreateCommentsTable();

  @override
  void up(SchemaBuilder schema) {
    schema.create('comments', (table) {
      table.increments('id');
      table.unsignedBigInteger('post_id');
      table.unsignedBigInteger('user_id').nullable();
      table.text('body');
      table.timestamps();

      table
          .foreign(['post_id'], references: 'posts', referencedColumns: ['id'])
          .onDelete(ReferenceAction.cascade);
      table
          .foreign(['user_id'], references: 'users', referencedColumns: ['id'])
          .onDelete(ReferenceAction.setNull);
      table.index(['post_id']);
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('comments', ifExists: true);
  }
}
