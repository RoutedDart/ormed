import 'dart:async';
import 'dart:io';

import 'package:ormed/src/migrations/seeder.dart';

import '../../migrations.dart';
import '../connection/orm_connection.dart';
import '../data_source.dart';
import '../driver/driver.dart';
import '../query/query.dart';
import 'test_schema_manager.dart';

/// Strategy for database isolation in tests
enum DatabaseIsolationStrategy {
  /// Run migrations before each group
  migrate,

  /// Use transactions for each test (fast, rollback after test)
  migrateWithTransactions,

  /// Truncate tables after each test (slower, but works everywhere)
  truncate,

  /// Drop and recreate schema after each test (slowest, most thorough)
  recreate,
}

/// Manages test database lifecycle and isolation
///
/// Supports two modes:
/// - **Sequential mode** (parallel=false): All tests share the base DataSource
/// - **Parallel mode** (parallel=true): Each test gets its own database instance
///
/// Example:
/// ```dart
/// final manager = TestDatabaseManager(
///   baseDataSource: dataSource,
///   migrations: [CreateUsersTable()],
///   strategy: DatabaseIsolationStrategy.migrateWithTransactions,
///   parallel: false, // Use shared database
/// );
/// ```
class TestDatabaseManager {
  final DataSource _baseDataSource;
  final Future<void> Function(DataSource)? _runMigrations;
  final List<Migration>? _migrations;
  final List<MigrationDescriptor>? _migrationDescriptors;
  final DatabaseIsolationStrategy _strategy;

  /// Whether to use parallel mode (separate database per test)
  final bool _parallel;

  /// Optional seeders to run after migrations
  final List<DatabaseSeeder Function(OrmConnection)>? _seeders;

  /// Track created test databases for cleanup (parallel mode)
  final Map<String, DataSource> _testDataSources = {};

  /// Track active transactions per test ID (parallel mode)
  final Map<String, DataSource> _activeTransactions = {};

  /// Optional TestSchemaManager for enhanced capabilities
  TestSchemaManager? _schemaManager;

  TestDatabaseManager({
    required DataSource baseDataSource,
    Future<void> Function(DataSource)? runMigrations,
    List<Migration>? migrations,
    List<MigrationDescriptor>? migrationDescriptors,
    List<DatabaseSeeder Function(OrmConnection)>? seeders,
    DatabaseIsolationStrategy strategy =
        DatabaseIsolationStrategy.migrateWithTransactions,
    bool parallel = false,
  }) : _baseDataSource = baseDataSource,
       _runMigrations = runMigrations,
       _migrations = migrations,
       _migrationDescriptors = migrationDescriptors,
       _seeders = seeders,
       _strategy = strategy,
       _parallel = parallel;

  /// Initialize the test database manager
  ///
  /// If migration descriptors are provided, this will create a TestSchemaManager
  /// for enhanced migration and seeding capabilities.
  Future<void> initialize() async {
    if (!_parallel) {
      await _baseDataSource.init();

      // Convert List<Migration> to List<MigrationDescriptor> if needed
      List<MigrationDescriptor>? descriptors = _migrationDescriptors;
      if (descriptors == null && _migrations != null && _migrations.isNotEmpty) {
        descriptors = [];
        final defaultSchema = _baseDataSource.options.defaultSchema;
        for (var i = 0; i < _migrations.length; i++) {
          final migration = _migrations[i];
          descriptors.add(
            MigrationDescriptor.fromMigration(
              id: MigrationId(
                DateTime.utc(2023, 1, 1, 0, 0, i + 1),
                migration.runtimeType.toString(),
              ),
              migration: migration,
              defaultSchema: defaultSchema,
            ),
          );
        }
      }

      // Use TestSchemaManager if migrations are provided
      if (descriptors != null && descriptors.isNotEmpty) {
        final driver = _baseDataSource.connection.driver;
        if (driver is SchemaDriver) {
          _schemaManager = TestSchemaManager(
            schemaDriver: driver as SchemaDriver,
            migrations: descriptors,
          );
          // TestSchemaManager handles all migration logic via MigrationRunner
          await _schemaManager!.setup();

          // Run seeders if provided
          if (_seeders != null && _seeders.isNotEmpty) {
            await _schemaManager!.seed(_baseDataSource.connection, _seeders);
          }
        } else {
          throw StateError(
            'Driver ${driver.runtimeType} does not support schema operations. '
            'TestSchemaManager requires a SchemaDriver implementation.',
          );
        }
      }
    }
  }

