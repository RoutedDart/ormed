import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../../driver_tests.dart';

void runQueryRowSyncTests(
  DataSource dataSource,
  DriverTestConfig config,
) {
  group('${config.driverName} QueryRow relations sync', () {
    

    setUp(() async {
      

      // Seed test data
      await dataSource.repo<Author>().insertMany([const Author(id: 1, name: 'Alice')]);
      await dataSource.repo<Post>().insertMany([
        Post(id: 1, authorId: 1, title: 'Post 1', publishedAt: DateTime(2024)),
        Post(
          id: 2,
          authorId: 1,
          title: 'Post 2',
          publishedAt: DateTime(2024, 2),
        ),
      ]);
      await dataSource.repo<Tag>().insertMany([const Tag(id: 1, label: 'dart')]);
      await dataSource.repo<PostTag>().insertMany([const PostTag(postId: 1, tagId: 1)]);
    });

    tearDown(() async {
      
    });

    test('eager loaded hasMany relations are synced to model', () async {
      final queryRows = await dataSource.context
          .query<Author>()
          .withRelation('posts')
          .where('id', 1)
          .rows();

      final queryRow = queryRows.first;
      final author = queryRow.model;

      // Verify both QueryRow and model have the relation
      expect(queryRow.hasRelation('posts'), isTrue);
      expect(author.relationLoaded('posts'), isTrue);

      // Verify the relation data is the same
      expect(queryRow.relationList<Post>('posts'), hasLength(2));
      expect(author.posts, hasLength(2));

      // Verify they reference the same instances
      expect(
        identical(
          queryRow.relationList<Post>('posts').first,
          author.posts.first,
        ),
        isTrue,
      );
    });

    test('eager loaded belongsTo relations are synced to model', () async {
      final queryRows = await dataSource.context
          .query<Post>()
          .withRelation('author')
          .where('id', 1)
          .rows();

      final queryRow = queryRows.first;
      final post = queryRow.model;

      // Verify both QueryRow and model have the relation
      expect(queryRow.hasRelation('author'), isTrue);
      expect(post.relationLoaded('author'), isTrue);

      // Verify the relation data is the same
      expect(queryRow.relation<Author>('author'), isNotNull);
      expect(post.author, isNotNull);

      // Verify they reference the same instance
      expect(
        identical(queryRow.relation<Author>('author'), post.author),
        isTrue,
      );
    });

    test('multiple eager loaded relations are all synced', () async {
      final queryRows = await dataSource.context
          .query<Post>()
          .withRelation('author')
          .withRelation('tags')
          .where('id', 1)
          .rows();

      final queryRow = queryRows.first;
      final post = queryRow.model;

      // Verify all relations are synced
      expect(queryRow.hasRelation('author'), isTrue);
      expect(queryRow.hasRelation('tags'), isTrue);
      expect(post.relationLoaded('author'), isTrue);
      expect(post.relationLoaded('tags'), isTrue);

      // Verify data integrity
      expect(post.author, isNotNull);
      expect(post.tags, hasLength(1));
    });

    test('non-eager loaded relations are not marked as loaded', () async {
      final queryRows = await dataSource.context
          .query<Author>()
          .where('id', 1)
          .rows();

      final queryRow = queryRows.first;
      final author = queryRow.model;

      // Verify relation is not loaded
      expect(queryRow.hasRelation('posts'), isFalse);
      expect(author.relationLoaded('posts'), isFalse);

      // Model should return default value
      expect(author.posts, isEmpty);
    });

    test('QueryRow.relations and model relations stay in sync', () async {
      final queryRows = await dataSource.context
          .query<Author>()
          .withRelation('posts')
          .where('id', 1)
          .rows();

      final queryRow = queryRows.first;
      final author = queryRow.model;

      // Both should have the same posts
      final queryRowPosts = queryRow.relationList<Post>('posts');
      final modelPosts = author.posts;

      expect(queryRowPosts.length, equals(modelPosts.length));
      expect(queryRowPosts.length, equals(2));

      // They should be the same list instance (identity)
      for (var i = 0; i < queryRowPosts.length; i++) {
        expect(identical(queryRowPosts[i], modelPosts[i]), isTrue);
      }
    });
  });
}
