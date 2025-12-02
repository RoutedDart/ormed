import 'package:ormed/migrations.dart';

class CreateUsersTable extends Migration {
  const CreateUsersTable() : super();

  @override
  void up(SchemaBuilder schema) {
    schema.create('users', (table) {
      table.integer('id').primaryKey().autoIncrement();
      table.string('email').unique();
      table.boolean('active');
      table.string('name').nullable();
      table.integer('age').nullable();
      table.dateTime('createdAt').nullable();
      table.text('profile').nullable();
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('users', ifExists: true);
  }
}
