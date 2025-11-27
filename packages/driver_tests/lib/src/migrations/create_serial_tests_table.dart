import 'package:ormed/migrations.dart';

class CreateSerialTestsTable extends Migration {
  const CreateSerialTestsTable() : super();

  @override
  void up(SchemaBuilder schema) {
    schema.create('serial_tests', (table) {
      table.integer('id').primaryKey().autoIncrement();
      table.string('label');
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('serial_tests', ifExists: true);
  }
}
