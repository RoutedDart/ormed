import 'package:ormed/migrations.dart';

class CreateMutationTargetsTable extends Migration {
  const CreateMutationTargetsTable() : super();

  @override
  void up(SchemaBuilder schema) {
    schema.create('mutation_targets', (table) {
      table.string('_id').primaryKey(); // MongoDB's _id field
      table.string('name').nullable();
      table.boolean('active').nullable();
      table.string('category').nullable();
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('mutation_targets', ifExists: true);
  }
}
