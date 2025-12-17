import 'dart:async';

import 'connection.dart';

typedef OrmConnectionBuilder = OrmConnection Function(ConnectionConfig config);
typedef ConnectionReleaseHook =
    FutureOr<void> Function(OrmConnection connection);

class ConnectionManager {
  ConnectionManager();

  static final ConnectionManager defaultManager = ConnectionManager();

  /// Convenience getter for accessing the default manager instance.
  static ConnectionManager get instance => defaultManager;

  final Map<String, Map<ConnectionRole?, _ConnectionRegistration>>
  _registrations = {};

  String? _defaultConnectionName;

  void register(
    String name,
    ConnectionConfig config,
    OrmConnectionBuilder factory, {
    ConnectionRole? role,
    bool singleton = true,
    ConnectionReleaseHook? onRelease,
  }) {
    final normalized = name.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        name,
        'name',
        'Connection name cannot be empty',
      );
    }
    final effectiveConfig = role == null ? config : config.copyWith(role: role);
    final family = _registrations.putIfAbsent(
      normalized,
      () => <ConnectionRole?, _ConnectionRegistration>{},
    );
    family[role] = _ConnectionRegistration(
      config: effectiveConfig,
      factory: factory,
      singleton: singleton,
      onRelease: onRelease,
    );
  }

  OrmConnection connection(
    String name, {
    ConnectionRole role = ConnectionRole.primary,
  }) {
    final registration = _resolve(name, role);
    if (registration.singleton) {
      return registration.instance ??= registration.factory(
        registration.config,
      );
    }
    return registration.factory(registration.config);
  }

  bool isRegistered(String name) => _registrations.containsKey(name.trim());

  Future<void> unregister(String name) async {
    final registrationFamily = _registrations.remove(name.trim());
    if (registrationFamily == null) return;
    for (final registration in registrationFamily.values) {
      final instance = registration.instance;
      if (instance != null) {
        final release = registration.onRelease;
        if (release != null) {
          await release(instance);
        }
        await instance.driver.close();
      }
    }
  }

  /// Returns every registered connection name.
  Iterable<String> get registeredConnectionNames =>
      List.unmodifiable(_registrations.keys);

  /// Sets the default connection name used by Model static helpers.
  /// This connection will be used when no connection is explicitly specified.
  void setDefaultConnection(String name) {
    final normalized = name.trim();
    if (!isRegistered(normalized)) {
      throw ArgumentError.value(
        name,
        'name',
        'Connection must be registered before setting as default',
      );
    }
    _defaultConnectionName = normalized;
  }

  /// Gets the default connection name, or null if none is set.
  String? get defaultConnectionName => _defaultConnectionName;

  /// Returns true if a default connection has been set.
  bool get hasDefaultConnection => _defaultConnectionName != null;

  /// Gets the default connection, or throws if none is set.
  OrmConnection get defaultConnection {
    final name = _defaultConnectionName;
    if (name == null) {
      throw StateError(
        'No default connection set. Call setDefaultConnection() first.',
      );
    }
    return connection(name);
  }

  /// Clears the default connection (useful for testing).
  void clearDefault() {
    _defaultConnectionName = null;
  }

  Future<T> use<T>(
    String name,
    FutureOr<T> Function(OrmConnection connection) action, {
    ConnectionRole role = ConnectionRole.primary,
  }) async {
    final registration = _resolve(name, role);
    if (registration.singleton) {
      final conn = connection(name, role: role);
      return await action(conn);
    }
    final conn = registration.factory(registration.config);
    try {
      return await action(conn);
    } finally {
      final release = registration.onRelease;
      if (release != null) {
        await release(conn);
      }
    }
  }

  T useSync<T>(
    String name,
    T Function(OrmConnection connection) action, {
    ConnectionRole role = ConnectionRole.primary,
  }) {
    final registration = _resolve(name, role);
    if (registration.singleton) {
      final conn = connection(name, role: role);
      return action(conn);
    }
    final conn = registration.factory(registration.config);
    try {
      return action(conn);
    } finally {
      final release = registration.onRelease;
      if (release != null) {
        final result = release(conn);
        if (result is Future) {
          throw StateError(
            'Release hook returned a Future in useSync. Use use() instead.',
          );
        }
      }
    }
  }

  _ConnectionRegistration _resolve(String name, ConnectionRole role) {
    final normalized = name.trim();
    final family = _registrations[normalized];
    if (family == null) {
      throw StateError(
        'No connection named $normalized registered. Call register(...) first.',
      );
    }
    final registration = family[role] ?? family[null];
    if (registration == null) {
      throw StateError(
        'Connection $normalized does not define a factory for role $role.',
      );
    }
    return registration;
  }
}

class _ConnectionRegistration {
  _ConnectionRegistration({
    required this.config,
    required this.factory,
    required this.singleton,
    this.onRelease,
  });

  final ConnectionConfig config;
  final OrmConnectionBuilder factory;
  final bool singleton;
  final ConnectionReleaseHook? onRelease;
  OrmConnection? instance;
}
