/// Tests for RelationResolver caching and path resolution.
library;

import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import 'package:driver_tests/driver_tests.dart';

void main() {
  late ModelRegistry registry;
  late InMemoryQueryExecutor executor;
  late QueryContext context;

  setUp(() {
    registry = ModelRegistry()
      ..registerAll([
        AuthorOrmDefinition.definition,
        PostOrmDefinition.definition,
        TagOrmDefinition.definition,
        PostTagOrmDefinition.definition,
      ]);
    executor = InMemoryQueryExecutor();
    context = QueryContext(driver: executor, registry: registry);
  });

  group('RelationResolver', () {
    group('path resolution', () {
      test('resolves single relation path', () {
        final resolver = RelationResolver(context);
        final path = resolver.resolvePath(
          PostOrmDefinition.definition,
          'author',
        );

        expect(path.segments, hasLength(1));
        expect(path.segments.first.name, equals('author'));
        expect(
          path.segments.first.targetDefinition.modelName,
          equals('Author'),
        );
      });

      test('resolves nested relation path', () {
        final resolver = RelationResolver(context);
        final path = resolver.resolvePath(
          AuthorOrmDefinition.definition,
          'posts.tags',
        );

        expect(path.segments, hasLength(2));
        expect(path.segments[0].name, equals('posts'));
        expect(path.segments[1].name, equals('tags'));
        expect(path.leaf.targetDefinition.modelName, equals('Tag'));
      });

      test('throws on invalid relation name', () {
        final resolver = RelationResolver(context);

        expect(
          () =>
              resolver.resolvePath(PostOrmDefinition.definition, 'nonexistent'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws on invalid nested relation name', () {
        final resolver = RelationResolver(context);

        expect(
          () => resolver.resolvePath(
            AuthorOrmDefinition.definition,
            'posts.nonexistent',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('caching', () {
      test('caches resolved paths by default', () {
        final resolver = RelationResolver(context);

        // First call - should resolve
        final path1 = resolver.resolvePath(
          PostOrmDefinition.definition,
          'author',
        );

        // Second call - should return cached
        final path2 = resolver.resolvePath(
          PostOrmDefinition.definition,
          'author',
        );

        // Should return the exact same instance (cached)
        expect(identical(path1, path2), isTrue);
      });

      test('caches different paths separately', () {
        final resolver = RelationResolver(context);

        final authorPath = resolver.resolvePath(
          PostOrmDefinition.definition,
          'author',
        );

        final tagsPath = resolver.resolvePath(
          PostOrmDefinition.definition,
          'tags',
        );

        // Different paths should not be identical
        expect(identical(authorPath, tagsPath), isFalse);

        // But subsequent calls to the same path should be cached
        final authorPath2 = resolver.resolvePath(
          PostOrmDefinition.definition,
          'author',
        );
        expect(identical(authorPath, authorPath2), isTrue);
      });

      test('cacheStats reports correct size', () {
        final resolver = RelationResolver(context);

        expect(resolver.cacheStats['size'], equals(0));

        resolver.resolvePath(PostOrmDefinition.definition, 'author');
        expect(resolver.cacheStats['size'], equals(1));

        resolver.resolvePath(PostOrmDefinition.definition, 'tags');
        expect(resolver.cacheStats['size'], equals(2));

        // Resolving same path again shouldn't increase cache size
        resolver.resolvePath(PostOrmDefinition.definition, 'author');
        expect(resolver.cacheStats['size'], equals(2));
      });

      test('clearCache removes all cached paths', () {
        final resolver = RelationResolver(context);

        resolver.resolvePath(PostOrmDefinition.definition, 'author');
        resolver.resolvePath(PostOrmDefinition.definition, 'tags');
        expect(resolver.cacheStats['size'], equals(2));

        resolver.clearCache();
        expect(resolver.cacheStats['size'], equals(0));

        // After clearing, should resolve fresh (new instance)
        final path1 = resolver.resolvePath(
          PostOrmDefinition.definition,
          'author',
        );
        resolver.clearCache();
        final path2 = resolver.resolvePath(
          PostOrmDefinition.definition,
          'author',
        );

        // Should not be identical since cache was cleared
        expect(identical(path1, path2), isFalse);
      });
    });

    group('uncached resolver', () {
      test('uncached resolver does not cache paths', () {
        final resolver = RelationResolver.uncached(context);

        final path1 = resolver.resolvePath(
          PostOrmDefinition.definition,
          'author',
        );

        final path2 = resolver.resolvePath(
          PostOrmDefinition.definition,
          'author',
        );

        // Uncached resolver creates new instances each time
        expect(identical(path1, path2), isFalse);

        // But the paths should still be equal in content
        expect(path1.segments.length, equals(path2.segments.length));
        expect(path1.segments.first.name, equals(path2.segments.first.name));
      });

      test('uncached resolver cacheStats returns zero', () {
        final resolver = RelationResolver.uncached(context);

        resolver.resolvePath(PostOrmDefinition.definition, 'author');
        resolver.resolvePath(PostOrmDefinition.definition, 'tags');

        // Cache size should always be 0 for uncached resolver
        expect(resolver.cacheStats['size'], equals(0));
      });
    });

    group('predicateFor', () {
      test('returns null when no constraint provided', () {
        final resolver = RelationResolver(context);
        final relation = PostOrmDefinition.definition.relations.first;

        final predicate = resolver.predicateFor(relation, null);

        expect(predicate, isNull);
      });

      test('builds predicate from constraint callback', () {
        final resolver = RelationResolver(context);
        final authorRelation = PostOrmDefinition.definition.relations
            .firstWhere((r) => r.name == 'author');

        final predicate = resolver.predicateFor(
          authorRelation,
          (q) => q.where('name', 'Alice'),
        );

        expect(predicate, isNotNull);
        expect(predicate, isA<FieldPredicate>());
        final fieldPredicate = predicate as FieldPredicate;
        expect(fieldPredicate.field, equals('name'));
        expect(fieldPredicate.value, equals('Alice'));
      });
    });

    group('segmentFor', () {
      test('builds segment for belongsTo relation', () {
        final resolver = RelationResolver(context);
        final authorRelation = PostOrmDefinition.definition.relations
            .firstWhere((r) => r.name == 'author');

        final segment = resolver.segmentFor(
          PostOrmDefinition.definition,
          authorRelation,
        );

        expect(segment.name, equals('author'));
        expect(segment.expectSingleResult, isTrue);
        expect(segment.foreignKeyOnParent, isTrue);
      });

      test('builds segment for hasMany relation', () {
        final resolver = RelationResolver(context);
        final postsRelation = AuthorOrmDefinition.definition.relations
            .firstWhere((r) => r.name == 'posts');

        final segment = resolver.segmentFor(
          AuthorOrmDefinition.definition,
          postsRelation,
        );

        expect(segment.name, equals('posts'));
        expect(segment.expectSingleResult, isFalse);
        expect(segment.foreignKeyOnParent, isFalse);
      });

      test('builds segment for manyToMany relation', () {
        final resolver = RelationResolver(context);
        final tagsRelation = PostOrmDefinition.definition.relations.firstWhere(
          (r) => r.name == 'tags',
        );

        final segment = resolver.segmentFor(
          PostOrmDefinition.definition,
          tagsRelation,
        );

        expect(segment.name, equals('tags'));
        expect(segment.pivotTable, isNotNull);
        expect(segment.pivotParentKey, isNotNull);
        expect(segment.pivotRelatedKey, isNotNull);
      });
    });
  });
}
