import 'package:ormed/ormed.dart';
import 'package:ormed_mysql/src/schema_state.dart';
import 'package:test/test.dart';

void main() {
  late OrmConnection connection;

  setUp(() {
    connection = OrmConnection(
      config: ConnectionConfig(name: 'mysql-state'),
      driver: InMemoryQueryExecutor(),
      registry: ModelRegistry(),
    );
  });

  tearDown(() async {
    await connection.driver.close();
  });

  test('provider returns schema state with required options', () {
    final provider = MySqlSchemaStateProvider(
      DatabaseConfig(
        driver: 'mysql',
        options: {'database': 'orm_test', 'username': 'root'},
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
