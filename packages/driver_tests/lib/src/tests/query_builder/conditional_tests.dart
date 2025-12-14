import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models/models.dart';

void runConditionalTests() {
  ormedGroup('Conditional Query Operations', (dataSource) {
    test('when - applies callback when condition is true', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'alice@example.com', active: true),
        User(id: 2, email: 'bob@example.com', active: false),
        User(id: 3, email: 'charlie@example.com', active: true),
      ]);

      final searchActive = true;
      final users = await dataSource.context
          .query<User>()
          .when(searchActive, (q) => q.where('active', true))
          .get();

      expect(users, hasLength(2));
      expect(users.map((u) => u.id), containsAll([1, 3]));
    });

    test('when - skips callback when condition is false', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'alice@example.com', active: true),
        User(id: 2, email: 'bob@example.com', active: false),
      ]);

      final searchActive = false;
      final users = await dataSource.context
          .query<User>()
          .when(searchActive, (q) => q.where('active', true))
          .get();

      // Should return all users since condition is false
      expect(users, hasLength(2));
    });

    test('when - chains multiple conditions', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'alice@test.com', active: true),
        User(id: 2, email: 'bob@example.com', active: false),
        User(id: 3, email: 'charlie@test.com', active: true),
      ]);

      final filterActive = true;
      final filterTestDomain = true;

      final users = await dataSource.context
          .query<User>()
          .when(filterActive, (q) => q.where('active', true))
          .when(filterTestDomain, (q) => q.whereLike('email', '%@test.com'))
          .get();

      expect(users, hasLength(2));
      expect(users.map((u) => u.id), containsAll([1, 3]));
    });

    test('unless applies callback when condition is false', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'alice@example.com', active: true),
        User(id: 2, email: 'bob@example.com', active: false),
        User(id: 3, email: 'charlie@example.com', active: true),
        User(id: 4, email: 'david@example.com', active: true),
      ]);

      final showAll = false;
      final users = await dataSource.context
          .query<User>()
          .unless(showAll, (q) => q.limit(2))
          .get();

      // Should be limited to 2 since showAll is false
      expect(users, hasLength(2));
    });

    test('unless - skips callback when condition is true', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'alice@example.com', active: true),
        User(id: 2, email: 'bob@example.com', active: false),
        User(id: 3, email: 'charlie@example.com', active: true),
      ]);

      final showAll = true;
      final users = await dataSource.context
          .query<User>()
          .unless(showAll, (q) => q.limit(1))
          .get();

      // Should return all users since showAll is true
      expect(users, hasLength(3));
    });

    test('tap invokes callback with built SQL', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'alice@example.com', active: true),
        User(id: 2, email: 'bob@example.com', active: false),
      ]);

      var tappedSql = '';
      var tapCallCount = 0;

      final users = await dataSource.context
          .query<User>()
          .where('active', true)
          .tap((q) {
            tappedSql = q.toSql().sql;
            tapCallCount++;
          })
          .get();

      expect(users, hasLength(1));
      expect(tapCallCount, 1);
      expect(tappedSql, contains('WHERE'));
      expect(tappedSql, contains('active'));
    });

    test('tap - can be chained multiple times', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'alice@example.com', active: true),
      ]);

      final tapMessages = <String>[];

      final users = await dataSource.context
          .query<User>()
          .tap((q) => tapMessages.add('Before where'))
          .where('active', true)
          .tap((q) => tapMessages.add('After where'))
          .orderBy('email')
          .tap((q) => tapMessages.add('After orderBy'))
          .get();

      expect(users, hasLength(1));
      expect(tapMessages, hasLength(3));
      expect(tapMessages, ['Before where', 'After where', 'After orderBy']);
    });

    test('combines when/unless flags in complex query', () async {
      await dataSource.repo<Post>().insertMany([
        Post(id: 1, authorId: 1, title: 'Post 1', publishedAt: DateTime.now()),
        Post(
          id: 2,
          authorId: 1,
          title: 'Post 2',
          publishedAt: DateTime(2000, 1, 1),
        ),
        Post(id: 3, authorId: 2, title: 'Post 3', publishedAt: DateTime.now()),
        Post(id: 4, authorId: 2, title: 'Post 4', publishedAt: DateTime.now()),
      ]);

      final filterPublished = true;
      final filterByAuthor = true;
      final limitResults = false;
      final authorId = 1;
      var debugSql = '';

      final posts = await dataSource.context
          .query<Post>()
          .when(filterPublished, (q) => q.whereNotNull('publishedAt'))
          .when(filterByAuthor, (q) => q.where('authorId', authorId))
          .unless(limitResults, (q) => q) // No limit
          .tap((q) => debugSql = q.toSql().sql)
          .get();

      // Should have 2 posts from author 1 (both have publishedAt set)
      expect(posts, hasLength(2));
      expect(posts.map((p) => p.authorId), everyElement(equals(1)));
      expect(debugSql, isNotEmpty);
    });

    test('when with null-aware condition', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'alice@example.com', active: true),
        User(id: 2, email: 'bob@example.com', active: false),
      ]);

      String? searchTerm;

      final users = await dataSource.context
          .query<User>()
          .when(
        ()=>searchTerm != null,
            (q) => q.whereLike('email', '%$searchTerm%'),
          )
          .get();

      // Should return all users since searchTerm is null
      expect(users, hasLength(2));

      // Now with a search term
      searchTerm = 'alice';
      final filteredUsers = await dataSource.context
          .query<User>()
          .when(
        ()=>searchTerm != null,
            (q) => q.whereLike('email', '%$searchTerm%'),
          )
          .get();

      expect(filteredUsers, hasLength(1));
      expect(filteredUsers.first.email, contains('alice'));
    });

    test('when accepts lazy condition function', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'alice@example.com', active: true),
        User(id: 2, email: 'bob@example.com', active: false),
        User(id: 3, email: 'charlie@example.com', active: true),
      ]);

      var conditionEvaluated = false;
      bool expensiveCheck() {
        conditionEvaluated = true;
        return true;
      }

      final users = await dataSource.context
          .query<User>()
          .when(() => expensiveCheck(), (q) => q.where('active', true))
          .get();

      expect(users, hasLength(2));
      expect(conditionEvaluated, isTrue);
    });

    test('when executes function predicate once', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'alice@example.com', active: true),
      ]);

      var functionCalled = 0;

      final users = await dataSource.context.query<User>().when(() {
        functionCalled++;
        return false;
      }, (q) => q.where('active', false)).get();

      expect(users, hasLength(1));
      expect(functionCalled, 1);
    });

    test('unless evaluates function predicate', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'alice@example.com', active: true),
        User(id: 2, email: 'bob@example.com', active: false),
        User(id: 3, email: 'charlie@example.com', active: true),
        User(id: 4, email: 'david@example.com', active: true),
      ]);

      var conditionEvaluated = false;
      bool checkShowAll() {
        conditionEvaluated = true;
        return false; // Don't show all
      }

      final users = await dataSource.context
          .query<User>()
          .unless(() => checkShowAll(), (q) => q.limit(2))
          .get();

      expect(users, hasLength(2));
      expect(conditionEvaluated, isTrue);
    });

    test('unless skips callback when boolean condition is true', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'alice@example.com', active: true),
        User(id: 2, email: 'bob@example.com', active: false),
      ]);

      final users = await dataSource.context
          .query<User>()
          .unless(() => true, (q) => q.where('active', true))
          .get();

      // Should return all users since condition is true
      expect(users, hasLength(2));
    });

    test('mixed boolean and function conditions', () async {
      await dataSource.repo<User>().insertMany([
        User(id: 1, email: 'alice@test.com', active: true),
        User(id: 2, email: 'bob@example.com', active: false),
        User(id: 3, email: 'charlie@test.com', active: true),
      ]);

      final filterActive = true;
      bool isDevelopmentMode() => true;

      final users = await dataSource.context
          .query<User>()
          .when(filterActive, (q) => q.where('active', true))
          .when(
            () => isDevelopmentMode(),
            (q) => q.whereLike('email', '%@test.com'),
          )
          .get();

      expect(users, hasLength(2));
      expect(users.map((u) => u.id), containsAll([1, 3]));
    });
  });
}
