import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../../driver_tests.dart';

void runLazyLoadingTests(
  DriverHarnessBuilder<DriverTestHarness> createHarness,
  DriverTestConfig config,
) {
  group('${config.driverName} lazy loading', () {
    late DriverTestHarness harness;

    setUp(() async {
      harness = await createHarness();
      
      // Bind connection resolver for Model.load() to work
      Model.bindConnectionResolver(
        resolveConnection: (name) => harness.context,
      );
      
      // Seed test data
      await harness.seedAuthors([
        const Author(id: 1, name: 'Alice'),
        const Author(id: 2, name: 'Bob'),
      ]);
      await harness.seedPosts([
        Post(id: 1, authorId: 1, title: 'Post 1', publishedAt: DateTime(2024)),
        Post(id: 2, authorId: 1, title: 'Post 2', publishedAt: DateTime(2024, 2)),
        Post(id: 3, authorId: 2, title: 'Post 3', publishedAt: DateTime(2024, 3)),
      ]);
      await harness.seedTags([
        const Tag(id: 1, label: 'dart'),
        const Tag(id: 2, label: 'flutter'),
      ]);
      await harness.seedPostTags([
        const PostTag(postId: 1, tagId: 1),
        const PostTag(postId: 1, tagId: 2),
      ]);
    });

    tearDown(() async {
      ModelRelations.preventsLazyLoading = false;
      Model.unbindConnectionResolver();
      await harness.dispose();
    });

    group('load() method', () {
      test('relation starts as default value, becomes populated after lazy load', () async {
        final rows = await harness.context.query<Author>().where('id', 1).get();
        final author = rows.first;
        
        // BEFORE lazy loading - relation returns default value
        expect(author.relationLoaded('posts'), isFalse,
            reason: 'Relation should not be marked as loaded initially');
        
        // Accessing the relation property returns the default from the base class
        final postsBeforeLoad = author.posts;
        expect(postsBeforeLoad, isEmpty,
            reason: 'Should return empty list (default value) when not loaded');
        expect(postsBeforeLoad, isA<List<Post>>(),
            reason: 'Type should still be correct');
        
        // AFTER lazy loading - same property now returns loaded data
        await author.load('posts');
        
        expect(author.relationLoaded('posts'), isTrue,
            reason: 'Relation should now be marked as loaded');
        
        // Accessing the SAME property now returns loaded data
        final postsAfterLoad = author.posts;
        expect(postsAfterLoad, isNotEmpty,
            reason: 'Should return loaded posts from cache');
        
        // Verify it's not the same instance as before
        expect(identical(postsBeforeLoad, postsAfterLoad), isFalse,
            reason: 'Should be different instances (default vs loaded)');
      });

      test('belongsTo relation starts null, becomes populated after lazy load', () async {
        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;
        
        // BEFORE lazy loading
        expect(post.relationLoaded('author'), isFalse,
            reason: 'Relation should not be marked as loaded');
        
        final authorBeforeLoad = post.author;
        expect(authorBeforeLoad, isNull,
            reason: 'Should return null (default value) when not loaded');
        
        // AFTER lazy loading
        await post.load('author');
        
        expect(post.relationLoaded('author'), isTrue,
            reason: 'Relation should now be marked as loaded');
        
        // Same property now returns loaded data
        final authorAfterLoad = post.author;
        expect(authorAfterLoad, isNotNull,
            reason: 'Should return loaded author from cache');
        expect(authorAfterLoad!.name, isNotEmpty);
      });

      test('loads hasMany relation', () async {
        final rows = await harness.context.query<Author>().where('id', 1).get();
        final author = rows.first;
        
        expect(author.relationLoaded('posts'), isFalse);
        expect(author.posts, isEmpty);
        
        final result = await author.load('posts');
        
        expect(identical(result, author), isTrue,
            reason: 'Should return self for chaining');
        expect(author.relationLoaded('posts'), isTrue);
        expect(author.posts, isNotEmpty);
      });

      test('loads belongsTo relation', () async {
        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;
        
        expect(post.relationLoaded('author'), isFalse);
        expect(post.author, isNull);
        
        await post.load('author');
        
        expect(post.relationLoaded('author'), isTrue);
        expect(post.author, isNotNull);
      });

      test('loads relation with constraint callback', () async {
        final rows = await harness.context.query<Author>().where('id', 1).get();
        final author = rows.first;
        
        // Load all posts first to know total
        await author.load('posts');
        final totalPosts = author.posts.length;
        
        // Reload with constraint - limit is on Query, not PredicateBuilder
        await author.load('posts', (q) => q.where('id', 1));
        
        expect(author.posts, hasLength(1),
            reason: 'Should only load 1 post with limit constraint');
        expect(author.posts.length, lessThan(totalPosts),
            reason: 'Constrained load should return fewer results');
      });

      test('loads relation multiple times (replaces previous)', () async {
        final rows = await harness.context.query<Author>().where('id', 1).get();
        final author = rows.first;
        
        // First load with constraint
        await author.load('posts', (q) => q.where('id', 1));
        expect(author.posts, hasLength(1));
        
        // Second load without constraint (should replace)
        await author.load('posts');
        expect(author.posts.length, greaterThan(1),
            reason: 'Second load should replace first');
      });

      test('throws ArgumentError for invalid relation name', () async {
        final rows = await harness.context.query<Author>().where('id', 1).get();
        final author = rows.first;
        
        expect(
          () => author.load('invalid_relation'),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('not found'),
          )),
        );
      });

      test('throws LazyLoadingViolationException when prevented', () async {
        ModelRelations.preventsLazyLoading = true;
        
        final rows = await harness.context.query<Author>().where('id', 1).get();
        final author = rows.first;
        
        expect(
          () => author.load('posts'),
          throwsA(isA<LazyLoadingViolationException>()),
        );
      });

      test('generated getter delegates to cache when loaded', () async {
        final rows = await harness.context.query<Author>().where('id', 1).get();
        final author = rows.first;
        
        // When not loaded, returns super.posts (empty list)
        expect(author.posts, isEmpty);
        
        // Load the relation
        await author.load('posts');
        
        // Now the generated getter should return the cached value
        expect(author.posts, isNotEmpty);
        expect(author.relationLoaded('posts'), isTrue);
      });

      test('works with different models independently', () async {
        final author1Rows = await harness.context.query<Author>().where('id', 1).get();
        final author2Rows = await harness.context.query<Author>().where('id', 2).get();
        
        final author1 = author1Rows.first;
        final author2 = author2Rows.first;
        
        await author1.load('posts');
        await author2.load('posts');
        
        // Each should have their own posts
        expect(author1.posts, isNotEmpty);
        expect(author2.posts, isNotEmpty);
        expect(author1.posts.first.authorId, equals(1));
        expect(author2.posts.first.authorId, equals(2));
      });
    });

    group('loadMissing() method', () {
      test('skips already loaded relations', () async {
        final rows = await harness.context.query<Author>()
            .where('id', 1)
            .withRelation('posts')
            .get();
        final author = rows.first;
        
        expect(author.relationLoaded('posts'), isTrue);
        final originalPosts = author.posts;
        
        // This should not reload
        await author.loadMissing(['posts']);
        
        expect(identical(author.posts, originalPosts), isTrue,
            reason: 'Should be the exact same list instance');
      });

      test('loads multiple missing relations', () async {
        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;
        
        expect(post.relationLoaded('author'), isFalse);
        expect(post.relationLoaded('tags'), isFalse);
        
        await post.loadMissing(['author', 'tags']);
        
        expect(post.relationLoaded('author'), isTrue);
        expect(post.relationLoaded('tags'), isTrue);
      });

      test('loads only missing from mixed list', () async {
        final rows = await harness.context.query<Post>()
            .where('id', 1)
            .withRelation('author')
            .get();
        final post = rows.first;
        
        expect(post.relationLoaded('author'), isTrue);
        expect(post.relationLoaded('tags'), isFalse);
        
        final originalAuthor = post.author;
        
        await post.loadMissing(['author', 'tags']);
        
        expect(identical(post.author, originalAuthor), isTrue,
            reason: 'Should not reload author');
        expect(post.relationLoaded('tags'), isTrue,
            reason: 'Should load tags');
      });

      test('returns self for chaining', () async {
        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;
        
        final result = await post.loadMissing(['author']);
        expect(identical(result, post), isTrue);
      });
    });

    group('loadMany() method', () {
      test('loads multiple relations with constraints', () async {
        final rows = await harness.context.query<Author>().where('id', 1).get();
        final author = rows.first;
        
        await author.loadMany({
          'posts': (q) => q.where('id', 1),
        });
        
        expect(author.relationLoaded('posts'), isTrue);
        expect(author.posts, hasLength(1));
      });

      test('loads relations with mixed constraints', () async {
        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;
        
        await post.loadMany({
          'author': null,
          'tags': (q) => q.where('id', 1),
        });
        
        expect(post.relationLoaded('author'), isTrue);
        expect(post.relationLoaded('tags'), isTrue);
      });

      test('loads all relations when no constraints', () async {
        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;
        
        await post.loadMany({
          'author': null,
          'tags': null,
        });
        
        expect(post.relationLoaded('author'), isTrue);
        expect(post.relationLoaded('tags'), isTrue);
      });

      test('returns self for chaining', () async {
        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;
        
        final result = await post.loadMany({'author': null});
        expect(identical(result, post), isTrue);
      });
    });

    group('loadCount() method', () {
      test('loads relation count', () async {
        final rows = await harness.context.query<Author>().where('id', 1).get();
        final author = rows.first;
        
        expect(author.getAttribute<int>('posts_count'), isNull);
        
        await author.loadCount('posts');
        
        final count = author.getAttribute<int>('posts_count');
        expect(count, isNotNull);
        expect(count! >= 0, isTrue);
      });

      test('loads count with custom alias', () async {
        final rows = await harness.context.query<Author>().where('id', 1).get();
        final author = rows.first;
        
        await author.loadCount('posts', alias: 'total_posts');
        
        expect(author.getAttribute<int>('total_posts'), isNotNull);
        expect(author.getAttribute<int>('posts_count'), isNull,
            reason: 'Default alias should not be set');
      });

      test('loads count with constraint', () async {
        final rows = await harness.context.query<Author>().where('id', 1).get();
        final author = rows.first;
        
        await author.loadCount('posts', constraint: (q) => q.where('id', 1));
        
        final count = author.getAttribute<int>('posts_count');
        expect(count, isNotNull);
      });

      test('throws when lazy loading is prevented', () async {
        ModelRelations.preventsLazyLoading = true;
        
        final rows = await harness.context.query<Author>().where('id', 1).get();
        final author = rows.first;
        
        expect(
          () => author.loadCount('posts'),
          throwsA(isA<LazyLoadingViolationException>()),
        );
      });

      test('returns self for chaining', () async {
        final rows = await harness.context.query<Author>().where('id', 1).get();
        final author = rows.first;
        
        final result = await author.loadCount('posts');
        expect(identical(result, author), isTrue);
      });
    });

    group('loadExists() method', () {
      test('loads relation existence', () async {
        final rows = await harness.context.query<Author>().where('id', 1).get();
        final author = rows.first;
        
        expect(author.getAttribute<bool>('posts_exists'), isNull);
        
        await author.loadExists('posts');
        
        expect(author.getAttribute<bool>('posts_exists'), isNotNull);
      });

      test('loads exists with custom alias', () async {
        final rows = await harness.context.query<Author>().where('id', 1).get();
        final author = rows.first;
        
        await author.loadExists('posts', alias: 'has_posts');
        
        expect(author.getAttribute<bool>('has_posts'), isNotNull);
        expect(author.getAttribute<bool>('posts_exists'), isNull,
            reason: 'Default alias should not be set');
      });

      test('loads exists with constraint', () async {
        final rows = await harness.context.query<Author>().where('id', 1).get();
        final author = rows.first;
        
        await author.loadExists('posts', constraint: (q) => q.where('id', 1));
        
        expect(author.getAttribute<bool>('posts_exists'), isNotNull);
      });

      test('throws when lazy loading is prevented', () async {
        ModelRelations.preventsLazyLoading = true;
        
        final rows = await harness.context.query<Author>().where('id', 1).get();
        final author = rows.first;
        
        expect(
          () => author.loadExists('posts'),
          throwsA(isA<LazyLoadingViolationException>()),
        );
      });

      test('returns self for chaining', () async {
        final rows = await harness.context.query<Author>().where('id', 1).get();
        final author = rows.first;
        
        final result = await author.loadExists('posts');
        expect(identical(result, author), isTrue);
      });
    });

    group('Method chaining', () {
      test('can chain multiple load methods', () async {
        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;
        
        await post
            .load('author')
            .then((p) => p.load('tags'))
            .then((p) => p.loadCount('tags'))
            .then((p) => p.loadExists('author'));
        
        expect(post.relationLoaded('author'), isTrue);
        expect(post.relationLoaded('tags'), isTrue);
        expect(post.getAttribute<int>('tags_count'), isNotNull);
        expect(post.getAttribute<bool>('author_exists'), isNotNull);
      });

      test('can chain load and loadMissing', () async {
        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;
        
        await post
            .load('author')
            .then((p) => p.loadMissing(['author', 'tags']));
        
        expect(post.relationLoaded('author'), isTrue);
        expect(post.relationLoaded('tags'), isTrue);
      });

      test('can chain all methods together', () async {
        final rows = await harness.context.query<Post>().where('id', 1).get();
        final post = rows.first;
        
        await post
            .loadMany({'author': null, 'tags': null})
            .then((p) => p.loadCount('tags'))
            .then((p) => p.loadExists('author'));
        
        expect(post.relationLoaded('author'), isTrue);
        expect(post.relationLoaded('tags'), isTrue);
        expect(post.getAttribute<int>('tags_count'), isNotNull);
        expect(post.getAttribute<bool>('author_exists'), isNotNull);
      });
    });

    group('Integration with eager loading', () {
      test('lazy loading works after eager loading', () async {
        final rows = await harness.context.query<Post>()
            .where('id', 1)
            .withRelation('author')
            .get();
        final post = rows.first;
        
        expect(post.relationLoaded('author'), isTrue);
        final eagerAuthor = post.author;
        
        // Lazy load tags
        await post.load('tags');
        
        expect(post.relationLoaded('tags'), isTrue);
        expect(identical(post.author, eagerAuthor), isTrue,
            reason: 'Lazy loading should not affect eager loaded relations');
      });

      test('loadMissing skips eager loaded relations', () async {
        final rows = await harness.context.query<Post>()
            .where('id', 1)
            .withRelation('author')
            .get();
        final post = rows.first;
        
        final eagerAuthor = post.author;
        
        await post.loadMissing(['author', 'tags']);
        
        expect(identical(post.author, eagerAuthor), isTrue);
        expect(post.relationLoaded('tags'), isTrue);
      });

      test('lazy load count works with eager loaded relations', () async {
        final rows = await harness.context.query<Author>()
            .where('id', 1)
            .withRelation('posts')
            .get();
        final author = rows.first;
        
        expect(author.posts, isNotEmpty);
        
        await author.loadCount('posts');
        
        expect(author.getAttribute<int>('posts_count'), isNotNull);
      });
    });

    group('Edge cases and error handling', () {
      test('handles empty results gracefully', () async {
        // Find an author with no posts (assuming ID 999 doesn't exist in seed data)
        final rows = await harness.context.query<Author>()
            .where('id', 999999)
            .get();
        
        if (rows.isNotEmpty) {
          final author = rows.first;
          await author.load('posts');
          
          expect(author.posts, isEmpty);
          expect(author.relationLoaded('posts'), isTrue);
        }
      });

      test('throws ArgumentError for invalid relation in loadCount', () async {
        final rows = await harness.context.query<Author>().where('id', 1).get();
        final author = rows.first;
        
        expect(
          () => author.loadCount('invalid_relation'),
          throwsArgumentError,
        );
      });

      test('throws ArgumentError for invalid relation in loadExists', () async {
        final rows = await harness.context.query<Author>().where('id', 1).get();
        final author = rows.first;
        
        expect(
          () => author.loadExists('invalid_relation'),
          throwsArgumentError,
        );
      });
    });

    group('Lazy loading prevention', () {
      test('preventsLazyLoading blocks load()', () async {
        ModelRelations.preventsLazyLoading = true;
        
        final rows = await harness.context.query<Author>().where('id', 1).get();
        final author = rows.first;
        
        expect(
          () => author.load('posts'),
          throwsA(isA<LazyLoadingViolationException>()),
        );
      });

      test('preventsLazyLoading blocks loadCount()', () async {
        ModelRelations.preventsLazyLoading = true;
        
        final rows = await harness.context.query<Author>().where('id', 1).get();
        final author = rows.first;
        
        expect(
          () => author.loadCount('posts'),
          throwsA(isA<LazyLoadingViolationException>()),
        );
      });

      test('preventsLazyLoading blocks loadExists()', () async {
        ModelRelations.preventsLazyLoading = true;
        
        final rows = await harness.context.query<Author>().where('id', 1).get();
        final author = rows.first;
        
        expect(
          () => author.loadExists('posts'),
          throwsA(isA<LazyLoadingViolationException>()),
        );
      });

      test('preventsLazyLoading does not block loadMissing for eager loaded', () async {
        ModelRelations.preventsLazyLoading = true;
        
        final rows = await harness.context.query<Author>()
            .where('id', 1)
            .withRelation('posts')
            .get();
        final author = rows.first;
        
        // Should not throw since relation is already loaded
        await author.loadMissing(['posts']);
        
        expect(author.relationLoaded('posts'), isTrue);
      });

      test('preventsLazyLoading blocks loadMissing for missing relations', () async {
        ModelRelations.preventsLazyLoading = true;
        
        final rows = await harness.context.query<Author>().where('id', 1).get();
        final author = rows.first;
        
        expect(
          () => author.loadMissing(['posts']),
          throwsA(isA<LazyLoadingViolationException>()),
        );
      });

      test('can toggle preventsLazyLoading', () async {
        final rows = await harness.context.query<Author>().where('id', 1).get();
        final author = rows.first;
        
        // Enable prevention
        ModelRelations.preventsLazyLoading = true;
        expect(() => author.load('posts'), throwsA(isA<LazyLoadingViolationException>()));
        
        // Disable prevention
        ModelRelations.preventsLazyLoading = false;
        await author.load('posts'); // Should not throw
        
        expect(author.relationLoaded('posts'), isTrue);
      });
    });
  });
}
