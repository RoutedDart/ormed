import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  test('ensureLedgerInitialized completes without error', () async {
    final connection = OrmConnection(
      config: ConnectionConfig(name: 'testing'),
      driver: InMemoryQueryExecutor(),
      registry: ModelRegistry(),
    );

    await connection.ensureLedgerInitialized(tableName: 'orm_migrations');
  });

  test('ensureSchemaReady returns empty report when no migrations', () async {
    final schemaDriver = FakeSchemaDriver();
    final ledger = InMemoryLedger();
    final runner = MigrationRunner(
      schemaDriver: schemaDriver,
      ledger: ledger,
      migrations: const [],
    );

    final connection = OrmConnection(
      config: ConnectionConfig(name: 'testing'),
      driver: InMemoryQueryExecutor(),
      registry: ModelRegistry(),
    );

    final report = await connection.ensureSchemaReady(
      runner: runner,
      applyPendingMigrations: true,
    );

    expect(report.actions, isEmpty);
  });
}

class FakeSchemaDriver implements SchemaDriver {
  @override
  Future<void> applySchemaPlan(SchemaPlan plan) async {}

  @override
  SchemaPreview describeSchemaPlan(SchemaPlan plan) => const SchemaPreview([]);

  @override
  Future<List<SchemaNamespace>> listSchemas() async => const [];

  @override
  Future<List<SchemaTable>> listTables({String? schema}) async => const [];

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

  @override
  Future<bool> createDatabase(String name, {Map<String, Object?>? options}) async => true;

  @override
  Future<bool> dropDatabase(String name) async => true;

  @override
  Future<bool> dropDatabaseIfExists(String name) async => true;

  @override
  Future<List<String>> listDatabases() async => const [];

  @override
  Future<bool> enableForeignKeyConstraints() async => true;

  @override
  Future<bool> disableForeignKeyConstraints() async => true;

  @override
  Future<T> withoutForeignKeyConstraints<T>(Future<T> Function() callback) async {
    return await callback();
  }

  @override
  Future<void> dropAllTables({String? schema}) async {}

  @override
  Future<bool> hasTable(String table, {String? schema}) async => false;

  @override
  Future<bool> hasView(String view, {String? schema}) async => false;

  @override
  Future<bool> hasColumn(String table, String column, {String? schema}) async => false;

  @override
  Future<bool> hasColumns(String table, List<String> columns, {String? schema}) async => false;

  @override
  Future<bool> hasIndex(String table, String index, {String? schema, String? type}) async => false;
}

class InMemoryLedger implements MigrationLedger {
  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<List<AppliedMigrationRecord>> readApplied() async => const [];

  @override
  Future<void> logApplied(
    MigrationDescriptor descriptor,
    DateTime appliedAt, {
    required int batch,
  }) async {}

  @override
  Future<void> remove(MigrationId id) async {}

  @override
  Future<int> nextBatchNumber() async => 1;
}
