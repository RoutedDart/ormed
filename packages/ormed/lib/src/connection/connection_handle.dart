import 'dart:async';

import 'connection.dart';

/// Lightweight handle returned when registering a named [OrmConnection].
class OrmConnectionHandle {
  OrmConnectionHandle({required this.name, ConnectionManager? manager})
    : manager = manager ?? ConnectionManager.defaultManager;

  final String name;
  final ConnectionManager manager;

  /// Runs [action] using the registered connection.
  Future<T> use<T>(
    FutureOr<T> Function(OrmConnection connection) action, {
    ConnectionRole role = ConnectionRole.primary,
  }) => manager.use(name, action, role: role);

  /// Runs [action] synchronously using the registered connection.
  T useSync<T>(
    T Function(OrmConnection connection) action, {
    ConnectionRole role = ConnectionRole.primary,
  }) => manager.useSync(name, action, role: role);

  /// Returns the connection instance for [role], registering it if necessary.
  OrmConnection connection({ConnectionRole role = ConnectionRole.primary}) =>
      manager.connection(name, role: role);

  /// Unregisters the connection and disposes any cached resources.
  Future<void> dispose() => manager.unregister(name);
}
