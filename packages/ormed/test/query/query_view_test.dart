import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import 'package:driver_tests/driver_tests.dart';

void main() {
  group('queryFromDefinition', () {
    late ModelRegistry registry;
    late InMemoryQueryExecutor driver;
    late QueryContext context;

    setUp(() {
      registry = ModelRegistry()..registerAll([AuthorOrmDefinition.definition]);
      driver = InMemoryQueryExecutor()
        ..register(AuthorOrmDefinition.definition, const [
          Author(id: 1, name: 'Alice', active: true),
        ]);
      context = QueryContext(registry: registry, driver: driver);
    });

    test('overrides table and alias for existing definitions', () async {
      final query = context.queryFromDefinition(
        AuthorOrmDefinition.definition,
        table: 'author_view',
        alias: 'av',
      );
      final plan = query.debugPlan();
      expect(plan.definition.tableName, 'author_view');
      expect(plan.tableAlias, 'av');
    });

    test('OrmConnection helper wires through', () async {
      final connection = OrmConnection(
        config: ConnectionConfig(name: 'primary'),
        driver: driver,
        registry: registry,
      );
      final models = await connection
          .queryFromDefinition(AuthorOrmDefinition.definition, table: 'authors')
          .get();
      expect(models.map((m) => m.name), ['Alice']);
    });

    test('OrmConnection.queryAs reuses registered definition', () async {
      final connection = OrmConnection(
        config: ConnectionConfig(name: 'primary'),
        driver: driver,
        registry: registry,
      );

      final plan = connection
          .queryAs<Author>(table: 'author_view', alias: 'av')
          .debugPlan();

      expect(plan.definition.tableName, 'author_view');
      expect(plan.tableAlias, 'av');
    });

    test('ModelRegistry alias reuses metadata for views', () async {
      final alias = registry.registerAlias(
        AuthorOrmDefinition.definition,
        aliasModelName: 'AuthorView',
        tableName: 'author_view',
      );

      final plan = context.queryFromDefinition(alias).debugPlan();
      expect(plan.definition.tableName, 'author_view');

      final fetched = registry.expectByName('AuthorView');
      expect(fetched.tableName, 'author_view');
    });
  });
}
