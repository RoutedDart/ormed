import 'package:mongo_dart/mongo_dart.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_mongo/ormed_mongo.dart';
import 'package:test/test.dart';

import 'shared.dart';

const productsCollection = 'products_integration';
const validatedCollection = 'validated_integration';
const ephemeralCollection = 'ephemeral_integration';

void main() {
  late MongoDriverAdapter adapter;
  late Db verifier;

  final integrationProductDefinition = AdHocModelDefinition(
    tableName: productsCollection,
  );

  setUpAll(() async {
    await waitForMongoReady();
    adapter = createAdapter();
    verifier = await openVerifier();
  });

  tearDownAll(() async {
    await adapter.close();
    await verifier.close();
  });

  setUp(() async {
    await dropCollection(verifier, productsCollection);
    await dropCollection(verifier, validatedCollection);
    await dropCollection(verifier, ephemeralCollection);
  });

  test('repository inserts produce stored documents', () async {
    final repository = Repository<Map<String, Object?>>(
      definition: integrationProductDefinition,
      driverName: adapter.metadata.name,
      codecs: adapter.codecs,
      runMutation: adapter.runMutation,
      describeMutation: adapter.describeMutation,
      attachRuntimeMetadata: (_) {},
    );

    await repository.insertMany([
      {'name': 'widget', 'category': 'gadgets', 'active': true},
      {'name': 'gizmo', 'category': 'gadgets', 'active': false},
    ]);

    final count = await verifier.collection(productsCollection).count();
    expect(count, 2);
  });

  test('Schema plan creates collection/index/validator', () async {
    final plan = SchemaPlan(
      mutations: [
        SchemaMutation.createCollection(
          collection: validatedCollection,
          validator: {
            'score': {'\$gt': 10},
          },
          options: {'capped': false},
        ),
        SchemaMutation.createIndex(
          collection: validatedCollection,
          keys: {'score': 1},
          options: {'name': 'score_idx', 'unique': false},
        ),
      ],
    );

    await adapter.applySchemaPlan(plan);
    final invalid = await verifier.collection(validatedCollection).insert({
      'score': 5,
    });
    expect(invalid['ok'], 0);
    expect(invalid, contains('errmsg'));
    final matches = await verifier.collection(validatedCollection).find({
      'score': 5,
    }).toList();
    expect(matches, isEmpty);

    await verifier.collection(validatedCollection).insert({'score': 42});
    final validCount = await verifier.collection(validatedCollection).count();
    expect(validCount, 1);
  });

  test('Schema plan drops indexes and collections', () async {
    await adapter.applySchemaPlan(
      SchemaPlan(
        mutations: [
          SchemaMutation.createCollection(collection: ephemeralCollection),
          SchemaMutation.createIndex(
            collection: ephemeralCollection,
            keys: {'flag': 1},
            options: {'name': 'ephemeral_idx'},
          ),
        ],
      ),
    );

    await adapter.applySchemaPlan(
      SchemaPlan(
        mutations: [
          SchemaMutation.dropIndex(
            collection: ephemeralCollection,
            name: 'ephemeral_idx',
          ),
          SchemaMutation.dropCollection(collection: ephemeralCollection),
        ],
      ),
    );

    try {
      final indexes = await verifier
          .collection(ephemeralCollection)
          .getIndexes();
      expect(indexes, isEmpty);
    } on MongoDartError {
      // Some Mongo versions throw if the namespace is missing.
    }
  });
}
