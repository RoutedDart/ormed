import 'package:ormed/migrations.dart';

class CreateEventModelsTable extends Migration {
  const CreateEventModelsTable() : super();

  @override
  void up(SchemaBuilder schema) {
    schema.create('event_models', (table) {
      table.integer('id').primaryKey().autoIncrement();
      table.string('name');
      table.integer('score');
      table.timestampsTz(precision: 6);
      table.softDeletesTz(precision: 6);
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('event_models', ifExists: true);
  }
}
