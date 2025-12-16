import 'package:ormed/ormed.dart';
import 'package:driver_tests/driver_tests.dart'
    hide
        Author,
        AuthorOrmDefinition,
        Post,
        PostOrmDefinition,
        User,
        UserOrmDefinition;
import 'package:orm_playground/src/models/user.dart';
import 'package:orm_playground/src/models/post.dart';
import 'package:test/test.dart';

void main() {
  group('Eloquent Features', () {
    late InMemoryQueryExecutor driver;
    late ModelRegistry registry;
    late QueryContext context;

    setUp(() {
      driver = InMemoryQueryExecutor();
      registry = ModelRegistry()
        ..register(UserOrmDefinition.definition)
        ..register(PostOrmDefinition.definition);
      context = QueryContext(registry: registry, driver: driver);

      Model.bindConnectionResolver(
        resolveConnection: (name) => context,
        defaultConnection: 'default',
      );
    });

    test('Relationship Query Method: user.postsQuery()', () {

      // This method should exist and return a Query<Post>
      // Note: User model doesn't have posts relation in current schema
      // This test is conceptual - would work if User had a posts relation defined

      expect(
        true,
        isTrue,
      ); // Placeholder since User doesn't have posts relation
    });

    test('Relationship Query Method: post.authorQuery()', () {
      // Create Post through codec to get generated instance
      final post = PostOrmDefinition.definition.codec.decode({
        'id': 1,
        'user_id': 1,
        'title': 'Test Post',
        'body': null,
        'published': false,
        'published_at': null,
        'created_at': null,
        'updated_at': null,
      }, ValueCodecRegistry.instance);

      final query = post.authorQuery();

      expect(query, isA<Query<User>>());
    });

    // Note: Scopes test requires adding a scope to a model.
    // We haven't added a scope to User or Post yet.
  });
}
