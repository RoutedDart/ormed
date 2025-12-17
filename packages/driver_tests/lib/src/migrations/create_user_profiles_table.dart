import 'package:ormed/migrations.dart';

class CreateUserProfilesTable extends Migration {
  const CreateUserProfilesTable();

  @override
  void up(SchemaBuilder schema) {
    schema.create('user_profiles', (table) {
      table.integer('id').primaryKey().autoIncrement();
      table.integer('user_id').unique();
      table.string('bio');
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('user_profiles');
  }
}
