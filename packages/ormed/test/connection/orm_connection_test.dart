import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  ModelRegistry registry = buildOrmRegistry();
  group('OrmConnection', () {
    late InMemoryQueryExecutor driver;
    late OrmConnection connection;

    setUp(() {
      driver = InMemoryQueryExecutor()
        ..register(AuthorOrmDefinition.definition, const [
          Author(id: 1, name: 'Alice', active: true),
        ]);
      connection = OrmConnection(
        config: ConnectionConfig(
          name: 'primary',
          database: 'app_db',
          tablePrefix: 'tenant_',
          options: const {'env': 'test'},
        ),
        driver: driver,
        registry: registry,
      );
    });

    test('exposes metadata and query helpers', () async {
      final author = await connection.query<Author>().first();
      expect(author?.name, 'Alice');

      expect(connection.name, 'primary');
      expect(connection.database, 'app_db');
      expect(connection.tablePrefix, 'tenant_');
      expect(connection.options['env'], 'test');

      final repo = connection.repository<Author>();
      expect(repo.definition, AuthorOrmDefinition.definition);
    });

    test('hydrates models with attached connection resolver', () async {
      final author = await connection.query<Author>().firstOrFail();
      expect(author, isA<ModelConnection>());
      final model = author as ModelConnection;
      expect(model.hasConnection, isTrue);
      expect(model.connectionResolver, same(connection.context));
      expect(model.connection, same(connection.driver));
    });

    test('pretend toggles flag for duration of callback', () async {
      expect(connection.pretending, isFalse);
      final statements = await connection.pretend(() async {
        expect(connection.pretending, isTrue);
      });
      expect(connection.pretending, isFalse);
      expect(statements, isEmpty);
    });

    test('runs query hooks in registration order', () async {
      final order = <String>[];
      connection.onBeforeQuery((_) => order.add('a'));
      connection.onBeforeQuery((_) => order.add('b'));
      await connection.query<Author>().firstOrNull();
      expect(order, ['a', 'b']);
    });

    test('query logging respects includeParameters flag', () async {
      connection.enableQueryLog(includeParameters: false);
      QueryLogEntry? callbackEntry;
      connection.onQueryLogged((entry) => callbackEntry = entry);

      await connection.query<Author>().whereEquals('id', 1).firstOrNull();

      expect(connection.queryLog, hasLength(1));
      final stored = connection.queryLog.single;
      expect(stored.parameters, isEmpty);
      expect(stored.parameterSets, isEmpty);
      expect(callbackEntry, isNotNull);
      expect(callbackEntry!.sql, isNotEmpty);
    });

    test('pretend mode short-circuits driver execution', () async {
      final countingDriver = _CountingInMemoryDriver()
        ..register(AuthorOrmDefinition.definition, const [
          Author(id: 1, name: 'Alice', active: true),
        ]);
      connection = OrmConnection(
        config: ConnectionConfig(name: 'primary'),
        driver: countingDriver,
        registry: registry,
      );

      final captured = await connection.pretend(() async {
        await connection.query<Author>().firstOrNull();
        await connection.repository<Author>().insert(
          const Author(id: 2, name: 'Bob', active: true),
        );
      });

      expect(countingDriver.selectCount, 0);
      expect(countingDriver.mutationCount, 0);
      expect(captured.length, equals(2));
      expect(connection.queryLog, isEmpty);
    });

    test('beforeExecuting hooks expose SQL previews', () async {
      final statements = <ExecutingStatement>[];
      final dispose = connection.beforeExecuting(statements.add);
      await connection.query<Author>().whereEquals('id', 1).firstOrNull();
      await connection.repository<Author>().insert(
        const Author(id: 3, name: 'Charlie', active: true),
      );
      dispose();
      expect(statements, hasLength(2));
      expect(statements.first.type, ExecutingStatementType.query);
      expect(statements.first.preview.sql, isNotEmpty);
      expect(statements.last.type, ExecutingStatementType.mutation);
      expect(statements.last.preview.sql, isNotEmpty);
    });

    test('long query handler triggers for slow drivers', () async {
      final slowDriver =
          _DelayingInMemoryDriver(delay: const Duration(milliseconds: 25))
            ..register(AuthorOrmDefinition.definition, const [
              Author(id: 1, name: 'Alice', active: true),
            ]);
      connection = OrmConnection(
        config: ConnectionConfig(name: 'primary'),
        driver: slowDriver,
        registry: registry,
      );

      LongRunningQueryEvent? longEvent;
      final dispose = connection.whenQueryingForLongerThan(
        const Duration(milliseconds: 5),
        (event) => longEvent = event,
      );

      await connection.query<Author>().firstOrNull();
      dispose();

      expect(longEvent, isNotNull);
      expect(
        longEvent!.duration,
        greaterThanOrEqualTo(const Duration(milliseconds: 5)),
      );
      expect(longEvent!.statement.type, ExecutingStatementType.query);
    });

    test('default schema and alias strategy apply to ad-hoc tables', () {
      connection = OrmConnection(
        config: ConnectionConfig(
          name: 'primary',
          defaultSchema: 'analytics',
          tableAliasStrategy: TableAliasStrategy.incremental,
        ),
        driver: driver,
        registry: registry,
      );

      final planA = connection.table('events').debugPlan();
      final planB = connection.table('events').debugPlan();

      expect(planA.definition.schema, 'analytics');
      expect(planA.tableAlias, 't0');
      expect(planB.tableAlias, 't1');

      final overridden = connection.table('events', as: 'custom').debugPlan();
      expect(overridden.tableAlias, 'custom');
    });
  });
}

class _CountingInMemoryDriver extends InMemoryQueryExecutor {
  int selectCount = 0;
  int mutationCount = 0;

  @override
  Future<List<Map<String, Object?>>> execute(QueryPlan plan) async {
    selectCount++;
    return super.execute(plan);
  }

  @override
  Future<MutationResult> runMutation(MutationPlan plan) async {
    mutationCount++;
    return super.runMutation(plan);
  }
}

class _DelayingInMemoryDriver extends InMemoryQueryExecutor {
  _DelayingInMemoryDriver({required this.delay});

  final Duration delay;

  @override
  Future<List<Map<String, Object?>>> execute(QueryPlan plan) async {
    await Future.delayed(delay);
    return super.execute(plan);
  }

  @override
  Future<MutationResult> runMutation(MutationPlan plan) async {
    await Future.delayed(delay);
    return super.runMutation(plan);
  }
}
