import 'package:ormed/migrations.dart';

class CreateUsersTable extends Migration {
  const CreateUsersTable();

  @override
  void up(SchemaBuilder schema) {
    schema.create('users', (table) {
      table.increments('id');
      table.string('email').unique();
      table.string('name');
      table.boolean('active').defaultValue(true);
      table.timestamp('created_at').nullable();
      table.timestamp('updated_at').nullable();
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('users', ifExists: true);
  }
}
