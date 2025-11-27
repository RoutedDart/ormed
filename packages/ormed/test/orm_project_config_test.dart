import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  test('single connection map can be read and written', () {
    final payload = {
      'driver': {
        'type': 'sqlite',
        'options': {'database': 'default.sqlite'},
      },
      'migrations': {
        'directory': 'database/migrations',
        'registry': 'database/migrations.dart',
        'ledger_table': 'orm_migrations',
      },
      'seeds': {
        'directory': 'database/seeders',
        'registry': 'database/seeders.dart',
        'default_class': 'DatabaseSeeder',
      },
    };

    final config = OrmProjectConfig.fromMap(payload);
    expect(config.connections.keys, ['default']);
    expect(config.connectionName, 'default');
    expect(config.driver.option('database'), 'default.sqlite');
    expect(config.migrations.directory, 'database/migrations');
    expect(config.seeds, isNotNull);
    expect(config.toMap(), containsPair('driver', payload['driver']));
  });

  test('multi-tenant map respects default connection', () {
    final payload = {
      'default_connection': 'analytics',
      'connections': {
        'default': {
          'driver': {
            'type': 'sqlite',
            'options': {'database': 'primary.sqlite'},
          },
          'migrations': {
            'directory': 'database/migrations',
            'registry': 'database/migrations.dart',
            'ledger_table': 'orm_migrations',
          },
        },
        'analytics': {
          'driver': {
            'type': 'sqlite',
            'options': {'database': 'analytics.sqlite'},
          },
          'migrations': {
            'directory': 'database/migrations',
            'registry': 'database/migrations.dart',
            'ledger_table': 'orm_migrations',
          },
        },
      },
    };

    final config = OrmProjectConfig.fromMap(payload);
    expect(config.connections.keys, containsAll(['default', 'analytics']));
    expect(config.connectionName, 'analytics');
    final primary = config.withConnection('default');
    expect(primary.connectionName, 'default');
  });
}
