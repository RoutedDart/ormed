import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models/models.dart';

void runScopeTests() {
  ormedGroup('Query Scope Operations', (dataSource) {
    test('generated local scope extensions work for ScopedUser', () async {
      await dataSource.repo<ScopedUser>().insertMany([
        const ScopedUser(
          id: 1,
          email: 'a@example.com',
          active: true,
          name: 'A',
        ),
        const ScopedUser(id: 2, email: 'b@test.com', active: true, name: 'B'),
        const ScopedUser(
          id: 3,
          email: 'c@example.com',
          active: false,
          name: 'C',
        ),
      ]);

      final example = await dataSource.context
          .query<$ScopedUser>()
          .withoutGlobalScope('activeOnly')
          .emailDomain('example.com')
          .get();

      expect(example, hasLength(2));
      expect(example.every((u) => u.email.endsWith('@example.com')), isTrue);

      final named = await dataSource.context
          .query<$ScopedUser>()
          .withoutGlobalScope('activeOnly')
          .named(name: 'B')
          .get();

      expect(named, hasLength(1));
      expect(named.single.name, 'B');
    });

    test('generated global scope applies automatically', () async {
      await dataSource.repo<ScopedUser>().insertMany([
        const ScopedUser(
          id: 1,
          email: 'a@example.com',
          active: true,
          name: 'A',
        ),
        const ScopedUser(
          id: 2,
          email: 'b@example.com',
          active: false,
          name: 'B',
        ),
      ]);

      // activeOnly is @OrmScope(global: true), so inactive rows are filtered
      final scoped = await dataSource.context.query<$ScopedUser>().get();
      expect(scoped, hasLength(1));
      expect(scoped.single.active, isTrue);

      final withInactive = await dataSource.context
          .query<$ScopedUser>()
          .withoutGlobalScope('activeOnly')
          .get();

      expect(withInactive, hasLength(2));
    });

    test('withoutGlobalScope - removes specific scope', () async {
      final registry = dataSource.context.scopeRegistry;

      // Register a test global scope
      registry.addGlobalScope<Post>('published', (query) {
        return query.whereNotNull('publishedAt');
      });

      await dataSource.repo<Post>().insertMany([
        Post(id: 1, authorId: 1, title: 'Active', publishedAt: DateTime.now()),
        Post(
          id: 2,
          authorId: 1,
          title: 'Draft',
          publishedAt: DateTime.now().subtract(const Duration(days: 365)),
        ),
      ]);

      // First query with scope applied
      final withScope = await dataSource.context.query<Post>().get();

      // Query with scope removed
      final withoutScope = await dataSource.context
          .query<Post>()
          .withoutGlobalScope('published')
          .get();

      expect(withoutScope.length, greaterThanOrEqualTo(withScope.length));
    });

    test('scope - applies named local scope', () async {
      final registry = dataSource.context.scopeRegistry;

      // Register a local scope
      registry.addLocalScope<Post>('byAuthor', (query, args) {
        final authorId = args.isNotEmpty ? args[0] as int : 1;
        return query.whereEquals('authorId', authorId);
      });

      await dataSource.repo<Author>().insertMany([
        Author(id: 1, name: 'Author 1'),
        Author(id: 2, name: 'Author 2'),
      ]);

      await dataSource.repo<Post>().insertMany([
        Post(id: 1, authorId: 1, title: 'Post 1', publishedAt: DateTime.now()),
        Post(id: 2, authorId: 2, title: 'Post 2', publishedAt: DateTime.now()),
        Post(id: 3, authorId: 1, title: 'Post 3', publishedAt: DateTime.now()),
      ]);

      final author1Posts = await dataSource.context.query<Post>().scope(
        'byAuthor',
        [1],
      ).get();

      expect(author1Posts, hasLength(2));
      expect(author1Posts.every((p) => p.authorId == 1), isTrue);
    });

    test('macro - applies query macro', () async {
      final registry = dataSource.context.scopeRegistry;

      // Register a query macro
      registry.addMacro('recentDays', (query, args) {
        final days = args.isNotEmpty ? args[0] as int : 7;
        final cutoff = DateTime.now().subtract(Duration(days: days));
        return query.where(
          'publishedAt',
          cutoff,
          PredicateOperator.greaterThan,
        );
      });

      final now = DateTime.now();
      await dataSource.repo<Post>().insertMany([
        Post(id: 1, authorId: 1, title: 'Recent', publishedAt: now),
        Post(
          id: 2,
          authorId: 1,
          title: 'Old',
          publishedAt: now.subtract(const Duration(days: 10)),
        ),
      ]);

      final recent = await dataSource.context.query<Post>().macro(
        'recentDays',
        [7],
      ).get();

      expect(recent.length, greaterThanOrEqualTo(1));
    });

    test('withTrashed - includes soft deleted records', () async {
      // Use Comment model which has soft deletes enabled
      await dataSource.repo<Comment>().insertMany([
        const Comment(id: 1, body: 'Active comment'),
        const Comment(id: 2, body: 'Deleted comment'),
      ]);

      // Soft delete one comment
      await dataSource.context.query<Comment>().whereEquals('id', 2).update({
        'deleted_at': DateTime.now(),
      });

      // Normal query shouldn't find deleted (soft delete scope active)
      final active = await dataSource.context.query<Comment>().get();

      // With trashed should include deleted using withoutGlobalScope
      final withDeleted = await dataSource.context
          .query<Comment>()
          .withoutGlobalScope(ScopeRegistry.softDeleteScopeIdentifier)
          .get();

      expect(withDeleted.length, greaterThanOrEqualTo(active.length));
      expect(withDeleted.length, equals(2)); // Should find both
      expect(active.length, equals(1)); // Should only find the active one
    });

    test('chaining scopes and macros', () async {
      final registry = dataSource.context.scopeRegistry;

      registry.addLocalScope<Post>('activeOnly', (query, args) {
        return query.whereNotNull('publishedAt');
      });

      registry.addMacro('limitResults', (query, args) {
        final limit = args.isNotEmpty ? args[0] as int : 10;
        return query.limit(limit);
      });

      await dataSource.repo<Post>().insertMany([
        Post(id: 1, authorId: 1, title: 'Post 1', publishedAt: DateTime.now()),
        Post(id: 2, authorId: 1, title: 'Post 2', publishedAt: DateTime.now()),
        Post(id: 3, authorId: 1, title: 'Post 3', publishedAt: DateTime.now()),
      ]);

      final results = await dataSource.context
          .query<Post>()
          .scope('activeOnly')
          .macro('limitResults', [2])
          .get();

      expect(results, hasLength(2)); // activeOnly scope with limit of 2
    });
  });
}
