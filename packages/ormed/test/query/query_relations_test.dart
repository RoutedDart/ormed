import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import 'package:driver_tests/driver_tests.dart';

void main() {
  groupHasMany();
  groupBelongsTo();
  groupManyToMany();
  groupMorphRelations();
}

void groupHasMany() {
  group('hasMany relations', () {
    late QueryContext context;

    setUp(() {
      ModelRegistry registry = bootstrapOrm();
      final executor = InMemoryQueryExecutor()
        ..register(AuthorOrmDefinition.definition, const [
          Author(id: 1, name: 'Alice', active: true),
          Author(id: 2, name: 'Bob', active: true),
        ])
        ..register(PostOrmDefinition.definition, [
          Post(
            id: 1,
            authorId: 1,
            title: 'Welcome',
            publishedAt: DateTime(2024),
          ),
          Post(
            id: 2,
            authorId: 1,
            title: 'Second',
            publishedAt: DateTime(2024, 2),
          ),
          Post(
            id: 3,
            authorId: 2,
            title: 'Intro',
            publishedAt: DateTime(2024, 3),
          ),
        ])
        ..register(PhotoOrmDefinition.definition, const [
          Photo(id: 1, imageableId: 1, imageableType: 'Post', path: 'hero.jpg'),
        ]);
      context = QueryContext(registry: registry, driver: executor);
    });

    test('whereHas records relation predicate metadata', () {
      final plan = context
          .query<Author>()
          .whereHas('posts', (posts) => posts.where('title', 'Welcome'))
          .debugPlan();

      expect(plan.predicate, isA<RelationPredicate>());
      final join = plan.relationJoins.singleWhere((j) => j.pathKey == 'posts');
      expect(join.edges, hasLength(1));
      expect(join.leaf.alias, 'rel_posts_0');
    });

    test('withCount registers hasMany aggregates', () {
      final plan = context.query<Author>().withCount('posts').debugPlan();

      final aggregate = plan.relationAggregates.single;
      expect(
        aggregate.path.segments.single.relation.kind,
        RelationKind.hasMany,
      );
    });

    test('withCount distinct flag persists', () {
      final plan = context
          .query<Author>()
          .withCount('posts', distinct: true)
          .debugPlan();

      expect(plan.relationAggregates.single.distinct, isTrue);
    });

    test('orderByRelation distinct only valid for count aggregates', () {
      expect(
        () => context.query<Author>().orderByRelation(
          'posts',
          aggregate: RelationAggregateType.exists,
          distinct: true,
        ),
        throwsArgumentError,
      );
    });

    test('withExists + orderByRelation reuse join metadata', () {
      final plan = context
          .query<Author>()
          .withExists('posts', alias: 'has_posts')
          .orderByRelation('posts', descending: true)
          .debugPlan();

      expect(plan.relationAggregates.single.alias, 'has_posts');
      expect(plan.relationOrders.single.descending, isTrue);
    });

    test('withRelation accepts constrained predicate', () {
      final plan = context
          .query<Author>()
          .withRelation('posts', (posts) => posts.where('title', 'Intro'))
          .debugPlan();

      expect(plan.relations.single.predicate, isNotNull);
    });

    test('withRelation registers join metadata', () {
      final plan = context.query<Author>().withRelation('posts').debugPlan();

      expect(plan.relationJoins.map((j) => j.pathKey), contains('posts'));
    });
  });
}

void groupBelongsTo() {
  group('belongsTo relations', () {
    late QueryContext context;

    setUp(() {
      ModelRegistry registry = bootstrapOrm();
      final executor = InMemoryQueryExecutor()
        ..register(AuthorOrmDefinition.definition, const [
          Author(id: 1, name: 'Alice', active: true),
        ])
        ..register(PostOrmDefinition.definition, [
          Post(
            id: 1,
            authorId: 1,
            title: 'Welcome',
            publishedAt: DateTime(2024),
          ),
        ]);
      context = QueryContext(registry: registry, driver: executor);
    });

    test('withCount works for belongsTo', () {
      final plan = context.query<Post>().withCount('author').debugPlan();

      expect(
        plan.relationAggregates.single.path.segments.single.relation.kind,
        RelationKind.belongsTo,
      );
    });

    test('whereHas works for belongsTo', () {
      final plan = context
          .query<Post>()
          .withTrashed()
          .whereHas('author', (authors) => authors.where('name', 'Alice'))
          .debugPlan();

      final predicate = plan.predicate as RelationPredicate;
      expect(
        predicate.path.segments.single.relation.kind,
        RelationKind.belongsTo,
      );
    });

    test('withRelation eager loads belongsTo relations', () {
      final plan = context.query<Post>().withRelation('author').debugPlan();

      expect(plan.relations.single.relation.kind, RelationKind.belongsTo);
    });
  });
}

