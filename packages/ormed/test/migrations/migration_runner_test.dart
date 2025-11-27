import 'package:ormed/migrations.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  group('MigrationRunner', () {
    late FakeSchemaDriver schemaDriver;
    late InMemoryLedger ledger;
    late List<MigrationDescriptor> descriptors;

    setUp(() {
      schemaDriver = FakeSchemaDriver();
      ledger = InMemoryLedger();
      descriptors = [
        _descriptor('2025_01_01_000000_create_users'),
        _descriptor('2025_01_02_000000_add_posts'),
      ];
    });

    test('applies pending migrations in order', () async {
      final runner = MigrationRunner(
        schemaDriver: schemaDriver,
        ledger: ledger,
        migrations: descriptors,
      );

      final report = await runner.applyAll();
      expect(report.actions, hasLength(2));
      expect(report.actions.first.descriptor.id, descriptors.first.id);
      expect(schemaDriver.appliedPlans, ['up:create_users', 'up:add_posts']);

      final status = await runner.status();
      expect(status.where((s) => s.applied).length, 2);
    });

    test('skips already applied migrations and validates checksum', () async {
      ledger.records.add(
        AppliedMigrationRecord(
          id: descriptors.first.id,
          checksum: descriptors.first.checksum,
          appliedAt: DateTime.utc(2025, 1, 1),
          batch: 1,
        ),
      );

      final runner = MigrationRunner(
        schemaDriver: schemaDriver,
        ledger: ledger,
        migrations: descriptors,
      );

      final report = await runner.applyAll();
      expect(report.actions, hasLength(1));
      expect(report.actions.single.descriptor.id, descriptors.last.id);
    });

    test('throws when ledger checksum differs', () async {
      ledger.records.add(
        AppliedMigrationRecord(
          id: descriptors.first.id,
          checksum: 'invalid',
          appliedAt: DateTime.utc(2025, 1, 1),
          batch: 1,
        ),
      );

      final runner = MigrationRunner(
        schemaDriver: schemaDriver,
        ledger: ledger,
        migrations: descriptors,
      );

      await expectLater(() => runner.applyAll(), throwsA(isA<StateError>()));
    });

    test('rolls back most recent migrations', () async {
      final runner = MigrationRunner(
        schemaDriver: schemaDriver,
        ledger: ledger,
        migrations: descriptors,
      );
      await runner.applyAll();
      final report = await runner.rollback(steps: 1);

      expect(report.actions, hasLength(1));
      expect(report.actions.single.descriptor.id, descriptors.last.id);
      expect(schemaDriver.appliedPlans.last, 'down:add_posts');
    });
  });
}

MigrationDescriptor _descriptor(String id) {
  final migrationId = MigrationId.parse(id);
  return MigrationDescriptor.fromMigration(
    id: migrationId,
    migration: _TestMigration(slug: migrationId.slug),
  );
}

class _TestMigration extends Migration {
  const _TestMigration({required this.slug});

  final String slug;

  @override
  void down(SchemaBuilder schema) {
    schema.raw('down:$slug');
  }

  @override
  void up(SchemaBuilder schema) {
    schema.raw('up:$slug');
  }
}

class FakeSchemaDriver implements SchemaDriver {
  final List<String> appliedPlans = [];

  @override
  Future<void> applySchemaPlan(SchemaPlan plan) async {
    appliedPlans.add(plan.mutations.first.sql ?? plan.description ?? 'unknown');
  }

  @override
  SchemaPreview describeSchemaPlan(SchemaPlan plan) => SchemaPreview(const []);

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
  final List<AppliedMigrationRecord> records = [];

  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<List<AppliedMigrationRecord>> readApplied() async =>
      List.unmodifiable(records);

  @override
  Future<void> logApplied(
    MigrationDescriptor descriptor,
    DateTime appliedAt, {
    required int batch,
  }) async {
    records.add(
      AppliedMigrationRecord(
        id: descriptor.id,
        checksum: descriptor.checksum,
        appliedAt: appliedAt,
        batch: batch,
      ),
    );
  }

  @override
  Future<void> remove(MigrationId id) async {
    records.removeWhere((record) => record.id == id);
  }

  @override
  Future<int> nextBatchNumber() async {
    if (records.isEmpty) return 1;
    final highest = records.fold<int>(0, (previous, record) {
      return record.batch > previous ? record.batch : previous;
    });
    return highest + 1;
  }
}
