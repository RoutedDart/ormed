import 'package:mongo_dart/mongo_dart.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_mongo/ormed_mongo.dart';
import 'package:test/test.dart';

import 'shared.dart';

void main() {
  group('MongoQueryBuilderExtensions', () {
    late DataSource dataSource;

    setUp(() async {
      dataSource = await createDataSource();
    });

    tearDown(() async {
      await dataSource.dispose();
    });

    test('project selects specific fields', () async {
      final db = (dataSource.connection.driver as MongoDriverAdapter).testDb!;
      try {
        final collectionName = 'users_project';
        await dropCollection(db, collectionName);
        final collection = db.collection(collectionName);

        await collection.insertAll([
          {'name': 'John', 'age': 30, 'email': 'john@example.com'},
          {'name': 'Jane', 'age': 25, 'email': 'jane@example.com'},
        ]);

        final query = Query(
          context: dataSource.context,
          definition: AdHocModelDefinition(tableName: 'users_project'),
        );

        // Apply project
        query.project(['name', 'email']);

        // Execute
        final results = await query.get();

        expect(results.length, 2);
        expect(results.first.containsKey('name'), isTrue);
        expect(results.first.containsKey('email'), isTrue);
        expect(results.first.containsKey('age'), isFalse);
      } finally {
        // await db.close();
      }
    });

    test('hint adds index hint', () async {
      final db = (dataSource.connection.driver as MongoDriverAdapter).testDb!;
      try {
        final collectionName = 'users_hint';
        await dropCollection(db, collectionName);
        final collection = db.collection(collectionName);

        await collection.createIndex(keys: {'name': 1}, name: 'name_idx');
        await collection.insertOne({'name': 'John', 'age': 30});

        final query = Query(
          context: dataSource.context,
          definition: AdHocModelDefinition(tableName: 'users_hint'),
        );

        // Apply hint
        query.hint('name_idx');

        // Execute
        final results = await query.get();
        expect(results.length, 1);

        // We can't easily verify the hint was used without profiling,
        // but we can verify it didn't crash
      } finally {
        // await db.close();
      }
    });

    test('push adds items to array', () async {
      final db = (dataSource.connection.driver as MongoDriverAdapter).testDb!;
      try {
        final collectionName = 'users_push';
        await dropCollection(db, collectionName);
        final collection = db.collection(collectionName);

        await collection.insertOne({
          'name': 'John',
          'tags': ['developer'],
        });

        final query = Query(
          context: dataSource.context,
          definition: AdHocModelDefinition(tableName: 'users_push'),
        );

        // Apply push
        await query.where('name', 'John').push('tags', 'manager');

        // Verify
        final user = await collection.findOne(where.eq('name', 'John'));
        expect(user, isNotNull);
        expect(user!['tags'], containsAll(['developer', 'manager']));
      } finally {
        // await db.close();
      }
    });

    test('pull removes items from array', () async {
      final db = (dataSource.connection.driver as MongoDriverAdapter).testDb!;
      try {
        final collectionName = 'users_pull';
        await dropCollection(db, collectionName);
        final collection = db.collection(collectionName);

        await collection.insertOne({
          'name': 'John',
          'tags': ['developer', 'manager', 'designer'],
        });

        final query = Query(
          context: dataSource.context,
          definition: AdHocModelDefinition(tableName: 'users_pull'),
        );

        // Apply pull
        await query.where('name', 'John').pull('tags', 'manager');

        // Verify
        final user = await collection.findOne(where.eq('name', 'John'));
        expect(user, isNotNull);
        expect(user!['tags'], equals(['developer', 'designer']));
      } finally {
        // await db.close();
      }
    });

    test('unset removes fields', () async {
      final db = (dataSource.connection.driver as MongoDriverAdapter).testDb!;
      try {
        final collectionName = 'users_unset';
        await dropCollection(db, collectionName);
        final collection = db.collection(collectionName);

        await collection.insertOne({
          'name': 'John',
          'age': 30,
          'temp': 'delete_me',
        });

        final query = Query(
          context: dataSource.context,
          definition: AdHocModelDefinition(tableName: 'users_unset'),
        );

        // Apply unset
        await query.where('name', 'John').unset('temp');

        // Verify
        final user = await collection.findOne(where.eq('name', 'John'));
        expect(user, isNotNull);
        expect(user!.containsKey('temp'), isFalse);
        expect(user['name'], equals('John'));
      } finally {
        // await db.close();
      }
    });
  });
}