  /// Get or create a database for the current test
  Future<DataSource> getDatabaseForTest(String testId) async {
    if (!_parallel) {
      return _baseDataSource;
    }

    final existing = _testDataSources[testId];
    if (existing != null) {
      return existing;
    }

    final testDataSource = await _createTestDatabase(testId);
    _testDataSources[testId] = testDataSource;

    return testDataSource;
  }

  /// Begin a test - sets up isolation
  ///
  /// [testId] identifies the test for parallel execution (when parallel=true).
  /// In parallel mode, each test gets its own database instance.
  Future<void> beginTest(String testId, DataSource dataSource) async {
    switch (_strategy) {
      case DatabaseIsolationStrategy.migrate:
        // Migrations already run in initialize
        break;
      case DatabaseIsolationStrategy.migrateWithTransactions:
        // Begin a transaction before each test
        await dataSource.beginTransaction();
        // Track the transaction for this test in parallel mode
        if (_parallel) {
          _activeTransactions[testId] = dataSource;
        }
        break;
      case DatabaseIsolationStrategy.truncate:
      case DatabaseIsolationStrategy.recreate:
        break;
    }
  }

  /// End a test - cleans up isolation
  ///
  /// [testId] identifies the test for parallel execution (when parallel=true).
  Future<void> endTest(String testId, DataSource dataSource) async {
    switch (_strategy) {
      case DatabaseIsolationStrategy.migrate:
        // No cleanup needed
        break;
      case DatabaseIsolationStrategy.migrateWithTransactions:
        // Rollback transaction after each test for isolation
        await dataSource.rollback();
        // Remove transaction tracking
        if (_parallel) {
          _activeTransactions.remove(testId);
        }
        break;
      case DatabaseIsolationStrategy.truncate:
        await _truncateTables(dataSource);
        break;
      case DatabaseIsolationStrategy.recreate:
        await _recreateSchema(dataSource);
        break;
    }
  }

  /// Cleanup all test databases
  ///
  /// Rolls back any active transactions and disposes all test databases.
  /// In parallel mode, also cleans up test database files.
  Future<void> cleanup() async {
    // Rollback any active transactions
    for (final entry in _activeTransactions.entries) {
      try {
        await entry.value.rollback();
      } catch (_) {
        // Ignore errors during cleanup
      }
    }
    _activeTransactions.clear();

    // Tear down schema manager if used
    // TestSchemaManager handles rollback via MigrationRunner
    if (_schemaManager != null) {
      try {
        await _schemaManager!.teardown();
      } catch (_) {
        // Ignore errors during cleanup
      }
    }

    // Dispose all test datasources
    for (final ds in _testDataSources.values) {
      try {
        await ds.dispose();
      } catch (_) {
        // Ignore errors during cleanup
      }
    }
    _testDataSources.clear();

    // Clean up test database files in parallel mode
    if (_parallel) {
      await _cleanupTestDatabases();
    }
  }

  Future<DataSource> _createTestDatabase(String testId) async {
    final options = _baseDataSource.options;
    final driver = _baseDataSource.connection.driver;
    
    // Use schema-based isolation for drivers that support it (PostgreSQL, MySQL)
    // Use database-based isolation for SQLite
    final supportsSchemas = driver.metadata.name == 'postgresql' || 
                            driver.metadata.name == 'mysql' ||
                            driver.metadata.name == 'mariadb';
    
    final DataSourceOptions testOptions;
    if (supportsSchemas) {
      // Create unique schema for this test
      // The schema will be created automatically when migrations run
      final testSchema = 'test_${testId.replaceAll('-', '_')}';
      testOptions = options.copyWith(defaultSchema: testSchema);
      
      final testDataSource = DataSource(testOptions);
      await testDataSource.init();
      return testDataSource;
    } else {
      // Fall back to database-based isolation (SQLite)
      final testDbName = '${options.name}_test_$testId';
      testOptions = options.copyWith(name: testDbName);
      
      final testDataSource = DataSource(testOptions);
      await testDataSource.init();
      return testDataSource;
    }
  }

  /// Tear down migrations (run down migrations)
  ///
  /// This is kept for backward compatibility with legacy migration approach.
  /// When using TestSchemaManager, teardown is handled automatically.
  Future<void> tearDownMigrations(DataSource dataSource) async {
    if (_schemaManager != null) {
      // TestSchemaManager handles teardown via MigrationRunner
      await _schemaManager!.teardown();
      return;
    }
  }

