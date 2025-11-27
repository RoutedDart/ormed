import 'package:ormed/migrations.dart';

class CreateImagesTable extends Migration {
  const CreateImagesTable() : super();

  @override
  void up(SchemaBuilder schema) {
    schema.create('images', (table) {
      table.integer('id').primaryKey();
      table.string('label');
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('images', ifExists: true);
  }
}
