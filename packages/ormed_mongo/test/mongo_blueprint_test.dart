import 'package:ormed/ormed.dart';
import 'package:ormed_mongo/ormed_mongo.dart';
import 'package:test/test.dart';

import 'shared.dart';

void main() {
  group('MongoDB Blueprint Extensions -', () {
    late DataSource dataSource;

    setUp(() async {
      dataSource = await createDataSource();

      dataSource.enableQueryLog();
      dataSource.onBeforeQuery((plan) {
        print("__");
        final preview = dataSource.connection.driver.describeQuery(plan);
        print(preview.sql);
        // print('[QUERY SQL] ${preview.normalized.command}');
      });
    });

    tearDown(() async {
      await dataSource.dispose();
    });

    test('jsonSchema creates collection with validation', () async {
      final db = (dataSource.connection.driver as MongoDriverAdapter).testDb!;
      try {
        final collectionName = 'validated_users';
        await dropCollection(db, collectionName);

        // Create table with JSON Schema validation using SchemaBuilder
        final builder = SchemaBuilder();
        builder.create(collectionName, (t) {
          t.id();
          t.string('name');
          t.string('email');
          t.integer('age');

          // Add JSON Schema validation
          t.jsonSchema(
            {
              'bsonType': 'object',
              'required': ['name', 'email'],
              'properties': {
                'name': {
                  'bsonType': 'string',
                  'minLength': 1,
                  'description': 'must be a string and is required',
                },
                'email': {
                  'bsonType': 'string',
                  'description': 'must be a string and is required',
                },
                'age': {
                  'bsonType': 'int',
                  'minimum': 0,
                  'description': 'must be an integer >= 0',
                },
              },
            },
            validationLevel: 'strict',
            validationAction: 'error',
          );
        });

        final plan = builder.build(description: 'create-validated-users');
        await (dataSource.connection.driver as SchemaDriver).applySchemaPlan(
          plan,
        );

        // Verify collection was created with validation
        final collection = db.collection(collectionName);

        // Valid document should insert successfully
        await collection.insertOne({
          'name': 'John Doe',
          'email': 'john@example.com',
          'age': 30,
        });

        // Invalid document (missing required field) should fail
        try {
          await collection.insertOne({
            'name': 'Jane Doe',
            // missing email
            'age': 25,
          });
          fail('Should have failed validation for missing email');
        } catch (e) {
          expect(e.toString(), contains('Document failed validation'));
        }

        // Invalid document (wrong type) should fail
        try {
          await collection.insertOne({
            'name': 'Bob Smith',
            'email': 'bob@example.com',
            'age': 'thirty', // should be int
          });
          fail('Should have failed validation for wrong age type');
        } catch (e) {
          expect(e.toString(), contains('Document failed validation'));
        }

        // Verify the validator is set correctly
        final collectionInfo = await db.getCollectionInfos({
          'name': collectionName,
        });

        print('Collection info: $collectionInfo');

        expect(collectionInfo, isNotEmpty);
        if (collectionInfo.first['options'] != null) {
          print('Options: ${collectionInfo.first['options']}');
          expect(collectionInfo.first['options']['validator'], isNotNull);
          expect(
            collectionInfo.first['options']['validator']['\$jsonSchema'],
            isNotNull,
          );
          expect(
            collectionInfo.first['options']['validationLevel'],
            equals('strict'),
          );
          expect(
            collectionInfo.first['options']['validationAction'],
            equals('error'),
          );
        }
      } finally {
        
      }
    });

    test('text index creates full-text search index', () async {
      final db = (dataSource.connection.driver as MongoDriverAdapter).testDb!;
      try {
        final collectionName = 'articles';
        await dropCollection(db, collectionName);

        final builder = SchemaBuilder();
        builder.create(collectionName, (t) {
          t.id();
          t.string('title');
          t.text('body');

          // Create text index
          t.textIndex(['title', 'body'], name: 'article_text_idx');
        });

        final plan = builder.build(description: 'create-articles');
        await (dataSource.connection.driver as SchemaDriver).applySchemaPlan(
          plan,
        );

        // Verify index was created
        final collection = db.collection(collectionName);
        final indexes = await collection.getIndexes();

        final textIndex = indexes.firstWhere(
          (idx) => idx['name'] == 'article_text_idx',
          orElse: () => {},
        );

        expect(textIndex, isNotEmpty);
        expect(textIndex['key'], isNotNull);
        expect(textIndex['key']['title'], equals('text'));
        expect(textIndex['key']['body'], equals('text'));
      } finally {
        
      }
    });

    test('geospatial indexes create 2dsphere index', () async {
      final db = (dataSource.connection.driver as MongoDriverAdapter).testDb!;
      try {
        final collectionName = 'locations';
        await dropCollection(db, collectionName);

        final builder = SchemaBuilder();
        builder.create(collectionName, (t) {
          t.id();
          t.string('name');
          t.json('location');

          // Create 2dsphere index
          t.geospatial(['location'], name: 'location_2dsphere');
        });

        final plan = builder.build(description: 'create-locations');
        await (dataSource.connection.driver as SchemaDriver).applySchemaPlan(
          plan,
        );

        // Verify index was created
        final collection = db.collection(collectionName);
        final indexes = await collection.getIndexes();

        final geoIndex = indexes.firstWhere(
          (idx) => idx['name'] == 'location_2dsphere',
          orElse: () => {},
        );

        expect(geoIndex, isNotEmpty);
        expect(geoIndex['key'], isNotNull);
        expect(geoIndex['key']['location'], equals('2dsphere'));

        // Insert a location document to verify index works
        await collection.insertOne({
          'name': 'New York',
          'location': {
            'type': 'Point',
            'coordinates': [-74.0060, 40.7128], // [longitude, latitude]
          },
        });
      } finally {
        
      }
    });

    test('sparse and unique indexes', () async {
      final db = (dataSource.connection.driver as MongoDriverAdapter).testDb!;
      try {
        final collectionName = 'users_sparse';
        await dropCollection(db, collectionName);

        final builder = SchemaBuilder();
        builder.create(collectionName, (t) {
          t.id();
          t.string('username');
          t.string('email');

          // Create sparse unique index on email
          t.unique(['email'], name: 'email_unique');
          // Note: sparse option needs to be added via driverOptions
          t.index(
            ['email'],
            name: 'email_unique_sparse',
            driverOptions: {
              'mongodb': {'sparse': true},
            },
          );
        });

        final plan = builder.build(description: 'create-users-sparse');
        await (dataSource.connection.driver as SchemaDriver).applySchemaPlan(
          plan,
        );

        // Verify index was created with correct properties
        final collection = db.collection(collectionName);
        final indexes = await collection.getIndexes();

        final emailIndex = indexes.firstWhere(
          (idx) => idx['name'] == 'email_unique',
          orElse: () => {},
        );

        expect(emailIndex, isNotEmpty);
        expect(emailIndex['unique'], isTrue);
        expect(emailIndex['sparse'], isTrue);

        // Can insert documents without email (sparse index)
        await collection.insertOne({'username': 'user1'});
        await collection.insertOne({'username': 'user2'});

        // Can insert document with email
        await collection.insertOne({
          'username': 'user3',
          'email': 'user3@example.com',
        });

        // Cannot insert duplicate email (unique constraint)
        try {
          await collection.insertOne({
            'username': 'user4',
            'email': 'user3@example.com', // duplicate
          });
          fail('Should have failed unique constraint');
        } catch (e) {
          expect(e.toString(), contains('duplicate key'));
        }
      } finally {
        
      }
    });

    test('TTL index with expireAfter', () async {
      final db = (dataSource.connection.driver as MongoDriverAdapter).testDb!;
      try {
        final collectionName = 'sessions';
        await dropCollection(db, collectionName);

        final builder = SchemaBuilder();
        builder.create(collectionName, (t) {
          t.id();
          t.string('sessionId');
          t.dateTime('createdAt');

          // Create TTL index - documents expire after 1 hour
          t.expire('createdAt', 3600, name: 'ttl_index');
        });

        final plan = builder.build(description: 'create-sessions');
        await (dataSource.connection.driver as SchemaDriver).applySchemaPlan(
          plan,
        );

        // Verify TTL index was created
        final collection = db.collection(collectionName);
        final indexes = await collection.getIndexes();

        final ttlIndex = indexes.firstWhere(
          (idx) => idx['name'] == 'ttl_index',
          orElse: () => {},
        );

        expect(ttlIndex, isNotEmpty);
        expect(ttlIndex['expireAfterSeconds'], equals(3600)); // 1 hour
      } finally {
        
      }
    });

    test('hashed index', () async {
      final db = (dataSource.connection.driver as MongoDriverAdapter).testDb!;
      try {
        final collectionName = 'sharded_users';
        await dropCollection(db, collectionName);

        final builder = SchemaBuilder();
        builder.create(collectionName, (t) {
          t.id();
          t.string('userId');

          // Create hashed index for sharding
          t.hashed('userId', name: 'userId_hashed');
        });

        final plan = builder.build(description: 'create-sharded-users');
        await (dataSource.connection.driver as SchemaDriver).applySchemaPlan(
          plan,
        );

        // Verify hashed index was created
        final collection = db.collection(collectionName);
        final indexes = await collection.getIndexes();

        final hashedIndex = indexes.firstWhere(
          (idx) => idx['name'] == 'userId_hashed',
          orElse: () => {},
        );

        expect(hashedIndex, isNotEmpty);
        expect(hashedIndex['key']['userId'], equals('hashed'));
      } finally {
        
      }
    });

    test('compound indexes', () async {
      final db = (dataSource.connection.driver as MongoDriverAdapter).testDb!;
      try {
        final collectionName = 'products';
        await dropCollection(db, collectionName);

        final builder = SchemaBuilder();
        builder.create(collectionName, (t) {
          t.id();
          t.string('category');
          t.decimal('price');
          t.string('brand');

          // Create compound index
          t.index([
            'category',
            'price',
            'brand',
          ], name: 'category_price_brand_idx');
        });

        final plan = builder.build(description: 'create-products');
        await (dataSource.connection.driver as SchemaDriver).applySchemaPlan(
          plan,
        );

        // Verify compound index was created
        final collection = db.collection(collectionName);
        final indexes = await collection.getIndexes();

        final compoundIndex = indexes.firstWhere(
          (idx) => idx['name'] == 'category_price_brand_idx',
          orElse: () => {},
        );

        expect(compoundIndex, isNotEmpty);
        expect(compoundIndex['key']['category'], equals(1));
        expect(compoundIndex['key']['price'], equals(1));
        expect(compoundIndex['key']['brand'], equals(1));
      } finally {
        
      }
    });
  });
}