void groupManyToMany() {
  group('many-to-many relations', () {
    late QueryContext context;

    setUp(() {
      ModelRegistry registry = bootstrapOrm();
      final executor = InMemoryQueryExecutor()
        ..register(PostOrmDefinition.definition, [
          Post(
            id: 1,
            authorId: 1,
            title: 'Welcome',
            publishedAt: DateTime(2024),
          ),
        ])
        ..register(TagOrmDefinition.definition, const [
          Tag(id: 1, label: 'featured'),
        ]);
      context = QueryContext(registry: registry, driver: executor);
    });

    test('orderByRelation works for many-to-many', () {
      final plan = context
          .query<Post>()
          .orderByRelation('tags', descending: true)
          .debugPlan();

      final order = plan.relationOrders.single;
      expect(order.path.segments.single.relation.kind, RelationKind.manyToMany);
    });

    test('withCount distinct collapses duplicate pivot rows', () {
      final plan = context
          .query<Post>()
          .withCount('tags', distinct: true)
          .debugPlan();

      final aggregate = plan.relationAggregates.single;
      expect(aggregate.distinct, isTrue);
    });
  });
}

void groupMorphRelations() {
  group('morph relations', () {
    late QueryContext context;

    setUp(() {
      ModelRegistry registry = bootstrapOrm();
      final executor = InMemoryQueryExecutor()
        ..register(AuthorOrmDefinition.definition, const [
          Author(id: 1, name: 'Alice', active: true),
        ])
        ..register(PostOrmDefinition.definition, [
          Post(
            id: 1,
            authorId: 1,
            title: 'Welcome',
            publishedAt: DateTime(2024),
          ),
        ])
        ..register(PhotoOrmDefinition.definition, const [
          Photo(id: 1, imageableId: 1, imageableType: 'Post', path: 'hero.jpg'),
        ])
        ..register(ImageOrmDefinition.definition, const [
          Image(id: 1, label: 'Logo'),
        ]);
      context = QueryContext(registry: registry, driver: executor);
    });

    test('orWhereHas supports morph relations', () {
      final plan = context
          .query<Author>()
          .orWhereHas(
            'posts.photos',
            (photos) => photos.where('path', 'hero.jpg'),
          )
          .debugPlan();

      final predicate = plan.predicate as RelationPredicate;
      expect(predicate.path.segments, hasLength(2));
    });

    test('nested morph orderByRelation/withExists capture metadata', () {
      final plan = context
          .query<Author>()
          .withExists('posts.photos', alias: 'has_photos')
          .orderByRelation('posts.photos', descending: true)
          .debugPlan();

      final aggregate = plan.relationAggregates.single;
      expect(aggregate.alias, 'has_photos');
      final order = plan.relationOrders.single;
      expect(order.path.segments, hasLength(2));
    });

    test('whereHas captures morph metadata on morphOne', () {
      final plan = context
          .query<Image>()
          .whereHas(
            'primaryPhoto',
            (photos) => photos.where('path', 'hero.jpg'),
          )
          .debugPlan();

      final predicate = plan.predicate as RelationPredicate;
      final segment = predicate.path.segments.single;
      expect(segment.morphTypeColumn, 'imageable_type');
      expect(segment.morphClass, 'Image');
    });

    test('whereHas supports nested morph paths', () {
      final plan = context
          .query<Author>()
          .whereHas(
            'posts.photos',
            (photos) => photos.where('path', 'hero.jpg'),
          )
          .debugPlan();

      final predicate = plan.predicate as RelationPredicate;
      expect(predicate.path.segments, hasLength(2));
      final leaf = predicate.path.leaf;
      expect(leaf.usesMorph, isTrue);
      expect(leaf.morphClass, 'Post');
    });
  });
}
