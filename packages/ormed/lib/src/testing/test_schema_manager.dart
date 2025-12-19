import 'dart:async';

import 'package:ormed/src/model/model.dart';
import 'package:ormed/src/query/query.dart';

import '../../migrations.dart';
import '../connection/orm_connection.dart';
import '../driver/driver.dart';
import '../seeding/seeder_runner.dart';

/// Manages test schema setup with migrations and seeding support
///
/// This class provides a driver-agnostic way to:
/// - Run migrations from ModelDefinitions
/// - Execute custom migrations
/// - Seed test data
/// - Reset schema between tests
///
/// Example usage:
/// ```dart
/// final manager = TestSchemaManager(
///   schemaDriver: connection.driver as SchemaDriver,
///   modelDefinitions: [UserOrmDefinition.definition],
///   migrations: [CreateUsersTable()],
/// );
///
/// await manager.setup();
/// await manager.seed([UserSeeder.new]);
/// await manager.teardown();
/// ```
class TestSchemaManager {
  TestSchemaManager({
    required SchemaDriver schemaDriver,
    List<ModelDefinition>? modelDefinitions,
    List<MigrationDescriptor>? migrations,
    String ledgerTable = 'orm_migrations',
    String? tablePrefix,
  }) : _schemaDriver = schemaDriver,
       _modelDefinitions = modelDefinitions ?? [],
       _migrations = migrations ?? [],
       _ledgerTable = ledgerTable,
       _tablePrefix = tablePrefix;

  final SchemaDriver _schemaDriver;
  final List<ModelDefinition> _modelDefinitions;
  final List<MigrationDescriptor> _migrations;
  final String _ledgerTable;
  final String? _tablePrefix;
  MigrationRunner? _runner;

  /// Initialize the migration runner
  MigrationRunner _createRunner() {
    if (_runner != null) return _runner!;

    _runner = MigrationRunner(
      schemaDriver: _schemaDriver,
      ledger: SqlMigrationLedger(
        _schemaDriver as DriverAdapter,
        tableName: _ledgerTable,
        tablePrefix: _tablePrefix,
      ),
      migrations: _migrations,
    );
    return _runner!;
  }

  /// Set up the test schema by running all migrations
  ///
  /// This will:
  /// 1. Initialize the migration ledger
  /// 2. Apply all pending migrations
  ///
  /// Example:
  /// ```dart
  /// await manager.setup();
  /// ```
  Future<MigrationReport> setup() async {
    if (_migrations.isEmpty) {
      return const MigrationReport([]);
    }

    final runner = _createRunner();
    return await runner.applyAll();
  }

  /// Tear down the test schema by rolling back all migrations
  ///
  /// This will:
  /// 1. Roll back all applied migrations
  /// 2. Drop the ledger table
  ///
  /// Example:
  /// ```dart
  /// await manager.teardown();
  /// ```
  Future<void> teardown() async {
    if (_migrations.isEmpty) {
      return;
    }

    final runner = _createRunner();
    final status = await runner.status();
    final appliedCount = status.where((m) => m.applied).length;

    if (appliedCount > 0) {
      await runner.rollback(steps: appliedCount);
    }

    // Drop the ledger table
    await _purgeLedger();
  }

  /// Reset the schema by tearing down and setting up again
  ///
  /// This is useful for ensuring a clean state between test runs.
  ///
  /// Example:
  /// ```dart
  /// await manager.reset();
  /// ```
  Future<MigrationReport> reset() async {
    await teardown();
    return await setup();
  }

  /// Purge all tables defined in model definitions
  ///
  /// This drops all tables without using migrations, useful for
  /// cleaning up after failed migrations or tests.
  ///
  /// Example:
  /// ```dart
  /// await manager.purge();
  /// ```
  Future<void> purge() async {
    final builder = SchemaBuilder(tablePrefix: _tablePrefix);
    final seenTables = <String>{};

    for (final definition in _modelDefinitions) {
      final table = definition.tableName;
      if (seenTables.add(table)) {
        builder.drop(table, ifExists: true, cascade: true);
      }
    }

    builder.drop(_ledgerTable, ifExists: true, cascade: true);

    if (builder.isEmpty) {
      return;
    }

    final plan = builder.build(description: 'purge-test-schema');
    await _schemaDriver.applySchemaPlan(plan);
  }

