/// Small example showing how to bootstrap the SQLite adapter.
library;

import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

part 'ormed_sqlite_example.orm.dart';

@OrmModel(table: 'users')
class ExampleUser {
  const ExampleUser({required this.id, required this.email});

  @OrmField(isPrimaryKey: true)
  final int id;

  final String email;
}

void main() async {
  final adapter = SqliteDriverAdapter.inMemory();
  final registry = ModelRegistry()
    ..register(ExampleUserOrmDefinition.definition);
  final context = QueryContext(registry: registry, driver: adapter);

  await adapter.executeRaw(
    'CREATE TABLE users (id INTEGER PRIMARY KEY, email TEXT NOT NULL)',
  );

  StructuredQueryLogger.printing(pretty: true).attach(context);

  final repository = context.repository<ExampleUser>();
  const user = ExampleUser(id: 1, email: 'example@example.com');

  final insertPreview = repository.previewInsert(user);
  print('Insert preview => ${insertPreview.sql} ${insertPreview.parameters}');

  await repository.insert(user);

  final query = context.query<ExampleUser>().whereEquals('email', user.email);
  final queryPreview = query.toSql();
  print('Query preview => ${queryPreview.sql} ${queryPreview.parameters}');

  final results = await query.get();
  print('Fetched \\${results.length} user(s)');
  await adapter.close();
}
