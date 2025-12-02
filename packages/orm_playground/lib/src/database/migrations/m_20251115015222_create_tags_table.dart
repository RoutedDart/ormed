import 'package:ormed/migrations.dart';

class CreateTagsTable extends Migration {
  const CreateTagsTable();

  @override
  void up(SchemaBuilder schema) {
    schema.create('tags', (table) {
      table.increments('id');
      table.string('name').unique();
      table.timestamps();
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('tags', ifExists: true);
  }
}