  /// Drop the migration ledger table
  Future<void> _purgeLedger() async {
    final builder = SchemaBuilder(tablePrefix: _tablePrefix)
      ..drop(_ledgerTable, ifExists: true, cascade: true);

    if (builder.isEmpty) {
      return;
    }

    final plan = builder.build(description: 'purge-ledger');
    await _schemaDriver.applySchemaPlan(plan);
  }

  /// Get migration status
  ///
  /// Returns the status of all registered migrations showing which
  /// have been applied and when.
  ///
  /// Example:
  /// ```dart
  /// final status = await manager.status();
  /// for (final migration in status) {
  ///   print('${migration.descriptor.id}: ${migration.applied}');
  /// }
  /// ```
  Future<List<MigrationStatus>> status() async {
    if (_migrations.isEmpty) {
      return [];
    }

    final runner = _createRunner();
    return await runner.status();
  }

  /// Run seeders using a connection
  ///
  /// Accepts a list of seeder factories and runs them in order.
  /// Each factory receives the OrmConnection to use for seeding.
  ///
  /// Example:
  /// ```dart
  /// await manager.seed(
  ///   connection,
  ///   [UserSeeder.new, PostSeeder.new],
  /// );
  /// ```
  Future<void> seed(
    OrmConnection connection,
    List<DatabaseSeeder Function(OrmConnection)> seederFactories,
  ) async {
    for (final factory in seederFactories) {
      final seeder = factory(connection);
      await seeder.run();
    }
  }

  /// Run seeders with pretend mode
  ///
  /// When pretend is true, queries are logged but not executed.
  /// This is useful for debugging seeders.
  ///
  /// Example:
  /// ```dart
  /// final statements = await manager.seedWithPretend(
  ///   connection,
  ///   [UserSeeder.new],
  ///   pretend: true,
  /// );
  /// ```
  Future<List<QueryLogEntry>> seedWithPretend(
    OrmConnection connection,
    List<DatabaseSeeder Function(OrmConnection)> seederFactories, {
    bool pretend = false,
  }) async {
    if (!pretend) {
      await seed(connection, seederFactories);
      return [];
    }

    return await connection.pretend(() async {
      for (final factory in seederFactories) {
        final seeder = factory(connection);
        await seeder.run();
      }
    });
  }
}

/// Extension to add test schema management to SchemaDriver
extension SchemaDriverTestExtensions on SchemaDriver {
  /// Create a test schema manager for this driver
  ///
  /// Example:
  /// ```dart
  /// final manager = schemaDriver.testManager(
  ///   modelDefinitions: [UserOrmDefinition.definition],
  ///   migrations: [CreateUsersTable()],
  /// );
  /// ```
  TestSchemaManager testManager({
    List<ModelDefinition>? modelDefinitions,
    List<MigrationDescriptor>? migrations,
    String ledgerTable = 'orm_migrations',
  }) {
    return TestSchemaManager(
      schemaDriver: this,
      modelDefinitions: modelDefinitions,
      migrations: migrations,
      ledgerTable: ledgerTable,
    );
  }
}

/// Run registered seeders on a connection
///
/// Example:
/// ```dart
/// await runSeederRegistry(
///   connection,
///   [
///     SeederRegistration(name: 'UserSeeder', factory: UserSeeder.new),
///     SeederRegistration(name: 'PostSeeder', factory: PostSeeder.new),
///   ],
///   names: ['UserSeeder'],
///   pretend: false,
/// );
/// ```
Future<void> runSeederRegistry(
  OrmConnection connection,
  List<SeederRegistration> seeders, {
  List<String>? names,
  bool pretend = false,
  void Function(String message)? log,
}) async {
  final runner = SeederRunner();
  await runner.run(
    connection: connection,
    seeders: seeders,
    names: names,
    pretend: pretend,
    log: log,
    onPretendQueries: log == null
        ? null
        : (entries) {
            for (final entry in entries) {
              log('[pretend] ${_formatQueryLogEntry(entry)}');
            }
          },
  );
}

/// Format a query log entry for display
String _formatQueryLogEntry(QueryLogEntry entry) {
  final normalized = entry.preview.normalized;
  final parts = <String>[
    normalized.command,
    if (normalized.arguments.isNotEmpty) 'args: ${normalized.arguments}',
    if (normalized.parameters.isNotEmpty) 'params: ${normalized.parameters}',
    '(${entry.duration.inMilliseconds}ms)',
  ];
  return parts.join(' ');
}
