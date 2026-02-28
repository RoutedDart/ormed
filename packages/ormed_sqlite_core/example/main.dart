import 'package:ormed/migrations.dart';
import 'package:ormed_sqlite_core/ormed_sqlite_core.dart';

void main() {
  final builder = SchemaBuilder()
    ..create('documents', (table) {
      table.increments('id');
      table.string('title');
      table.numeric('score', precision: 10, scale: 2);
      table.blob('payload').nullable();
      table.timestamps();
    });

  final compiler = SchemaPlanCompiler(const SqliteSchemaDialect());
  final preview = compiler.compile(builder.build());
  for (final statement in preview.statements) {
    print(statement.sql);
  }
}
