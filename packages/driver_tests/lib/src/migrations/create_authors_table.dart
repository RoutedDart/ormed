import 'package:ormed/migrations.dart';

class CreateAuthorsTable extends Migration {
  const CreateAuthorsTable() : super();

  @override
  void up(SchemaBuilder schema) {
    schema.create('authors', (table) {
      table.integer('id').primaryKey();
      table.string('name');
      table.boolean('active').defaultValue(false);
      table.nullableTimestamps(precision: 6); // Adds created_at and updated_at (non-TZ, nullable, microsecond precision)
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('authors', ifExists: true);
  }
}
