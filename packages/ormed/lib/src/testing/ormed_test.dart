import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart' show sha256;
import 'package:meta/meta.dart';
import 'package:test/test.dart';

import '../../migrations.dart';
import '../connection/orm_connection.dart';
import '../data_source.dart';
import '../driver/driver_adapter.dart' show DriverAdapter;
import '../query/query.dart';
import 'test_database_manager.dart';

/// Re-export DatabaseIsolationStrategy as DatabaseRefreshStrategy for backwards compatibility
typedef DatabaseRefreshStrategy = DatabaseIsolationStrategy;

/// Global test counter for unique IDs

/// Configuration object returned by setUpOrmed.
/// Pass this to ormedGroup to ensure the correct manager is used.
class OrmedTestConfig {
  /// Unique key identifying this test configuration
  final String configKey;

  /// The DataSource name
  final String dataSourceName;

  /// Hash to detect configuration changes
  final String _configHash;

  OrmedTestConfig._({
    required this.configKey,
    required this.dataSourceName,
    required String configHash,
  }) : _configHash = configHash;

  /// Hash of the configuration used to create this test environment.
  String get configHash => _configHash;

  /// Get the manager for this configuration
  TestDatabaseManager get manager {
    final m = _managers[configKey];
    if (m == null) {
      throw StateError(
        'No manager found for config key "$configKey". '
        'The test environment may have been disposed or not initialized.',
      );
    }
    return m;
  }

  /// Get the DataSource for this configuration
  DataSource get dataSource => manager.baseDataSource;

  @override
  String toString() => 'OrmedTestConfig($configKey, ds: $dataSourceName)';
}

/// Tracks managers per configuration key.
/// Key: Unique config key (hash of DataSource name + call site)
/// Value: The TestDatabaseManager for that configuration
final Map<String, TestDatabaseManager> _managers = {};

/// Tracks which databases have been provisioned for migrateWithTransactions strategy.
/// Key: DataSource name (unique identifier for each database connection)
/// Value: The provisioned DataSource
final Map<String, DataSource> _provisionedDatabases = {};

/// Reference count per database for how many setUpOrmed calls are active.
final Map<String, int> _databaseRefCount = {};

/// Zone key for the current test configuration
final _zoneConfigKey = Object();

/// Get the current OrmedTestConfig from Zone-local storage
OrmedTestConfig? get _currentZoneConfig {
  return Zone.current[_zoneConfigKey] as OrmedTestConfig?;
}

/// Stack of active configurations (for nested groups)
final List<OrmedTestConfig> _configStack = [];

/// Legacy: The most recently registered config for backwards compatibility.
OrmedTestConfig? _lastRegisteredConfig;

/// Context for the current test group
class _GroupContext {
  DataSource? dataSource;
  final TestDatabaseManager manager;
  final DatabaseIsolationStrategy strategy;
  final String groupId;
  final OrmedTestConfig? config;

  _GroupContext(this.manager, this.strategy, this.groupId, {this.config});
}

_GroupContext? _currentGroupContext;

/// Generate a unique configuration key based on DataSource name and call context
String _generateConfigKey(String dataSourceName, {String? hint}) {
  // Use timestamp + counter + datasource name for uniqueness
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  final raw = '$dataSourceName:$timestamp:${hint ?? ''}';
  final hash = sha256.convert(utf8.encode(raw)).toString().substring(0, 16);
  return '${dataSourceName}_$hash';
}

