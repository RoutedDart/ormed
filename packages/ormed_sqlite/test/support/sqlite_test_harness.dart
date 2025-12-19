import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

/// Reusable SQLite test harness mirroring the MySQL harness pattern.
///
/// Provides a preconfigured [DataSource], registered codecs/registry, and
/// an [adapterFactory] for setUpOrmed isolation.
class SqliteTestHarness {
  SqliteTestHarness({
    required this.adapter,
    required this.dataSource,
    required this.registry,
    required this.customCodecs,
    required this.enableNamedTimezones,
    required this.logging,
  });

  final SqliteDriverAdapter adapter;
  final DataSource dataSource;
  final ModelRegistry registry;
  final Map<String, ValueCodec<dynamic>> customCodecs;
  final bool enableNamedTimezones;
  final bool logging;

  /// Returns a fresh in-memory adapter for isolated databases.
  SqliteDriverAdapter createTestAdapter(String testDbName) {
    // In-memory adapter is sufficient; database name is irrelevant for sqlite.
    return SqliteDriverAdapter.inMemory();
  }

  Future<void> dispose() async {
    await dataSource.dispose();
  }
}

Future<SqliteTestHarness> createSqliteTestHarness({
  bool logging = true,
  bool enableNamedTimezones = true,
}) async {
  SqliteDriverAdapter.registerCodecs();

  final registry = bootstrapOrm();

  // Custom codecs used by driver_tests fixtures.
  final customCodecs = <String, ValueCodec<dynamic>>{
    'PostgresPayloadCodec': const PostgresPayloadCodec(),
    'SqlitePayloadCodec': const SqlitePayloadCodec(),
    'JsonMapCodec': const JsonMapCodec(),
  };

  // Keep global registry in sync for helpers that rely on it.
  customCodecs.forEach((key, codec) {
    ValueCodecRegistry.instance.registerCodec(key: key, codec: codec);
  });

  final adapter = SqliteDriverAdapter.inMemory();

  final dataSource = DataSource(
    DataSourceOptions(
      // Bump name to force fresh provisioning when migrations evolve.
      name: 'driver_tests_sqlite_base_v2',
      driver: adapter,
      entities: registry.allDefinitions,
      registry: registry,
      codecs: customCodecs,
      enableNamedTimezones: enableNamedTimezones,
      logging: logging,
    ),
  );

  await dataSource.init();

  setUpOrmed(
    dataSource: dataSource,
    migrationDescriptors: driverTestMigrationEntries
        .map(
          (e) => MigrationDescriptor.fromMigration(
            id: e.id,
            migration: e.migration,
            defaultSchema: dataSource.options.defaultSchema,
          ),
        )
        .toList(),
    strategy: DatabaseIsolationStrategy.migrateWithTransactions,
    adapterFactory: (dbName) => SqliteDriverAdapter.inMemory(),
  );
  return SqliteTestHarness(
    adapter: adapter,
    dataSource: dataSource,
    registry: registry,
    customCodecs: customCodecs,
    enableNamedTimezones: enableNamedTimezones,
    logging: logging,
  );
}
