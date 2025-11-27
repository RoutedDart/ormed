import 'package:ormed/migrations.dart';

class CreateUsersTable extends Migration {
  const CreateUsersTable() : super();

  @override
  void up(SchemaBuilder schema) {
    schema.create('users', (table) {
      table.integer('id').primaryKey();
      table.string('email').unique();
      table.boolean('active');
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('users', ifExists: true);
  }
}
