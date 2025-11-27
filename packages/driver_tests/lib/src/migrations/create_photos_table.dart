import 'package:ormed/migrations.dart';

class CreatePhotosTable extends Migration {
  const CreatePhotosTable() : super();

  @override
  void up(SchemaBuilder schema) {
    schema.create('photos', (table) {
      table.integer('id').primaryKey();
      table.integer('imageable_id');
      table.string('imageable_type');
      table.string('path');
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('photos', ifExists: true);
  }
}
