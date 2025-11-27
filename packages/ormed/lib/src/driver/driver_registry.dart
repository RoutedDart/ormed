/// Provides a centralized table for driver-specific connection registration.
library;

import 'dart:async';
import 'dart:io';

import '../connection/connection_handle.dart';
import '../connection/connection_manager.dart';
import '../model_registry.dart';
import '../orm_project_config.dart';

/// Signature used by drivers to register an `OrmConnection` for a tenant.
typedef DriverRegistration =
    FutureOr<OrmConnectionHandle> Function({
      required Directory root,
      required ConnectionManager manager,
      required ModelRegistry registry,
      required String connectionName,
      required ConnectionDefinition definition,
    });

/// Registry of driver callbacks keyed by normalized driver type.
class DriverRegistry {
  DriverRegistry._();

  static final Map<String, DriverRegistration> _registry = {};

  /// Registers [handler] for [driverType].
  static void registerDriver(String driverType, DriverRegistration handler) {
    final normalized = driverType.toLowerCase();
    if (_registry.containsKey(normalized)) {
      throw StateError('Driver $normalized is already registered.');
    }
    _registry[normalized] = handler;
  }

  /// Returns the handler for [driverType] or throws if missing.
  static DriverRegistration driver(String driverType) {
    final normalized = driverType.toLowerCase();
    final handler = _registry[normalized];
    if (handler == null) {
      throw StateError('Driver $normalized is not registered.');
    }
    return handler;
  }

  /// Whether a handler exists for [driverType].
  static bool contains(String driverType) =>
      _registry.containsKey(driverType.toLowerCase());
}
