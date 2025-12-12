import 'package:ormed/migrations.dart';

class CreateDerivedForFactoriesTable extends Migration {
  const CreateDerivedForFactoriesTable();

  @override
  void up(SchemaBuilder schema) {
    schema.create('derived_for_factories', (table) {
      table.integer('id').primaryKey().autoIncrement();
      table.string('baseName').nullable();
      table.string('layerOneNotes').nullable();
      table.boolean('layerTwoFlag').nullable();
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('derived_for_factories', ifExists: true);
  }
}
