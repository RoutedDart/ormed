import 'package:test/test.dart';

import '../../models/models.dart';
import '../../harness/driver_test_harness.dart';
import '../../config.dart';

void runJoinClausesTests(
  DriverHarnessBuilder<DriverTestHarness> createHarness,
  DriverTestConfig config,
) {
  if (!config.supportsJoins) {
    return;
  }

  group('Join Clauses tests', () {
    late DriverTestHarness harness;

    setUp(() async {
      harness = await createHarness();
    });

    tearDown(() async => harness.dispose());

    test('join', () async {
      await harness.seedAuthors([Author(id: 1, name: 'author1')]);
      await harness.seedPosts([
        Post(id: 1, authorId: 1, title: 'post1', publishedAt: DateTime.now()),
      ]);

      final results = await harness.context
          .query<Post>()
          .join('authors', 'authors.id', '=', 'posts.author_id')
          .get();

      expect(results, hasLength(1));
    });

    test('leftJoin', () async {
      await harness.seedAuthors([Author(id: 1, name: 'author1')]);
      await harness.seedPosts([
        Post(id: 1, authorId: 1, title: 'post1', publishedAt: DateTime.now()),
        Post(id: 2, authorId: 2, title: 'post2', publishedAt: DateTime.now()),
      ]);

      final results = await harness.context
          .query<Post>()
          .leftJoin('authors', 'authors.id', '=', 'posts.author_id')
          .get();

      expect(results, hasLength(2));
    });

    test('rightJoin', () async {
      if (!config.supportsRightJoin) {
        return;
      }

      await harness.seedAuthors([
        Author(id: 1, name: 'author1'),
        Author(id: 2, name: 'author2'),
      ]);
      await harness.seedPosts([
        Post(id: 1, authorId: 1, title: 'post1', publishedAt: DateTime.now()),
        Post(id: 2, authorId: 2, title: 'post2', publishedAt: DateTime.now()),
      ]);

      final results = await harness.context
          .query<Author>()
          .rightJoin('posts', 'posts.author_id', '=', 'authors.id')
          .get();

      expect(results, hasLength(2));
    });

    test('crossJoin', () async {
      await harness.seedAuthors([Author(id: 1, name: 'author1')]);
      await harness.seedTags([Tag(id: 1, label: 'tag1')]);

      final results = await harness.context
          .query<Author>()
          .crossJoin('tags')
          .get();
      expect(results, hasLength(1));
    });

    test('joinRelation', () async {
      await harness.seedAuthors([Author(id: 1, name: 'author1')]);
      await harness.seedPosts([
        Post(id: 1, authorId: 1, title: 'post1', publishedAt: DateTime.now()),
      ]);

      final results = await harness.context
          .query<Author>()
          .joinRelation('posts')
          .get();

      expect(results, hasLength(1));
    });
  });
}
