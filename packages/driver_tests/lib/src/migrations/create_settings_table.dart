import 'package:ormed/migrations.dart';

class CreateSettingsTable extends Migration {
  const CreateSettingsTable() : super();

  @override
  void up(SchemaBuilder schema) {
    schema.create('settings', (table) {
      table.integer('id').primaryKey();
      table.json('payload'); // Use json type for Map<String, dynamic>
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('settings', ifExists: true);
  }
}
