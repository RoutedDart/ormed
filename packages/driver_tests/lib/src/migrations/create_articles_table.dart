import 'package:ormed/migrations.dart';

class CreateArticlesTable extends Migration {
  const CreateArticlesTable() : super();

  @override
  void up(SchemaBuilder schema) {
    schema.create('articles', (table) {
      table.integer('id').primaryKey();
      table.string('title');
      table.text('body').nullable();
      table.string('status');
      table.double('rating'); // Use double for floating-point numbers
      table.integer('priority');
      table.dateTime('published_at');
      table.dateTime('reviewed_at').nullable();
      table.integer('category_id');
    });
  }

  @override
  void down(SchemaBuilder schema) {
    schema.drop('articles', ifExists: true);
  }
}
