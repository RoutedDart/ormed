import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../../driver_tests.dart';

void runRelationResolverCacheTests(DataSource dataSource) {
  group(
    '${dataSource.connection.driver.metadata.name} RelationResolver caching',
    () {
      setUp(() async {
        // Bind connection resolver for Model methods to work
        Model.bindConnectionResolver(
          resolveConnection: (name) => dataSource.context,
        );

        // Seed test datas
        await dataSource.repo<Author>().insertMany([
          const Author(id: 1, name: 'Alice'),
          const Author(id: 2, name: 'Bob'),
        ]);
        await dataSource.repo<Post>().insertMany([
          Post(
            id: 1,
            authorId: 1,
            title: 'Post 1',
            publishedAt: DateTime(2024),
          ),
          Post(
            id: 2,
            authorId: 1,
            title: 'Post 2',
            publishedAt: DateTime(2024, 2),
          ),
          Post(
            id: 3,
            authorId: 2,
            title: 'Post 3',
            publishedAt: DateTime(2024, 3),
          ),
        ]);
        await dataSource.repo<Tag>().insertMany([
          const Tag(id: 1, label: 'dart'),
          const Tag(id: 2, label: 'flutter'),
        ]);
        await dataSource.repo<PostTag>().insertMany([
          const PostTag(postId: 1, tagId: 1),
          const PostTag(postId: 1, tagId: 2),
          const PostTag(postId: 2, tagId: 1),
        ]);
      });

      tearDown(() async {
        Model.unbindConnectionResolver();
      });

      group('cached resolver', () {
        test('caches resolved paths for reuse', () {
          final resolver = RelationResolver(dataSource.context);

          // First resolution
          final path1 = resolver.resolvePath(
            AuthorOrmDefinition.definition,
            'posts',
          );

          // Second resolution should return cached
          final path2 = resolver.resolvePath(
            AuthorOrmDefinition.definition,
            'posts',
          );

          // Should be the exact same instance
          expect(identical(path1, path2), isTrue);
        });

        test('cacheStats reports correct size', () {
          final resolver = RelationResolver(dataSource.context);

          expect(resolver.cacheStats['size'], equals(0));

          resolver.resolvePath(AuthorOrmDefinition.definition, 'posts');
          expect(resolver.cacheStats['size'], equals(1));

          resolver.resolvePath(PostOrmDefinition.definition, 'author');
          expect(resolver.cacheStats['size'], equals(2));

          resolver.resolvePath(PostOrmDefinition.definition, 'tags');
          expect(resolver.cacheStats['size'], equals(3));

          // Resolving same path shouldn't increase cache size
          resolver.resolvePath(AuthorOrmDefinition.definition, 'posts');
          expect(resolver.cacheStats['size'], equals(3));
        });

        test('clearCache removes all cached entries', () {
          final resolver = RelationResolver(dataSource.context);

          resolver.resolvePath(AuthorOrmDefinition.definition, 'posts');
          resolver.resolvePath(PostOrmDefinition.definition, 'author');
          expect(resolver.cacheStats['size'], equals(2));

          resolver.clearCache();
          expect(resolver.cacheStats['size'], equals(0));
        });

        test('after clearCache, paths are resolved fresh', () {
          final resolver = RelationResolver(dataSource.context);

          final path1 = resolver.resolvePath(
            AuthorOrmDefinition.definition,
            'posts',
          );

          resolver.clearCache();

          final path2 = resolver.resolvePath(
            AuthorOrmDefinition.definition,
            'posts',
          );

          // After clear, should be different instances
          expect(identical(path1, path2), isFalse);

          // But should have same structure
          expect(path1.segments.length, equals(path2.segments.length));
          expect(path1.segments.first.name, equals(path2.segments.first.name));
        });

        test('caches nested relation paths', () {
          final resolver = RelationResolver(dataSource.context);

          final path1 = resolver.resolvePath(
            AuthorOrmDefinition.definition,
            'posts.tags',
          );

          final path2 = resolver.resolvePath(
            AuthorOrmDefinition.definition,
            'posts.tags',
          );

          expect(identical(path1, path2), isTrue);
          expect(path1.segments, hasLength(2));
        });

        test('different paths are cached separately', () {
          final resolver = RelationResolver(dataSource.context);

          final postsPath = resolver.resolvePath(
            AuthorOrmDefinition.definition,
            'posts',
          );

          final tagsPath = resolver.resolvePath(
            PostOrmDefinition.definition,
            'tags',
          );

          expect(identical(postsPath, tagsPath), isFalse);

          // Each can be retrieved from cache independently
          final postsPath2 = resolver.resolvePath(
            AuthorOrmDefinition.definition,
            'posts',
          );
          final tagsPath2 = resolver.resolvePath(
            PostOrmDefinition.definition,
            'tags',
          );

          expect(identical(postsPath, postsPath2), isTrue);
          expect(identical(tagsPath, tagsPath2), isTrue);
        });

        test('caches paths by model and relation combination', () {
          final resolver = RelationResolver(dataSource.context);

          // Same relation name on different models
          // (if Post had an 'author' and Tag had an 'author', they'd be separate)
          final postAuthor = resolver.resolvePath(
            PostOrmDefinition.definition,
            'author',
          );

          // Verify it's cached
          final postAuthor2 = resolver.resolvePath(
            PostOrmDefinition.definition,
            'author',
          );

          expect(identical(postAuthor, postAuthor2), isTrue);
        });
      });

      group('uncached resolver', () {
        test('does not cache paths', () {
          final resolver = RelationResolver.uncached(dataSource.context);

          final path1 = resolver.resolvePath(
            AuthorOrmDefinition.definition,
            'posts',
          );

          final path2 = resolver.resolvePath(
            AuthorOrmDefinition.definition,
            'posts',
          );

          // Uncached resolver creates new instances each time
          expect(identical(path1, path2), isFalse);
        });

        test('cacheStats always returns zero', () {
          final resolver = RelationResolver.uncached(dataSource.context);

          resolver.resolvePath(AuthorOrmDefinition.definition, 'posts');
          resolver.resolvePath(PostOrmDefinition.definition, 'author');
          resolver.resolvePath(PostOrmDefinition.definition, 'tags');

          expect(resolver.cacheStats['size'], equals(0));
        });

        test('resolves paths correctly despite no caching', () {
          final resolver = RelationResolver.uncached(dataSource.context);

          final path = resolver.resolvePath(
            AuthorOrmDefinition.definition,
            'posts.tags',
          );

          expect(path.segments, hasLength(2));
          expect(path.segments[0].name, equals('posts'));
          expect(path.segments[1].name, equals('tags'));
          expect(path.leaf.targetDefinition.modelName, equals('Tag'));
        });
      });

      group('integration with query operations', () {
        test('caching works across multiple query operations', () async {
          // Multiple queries using withRelation should benefit from caching
          // (internally the query builder uses a cached resolver)
          final authors1 = await dataSource.context
              .query<Author>()
              .withRelation('posts')
              .get();

          final authors2 = await dataSource.context
              .query<Author>()
              .withRelation('posts')
              .get();

          // Both should work correctly
          expect(authors1.first.relationLoaded('posts'), isTrue);
          expect(authors2.first.relationLoaded('posts'), isTrue);
        });

        test('caching works with lazy loading', () async {
          final rows1 = await dataSource.context
              .query<Author>()
              .where('id', 1)
              .get();
          final rows2 = await dataSource.context
              .query<Author>()
              .where('id', 2)
              .get();

          final author1 = rows1.first;
          final author2 = rows2.first;

          // Multiple lazy loads should work
          await author1.load('posts');
          await author2.load('posts');

          expect(author1.relationLoaded('posts'), isTrue);
          expect(author2.relationLoaded('posts'), isTrue);
        });

        test('caching works with nested relation loading', () async {
          final rows = await dataSource.context
              .query<Author>()
              .where('id', 1)
              .get();
          final author = rows.first;

          // Load nested relations multiple times
          await author.load('posts.tags');

          expect(author.relationLoaded('posts'), isTrue);
          for (final post in author.posts) {
            if (post.id == 1) {
              expect(post.relationLoaded('tags'), isTrue);
            }
          }
        });

        test('caching works with batch loading', () async {
          final authors = await dataSource.context.query<Author>().get();

          // Batch load should work with caching
          await Model.loadRelations(authors, 'posts');

          for (final author in authors) {
            expect(author.relationLoaded('posts'), isTrue);
          }
        });
      });

      group('error handling', () {
        test('invalid relation throws ArgumentError (cached)', () {
          final resolver = RelationResolver(dataSource.context);

          expect(
            () =>
                resolver.resolvePath(AuthorOrmDefinition.definition, 'invalid'),
            throwsA(isA<ArgumentError>()),
          );

          // Cache should not contain failed resolution
          expect(resolver.cacheStats['size'], equals(0));
        });

        test('invalid relation throws ArgumentError (uncached)', () {
          final resolver = RelationResolver.uncached(dataSource.context);

          expect(
            () =>
                resolver.resolvePath(AuthorOrmDefinition.definition, 'invalid'),
            throwsA(isA<ArgumentError>()),
          );
        });

        test('invalid nested relation throws ArgumentError', () {
          final resolver = RelationResolver(dataSource.context);

          expect(
            () => resolver.resolvePath(
              AuthorOrmDefinition.definition,
              'posts.invalid',
            ),
            throwsA(isA<ArgumentError>()),
          );
        });
      });

      group('segmentFor method', () {
        test('builds segment for belongsTo relation', () {
          final resolver = RelationResolver(dataSource.context);
          final authorRelation = PostOrmDefinition.definition.relations
              .firstWhere((r) => r.name == 'author');

          final segment = resolver.segmentFor(
            PostOrmDefinition.definition,
            authorRelation,
          );

          expect(segment.name, equals('author'));
          expect(segment.expectSingleResult, isTrue);
          expect(segment.foreignKeyOnParent, isTrue);
          expect(segment.targetDefinition.modelName, equals('Author'));
        });

        test('builds segment for hasMany relation', () {
          final resolver = RelationResolver(dataSource.context);
          final postsRelation = AuthorOrmDefinition.definition.relations
              .firstWhere((r) => r.name == 'posts');

          final segment = resolver.segmentFor(
            AuthorOrmDefinition.definition,
            postsRelation,
          );

          expect(segment.name, equals('posts'));
          expect(segment.expectSingleResult, isFalse);
          expect(segment.foreignKeyOnParent, isFalse);
          expect(segment.targetDefinition.modelName, equals('Post'));
        });

        test('builds segment for manyToMany relation', () {
          final resolver = RelationResolver(dataSource.context);
          final tagsRelation = PostOrmDefinition.definition.relations
              .firstWhere((r) => r.name == 'tags');

          final segment = resolver.segmentFor(
            PostOrmDefinition.definition,
            tagsRelation,
          );

          expect(segment.name, equals('tags'));
          expect(segment.pivotTable, isNotNull);
          expect(segment.pivotParentKey, isNotNull);
          expect(segment.pivotRelatedKey, isNotNull);
          expect(segment.targetDefinition.modelName, equals('Tag'));
        });
      });

      group('predicateFor method', () {
        test('returns null when no constraint provided', () {
          final resolver = RelationResolver(dataSource.context);
          final relation = PostOrmDefinition.definition.relations.first;

          final predicate = resolver.predicateFor(relation, null);

          expect(predicate, isNull);
        });

        test('builds predicate from constraint callback', () {
          final resolver = RelationResolver(dataSource.context);
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

        test('builds complex predicate with multiple conditions', () {
          final resolver = RelationResolver(dataSource.context);
          final postsRelation = AuthorOrmDefinition.definition.relations
              .firstWhere((r) => r.name == 'posts');

          final predicate = resolver.predicateFor(
            postsRelation,
            (q) => q.where('id', 1).where('title', 'Test'),
          );

          expect(predicate, isNotNull);
          expect(predicate, isA<PredicateGroup>());
        });
      });
    },
  );
}
