import 'package:ormed/migrations.dart';

class CreateUniqueUsersTable extends Migration {
  const CreateUniqueUsersTable() : super();

  @override
  void up(SchemaBuilder schema) {
    schema.create('unique_users', (table) {
      table.integer('id').primaryKey().autoIncrement();
      table.string('email').unique();
      table.boolean('active');
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('unique_users', ifExists: true);
  }
}
