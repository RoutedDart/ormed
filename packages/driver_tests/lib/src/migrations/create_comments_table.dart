import 'package:ormed/migrations.dart';

class CreateCommentsTable extends Migration {
  const CreateCommentsTable() : super();

  @override
  void up(SchemaBuilder schema) {
    schema.create('comments', (table) {
      table.integer('id').primaryKey().autoIncrement();
      table.string('body');
      table.dateTime('deleted_at').nullable(); // nullable field
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('comments', ifExists: true);
  }
}