  Future<void> _truncateTables(DataSource dataSource) async {
    List<String> tables;

    // Try to use SchemaInspector if the driver supports it
    if (dataSource.connection.driver is SchemaDriver) {
      final schemaDriver = dataSource.connection.driver as SchemaDriver;
      final inspector = SchemaInspector(schemaDriver);
      tables = await inspector.tableListing(schemaQualified: false);
    } else {
      // Fall back to entity definitions
      tables = dataSource.options.entities.map((e) => e.tableName).toList();
    }

    // Skip migration ledger table to preserve migration state
    const ledgerTables = {'orm_migrations', 'migrations'};
    
    for (final table in tables) {
      if (!ledgerTables.contains(table)) {
        await dataSource.context.driver.truncateTable(table);
      }
    }
  }

  Future<void> _recreateSchema(DataSource dataSource) async {
    if (_schemaManager != null) {
      await _schemaManager!.reset();
    }
  }

  Future<void> _cleanupTestDatabases() async {
    final testDbDir = Directory('test_databases');
    if (testDbDir.existsSync()) {
      await testDbDir.delete(recursive: true);
    }
  }

  /// Get the underlying TestSchemaManager if available
  ///
  /// This is useful for advanced scenarios like pretend mode or status inspection.
  ///
  /// Example:
  /// ```dart
  /// final schemaManager = testDatabaseManager.schemaManager;
  /// if (schemaManager != null) {
  ///   final status = await schemaManager.status();
  ///   print('Migration status: $status');
  /// }
  /// ```
  TestSchemaManager? get schemaManager => _schemaManager;

  /// Run seeders manually
  ///
  /// This can be called after initialization to seed additional data or
  /// re-seed data between tests.
  ///
  /// Delegates to TestSchemaManager which handles seeding via DatabaseSeeder classes.
  ///
  /// Example:
  /// ```dart
  /// await testDatabaseManager.seed([
  ///   UserSeeder.new,
  ///   PostSeeder.new,
  /// ]);
  /// ```
  Future<void> seed(
    List<DatabaseSeeder Function(OrmConnection)> seeders,
  ) async {
    if (_schemaManager != null) {
      // TestSchemaManager handles all seeding logic
      await _schemaManager!.seed(_baseDataSource.connection, seeders);
    } else {
      throw StateError(
        'Seeding is only available when using migrationDescriptors. '
        'Provide migrationDescriptors in the constructor to enable seeding.',
      );
    }
  }

  /// Run seeders in pretend mode to see what queries would be executed
  ///
  /// This is useful for debugging seeders without actually modifying the database.
  /// Delegates to TestSchemaManager which uses OrmConnection.pretend().
  ///
  /// Example:
  /// ```dart
  /// final statements = await testDatabaseManager.seedWithPretend(
  ///   [UserSeeder.new],
  ///   pretend: true,
  /// );
  /// for (final entry in statements) {
  ///   print('Query: ${entry.preview.normalized.command}');
  /// }
  /// ```
  Future<List<QueryLogEntry>> seedWithPretend(
    List<DatabaseSeeder Function(OrmConnection)> seeders, {
    bool pretend = false,
  }) async {
    if (_schemaManager != null) {
      // TestSchemaManager handles pretend mode via OrmConnection
      return await _schemaManager!.seedWithPretend(
        _baseDataSource.connection,
        seeders,
        pretend: pretend,
      );
    } else {
      throw StateError(
        'Pretend mode is only available when using migrationDescriptors. '
        'Provide migrationDescriptors in the constructor to enable pretend mode.',
      );
    }
  }

  /// Get migration status
  ///
  /// Shows which migrations have been applied and when.
  /// Delegates to TestSchemaManager which queries the MigrationRunner.
  ///
  /// Example:
  /// ```dart
  /// final status = await testDatabaseManager.migrationStatus();
  /// for (final migration in status) {
  ///   print('${migration.descriptor.id.slug}: ${migration.applied}');
  /// }
  /// ```
  Future<List<MigrationStatus>> migrationStatus() async {
    if (_schemaManager != null) {
      // TestSchemaManager delegates to MigrationRunner for status
      return await _schemaManager!.status();
    } else {
      throw StateError(
        'Migration status is only available when using migrationDescriptors. '
        'Provide migrationDescriptors in the constructor to enable status inspection.',
      );
    }
  }
}
