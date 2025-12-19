import 'dart:io';

import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/ormed_postgres.dart';

/// Parses a PostgreSQL connection URL and returns its components.
class PostgresConnectionInfo {
  final String host;
  final int port;
  final String database;
  final String? username;
  final String? password;

  PostgresConnectionInfo({
    required this.host,
    required this.port,
    required this.database,
    this.username,
    this.password,
  });

  /// Parse a postgres:// URL into connection components.
  factory PostgresConnectionInfo.fromUrl(String url) {
    final uri = Uri.parse(url);
    return PostgresConnectionInfo(
      host: uri.host.isEmpty ? 'localhost' : uri.host,
      port: uri.port == 0 ? 5432 : uri.port,
      database: uri.pathSegments.isNotEmpty
          ? uri.pathSegments.first
          : 'postgres',
      username: uri.userInfo.contains(':')
          ? uri.userInfo.split(':').first
          : uri.userInfo.isEmpty
          ? null
          : uri.userInfo,
      password: uri.userInfo.contains(':')
          ? uri.userInfo.split(':').last
          : null,
    );
  }

  /// Reconstruct the URL, optionally with a different database.
  String toUrl({String? database}) {
    final db = database ?? this.database;
    final auth = username != null
        ? (password != null ? '$username:$password@' : '$username@')
        : '';
    return 'postgres://$auth$host:$port/$db';
  }
}

/// Reusable PostgreSQL test harness mirroring the SQLite harness pattern.
///
/// Provides a preconfigured [DataSource], registered codecs/registry, and
/// an [adapterFactory] for setUpOrmed isolation.
class PostgresTestHarness {
  PostgresTestHarness({
    required this.adapter,
    required this.dataSource,
    required this.registry,
    required this.customCodecs,
    required this.connectionUrl,
    required this.connectionInfo,
    required this.enableNamedTimezones,
    required this.logging,
  });

  final PostgresDriverAdapter adapter;
  final DataSource dataSource;
  final ModelRegistry registry;
  final Map<String, ValueCodec<dynamic>> customCodecs;
  final String connectionUrl;
  final PostgresConnectionInfo connectionInfo;
  final bool enableNamedTimezones;
  final bool logging;

  /// Returns a fresh adapter for isolated test databases.
  ///
  /// Note: For PostgreSQL, each test database uses a separate schema
  /// within the same database connection.
  PostgresDriverAdapter createTestAdapter(String testDbName) {
    return PostgresDriverAdapter.custom(
      config: DatabaseConfig(
        driver: 'postgres',
        options: {'url': connectionUrl},
      ),
    );
  }

  Future<void> dispose() async {
    await dataSource.dispose();
  }
}

/// Creates a PostgreSQL test harness for driver tests.
///
/// Uses the `POSTGRES_URL` environment variable if set, otherwise
/// defaults to `postgres://postgres:postgres@localhost:6543/orm_test`.
///
/// For concurrent test execution, each test group gets its own PostgreSQL schema
/// within the same database. This is much faster than creating separate databases.
///
/// Example:
/// ```dart
/// void main() async {
///   final harness = await createPostgresTestHarness();
///
///   tearDownAll(() async {
///     await harness.dispose();
///   });
///
///   // Tests use ormedTest() which gets isolated databases automatically
///   runAllDriverTests();
/// }
/// ```
Future<PostgresTestHarness> createPostgresTestHarness({
  bool logging = true,
  bool enableNamedTimezones = true,
  String? connectionUrl,
}) async {
  registerOrmFactories();
  PostgresDriverAdapter.registerCodecs();

  final registry = bootstrapOrm();

  // Custom codecs used by driver_tests fixtures.
  final customCodecs = <String, ValueCodec<dynamic>>{
    'PostgresPayloadCodec': const PostgresPayloadCodec(),
    'SqlitePayloadCodec': const SqlitePayloadCodec(),
    'MariaDbPayloadCodec': const MariaDbPayloadCodec(),
    'JsonMapCodec': const JsonMapCodec(),
    'Map<String, Object?>': const JsonMapCodec(),
    'Map<String, Object?>?': const JsonMapCodec(),
  };

  // Keep global registry in sync for helpers that rely on it.
  customCodecs.forEach((key, codec) {
    ValueCodecRegistry.instance.registerCodec(key: key, codec: codec);
  });

  final url =
      connectionUrl ??
      Platform.environment['POSTGRES_URL'] ??
      'postgres://postgres:postgres@localhost:6543/orm_test';

  // Parse the connection URL for later use
  final connectionInfo = PostgresConnectionInfo.fromUrl(url);

  final adapter = PostgresDriverAdapter.custom(
    config: DatabaseConfig(driver: 'postgres', options: {'url': url}),
  );

  final dataSource = DataSource(
    DataSourceOptions(
      name: 'driver_tests_postgres_base',
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
            tablePrefix: dataSource.options.tablePrefix,
          ),
        )
        .toList(),
    // Use 'recreate' strategy with schema-based isolation for PostgreSQL.
    // Each test group gets its own schema within the database, enabling
    // concurrent test execution. The TestDatabaseManager will use
    // createSchema/dropSchemaIfExists for PostgreSQL instead of
    // createDatabase/dropDatabaseIfExists.
    strategy: DatabaseIsolationStrategy.recreate,
    adapterFactory: (dbName) {
      // Create a new adapter for each test group that will use its own schema.
      // The TestDatabaseManager will call setCurrentSchema(dbName) to isolate
      // operations to the test group's schema.
      return PostgresDriverAdapter.custom(
        config: DatabaseConfig(driver: 'postgres', options: {'url': url}),
      );
    },
  );

  return PostgresTestHarness(
    adapter: adapter,
    dataSource: dataSource,
    registry: registry,
    customCodecs: customCodecs,
    connectionUrl: url,
    connectionInfo: connectionInfo,
    enableNamedTimezones: enableNamedTimezones,
    logging: logging,
  );
}
