import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  group('SqlMigrationLedger', () {
    test('falls back to raw SQL when schema driver is unavailable', () async {
      final driver = _FakeDriverAdapter(name: 'mysql');
      final ledger = SqlMigrationLedger(driver, tableName: 'orm_migrations');

      await ledger.ensureInitialized();

      expect(
        driver.executedSql.single.sql,
        contains('CREATE TABLE IF NOT EXISTS `orm_migrations`'),
      );
    });

    test('creates ledger table via schema driver when supported', () async {
      final driver = _SchemaAwareFakeDriver(name: 'sqlite');
      final ledger = SqlMigrationLedger(driver, tableName: 'orm_migrations');

      await ledger.ensureInitialized();

      expect(driver.appliedPlans, hasLength(1));
      final plan = driver.appliedPlans.single;
      expect(plan.mutations, hasLength(1));
      final mutation = plan.mutations.single;
      expect(mutation.operation, SchemaMutationOperation.createTable);
      final blueprint = mutation.blueprint!;
      expect(blueprint.table, 'orm_migrations');
      final columnNames = blueprint.columns.map((c) => c.name).toList();
      expect(columnNames, containsAll(['id', 'checksum', 'applied_at']));
      final idColumn = blueprint.columns
          .firstWhere((column) => column.name == 'id')
          .definition!;
      expect(idColumn.primaryKey, isTrue);

      await ledger.ensureInitialized();
      expect(driver.appliedPlans, hasLength(1));
    });

    test('logs, reads, and removes entries via ORM', () async {
      final driver = InMemoryQueryExecutor();
      final ledger = SqlMigrationLedger(driver, tableName: 'orm_migrations');

      await ledger.ensureInitialized();
      final descriptor = _descriptor('2024_01_01_000000_create_users');
      final appliedAt = DateTime.utc(2024, 1, 1);

      await ledger.logApplied(descriptor, appliedAt, batch: 1);
      final applied = await ledger.readApplied();

      expect(applied, hasLength(1));
      expect(applied.single.id, descriptor.id);
      expect(applied.single.checksum, descriptor.checksum);
      expect(applied.single.appliedAt, appliedAt);

      await ledger.remove(descriptor.id);
      final remaining = await ledger.readApplied();
      expect(remaining, isEmpty);
    });

    test('managed constructor routes through connection manager', () async {
      final manager = ConnectionManager();
      var invocations = 0;

      manager.register(
        'cli',
        ConnectionConfig(name: 'cli'),
        (_) {
          invocations++;
          final driver = _FakeDriverAdapter(name: 'sqlite');
          return OrmConnection(
            config: ConnectionConfig(name: 'cli'),
            driver: driver,
            registry: ModelRegistry(),
          );
        },
        singleton: false,
        onRelease: (connection) => connection.driver.close(),
      );

      final ledger = SqlMigrationLedger.managed(
        connectionName: 'cli',
        manager: manager,
        tableName: 'migrations',
      );

      await ledger.ensureInitialized();
      await ledger.readApplied();
      await ledger.logApplied(
        _descriptor('2024_01_01_000000_create_users'),
        DateTime.utc(2024, 1, 1),
        batch: 1,
      );

      expect(invocations, 3);
    });
  });
}

MigrationDescriptor _descriptor(String id) {
  final migrationId = MigrationId.parse(id);
  return MigrationDescriptor.fromMigration(
    id: migrationId,
    migration: _TestMigration(),
  );
}

class _TestMigration extends Migration {
  @override
  void down(SchemaBuilder schema) {}

  @override
  void up(SchemaBuilder schema) {}
}

class _FakeDriverAdapter extends DriverAdapter {
  _FakeDriverAdapter({required String name})
    : _metadata = DriverMetadata(name: name);

  final DriverMetadata _metadata;
  final ValueCodecRegistry _codecs = ValueCodecRegistry.standard();
  final List<_ExecutedSql> executedSql = [];

  @override
  DriverMetadata get metadata => _metadata;

  @override
  ValueCodecRegistry get codecs => _codecs;

  @override
  Future<void> close() async {}

  @override
  Future<void> executeRaw(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    executedSql.add(_ExecutedSql(sql, parameters));
  }

  @override
  Future<List<Map<String, Object?>>> queryRaw(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    executedSql.add(_ExecutedSql(sql, parameters));
    return const [];
  }

  @override
  Future<List<Map<String, Object?>>> execute(QueryPlan plan) =>
      Future.value(const []);

  @override
  Stream<Map<String, Object?>> stream(QueryPlan plan) =>
      const Stream<Map<String, Object?>>.empty();

  @override
  StatementPreview describeQuery(QueryPlan plan) =>
      const StatementPreview(payload: SqlStatementPayload(sql: ''));

  @override
  Future<MutationResult> runMutation(MutationPlan plan) async =>
      const MutationResult(affectedRows: 0);

  @override
  StatementPreview describeMutation(MutationPlan plan) =>
      const StatementPreview(payload: SqlStatementPayload(sql: ''));

  @override
  PlanCompiler get planCompiler => fallbackPlanCompiler();

  @override
  Future<R> transaction<R>(Future<R> Function() action) => action();

  @override
  Future<int?> threadCount() async => null;
}

class _ExecutedSql {
  const _ExecutedSql(this.sql, this.parameters);

  final String sql;
  final List<Object?> parameters;
}

class _SchemaAwareFakeDriver extends _FakeDriverAdapter
    implements SchemaDriver {
  _SchemaAwareFakeDriver({required super.name});

  final List<SchemaPlan> appliedPlans = [];
  final Set<String> _tables = {};

  @override
  Future<void> applySchemaPlan(SchemaPlan plan) async {
    appliedPlans.add(plan);
    for (final mutation in plan.mutations) {
      if (mutation.operation == SchemaMutationOperation.createTable &&
          mutation.table != null) {
        _tables.add(mutation.table!);
      } else if (mutation.operation == SchemaMutationOperation.dropTable &&
          mutation.dropOptions != null) {
        _tables.remove(mutation.dropOptions!.table);
      }
    }
  }

  @override
  SchemaPreview describeSchemaPlan(SchemaPlan plan) => const SchemaPreview([]);

  @override
  Future<List<SchemaNamespace>> listSchemas() async => const [];

  @override
  Future<List<SchemaTable>> listTables({String? schema}) async =>
      _tables.map((name) => SchemaTable(name: name, schema: null)).toList();

  @override
  Future<List<SchemaView>> listViews({String? schema}) async => const [];

  @override
  Future<List<SchemaColumn>> listColumns(
    String table, {
    String? schema,
  }) async => const [];

  @override
  Future<List<SchemaIndex>> listIndexes(String table, {String? schema}) async =>
      const [];

  @override
  Future<List<SchemaForeignKey>> listForeignKeys(
    String table, {
    String? schema,
  }) async => const [];
}
