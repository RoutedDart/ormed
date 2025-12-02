import 'package:ormed/migrations.dart';

class CreateAuthorsTable extends Migration {
  const CreateAuthorsTable() : super();

  @override
  void up(SchemaBuilder schema) {
    schema.create('authors', (table) {
      table.integer('id').primaryKey();
      table.string('name');
      table.boolean('active').defaultValue(false);
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('authors', ifExists: true);
  }
}
