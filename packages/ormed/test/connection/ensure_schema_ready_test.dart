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
