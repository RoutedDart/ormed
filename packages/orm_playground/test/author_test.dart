import 'package:ormed/ormed.dart';
import 'package:driver_tests/driver_tests.dart'
    hide Author, AuthorOrmDefinition, Authors;
import 'package:orm_playground/src/models/author.dart';
import 'package:test/test.dart';

void main() {
  group('Author Static Accessors', () {
    late InMemoryQueryExecutor driver;
    late ModelRegistry registry;
    late QueryContext context;

    setUp(() {
      driver = InMemoryQueryExecutor();
      registry = ModelRegistry()..register(AuthorOrmDefinition.definition);
      context = QueryContext(registry: registry, driver: driver);

      Model.bindConnectionResolver(
        resolveConnection: (name) => context,
        defaultConnection: 'default',
      );

      // Register some data
      driver.register(AuthorOrmDefinition.definition, [
        Author(id: 1, name: 'Test Author'),
      ]);
    });

    test('Authors.query() returns a Query<Author>', () {
      final q = Authors.query();
      expect(q, isA<Query<Author>>());
    });

    test('Authors.find() returns a Future<Author?>', () async {
      final author = await Authors.find(1);
      expect(author, isNotNull);
      expect(author!.name, 'Test Author');
    });

    test('Authors.all() returns a Future<List<Author>>', () async {
      final authors = await Authors.all();
      expect(authors, isNotEmpty);
      expect(authors.first.name, 'Test Author');
    });
  });
}
