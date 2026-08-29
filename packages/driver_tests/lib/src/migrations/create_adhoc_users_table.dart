import 'package:ormed/migrations.dart';

/// A migration-only table intentionally omitted from the model registry.
class CreateAdHocUsersTable extends Migration {
  const CreateAdHocUsersTable() : super();

  @override
  void up(SchemaBuilder schema) {
    schema.create('adhoc_users', (table) {
      table.integer('id').primaryKey().autoIncrement();
      table.string('email').unique();
      table.boolean('active');
      table.string('name').nullable();
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('adhoc_users', ifExists: true);
  }
}
