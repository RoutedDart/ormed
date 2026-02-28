import 'dart:io';

import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:ormed_d1/ormed_d1.dart';

import 'd1_sqlite_cli_mock_server.dart';

enum D1SharedTestBackend { mock, real }

D1SharedTestBackend resolveD1SharedTestBackend(
  OrmedEnvironment env, {
  D1SharedTestBackend fallback = D1SharedTestBackend.mock,
}) {
  final raw = env.firstNonEmpty([
    'D1_TEST_MODE',
    'D1_TEST_BACKEND',
    'D1_SHARED_BACKEND',
  ]);
  if (raw == null) {
    return fallback;
  }

  switch (raw.trim().toLowerCase()) {
    case 'mock':
    case 'sqlite':
    case 'sqlite-cli':
      return D1SharedTestBackend.mock;
    case 'real':
    case 'remote':
    case 'd1':
      return D1SharedTestBackend.real;
    default:
      return fallback;
  }
}

String? d1SharedTestSkipReason({
  required D1SharedTestBackend backend,
  required OrmedEnvironment env,
}) {
  if (backend == D1SharedTestBackend.mock) {
    if (!D1SqliteCliMockServer.isAvailable) {
      return 'sqlite3 CLI is not available on PATH for mock D1 shared tests.';
    }
    return null;
  }

  final accountId = env.value('D1_ACCOUNT_ID') ?? env.value('CF_ACCOUNT_ID');
  final databaseId = env.value('D1_DATABASE_ID');
  final apiToken = env.value('D1_API_TOKEN') ?? env.value('D1_SECRET');
  final missing = <String>[
    if (accountId == null) 'D1_ACCOUNT_ID/CF_ACCOUNT_ID',
    if (databaseId == null) 'D1_DATABASE_ID',
    if (apiToken == null) 'D1_API_TOKEN/D1_SECRET',
  ];
  if (missing.isEmpty) {
    return null;
  }
  return 'Missing env vars: ${missing.join(', ')}';
}

/// Reusable D1 test harness for shared driver tests.
class D1TestHarness {
  D1TestHarness({
    required this.adapter,
    required this.dataSource,
    required this.registry,
    required this.customCodecs,
    required this.accountId,
    required this.databaseId,
    required this.baseUrl,
    required this.backend,
    required this.driverOptions,
    required this.logging,
    required this.enableNamedTimezones,
    this.mockServer,
  });

  final D1DriverAdapter adapter;
  final DataSource dataSource;
  final ModelRegistry registry;
  final Map<String, ValueCodec<dynamic>> customCodecs;
  final String accountId;
  final String databaseId;
  final String baseUrl;
  final D1SharedTestBackend backend;
  final Map<String, Object?> driverOptions;
  final bool logging;
  final bool enableNamedTimezones;
  final D1SqliteCliMockServer? mockServer;

  bool get isMock => backend == D1SharedTestBackend.mock;

  D1DriverAdapter createTestAdapter(String testDbName) {
    final options = Map<String, Object?>.from(driverOptions);
    return D1DriverAdapter.custom(
      config: DatabaseConfig(driver: 'd1', options: options),
    );
  }

  Future<void> dispose() async {
    await dataSource.dispose();
    await adapter.close();
    await mockServer?.close();
  }
}

