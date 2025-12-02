import 'package:ormed/ormed.dart';
import 'package:driver_tests/driver_tests.dart';
import 'package:ormed_mongo/src/mongo_query_plan_metadata.dart';
import 'package:ormed_mongo/src/mongo_relation_hook.dart';
import 'package:test/test.dart';

import 'shared.dart';
import 'package:ormed_mongo/ormed_mongo.dart';

void main() {
  late DataSource dataSource;
  late MongoDriverAdapter driverAdapter;

  setUpAll(() async {
    await waitForMongoReady();
    await clearDatabase();
    driverAdapter = createAdapter();
    registerDriverTestFactories();
    dataSource = DataSource(DataSourceOptions(
      driver: driverAdapter,
      entities: generatedOrmModelDefinitions,
    ));
    await dataSource.init();
  });

  setUp(() async {
    await clearDatabase();
    await seedGraph(dataSource);
  });

  tearDownAll(() async => await dataSource.dispose());

  test('Mongo metadata captures eager-relation descriptors', () async {
    final plan = dataSource.context
        .query<Post>()
        .withRelation('author')
        .whereEquals('id', 1)
        .debugPlan();

    final rows = await dataSource.context.runSelect(plan);

    expect(rows, isNotEmpty);

    final metadata = metadataForPlan(plan);
    expect(metadata, isNotNull);
    expect(metadata!.relationLoads, hasLength(1));
    expect(metadata.relationLoads.first.relation.name, 'author');
    expect(metadata.relationLoads.first.predicate, isNull);
  });

  test('Relation metadata records constraints supplied via helper', () async {
    final plan = dataSource.context
        .query<Post>()
        .withRelation('photos', (builder) => builder.where('path', 'hero.jpg'))
        .debugPlan();

    await dataSource.context.runSelect(plan);

    final metadata = metadataForPlan(plan);
    expect(metadata, isNotNull);
    expect(metadata!.relationLoads, hasLength(1));
    final predicate = metadata.relationLoads.first.predicate;
    expect(predicate, isNotNull);
  });

  test('Mongo metadata records relation aggregate descriptors', () async {
    final query = dataSource.context.query<Author>().withCount('posts');
    final plan = query.debugPlan();
    await dataSource.context.runSelect(plan);

    final metadata = metadataForPlan(plan);
    expect(metadata, isNotNull);
    expect(metadata!.relationAggregates, hasLength(1));
    expect(
      metadata.relationAggregates.first.alias,
      equals(plan.relationAggregates.first.alias),
    );
  });

  test(
    'Mongo metadata records nested relation aggregate descriptors',
    () async {
      final query = dataSource.context.query<Author>().withCount('posts.photos');
      final plan = query.debugPlan();
      await dataSource.context.runSelect(plan);

      final metadata = metadataForPlan(plan);
      expect(metadata, isNotNull);
      expect(metadata!.relationAggregates, hasLength(1));
      final aggregate = metadata.relationAggregates.first;
      expect(
        aggregate.path.segments.map((segment) => segment.name).join('.'),
        equals('posts.photos'),
      );
      expect(aggregate.alias, equals(plan.relationAggregates.first.alias));
    },
  );

  test('Mongo metadata captures relation order descriptors', () async {
    final query = dataSource.context.query<Author>().orderByRelation(
      'posts',
      aggregate: RelationAggregateType.count,
      descending: true,
    );
    final plan = query.debugPlan();
    await dataSource.context.runSelect(plan);

    final metadata = metadataForPlan(plan);
    expect(metadata, isNotNull);
    expect(metadata!.relationOrders, isNotEmpty);
    final order = metadata.relationOrders.first;
    expect(order.aggregateType, equals(RelationAggregateType.count));
    expect(
      order.path.segments.map((segment) => segment.name).join('.'),
      equals('posts'),
    );
  });

  test('Mongo relation helper synthesizes relation counts', () async {
    final query = dataSource.context
        .query<Author>()
        .withCount('posts')
        .orderBy('id');
    final alias = query.debugPlan().relationAggregates.single.alias;
    final rows = await query.rows();

    for (final row in rows) {
      expect(row.row[alias], isA<int>());
      expect(row.row[alias], isNotNull);
      expect(row.row[alias], greaterThanOrEqualTo(0));
    }
  });

  test('Mongo relation helper handles withExists', () async {
    final query = dataSource.context
        .query<Author>()
        .withExists('posts')
        .orderBy('id');
    final alias = query.debugPlan().relationAggregates.single.alias;
    final rows = await query.rows();

    for (final row in rows) {
      expect(row.row[alias], isA<bool>());
    }
  });

  test('Mongo relation helper streams aggregates', () async {
    final query = dataSource.context
        .query<Author>()
        .withCount('posts')
        .orderBy('id');
    final alias = query.debugPlan().relationAggregates.single.alias;
    final baseline = {
      for (final row in await query.rows()) row.model.id: row.row[alias],
    };
    final rows = await query.streamRows().toList();

    for (final row in rows) {
      final authorId = row.model.id;
      expect(row.row[alias], equals(baseline[authorId]));
    }
  });

  test('Mongo relation helper orders by relation aggregates', () async {
    final rows = await dataSource.context
        .query<Author>()
        .orderByRelation(
          'posts',
          aggregate: RelationAggregateType.count,
          descending: true,
        )
        .rows();

    expect(rows.first.model.id, equals(1));
    expect(rows.last.model.id, equals(2));
  });

  test('Mongo relation helper streams ordered aggregates', () async {
    final rows = await dataSource.context
        .query<Author>()
        .orderByRelation(
          'posts',
          aggregate: RelationAggregateType.count,
          descending: true,
        )
        .streamRows()
        .toList();

    expect(rows.first.model.id, equals(1));
    expect(rows.last.model.id, equals(2));
  });

  test('Mongo relation helper handles nested relation counts', () async {
    final posts = await dataSource.context.query<Post>().get();
    final photos = await dataSource.context.query<Photo>().get();
    final postIdsByAuthor = <int, List<int>>{};
    for (final post in posts) {
      postIdsByAuthor.putIfAbsent(post.authorId, () => <int>[]).add(post.id);
    }
    final nestedCounts = <int, int>{};
    for (final photo in photos) {
      if (photo.imageableType != 'Post') continue;
      for (final entry in postIdsByAuthor.entries) {
        if (entry.value.contains(photo.imageableId)) {
          nestedCounts[entry.key] = (nestedCounts[entry.key] ?? 0) + 1;
        }
      }
    }

    final query = dataSource.context
        .query<Author>()
        .withCount('posts.photos')
        .orderBy('id');
    final alias = query.debugPlan().relationAggregates.single.alias;
    final rows = await query.rows();

    for (final row in rows) {
      final authorId = row.model.id;
      final expected = nestedCounts[authorId] ?? 0;
      expect(row.row[alias], equals(expected));
    }
  });

  test('Mongo relation helper orders by nested relation aggregates', () async {
    final rows = await dataSource.context
        .query<Author>()
        .orderByRelation(
          'posts.photos',
          aggregate: RelationAggregateType.count,
          descending: true,
        )
        .rows();

    expect(rows.first.model.id, equals(1));
    expect(rows.last.model.id, equals(2));
  });

  test('Mongo relation helper streams nested ordered aggregates', () async {
    final rows = await dataSource.context
        .query<Author>()
        .orderByRelation(
          'posts.photos',
          aggregate: RelationAggregateType.count,
          descending: true,
        )
        .streamRows()
        .toList();

    expect(rows.first.model.id, equals(1));
    expect(rows.last.model.id, equals(2));
  });

  test('Mongo driver metadata registers the relation hook', () {
    expect(driverAdapter.metadata.relationHook, isA<MongoRelationHook>());
  });
}
