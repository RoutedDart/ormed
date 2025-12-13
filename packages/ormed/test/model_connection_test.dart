import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';


void main() {
  group('ModelConnection', () {
    late ModelRegistry registry;
    late InMemoryQueryExecutor executor;
    late QueryContext context;

    setUp(() {
      registry = ModelRegistry()..registerGeneratedModels();
      executor = InMemoryQueryExecutor();
      executor.register(CommentOrmDefinition.definition, [
        Comment(id: 1, body: 'Hydrated')..deletedAt = null,
      ]);
      context = QueryContext(registry: registry, driver: executor);
    });

    test('attaches connection resolver when hydrating models', () async {
      final model = await context.query<Comment>().firstOrFail();
      expect(model.connection, same(executor));
      expect(model.connectionResolver, same(context));
    });
  });
}
