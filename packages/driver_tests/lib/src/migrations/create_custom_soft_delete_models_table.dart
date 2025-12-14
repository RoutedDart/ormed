import 'package:ormed/migrations.dart';

class CreateCustomSoftDeleteModelsTable extends Migration {
  const CreateCustomSoftDeleteModelsTable() : super();

  @override
  void up(SchemaBuilder schema) {
    schema.create('custom_soft_delete_models', (table) {
      table.integer('id').primaryKey();
      table.string('title');
      table.dateTime('removed_on').nullable();
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('custom_soft_delete_models', ifExists: true);
  }
}
