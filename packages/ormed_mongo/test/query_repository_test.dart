import 'package:mongo_dart/mongo_dart.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_mongo/ormed_mongo.dart';
import 'package:test/test.dart';

import 'shared.dart';

void main() {
  late MongoDriverAdapter adapter;
  late QueryContext context;
  late Db verifier;
  const repoTable = 'products_repo';
  final repoDefinition = AdHocModelDefinition(
    tableName: repoTable,
    columns: const [AdHocColumn(name: '_id', isPrimaryKey: true)],
  );

  setUpAll(() async {
    await waitForMongoReady();
    adapter = createAdapter();
    context = createContext(adapter);
    verifier = await openVerifier();
  });

  tearDownAll(() async {
    await adapter.close();
    await verifier.close();
  });

  setUp(() async {
    await dropCollection(verifier, repoTable);
  });

  Future<Repository<Map<String, Object?>>> createRepository() async {
    return Repository<Map<String, Object?>>(
      definition: repoDefinition,
      driverName: adapter.metadata.name,
      codecs: adapter.codecs,
      runMutation: adapter.runMutation,
      describeMutation: adapter.describeMutation,
      attachRuntimeMetadata: (_) {},
    );
  }

  test('repository inserts and query builder filters', () async {
    final repo = await createRepository();
    await repo.insertMany([
      {'name': 'widget', 'category': 'gadgets', 'active': true},
      {'name': 'gizmo', 'category': 'widgets', 'active': false},
      {'name': 'whiz', 'category': 'gadgets', 'active': true},
    ]);

    final rows = await context.table(repoTable).orderBy('name').get();

    expect(rows, hasLength(3));
    expect(
      rows.map((row) => row['name']),
      containsAll(['gizmo', 'whiz', 'widget']),
    );
  });

  test('query builder applies not-null filtering and limit', () async {
    final repo = await createRepository();
    await repo.insertMany([
      {'name': 'widget', 'category': 'gadgets', 'active': true},
      {'name': 'gizmo', 'category': 'widgets', 'active': false},
      {'name': 'whiz', 'category': 'gadgets', 'active': true},
      {'name': 'ghost', 'category': null, 'active': true},
    ]);

    final rows = await context
        .table(repoTable)
        .whereNotNull('category')
        .whereEquals('active', true)
        .orderBy('name', descending: true)
        .limit(1)
        .get();

    expect(rows, hasLength(1));
    expect(rows.first['name'], equals('widget'));
  });
}