/// Configure Ormed for testing
///
/// Call this once in your test file's `main()` before defining tests.
/// Returns an [OrmedTestConfig] that can be passed to [ormedGroup] to ensure
/// the correct database manager is used.
///
/// ```dart
/// Future<void> main() async {
///   final harness = await createTestHarness();
///   final config = setUpOrmed(dataSource: harness.dataSource, ...);
///
///   tearDownAll(() => harness.dispose());
///
///   runAllDriverTests(config); // Pass config to tests
/// }
/// ```
OrmedTestConfig setUpOrmed({
  required DataSource dataSource,
  Future<void> Function(DataSource)? runMigrations,
  List<Migration>? migrations,
  List<MigrationDescriptor>? migrationDescriptors,
  List<DatabaseSeeder Function(OrmConnection)>? seeders,
  DatabaseIsolationStrategy strategy =
      DatabaseIsolationStrategy.migrateWithTransactions,
  bool parallel = false, // Deprecated, ignored
  DriverAdapter Function(String testDbName)? adapterFactory,

  //TODO
  //ModelRegistry reigstry
  //DriverAdapter adapter // remove datasource and create data source inside setupOrmed when needed dont accept user datasource
}) {
  final dbName = dataSource.options.name;

  // Generate a unique config key for this setUpOrmed call.
  // This ensures that even if multiple test files use the same DataSource name,
  // they get separate managers (unless they explicitly share one).
  final configKey = _generateConfigKey(dbName);

  // Create the configuration hash for collision detection
  final configHash = sha256
      .convert(
        utf8.encode(
          '$dbName:${migrations?.length ?? 0}:${migrationDescriptors?.length ?? 0}:$strategy',
        ),
      )
      .toString()
      .substring(0, 16);

  // Check for existing manager with same DataSource name.
  // For migrateWithTransactions, we WANT to share the provisioned database
  // across multiple test files (like Laravel's RefreshDatabase).
  // But each test file gets its own config key to track its lifecycle.
  TestDatabaseManager? manager;

  // Look for an existing manager that can be shared
  for (final entry in _managers.entries) {
    final existingManager = entry.value;
    if (existingManager.baseDataSource.options.name == dbName) {
      // Found an existing manager for the same database
      // Verify configurations match (same migrations, etc.)
      if (strategy == DatabaseIsolationStrategy.migrateWithTransactions) {
        // For migrateWithTransactions, we share the manager
        manager = existingManager;
        // Store under our config key as well
        _managers[configKey] = manager;
        break;
      } else {
        // For other strategies, we need separate databases per test file
        // So create a new manager
      }
    }
  }

  // Create new manager if we didn't find one to share
  if (manager == null) {
    manager = TestDatabaseManager(
      baseDataSource: dataSource,
      runMigrations: runMigrations,
      migrations: migrations,
      migrationDescriptors: migrationDescriptors,
      seeders: seeders,
      strategy: strategy,
      adapterFactory: adapterFactory,
    );
    _managers[configKey] = manager;
  }

  // Create the config object
  final config = OrmedTestConfig._(
    configKey: configKey,
    dataSourceName: dbName,
    configHash: configHash,
  );

  // Track as the last registered config for legacy fallback
  _lastRegisteredConfig = config;

  // Push to config stack
  _configStack.add(config);

  setUpAll(() async {
    await manager!.initialize();

    // For migrateWithTransactions: provision the base database ONCE at startup.
    // All test groups will reuse this database, using transaction rollback for isolation.
    // This is like Laravel's RefreshDatabase trait approach.
    // When multiple test files call setUpOrmed(), only the first one per database provisions it.
    if (strategy == DatabaseIsolationStrategy.migrateWithTransactions) {
      _databaseRefCount[dbName] = (_databaseRefCount[dbName] ?? 0) + 1;

      if (!_provisionedDatabases.containsKey(dbName)) {
        await manager.provisionDatabase(manager.baseDataSource);
        _provisionedDatabases[dbName] = dataSource;
      }
    }
  });

  tearDownAll(() async {
    // Remove from config stack
    _configStack.remove(config);
    if (_lastRegisteredConfig == config) {
      _lastRegisteredConfig = _configStack.isNotEmpty
          ? _configStack.last
          : null;
    }

    // Clean up the base database if we provisioned it
    if (strategy == DatabaseIsolationStrategy.migrateWithTransactions) {
      _databaseRefCount[dbName] = (_databaseRefCount[dbName] ?? 1) - 1;

      // Only drop the database when the last test file for this database cleans up
      if ((_databaseRefCount[dbName] ?? 0) <= 0 &&
          _provisionedDatabases.containsKey(dbName)) {
        try {
          await manager!.dropDatabase(manager.baseDataSource);
        } catch (_) {
          // Ignore cleanup errors
        }
        _provisionedDatabases.remove(dbName);
        _databaseRefCount.remove(dbName);
      }
    }
    await manager!.cleanup();
    _managers.remove(configKey);
  });

  return config;
}

