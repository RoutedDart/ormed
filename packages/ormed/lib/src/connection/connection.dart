import 'dart:math';

export 'connection_manager.dart';
export 'connection_resolver.dart';
export 'orm_connection.dart';

/// Indicates which connection role should be established.
enum ConnectionRole { primary, read, write }

/// Strategies for auto-generating table aliases in ad-hoc queries.
enum TableAliasStrategy { none, tableName, incremental }

extension ConnectionRoleX on ConnectionRole {
  bool get isReadRequest => this == ConnectionRole.read;

  bool get isWriteRequest =>
      this == ConnectionRole.primary || this == ConnectionRole.write;
}

const _unset = Object();

/// Immutable metadata describing how an ORM connection should be identified.
class ConnectionConfig {
  ConnectionConfig({
    required String name,
    this.database,
    this.tablePrefix = '',
    this.role = ConnectionRole.primary,
    Map<String, Object?>? options,
    this.defaultSchema,
    this.tableAliasStrategy = TableAliasStrategy.none,
  }) : name = _validateName(name),
       options = Map.unmodifiable(
         Map<String, Object?>.from(options ?? const {}),
       );

  /// Logical connection name (e.g. `primary`, `reporting`).
  final String name;

  /// Optional database/catalog identifier for observability.
  final String? database;

  /// Table prefix automatically applied by some schemas.
  final String tablePrefix;

  /// Role requested when establishing the connection.
  final ConnectionRole role;

  /// Arbitrary options forwarded to higher-level consumers.
  final Map<String, Object?> options;

  /// Default schema applied to ad-hoc tables when not specified.
  final String? defaultSchema;

  /// Strategy used when generating table aliases for ad-hoc queries.
  final TableAliasStrategy tableAliasStrategy;

  ConnectionConfig copyWith({
    String? name,
    Object? database = _unset,
    String? tablePrefix,
    ConnectionRole? role,
    Map<String, Object?>? options,
    Object? defaultSchema = _unset,
    TableAliasStrategy? tableAliasStrategy,
  }) => ConnectionConfig(
    name: name ?? this.name,
    database: identical(database, _unset) ? this.database : database as String?,
    tablePrefix: tablePrefix ?? this.tablePrefix,
    role: role ?? this.role,
    options: options ?? this.options,
    defaultSchema: identical(defaultSchema, _unset)
        ? this.defaultSchema
        : defaultSchema as String?,
    tableAliasStrategy: tableAliasStrategy ?? this.tableAliasStrategy,
  );

  static String _validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(
        value,
        'name',
        'Connection name cannot be empty',
      );
    }
    return trimmed;
  }
}

/// Endpoint configuration describing a single concrete connection target.
class DatabaseEndpoint {
  const DatabaseEndpoint({
    required this.driver,
    this.options = const {},
    this.name,
  });

  final String driver;
  final Map<String, Object?> options;
  final String? name;

  DatabaseEndpoint copyWith({
    String? driver,
    Map<String, Object?>? options,
    String? name,
  }) => DatabaseEndpoint(
    driver: driver ?? this.driver,
    options: options ?? this.options,
    name: name ?? this.name,
  );
}

/// High-level database configuration that may include read replicas.
class DatabaseConfig extends DatabaseEndpoint {
  const DatabaseConfig({
    required super.driver,
    super.options,
    super.name,
    this.replicas = const [],
  });

  final List<DatabaseEndpoint> replicas;

  DatabaseEndpoint endpointFor(ConnectionRole role, [Random? random]) {
    final wantsReplica = role == ConnectionRole.read;
    final shouldUsePrimary =
        !wantsReplica || replicas.isEmpty || role == ConnectionRole.write;
    if (shouldUsePrimary) {
      return DatabaseEndpoint(driver: driver, options: options, name: name);
    }
    final rng = random ?? Random();
    final index = rng.nextInt(replicas.length);
    return replicas[index];
  }
}

/// Metadata describing a materialized connection handle.
class ConnectionMetadata {
  const ConnectionMetadata({
    required this.driver,
    required this.role,
    this.description,
  });

  final String driver;
  final ConnectionRole role;
  final String? description;
}

/// Handle returned by connectors. Wraps a client and exposes a close callback.
class ConnectionHandle<TClient> {
  ConnectionHandle({
    required this.client,
    required this.metadata,
    Future<void> Function()? onClose,
  }) : _onClose = onClose;

  final TClient client;
  final ConnectionMetadata metadata;
  final Future<void> Function()? _onClose;
  bool _closed = false;

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    final onClose = _onClose;
    if (onClose != null) {
      await onClose();
    }
  }
}

/// Connector implementations build concrete connections for a driver.
abstract class Connector<TClient> {
  Future<ConnectionHandle<TClient>> connect(
    DatabaseEndpoint endpoint,
    ConnectionRole role,
  );
}

typedef ConnectorBuilder = Connector Function();

/// Factory that dispatches to registered connectors based on driver type.
class ConnectionFactory {
  ConnectionFactory({Map<String, ConnectorBuilder>? connectors})
    : _connectors = {...?connectors};

  final Map<String, ConnectorBuilder> _connectors;

  void register(String driver, ConnectorBuilder builder) {
    _connectors[driver] = builder;
  }

  Future<ConnectionHandle<dynamic>> open(
    DatabaseConfig config, {
    ConnectionRole role = ConnectionRole.primary,
    Random? random,
  }) async {
    final endpoint = config.endpointFor(role, random);
    final builder = _connectors[endpoint.driver];
    if (builder == null) {
      throw StateError(
        'No connector registered for driver "${endpoint.driver}".',
      );
    }
    final connector = builder();
    return connector.connect(endpoint, role);
  }
}
