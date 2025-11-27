import 'dart:async';
import 'dart:math';

import 'package:ormed/src/connection/connection.dart';
import 'package:test/test.dart';

void main() {
  group('DatabaseConfig', () {
    test('returns primary endpoint when no replicas configured', () {
      const config = DatabaseConfig(
        driver: 'sqlite',
        options: {'path': 'app.db'},
      );
      final endpoint = config.endpointFor(ConnectionRole.primary);
      expect(endpoint.driver, 'sqlite');
      expect(endpoint.options['path'], 'app.db');
    });

    test('returns replica when available', () {
      const config = DatabaseConfig(
        driver: 'postgres',
        replicas: [
          DatabaseEndpoint(driver: 'postgres', options: {'host': 'read-1'}),
          DatabaseEndpoint(driver: 'postgres', options: {'host': 'read-2'}),
        ],
      );
      final endpoint = config.endpointFor(ConnectionRole.read, _MockRandom());
      expect(endpoint.options['host'], 'read-1');
    });
  });

  group('ConnectionFactory', () {
    test('throws when driver missing', () async {
      final factory = ConnectionFactory();
      expect(
        () => factory.open(const DatabaseConfig(driver: 'unknown')),
        throwsStateError,
      );
    });

    test('registers and opens connector', () async {
      final factory = ConnectionFactory();
      factory.register('sqlite', () => _CountingConnector());
      final handle = await factory.open(const DatabaseConfig(driver: 'sqlite'));
      expect(handle.metadata.driver, 'sqlite');
      await handle.close();
    });
  });

  group('ConnectionConfig', () {
    test('applies defaults', () {
      final config = ConnectionConfig(name: 'primary');
      expect(config.name, 'primary');
      expect(config.database, isNull);
      expect(config.tablePrefix, isEmpty);
      expect(config.role, ConnectionRole.primary);
      expect(config.options, isEmpty);
    });

    test('throws when name empty', () {
      expect(() => ConnectionConfig(name: '   '), throwsArgumentError);
    });

    test('clones options defensively', () {
      final original = {'pool': 5};
      final config = ConnectionConfig(name: 'primary', options: original);
      original['pool'] = 10;
      expect(config.options['pool'], 5);
      expect(() => config.options['pool'] = 1, throwsUnsupportedError);
    });

    test('supports copyWith overrides', () {
      final base = ConnectionConfig(
        name: 'primary',
        database: 'app',
        tablePrefix: 'tenant_',
        role: ConnectionRole.primary,
        defaultSchema: 'public',
        tableAliasStrategy: TableAliasStrategy.tableName,
      );
      final copy = base.copyWith(
        name: 'reporting',
        role: ConnectionRole.read,
        tablePrefix: 'custom_',
        options: const {'readonly': true},
        defaultSchema: 'analytics',
        tableAliasStrategy: TableAliasStrategy.incremental,
      );
      expect(copy.name, 'reporting');
      expect(copy.database, 'app');
      expect(copy.role, ConnectionRole.read);
      expect(copy.tablePrefix, 'custom_');
      expect(copy.options['readonly'], isTrue);
      expect(copy.defaultSchema, 'analytics');
      expect(copy.tableAliasStrategy, TableAliasStrategy.incremental);
    });

    test('copyWith can null database', () {
      final base = ConnectionConfig(name: 'primary', database: 'app');
      final copy = base.copyWith(database: null);
      expect(copy.database, isNull);
    });
  });
}

class _MockRandom implements Random {
  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0.0;

  @override
  int nextInt(int max) => 0;
}

class _CountingConnector extends Connector<int> {
  _CountingConnector();

  @override
  Future<ConnectionHandle<int>> connect(
    DatabaseEndpoint endpoint,
    ConnectionRole role,
  ) async {
    return ConnectionHandle<int>(
      client: 1,
      metadata: ConnectionMetadata(driver: endpoint.driver, role: role),
    );
  }
}
