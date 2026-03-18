import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:ormed_d1/ormed_d1.dart';

import 'models/example_user.dart';

Future<void> main() async {
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

  final registry = ModelRegistry()
    ..register(ExampleUserOrmDefinition.definition);

  final adapter = D1DriverAdapter.custom(
    config: DatabaseConfig(driver: 'd1', options: driverOptions),
  );
  final dataSource = DataSource(
    DataSourceOptions(
      name: 'd1_generated_helpers',
      driver: adapter,
      registry: registry,
    ),
  );

  await dataSource.init();
  dataSource.setAsDefault();

  final uniqueEmail =
      'generated-helper-${DateTime.now().microsecondsSinceEpoch}@example.com';

  try {
    await _ensureUsersTable(dataSource.connection.driver);
    final inserted = await ExampleUsers.repo().insert(
      ExampleUserInsertDto(
        email: uniqueEmail,
        active: true,
        name: 'Generated Helper User',
      ),
    );
    stdout.writeln(
      '[generated-helpers] inserted id=${inserted.id} email=${inserted.email}',
    );

    final fetched = await ExampleUsers.query()
        .whereEquals('email', uniqueEmail)
        .first();
    if (fetched == null) {
      throw StateError('[generated-helpers] expected inserted user to exist.');
    }
    stdout.writeln(
      '[generated-helpers] query helper found id=${fetched.id} name=${fetched.name}',
    );

    await ExampleUsers.repo().update(
      ExampleUserUpdateDto(
        id: fetched.id,
        name: 'Generated Helper User (updated)',
      ),
    );

    final updated = await ExampleUsers.query()
        .whereEquals('id', fetched.id)
        .first();
    stdout.writeln(
      '[generated-helpers] updated name=${updated?.name ?? "<missing>"}',
    );
  } finally {
    await dataSource.connection.driver.executeRaw(
      'DELETE FROM "example_users" WHERE "email" = ?',
      [uniqueEmail],
    );
    await dataSource.dispose();
  }
}

Future<void> _ensureUsersTable(DriverAdapter driver) async {
  await driver.executeRaw('''
    CREATE TABLE IF NOT EXISTS "example_users" (
      "id" INTEGER PRIMARY KEY AUTOINCREMENT,
      "email" TEXT NOT NULL,
      "active" INTEGER NOT NULL DEFAULT 1,
      "name" TEXT,
      "created_at" TEXT
    )
  ''');
}
