import 'package:mongo_dart/mongo_dart.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_mongo/ormed_mongo.dart';
import 'package:test/test.dart';

import 'shared.dart';

const mutationCollection = 'mutation_targets';

void main() {
  late MongoDriverAdapter adapter;
  late QueryContext context;
  late Db verifier;
  final registry = ModelRegistry();
  final definition = buildAnnotatedDefinition(
    mutationCollection,
    columns: const [
      AdHocColumn(name: '_id', isPrimaryKey: true),
      AdHocColumn(name: 'name'),
      AdHocColumn(name: 'active'),
      AdHocColumn(name: 'category'),
    ],
  );

  setUpAll(() async {
    await waitForMongoReady();
    adapter = createAdapter();
    registry.register(definition);
    context = QueryContext(registry: registry, driver: adapter);
    verifier = await openVerifier();
  });

  tearDownAll(() async {
    await adapter.close();
    await verifier.close();
  });

  setUp(() async {
    await dropCollection(verifier, mutationCollection);
  });

  test('repository updates apply via Mongo driver', () async {
    final repo = context.repository<Map<String, Object?>>();
    final targetId = ObjectId();
    await repo.insertMany([
      {'_id': targetId, 'name': 'widget', 'active': true},
    ]);

    await repo.updateMany([
      {'_id': targetId, 'name': 'widget-updated', 'active': false},
    ]);

    final stored = await verifier.collection(mutationCollection).findOne({
      '_id': targetId,
    });
    expect(stored, isNotNull);
    expect(stored!['name'], 'widget-updated');
    expect(stored['active'], false);
  });

  test('repository deletions remove documents', () async {
    final repo = context.repository<Map<String, Object?>>();
    final targetId = ObjectId();
    await repo.insertMany([
      {'_id': targetId, 'name': 'to-delete', 'active': true},
    ]);

    final removed = await repo.deleteByKeys([
      {'_id': targetId},
    ]);
    expect(removed, equals(1));

    final count = await verifier.collection(mutationCollection).count();
    expect(count, 0);
  });

  test('join builder throws unsupported error for Mongo', () async {
    final query = context.query<Map<String, Object?>>();
    expect(() => query.join('other', 'id', '=', 1), throwsUnsupportedError);
  });

  test('insertUsing builder throws unsupported error for Mongo', () async {
    final query = context.query<Map<String, Object?>>();
    expect(() => query.insertUsing(['name'], query), throwsUnsupportedError);
  });

  test('query builder updates modify matching documents', () async {
    final repo = context.repository<Map<String, Object?>>();
    await repo.insertMany([
      {
        '_id': ObjectId(),
        'name': 'widget',
        'category': 'gadgets',
        'active': true,
      },
      {
        '_id': ObjectId(),
        'name': 'gizmo',
        'category': 'gadgets',
        'active': true,
      },
      {
        '_id': ObjectId(),
        'name': 'whiz',
        'category': 'widgets',
        'active': true,
      },
    ]);

    final count = await context
        .query<Map<String, Object?>>()
        .whereEquals('category', 'gadgets')
        .update({'active': false});
    expect(count, equals(2));

    final updated = await verifier.collection(mutationCollection).find({
      'category': 'gadgets',
    }).toList();
    expect(updated, hasLength(2));
    expect(updated.every((row) => row['active'] == false), isTrue);
  });

  test('forceDelete honors query delete filters', () async {
    final repo = context.repository<Map<String, Object?>>();
    await repo.insertMany([
      {'_id': ObjectId(), 'name': 'widget', 'category': 'garbage'},
      {'_id': ObjectId(), 'name': 'trash', 'category': 'garbage'},
    ]);

    final removed = await context
        .query<Map<String, Object?>>()
        .whereEquals('category', 'garbage')
        .forceDelete();
    expect(removed, equals(2));

    final remaining = await verifier.collection(mutationCollection).count();
    expect(remaining, equals(0));
  });

  test('repository upsert merges duplicates using unique columns', () async {
    final repo = context.repository<Map<String, Object?>>();
    await repo.upsertMany(
      [
        {'_id': ObjectId(), 'name': 'widget', 'active': true},
      ],
      uniqueBy: ['name'],
      updateColumns: ['active'],
    );

    await repo.upsertMany(
      [
        {'_id': ObjectId(), 'name': 'widget', 'active': false},
      ],
      uniqueBy: ['name'],
      updateColumns: ['active'],
    );

    final stored = await verifier.collection(mutationCollection).findOne({
      'name': 'widget',
    });
    expect(stored, isNotNull);
    expect(stored!['active'], false);
  });
}
