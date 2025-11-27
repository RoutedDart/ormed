/// Tests for orchestrating `DriverRegistry` entries through `registerConnectionsFromConfig`.
library;

import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  const driverType = 'fake-driver-registry-test';

  setUpAll(() {
    DriverRegistry.registerDriver(driverType, ({
      required Directory root,
      required ConnectionManager manager,
      required ModelRegistry registry,
      required String connectionName,
      required ConnectionDefinition definition,
    }) {
      final connectionConfig = ConnectionConfig(name: connectionName);
      manager.register(
        connectionName,
        connectionConfig,
        (_) =>
            throw StateError('Connection builder should not run during tests.'),
      );
      return OrmConnectionHandle(name: connectionName, manager: manager);
    });
  });

  group('registerConnectionsFromConfig', () {
    late Directory root;

    setUp(() {
      root = Directory.systemTemp.createTempSync(
        'ormed_connection_registration_test',
      );
    });

    tearDown(() {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });

    test('registers every tenant and returns the selected handle', () async {
      final config = OrmProjectConfig.fromMap(_multiTenantConfig(driverType));
      final manager = ConnectionManager();

      final handle = await registerConnectionsFromConfig(
        root: root,
        config: config,
        manager: manager,
        targetConnection: 'analytics',
      );

      final analyticsConfig = config.withConnection('analytics');
      final expectedAnalyticsName = connectionNameForConfig(
        root,
        analyticsConfig,
      );
      expect(handle.name, equals(expectedAnalyticsName));

      for (final entry in config.connections.entries) {
        final expectedName = connectionNameForConfig(
          root,
          config.withConnection(entry.key),
        );
        expect(
          manager.isRegistered(expectedName),
          isTrue,
          reason: 'Connection ${entry.key} should be registered',
        );
      }
    });

    test('throws when a driver handler is missing', () {
      final config = OrmProjectConfig.fromMap(
        _multiTenantConfig('missing-driver'),
      );
      final manager = ConnectionManager();
      expect(
        registerConnectionsFromConfig(
          root: root,
          config: config,
          manager: manager,
        ),
        throwsStateError,
      );
    });
  });
}

Map<String, Object?> _multiTenantConfig(String driverType) => {
  'default_connection': 'primary',
  'connections': {
    'primary': {
      'driver': {'type': driverType, 'options': <String, Object?>{}},
      'migrations': _migrationSection(),
    },
    'analytics': {
      'driver': {'type': driverType, 'options': <String, Object?>{}},
      'migrations': _migrationSection(),
    },
  },
};

Map<String, Object?> _migrationSection() => {
  'directory': 'database/migrations',
  'registry': 'database/migrations.dart',
  'ledger_table': 'orm_migrations',
  'schema_dump': 'database/schema.sql',
};
