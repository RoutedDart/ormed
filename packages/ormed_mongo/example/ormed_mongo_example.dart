import 'package:ormed_mongo/ormed_mongo.dart';
import 'package:ormed/ormed.dart';

Future<void> main() async {
  final adapter = MongoDriverAdapter.custom(
    config: const DatabaseConfig(
      driver: 'mongo',
      options: {'url': 'mongodb://127.0.0.1:27017', 'database': 'orm_test'},
    ),
  );
  final preview = adapter.planCompiler.compileSelect(
    QueryPlan(definition: AdHocModelDefinition(tableName: 'example')),
  );
  print('Command: ${(preview.payload as DocumentStatementPayload).command}');
  await adapter.close();
}
