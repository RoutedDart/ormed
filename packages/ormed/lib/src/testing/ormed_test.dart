import 'dart:async';

import 'package:meta/meta.dart';
import 'package:test/test.dart';

import '../../migrations.dart';
import '../../testing.dart' show DatabaseSeeder;
import '../connection/orm_connection.dart';
import '../data_source.dart';
import '../query/query.dart';
import 'test_database_manager.dart';
import 'test_schema_manager.dart';

/// Re-export DatabaseIsolationStrategy as DatabaseRefreshStrategy for backwards compatibility
typedef DatabaseRefreshStrategy = DatabaseIsolationStrategy;

/// Global test database manager instance
TestDatabaseManager? _globalManager;
int _testCounter = 0;

/// Configure Ormed for testing
///
/// Call this once in your test file's `main()` before defining tests.
///
/// **Basic usage:**
/// ```dart
/// void main() {
///   setUpOrmed(
///     dataSource: myDataSource,
///     migrations: [CreateUsersTable()],
///   );
///
///   test('my test', () async {
///     // Your test code
///   });
/// }
/// ```
///
/// **With seeding:**
/// ```dart
/// void main() {
///   setUpOrmed(
///     dataSource: myDataSource,
///     migrationDescriptors: [
///       MigrationDescriptor.fromMigration(
///         id: MigrationId(DateTime.utc(2024, 1, 1), 'create_users'),
///         migration: CreateUsersTable(),
///       ),
///     ],
///     seeders: [UserSeeder.new, PostSeeder.new],
///   );
/// }
/// ```
void setUpOrmed({
  required DataSource dataSource,
  Future<void> Function(DataSource)? runMigrations,
  List<Migration>? migrations,
  List<MigrationDescriptor>? migrationDescriptors,
  List<DatabaseSeeder Function(OrmConnection)>? seeders,
  DatabaseIsolationStrategy strategy =
      DatabaseIsolationStrategy.migrateWithTransactions,
  bool parallel = false,
}) {
  _globalManager = TestDatabaseManager(
    baseDataSource: dataSource,
    runMigrations: runMigrations,
    migrations: migrations,
    migrationDescriptors: migrationDescriptors,
    seeders: seeders,
    strategy: strategy,
    parallel: parallel,
  );

  setUpAll(() async {
    await _globalManager!.initialize();
  });

  tearDownAll(() async {
    await _globalManager!.cleanup();
    _globalManager = null;
  });
}

/// Run a test with database isolation
///
/// Automatically sets up and tears down database state for each test.
/// Use this instead of `test()` from the test package:
///
/// ```dart
/// ormedTest('creates a user', () async {
///   final user = User(name: 'John');
///   await user.save();
///
///   expect(user.id, isNotNull);
/// });
/// ```
void ormedTest(
  String description,
  FutureOr<void> Function() body, {
  String? testOn,
  Timeout? timeout,
  dynamic skip,
  dynamic tags,
  Map<String, dynamic>? onPlatform,
  int? retry,
}) {
  test(
    description,
    () async {
      if (_globalManager == null) {
        throw StateError(
          'Ormed test environment not initialized. '
          'Call setUpOrmed() in your main() before defining tests.',
        );
      }

      final testId =
          'test_${_testCounter++}_${DateTime.now().millisecondsSinceEpoch}';
      final dataSource = await _globalManager!.getDatabaseForTest(testId);

      await _globalManager!.beginTest(testId, dataSource);
      try {
        await body();
      } finally {
        await _globalManager!.endTest(testId, dataSource);
      }
    },
    testOn: testOn,
    timeout: timeout,
    skip: skip,
    tags: tags,
    onPlatform: onPlatform,
    retry: retry,
  );
}