/// Run a test with database isolation
///
/// Automatically sets up and tears down database state for each test.
/// The [DataSource] is passed to the test body.
///
/// ```dart
/// ormedTest('creates a user', (db) async {
///   final user = User(name: 'John');
///   await user.save(db); // Pass db explicitly if needed, or rely on context if models support it
///
///   expect(user.id, isNotNull);
/// });
/// ```
void ormedTest(
  String description,
  FutureOr<void> Function(DataSource dataSource) body, {
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
      final context = _currentGroupContext;

      // Resolve manager from context/config or fail
      final manager =
          context?.manager ??
          _currentZoneConfig?.manager ??
          _lastRegisteredConfig?.manager ??
          (_managers.isEmpty ? null : _managers.values.first);
      if (manager == null) {
        throw StateError(
          'Ormed test environment not initialized. '
          'ormedTest must be called within an ormedGroup, or call setUpOrmed() first.',
        );
      }

      DataSource dataSource;
      bool isStandalone = context == null;

      if (isStandalone) {
        // Standalone test: create fresh DB
        final testId = 'test_${DateTime.now().millisecondsSinceEpoch}';
        dataSource = await manager.createDatabase(testId);
        // Optional: begin transaction for consistency, though we drop DB anyway
        await dataSource.beginTransaction();
        dataSource.setAsDefault();
      } else {
        // Group test: use context's datasource
        if (context.dataSource == null) {
          // If strategy is recreate, dataSource might be null in context until setUp runs?
          // But ormedTest runs inside the test body, so setUp has run.
          // If strategy is recreate, setUp creates the DB.
          throw StateError(
            'Group DataSource not initialized. Check ormedGroup strategy.',
          );
        }
        dataSource = context.dataSource!;
        // Transaction management is handled by ormedGroup's setUp/tearDown
      }

      try {
        await body(dataSource);
      } finally {
        if (isStandalone) {
          await dataSource.rollback();
          await manager.dropDatabase(dataSource);
        }
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
/// ```dart
/// ormedGroup('User tests', (db) {
///   ormedTest('creates a user', (db) async {
///     // ...
///   });
/// });
/// ```
///
/// Pass [config] from [setUpOrmed] for explicit manager association:
/// ```dart
/// final config = setUpOrmed(dataSource: harness.dataSource, ...);
/// ormedGroup('User tests', (db) { ... }, config: config);
/// ```
@isTestGroup
void ormedGroup(
  String description,
  void Function(DataSource dataSource) body, {
  OrmedTestConfig? config,
  DataSource? dataSource, // Optional override
  List<Migration>? migrations, // Optional override
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
      // Resolve the manager to use
      late final TestDatabaseManager manager;
      late final OrmedTestConfig? resolvedConfig;

      // Priority for finding manager:
      // 1. Explicit config parameter
      // 2. Explicit dataSource parameter
      // 3. Parent group's context
      // 4. Current Zone's config
      // 5. Last registered config (legacy fallback)
      // 6. Any available manager (last resort)

      if (config != null) {
        // Explicit config provided - use it
        manager = config.manager;
        resolvedConfig = config;
      } else if (dataSource != null) {
        // Custom dataSource provided - look up its manager or find matching one
        resolvedConfig = null;
        final dsName = dataSource.options.name;

        // First, look for a manager registered for this dataSource
        TestDatabaseManager? foundManager;
        for (final entry in _managers.entries) {
          if (entry.value.baseDataSource.options.name == dsName) {
            foundManager = entry.value;
            break;
          }
        }

        if (foundManager == null) {
          throw StateError(
            'No manager found for DataSource "$dsName". '
            'Call setUpOrmed() with this DataSource first.',
          );
        }

        // Create a new manager with overrides if needed
        if (migrations != null || refreshStrategy != null) {
          manager = TestDatabaseManager(
            baseDataSource: dataSource,
            migrations: migrations ?? foundManager.migrations,
            migrationDescriptors: foundManager.migrationDescriptors,
            seeders: foundManager.seeders,
            strategy: refreshStrategy ?? foundManager.strategy,
            adapterFactory: foundManager.adapterFactory,
            runMigrations: foundManager.runMigrations,
          );
        } else {
          manager = foundManager;
        }
      } else if (_currentGroupContext?.config != null) {
        // Use parent group's config
        resolvedConfig = _currentGroupContext!.config;
        manager = resolvedConfig!.manager;
      } else if (_currentGroupContext != null) {
        // Use parent group's manager (no config)
        resolvedConfig = null;
        manager = _currentGroupContext!.manager;
      } else if (_currentZoneConfig != null) {
        // Use Zone-local config
        resolvedConfig = _currentZoneConfig;
        manager = resolvedConfig!.manager;
      } else if (_lastRegisteredConfig != null) {
        // Legacy fallback: use last registered config
        resolvedConfig = _lastRegisteredConfig;
        manager = resolvedConfig!.manager;
      } else if (_managers.isNotEmpty) {
        // Last resort: use any available manager
        resolvedConfig = null;
        manager = _managers.values.first;
        // Log a warning - this shouldn't happen in well-structured tests
        print(
          '[ormed_test] Warning: No explicit config found for ormedGroup "$description". '
          'Using first available manager. Consider passing config explicitly.',
        );
      } else {
        throw StateError(
          'No test manager available. Call setUpOrmed() in main() first, '
          'or pass config parameter to ormedGroup.',
        );
      }

      final strategy = refreshStrategy ?? manager.strategy;
      final groupId = 'group_${DateTime.now().millisecondsSinceEpoch}';

      // For migrateWithTransactions, we reuse the base DataSource (like Laravel's RefreshDatabase).
      final reuseBaseDataSource =
          strategy == DatabaseIsolationStrategy.migrateWithTransactions;

      late DataSource groupDataSource;
      if (reuseBaseDataSource) {
        // Reuse the base data source - much faster!
        groupDataSource = manager.baseDataSource;
      } else {
        // Create a new DataSource for this group
        groupDataSource = manager.createDataSource(groupId);
      }

      final context = _GroupContext(
        manager,
        strategy,
        groupId,
        config: resolvedConfig,
      );
      context.dataSource = groupDataSource;
      _currentGroupContext = context;

      if (dataSource != null) {
        setUpAll(() async {
          await manager.initialize();
        });
      }

      if (strategy == DatabaseIsolationStrategy.migrateWithTransactions) {
        setUp(() async {
          _currentGroupContext = context;
          await groupDataSource.beginTransaction();
          context.dataSource?.setAsDefault();
        });

        tearDown(() async {
          await groupDataSource.rollback();
          _currentGroupContext = null;
        });
      } else if (strategy == DatabaseIsolationStrategy.truncate) {
        setUpAll(() async {
          await manager.provisionDatabase(groupDataSource);
          context.dataSource = groupDataSource;
        });

        tearDownAll(() async {
          await manager.dropDatabase(groupDataSource);
          context.dataSource = null;
          _currentGroupContext = null;
        });

        setUp(() async {
          _currentGroupContext = context;
          final ds = context.dataSource ?? groupDataSource;
          final schemaManager = manager.getSchemaManager(ds);

          if (schemaManager != null) {
            // Reset schema to a clean state between tests
            await schemaManager.reset();
          } else {
            // Fallback: rerun migrations if no schema manager is available
            await manager.migrate(ds);
          }
          context.dataSource?.setAsDefault();
        });

        tearDown(() {
          _currentGroupContext = null;
        });
      } else if (strategy == DatabaseIsolationStrategy.recreate) {
        setUpAll(() async {
          await manager.provisionDatabase(groupDataSource);
          context.dataSource = groupDataSource;
        });

        tearDownAll(() async {
          await manager.dropDatabase(groupDataSource);
          context.dataSource = null;
          _currentGroupContext = null;
        });

        setUp(() async {
          _currentGroupContext = context;
          final ds = context.dataSource ?? groupDataSource;
          final schemaManager = manager.getSchemaManager(ds);

          if (schemaManager != null) {
            await schemaManager.reset();
          } else {
            await manager.migrate(ds);
          }
          context.dataSource?.setAsDefault();
        });

        tearDown(() {
          _currentGroupContext = null;
        });
      } else {
        // Fallback to truncate-like behaviour for unknown strategies
        setUpAll(() async {
          await manager.provisionDatabase(groupDataSource);
          context.dataSource = groupDataSource;
        });

        tearDownAll(() async {
          await manager.dropDatabase(groupDataSource);
          context.dataSource = null;
          _currentGroupContext = null;
        });

        setUp(() async {
          _currentGroupContext = context;
          final ds = context.dataSource ?? groupDataSource;
          final schemaManager = manager.getSchemaManager(ds);

          if (schemaManager != null) {
            await schemaManager.reset();
          } else {
            await manager.migrate(ds);
          }
          context.dataSource?.setAsDefault();
        });

        tearDown(() {
          _currentGroupContext = null;
        });
      }

      // Execute body to define tests
      body(groupDataSource);

      // Clear context after body execution (synchronous)
      _currentGroupContext = null;
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
///
/// Returns the manager from the current group context, or the first available
/// manager if not in a group context.
TestDatabaseManager? get testDatabaseManager {
  if (_currentGroupContext != null) {
    return _currentGroupContext!.manager;
  }
  return _managers.isEmpty ? null : _managers.values.first;
}

/// Get the current test data source (valid inside ormedGroup/ormedTest)
///
/// This is useful for accessing the datasource in `setUp` or `tearDown` blocks
/// within an `ormedGroup`.
DataSource? get currentTestDataSource => _currentGroupContext?.dataSource;

/// Seed data in the current test environment
Future<void> seedTestData(
  List<DatabaseSeeder Function(OrmConnection)> seeders,
  DataSource dataSource,
) async {
  final manager =
      _currentGroupContext?.manager ??
      _managers[dataSource.options.name] ??
      (_managers.isEmpty ? null : _managers.values.first);
  if (manager == null) {
    throw StateError('Ormed test environment not initialized.');
  }
  await manager.seed(seeders, dataSource);
}

/// Preview seeder queries without executing them
Future<List<QueryLogEntry>> previewTestSeed(
  List<DatabaseSeeder Function(OrmConnection)> seeders,
  DataSource dataSource,
) async {
  final manager =
      _currentGroupContext?.manager ??
      _managers[dataSource.options.name] ??
      (_managers.isEmpty ? null : _managers.values.first);
  if (manager == null) {
    throw StateError('Ormed test environment not initialized.');
  }
  return await manager.seedWithPretend(seeders, dataSource, pretend: true);
}

/// Get migration status in the test environment
Future<List<MigrationStatus>> testMigrationStatus(DataSource dataSource) async {
  final manager =
      _currentGroupContext?.manager ??
      _managers[dataSource.options.name] ??
      (_managers.isEmpty ? null : _managers.values.first);
  if (manager == null) {
    throw StateError('Ormed test environment not initialized.');
  }
  return await manager.migrationStatus(dataSource);
}
