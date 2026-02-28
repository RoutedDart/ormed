import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:ormed_d1/ormed_d1.dart';

Future<void> main(List<String> args) async {
  final mode = args.isEmpty ? 'both' : args.first.trim().toLowerCase();
  if (!const {'both', 'from-config', 'direct'}.contains(mode)) {
    stderr.writeln(
      'Usage: dart run example/data_source_verification.dart [both|from-config|direct]',
    );
    exitCode = 64;
    return;
  }

  final env = OrmedEnvironment.fromDirectory(Directory.current);
  final baseUrl = env.value('D1_BASE_URL');

  late final String accountId;
  late final String databaseId;
  late final String apiToken;
  try {
    accountId = env.requireAny(const ['D1_ACCOUNT_ID', 'CF_ACCOUNT_ID']);
    databaseId = env.require('D1_DATABASE_ID');
    apiToken = env.requireAny(const ['D1_API_TOKEN', 'D1_SECRET']);
  } on ArgumentError catch (error) {
    stderr.writeln(error.message);
    exitCode = 64;
    return;
  }

  ensureD1DriverRegistration();

  final driverOptions = <String, Object?>{
    'accountId': accountId,
    'databaseId': databaseId,
    'apiToken': apiToken,
    if (baseUrl != null) 'baseUrl': baseUrl,
    'debugLog': env.boolValue('D1_DEBUG_LOG', fallback: false),
    'maxAttempts': env.intValue('D1_RETRY_ATTEMPTS', fallback: 4),
    'requestTimeoutMs': env.intValue('D1_REQUEST_TIMEOUT_MS', fallback: 30000),
    'retryBaseDelayMs': env.intValue('D1_RETRY_BASE_DELAY_MS', fallback: 250),
    'retryMaxDelayMs': env.intValue('D1_RETRY_MAX_DELAY_MS', fallback: 3000),
  };

  if (mode == 'both' || mode == 'from-config') {
    await _verifyWithDataSourceFromConfig(driverOptions);
  }
  if (mode == 'both' || mode == 'direct') {
    await _verifyWithDirectDataSource(driverOptions);
  }
}

Future<void> _verifyWithDataSourceFromConfig(
  Map<String, Object?> driverOptions,
) async {
  final config = OrmProjectConfig(
    activeConnectionName: 'd1_from_config',
    connections: {
      'd1_from_config': ConnectionDefinition(
        name: 'd1_from_config',
        driver: DriverConfig(type: 'd1', options: Map.of(driverOptions)),
        migrations: MigrationSection(
          directory: 'database/migrations',
          registry: 'database/migrations.dart',
          ledgerTable: 'orm_migrations',
          schemaDump: 'database/schema',
        ),
      ),
    },
  );

  final dataSource = DataSource.fromConfig(config, registry: ModelRegistry());

  await dataSource.init();
  try {
    await _runVerificationQuery(dataSource, label: 'from-config');
  } finally {
    await dataSource.dispose();
  }
}

Future<void> _verifyWithDirectDataSource(
  Map<String, Object?> driverOptions,
) async {
  final adapter = D1DriverAdapter.custom(
    config: DatabaseConfig(driver: 'd1', options: Map.of(driverOptions)),
  );

  final dataSource = DataSource(
    DataSourceOptions(
      name: 'd1_direct',
      driver: adapter,
      registry: ModelRegistry(),
    ),
  );

  await dataSource.init();
  try {
    await _runVerificationQuery(dataSource, label: 'direct');
  } finally {
    await dataSource.dispose();
  }
}

Future<void> _runVerificationQuery(
  DataSource dataSource, {
  required String label,
}) async {
  final rows = await dataSource.connection.driver.queryRaw('SELECT 1 AS ok');
  if (rows.isEmpty) {
    throw StateError('[$label] D1 query returned no rows.');
  }

  stdout.writeln('[$label] SELECT 1 AS ok -> ${rows.first['ok']}');

  final nowRows = await dataSource.connection.driver.queryRaw(
    'SELECT CURRENT_TIMESTAMP AS now_utc',
  );
  final now = nowRows.isEmpty ? '<unknown>' : nowRows.first['now_utc'];
  stdout.writeln('[$label] CURRENT_TIMESTAMP -> $now');
}
