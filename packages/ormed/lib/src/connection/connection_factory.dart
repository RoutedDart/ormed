import 'connection.dart';
import 'connection_handle.dart';
import 'connection_manager.dart';

/// Registers named ORM connections and returns disposable handles.
class OrmConnectionFactory {
  OrmConnectionFactory({ConnectionManager? manager})
    : manager = manager ?? ConnectionManager.defaultManager;

  final ConnectionManager manager;

  /// Registers a connection with [manager] and returns a handle for usage.
  OrmConnectionHandle register({
    required String name,
    required ConnectionConfig connection,
    required OrmConnectionBuilder builder,
    bool singleton = true,
    ConnectionRole? role,
    ConnectionReleaseHook? onRelease,
  }) {
    manager.register(
      name,
      connection,
      (_) => builder(connection),
      role: role,
      singleton: singleton,
      onRelease: onRelease,
    );
    return OrmConnectionHandle(name: name, manager: manager);
  }
}
