import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/src/schema_state.dart';
import 'package:test/test.dart';

void main() {
  late OrmConnection connection;

  setUp(() {
    connection = OrmConnection(
      config: ConnectionConfig(name: 'postgres-state'),
      driver: InMemoryQueryExecutor(),
      registry: ModelRegistry(),
    );
  });

  tearDown(() async {
    await connection.driver.close();
  });

  test('provider exposes schema state with default connection args', () {
    final provider = PostgresSchemaStateProvider(
      DatabaseConfig(
        driver: 'postgres',
        options: {'database': 'orm_test', 'username': 'postgres'},
      ),
    );

    final state = provider.createSchemaState(
      connection: connection,
      ledgerTable: 'orm_migrations',
    );

    expect(state, isNotNull);
    expect(state!.canDump, isTrue);
    expect(state.canLoad, isTrue);
  });
}
