import 'dart:io';

import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_mysql/ormed_mysql.dart';

/// Parses a MariaDB connection URL and returns its components.
class MariaDbConnectionInfo {
  final String host;
  final int port;
  final String database;
  final String? username;
  final String? password;
  final bool secure;

  MariaDbConnectionInfo({
    required this.host,
    required this.port,
    required this.database,
    this.username,
    this.password,
    this.secure = true, // Default to true for caching_sha2_password auth
  });

  /// Parse a mariadb:// URL into connection components.
  factory MariaDbConnectionInfo.fromUrl(String url) {
    final uri = Uri.parse(url);
    // Check for ssl or secure query parameter
    final hasSecure = uri.queryParameters['ssl'] == 'true' ||
        uri.queryParameters['secure'] == 'true' ||
        // Default to true for MariaDB to match MySQL behavior
        !uri.queryParameters.containsKey('ssl') && !uri.queryParameters.containsKey('secure');
    return MariaDbConnectionInfo(
      host: uri.host.isEmpty ? 'localhost' : uri.host,
      port: uri.port == 0 ? 3306 : uri.port,
      database:
          uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'mysql',
      username: uri.userInfo.contains(':')
          ? uri.userInfo.split(':').first
          : uri.userInfo.isEmpty
              ? null
              : uri.userInfo,
      password:
          uri.userInfo.contains(':') ? uri.userInfo.split(':').last : null,
      secure: hasSecure,
    );
  }

  /// Reconstruct the URL, optionally with a different database.
  String toUrl({String? database, bool? secure}) {
    final db = database ?? this.database;
    final useSsl = secure ?? this.secure;
    final auth = username != null
        ? (password != null ? '$username:$password@' : '$username@')
        : '';
    final sslQuery = useSsl ? '?secure=true' : '';
    return 'mariadb://$auth$host:$port/$db$sslQuery';
  }
}

/// Reusable MariaDB test harness for driver packages.
///
/// This sets up a DataSource with the driver test registry, registers
/// codecs, and provides adapter factory for parallel test isolation.
///
/// MariaDB uses databases for isolation (schema = database in MariaDB),
/// so each test group gets its own database with unique table prefixes.
class MariaDbTestHarness {
  MariaDbTestHarness({
    required this.adapter,
    required this.dataSource,
    required this.registry,
    required this.connectionUrl,
    required this.connectionInfo,
    required this.customCodecs,
    required this.logging,
    required this.enableNamedTimezones,
  });

  final MariaDbDriverAdapter adapter;
  final DataSource dataSource;
  final ModelRegistry registry;
  final String connectionUrl;
  final MariaDbConnectionInfo connectionInfo;
  final Map<String, ValueCodec<dynamic>> customCodecs;
  final bool logging;
  final bool enableNamedTimezones;

  /// Create a new adapter for test isolation (parallel mode)
  ///
  /// Returns a fresh adapter that will connect to the same MariaDB server
  /// but will use a unique database for this test group.
  /// The TestDatabaseManager will call createSchema/setCurrentSchema
  /// to set up the isolated database.
  MariaDbDriverAdapter createTestAdapter(String testDbName) {
    // For MariaDB, createSchema creates a database.
    // We connect to the base database initially, then TestDatabaseManager
    // will create and switch to the test-specific database.
    return MariaDbDriverAdapter.custom(
      config: DatabaseConfig(
        driver: 'mariadb',
        options: {'url': connectionUrl, 'ssl': connectionInfo.secure},
      ),
    );
  }

  Future<void> dispose() async {
    await dataSource.dispose();
    await adapter.close();
  }
}

/// Creates a MariaDB test harness for driver tests.
///
/// Uses the `MARIADB_URL` environment variable if set, otherwise
/// defaults to `mariadb://root:secret@localhost:6604/orm_test`.
///
/// For concurrent test execution, each test group gets its own MariaDB database.
/// MariaDB treats schemas as databases, so we use database-level isolation.
///
/// Example:
/// ```dart
/// void main() async {
///   final harness = await createMariaDbTestHarness();
///
///   tearDownAll(() async {
///     await harness.dispose();
///   });
///
///   // Tests use ormedTest() which gets isolated databases automatically
///   runAllDriverTests();
/// }
/// ```
Future<MariaDbTestHarness> createMariaDbTestHarness({
  String? url,
  bool logging = true,
  bool enableNamedTimezones = true,
}) async {
  registerOrmFactories();
  MySqlDriverAdapter.registerCodecs();

  final resolvedUrl = url ??
      Platform.environment['MARIADB_URL'] ??
      'mariadb://root:secret@localhost:6604/orm_test';

  // Parse the connection URL for later use
  final connectionInfo = MariaDbConnectionInfo.fromUrl(resolvedUrl);

  final adapter = MariaDbDriverAdapter.custom(
    config: DatabaseConfig(
      driver: 'mariadb',
      options: {'url': resolvedUrl, 'ssl': connectionInfo.secure},
    ),
  );

  final registry = buildOrmRegistry();

  // Custom codecs used by driver_tests fixtures.
  final customCodecs = <String, ValueCodec<dynamic>>{
    'PostgresPayloadCodec': const PostgresPayloadCodec(),
    'SqlitePayloadCodec': const SqlitePayloadCodec(),
    'MariaDbPayloadCodec': const MariaDbPayloadCodec(),
    'JsonMapCodec': const JsonMapCodec(),
    'json': const JsonMapCodec(),
    'bool': const MySqlBoolCodec(),
    'bool?': const MySqlBoolCodec(),
    'Map<String, Object?>': const JsonMapCodec(),
    'Map<String, Object?>?': const JsonMapCodec(),
  };

  // Register globally so ValueCodecRegistry.instance stays in sync for helpers
  // that don't receive DataSourceOptions.codecs.
  customCodecs.forEach((key, codec) {
    ValueCodecRegistry.instance.registerCodec(key: key, codec: codec);
  });

  final dataSource = DataSource(
    DataSourceOptions(
      name: 'driver_tests_mariadb_base',
      driver: adapter,
      entities: registry.allDefinitions,
      registry: registry,
      codecs: customCodecs,
      logging: logging,
      enableNamedTimezones: enableNamedTimezones,
    ),
  );

  await dataSource.init();

  if (logging) {
    dataSource.enableQueryLog();
  }

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
    // Use 'migrateWithTransactions' strategy for MariaDB for much better performance.
    // This uses transactions for test isolation (rollback after each test).
    // Each test group still gets its own database, but tests within a group
    // use transaction rollback for fast cleanup.
    strategy: DatabaseIsolationStrategy.migrateWithTransactions,
    adapterFactory: (dbName) {
      // Create a new adapter for each test group.
      // The TestDatabaseManager will call setCurrentSchema(dbName) to
      // switch to the test group's database.
      return MariaDbDriverAdapter.custom(
        config: DatabaseConfig(
          driver: 'mariadb',
          options: {'url': resolvedUrl, 'ssl': connectionInfo.secure},
        ),
      );
    },
  );

  return MariaDbTestHarness(
    adapter: adapter,
    dataSource: dataSource,
    registry: registry,
    connectionUrl: resolvedUrl,
    connectionInfo: connectionInfo,
    customCodecs: customCodecs,
    logging: logging,
    enableNamedTimezones: enableNamedTimezones,
  );
}
