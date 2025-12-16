library;

import 'package:ormed/ormed.dart';

class CreateScopedUsersTable extends Migration {
  const CreateScopedUsersTable();

  @override
  void up(SchemaBuilder builder) {
    builder.create('scoped_users', (table) {
      table.increments('id');
      table.string('email');
      table.boolean('active');
      table.string('name').nullable();
    });
  }

  @override
  void down(SchemaBuilder builder) {
    builder.drop('scoped_users', ifExists: true);
  }
}
