/// Manages the playground's configured connections and seeded registry.
library;

import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:orm_playground/orm_registry.g.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';
import 'package:path/path.dart' as p;

final _ = registerSqliteOrmConnection;

/// Helper that wires the playground into `ConnectionManager` via `orm.yaml`.
class PlaygroundDatabase {
  /// Creates a helper that wires every connection defined in [orm.yaml].
  factory PlaygroundDatabase({Directory? workspaceRoot}) {
    final root = workspaceRoot ?? Directory.current;
    final configFile = File(p.join(root.path, 'orm.yaml'));
    final config = loadOrmProjectConfig(configFile);
    final path = _deriveDatabasePath(root, config);
    return PlaygroundDatabase._(
      root: root,
      config: config,
      registry: buildOrmRegistry(),
      databasePath: path,
    );
  }

  PlaygroundDatabase._({
    required this.root,
    required OrmProjectConfig config,
    required ModelRegistry registry,
    required this.databasePath,
  }) : _config = config,
       _registry = registry;

  /// Directory that contains `orm.yaml`.
  final Directory root;

  /// Default SQLite path derived from the active connection or overrides.
  final String databasePath;

  final OrmProjectConfig _config;
  final ModelRegistry _registry;
  final Set<String> _registeredConnections = {};
  bool _connectionsRegistered = false;

  /// Opens the configured connection for [tenant].
  Future<OrmConnection> open({String tenant = 'default'}) async {
    await _ensureRegistered();
    final connectionName = _connectionNameForTenant(tenant);
    return ConnectionManager.defaultManager.connection(connectionName);
  }

  /// Releases every registered connection.
  Future<void> dispose() async {
    if (!_connectionsRegistered) return;
    final manager = ConnectionManager.defaultManager;
    final names = List<String>.from(_registeredConnections);
    for (final connectionName in names) {
      await manager.unregister(connectionName);
      _registeredConnections.remove(connectionName);
    }
    _connectionsRegistered = false;
  }

  Future<void> _ensureRegistered() async {
    if (_connectionsRegistered) return;
    _bootstrapPlaygroundDrivers();
    final manager = ConnectionManager.defaultManager;
    final before = manager.registeredConnectionNames.toSet();
    await registerConnectionsFromConfig(
      root: root,
      config: _config,
      registry: _registry,
    );
    final after = manager.registeredConnectionNames.toSet();
    _registeredConnections.addAll(after.difference(before));
    _connectionsRegistered = true;
  }

  String _connectionNameForTenant(String tenant) =>
      connectionNameForConfig(root, _config.withConnection(tenant));

  bool _playgroundDriversBootstrapped = false;

  void _bootstrapPlaygroundDrivers() {
    if (_playgroundDriversBootstrapped) return;
    _playgroundDriversBootstrapped = true;
    ensureSqliteDriverRegistration();
  }

  static String _deriveDatabasePath(Directory root, OrmProjectConfig config) {
    final configured = config.activeConnection.driver.option('database');
    if (configured != null && configured.isNotEmpty) {
      return p.normalize(p.join(root.path, configured));
    }
    return _defaultDatabasePath(root);
  }

  static String _defaultDatabasePath(Directory root) {
    final override = Platform.environment['PLAYGROUND_DB'];
    if (override != null && override.isNotEmpty) {
      return p.normalize(override);
    }
    final workspaceDatabase = File(
      p.join(root.path, 'orm_playground', 'database.sqlite'),
    );
    if (workspaceDatabase.existsSync()) {
      return workspaceDatabase.path;
    }
    return p.normalize(p.join(root.path, 'database.sqlite'));
  }
}
