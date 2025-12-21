import 'package:ormed/migrations.dart';

class CreateDerivedForFactoriesTable extends Migration {
  const CreateDerivedForFactoriesTable();

  @override
  void up(SchemaBuilder schema) {
    schema.create('derived_for_factories', (table) {
      table.integer('id').primaryKey().autoIncrement();
      table.string('base_name').nullable();
      table.string('layer_one_notes').nullable();
      table.boolean('layer_two_flag').nullable();
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('derived_for_factories', ifExists: true);
  }
}