/// Run a test group with database isolation
///
/// Similar to `ormedTest` but for grouping related tests:
///
/// ```dart
/// ormedGroup('User tests', () {
///   ormedTest('creates a user', () async {
///     // ...
///   });
///
///   ormedTest('updates a user', () async {
///     // ...
///   });
/// });
/// ```
@isTestGroup
void ormedGroup(
  String description,
  void Function() body, {
  DataSource? dataSource,
  List<Migration>? migrations,
  DatabaseRefreshStrategy? refreshStrategy,
  String? testOn,
  Timeout? timeout,
  dynamic skip,
  dynamic tags,
  Map<String, dynamic>? onPlatform,
  int? retry,
}) {
  group(
    description,
    () {
      late TestDatabaseManager manager;

      // Set up migrations if provided
      if (dataSource != null) {
        setUpAll(() async {
          manager = TestDatabaseManager(
            baseDataSource: dataSource,
            migrations: migrations,
            strategy:
                refreshStrategy ??
                DatabaseIsolationStrategy.migrateWithTransactions,
          );
          await manager.initialize();
        });

        setUp(() async {
          // Use a consistent test ID for group-based tests (non-parallel)
          await manager.beginTest('group_test', dataSource);
        });

        tearDown(() async {
          await manager.endTest('group_test', dataSource);
        });

        tearDownAll(() async {
          if (migrations != null && migrations.isNotEmpty) {
            await manager.tearDownMigrations(dataSource);
          }
          await manager.cleanup();
        });
      }

      body();
    },
    testOn: testOn,
    timeout: timeout,
    skip: skip,
    tags: tags,
    onPlatform: onPlatform,
    retry: retry,
  );
}

/// Get current test database manager
TestDatabaseManager? get testDatabaseManager => _globalManager;

/// Get the underlying TestSchemaManager if available
///
/// This provides access to advanced features like pretend mode and status inspection.
///
/// Example:
/// ```dart
/// final schemaManager = testSchemaManager;
/// if (schemaManager != null) {
///   final status = await schemaManager.status();
///   print('Migrations applied: ${status.where((m) => m.applied).length}');
/// }
/// ```
TestSchemaManager? get testSchemaManager => _globalManager?.schemaManager;

/// Seed data in the current test environment
///
/// This is a convenience wrapper around `testDatabaseManager.seed()`.
///
/// Example:
/// ```dart
/// ormedTest('with seeded data', () async {
///   await seedTestData([UserSeeder.new, PostSeeder.new]);
///
///   final users = await User.all();
///   expect(users, isNotEmpty);
/// });
/// ```
Future<void> seedTestData(
  List<DatabaseSeeder Function(OrmConnection)> seeders,
) async {
  if (_globalManager == null) {
    throw StateError(
      'Ormed test environment not initialized. '
      'Call setUpOrmed() in your main() before seeding.',
    );
  }
  await _globalManager!.seed(seeders);
}

/// Preview seeder queries without executing them
///
/// This is useful for debugging seeders and understanding what SQL will be executed.
///
/// Example:
/// ```dart
/// test('debug seeder', () async {
///   final statements = await previewTestSeed([UserSeeder.new]);
///
///   for (final entry in statements) {
///     print('Query: ${entry.preview.normalized.command}');
///   }
/// });
/// ```
Future<List<QueryLogEntry>> previewTestSeed(
  List<DatabaseSeeder Function(OrmConnection)> seeders,
) async {
  if (_globalManager == null) {
    throw StateError(
      'Ormed test environment not initialized. '
      'Call setUpOrmed() in your main() before using pretend mode.',
    );
  }
  return await _globalManager!.seedWithPretend(seeders, pretend: true);
}

/// Get migration status in the test environment
///
/// Shows which migrations have been applied and when.
///
/// Example:
/// ```dart
/// test('check migrations', () async {
///   final status = await testMigrationStatus();
///
///   expect(status.every((m) => m.applied), isTrue);
/// });
/// ```
Future<List<MigrationStatus>> testMigrationStatus() async {
  if (_globalManager == null) {
    throw StateError(
      'Ormed test environment not initialized. '
      'Call setUpOrmed() in your main() before checking status.',
    );
  }
  return await _globalManager!.migrationStatus();
}