Future<D1TestHarness> createD1TestHarness({
  bool logging = true,
  bool enableNamedTimezones = true,
  D1SharedTestBackend? backend,
  String? accountId,
  String? databaseId,
  String? apiToken,
  String? baseUrl,
}) async {
  D1DriverAdapter.registerCodecs();
  final env = OrmedEnvironment.fromDirectory(Directory.current);
  final resolvedBackend = backend ?? resolveD1SharedTestBackend(env);

  D1SqliteCliMockServer? mockServer;
  late final String resolvedAccountId;
  late final String resolvedDatabaseId;
  late final String resolvedApiToken;

  if (resolvedBackend == D1SharedTestBackend.mock) {
    if (!D1SqliteCliMockServer.isAvailable) {
      throw StateError(
        'sqlite3 CLI is not available on PATH for mock D1 shared tests.',
      );
    }
    mockServer = await D1SqliteCliMockServer.start();
    resolvedAccountId =
        accountId ??
        env.value('D1_ACCOUNT_ID') ??
        env.value('CF_ACCOUNT_ID') ??
        'mock-account';
    resolvedDatabaseId =
        databaseId ?? env.value('D1_DATABASE_ID') ?? 'mock-database';
    resolvedApiToken =
        apiToken ??
        env.value('D1_API_TOKEN') ??
        env.value('D1_SECRET') ??
        'mock-token';
  } else {
    try {
      resolvedAccountId =
          accountId ??
          env.requireAny(
            ['D1_ACCOUNT_ID', 'CF_ACCOUNT_ID'],
            message:
                'D1_ACCOUNT_ID or CF_ACCOUNT_ID is required for real D1 shared tests.',
          );
      resolvedDatabaseId =
          databaseId ??
          env.require(
            'D1_DATABASE_ID',
            message: 'D1_DATABASE_ID is required for real D1 shared tests.',
          );
      resolvedApiToken =
          apiToken ??
          env.requireAny(
            ['D1_API_TOKEN', 'D1_SECRET'],
            message:
                'D1_API_TOKEN or D1_SECRET is required for real D1 shared tests.',
          );
    } on ArgumentError catch (error) {
      throw StateError(error.message.toString());
    }
  }

  final resolvedBaseUrl =
      baseUrl ??
      mockServer?.baseUrl ??
      env.string(
        'D1_BASE_URL',
        fallback: 'https://api.cloudflare.com/client/v4',
      );
  final resolvedDebugLog = env.boolValue('D1_DEBUG_LOG', fallback: false);
  final resolvedMaxAttempts = env.intValue('D1_RETRY_ATTEMPTS', fallback: 5);
  final resolvedRequestTimeoutMs = env.intValue(
    'D1_REQUEST_TIMEOUT_MS',
    fallback: 30000,
  );
  final resolvedRetryBaseDelayMs = env.intValue(
    'D1_RETRY_BASE_DELAY_MS',
    fallback: 250,
  );
  final resolvedRetryMaxDelayMs = env.intValue(
    'D1_RETRY_MAX_DELAY_MS',
    fallback: 3000,
  );

  final registry = bootstrapOrm();

  final customCodecs = <String, ValueCodec<dynamic>>{
    'PostgresPayloadCodec': const PostgresPayloadCodec(),
    'SqlitePayloadCodec': const SqlitePayloadCodec(),
    'JsonMapCodec': const JsonMapCodec(),
  };

  customCodecs.forEach((key, codec) {
    ValueCodecRegistry.instance.registerCodec(key: key, codec: codec);
  });

  final driverOptions = <String, Object?>{
    'accountId': resolvedAccountId,
    'databaseId': resolvedDatabaseId,
    'apiToken': resolvedApiToken,
    'baseUrl': resolvedBaseUrl,
    'debugLog': resolvedDebugLog,
    'maxAttempts': resolvedMaxAttempts,
    'requestTimeoutMs': resolvedRequestTimeoutMs,
    'retryBaseDelayMs': resolvedRetryBaseDelayMs,
    'retryMaxDelayMs': resolvedRetryMaxDelayMs,
  };

  final adapter = D1DriverAdapter.custom(
    config: DatabaseConfig(driver: 'd1', options: driverOptions),
  );

  await _resetDriverTestObjects(adapter: adapter);

  final dataSource = DataSource(
    DataSourceOptions(
      name: 'driver_tests_d1_base_v1',
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
    strategy: DatabaseIsolationStrategy.truncate,
    adapterFactory: (_) => D1DriverAdapter.custom(
      config: DatabaseConfig(
        driver: 'd1',
        options: Map<String, Object?>.from(driverOptions),
      ),
    ),
  );

  return D1TestHarness(
    adapter: adapter,
    dataSource: dataSource,
    registry: registry,
    customCodecs: customCodecs,
    accountId: resolvedAccountId,
    databaseId: resolvedDatabaseId,
    baseUrl: resolvedBaseUrl,
    backend: resolvedBackend,
    driverOptions: Map<String, Object?>.from(driverOptions),
    logging: logging,
    enableNamedTimezones: enableNamedTimezones,
    mockServer: mockServer,
  );
}

Future<void> _resetDriverTestObjects({required D1DriverAdapter adapter}) async {
  await adapter.withoutForeignKeyConstraints(() async {
    final tables = await adapter.queryRaw(
      "SELECT name FROM sqlite_master "
      "WHERE type = 'table' "
      "AND name NOT LIKE 'sqlite_%' "
      "AND name NOT LIKE '_cf_%'",
    );

    for (final object in tables) {
      final name = object['name']?.toString();
      if (name == null || name.isEmpty) continue;
      await adapter.executeRaw(
        'DROP TABLE IF EXISTS "${_escapeIdentifier(name)}"',
      );
    }
  });
}

String _escapeIdentifier(String identifier) => identifier.replaceAll('"', '""');
