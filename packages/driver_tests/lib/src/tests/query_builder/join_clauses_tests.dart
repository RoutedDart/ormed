import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models/models.dart';

import '../../config.dart';

void runJoinClausesTests(
  DataSource dataSource,
  DriverTestConfig config,
) {
  if (!config.supportsJoins) {
    return;
  }

  group('Join Clauses tests', () {
    

    setUp(() async {
      
    });

    

    test('join', () async {
      await dataSource.repo<Author>().insertMany([Author(id: 1, name: 'author1')]);
      await dataSource.repo<Post>().insertMany([
        Post(id: 1, authorId: 1, title: 'post1', publishedAt: DateTime.now()),
      ]);

      final results = await dataSource.context
          .query<Post>()
          .join('authors', 'authors.id', '=', 'posts.author_id')
          .get();

      expect(results, hasLength(1));
    });

    test('leftJoin', () async {
      await dataSource.repo<Author>().insertMany([Author(id: 1, name: 'author1')]);
      await dataSource.repo<Post>().insertMany([
        Post(id: 1, authorId: 1, title: 'post1', publishedAt: DateTime.now()),
        Post(id: 2, authorId: 2, title: 'post2', publishedAt: DateTime.now()),
      ]);

      final results = await dataSource.context
          .query<Post>()
          .leftJoin('authors', 'authors.id', '=', 'posts.author_id')
          .get();

      expect(results, hasLength(2));
    });

    test('rightJoin', () async {
      if (!config.supportsRightJoin) {
        return;
      }

      await dataSource.repo<Author>().insertMany([
        Author(id: 1, name: 'author1'),
        Author(id: 2, name: 'author2'),
      ]);
      await dataSource.repo<Post>().insertMany([
        Post(id: 1, authorId: 1, title: 'post1', publishedAt: DateTime.now()),
        Post(id: 2, authorId: 2, title: 'post2', publishedAt: DateTime.now()),
      ]);

      final results = await dataSource.context
          .query<Author>()
          .rightJoin('posts', 'posts.author_id', '=', 'authors.id')
          .get();

      expect(results, hasLength(2));
    });

    test('crossJoin', () async {
      await dataSource.repo<Author>().insertMany([Author(id: 1, name: 'author1')]);
      await dataSource.repo<Tag>().insertMany([Tag(id: 1, label: 'tag1')]);

      final results = await dataSource.context
          .query<Author>()
          .crossJoin('tags')
          .get();
      expect(results, hasLength(1));
    });

    test('joinRelation', () async {
      await dataSource.repo<Author>().insertMany([Author(id: 1, name: 'author1')]);
      await dataSource.repo<Post>().insertMany([
        Post(id: 1, authorId: 1, title: 'post1', publishedAt: DateTime.now()),
      ]);

      final results = await dataSource.context
          .query<Author>()
          .joinRelation('posts')
          .get();

      expect(results, hasLength(1));
    });
  });
}
