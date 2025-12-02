import 'package:ormed/migrations.dart';

class CreateDriverOverrideEntriesTable extends Migration {
  const CreateDriverOverrideEntriesTable() : super();

  @override
  void up(SchemaBuilder schema) {
    schema.create('driver_override_entries', (table) {
      table.integer('id').primaryKey();
      table.json('payload');
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('driver_override_entries', ifExists: true);
  }
}
