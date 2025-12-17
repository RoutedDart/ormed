import 'package:ormed/ormed.dart';
import 'package:test/test.dart';
import 'dart:io';

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
        'format': 'sql',
      },
      'seeds': {
        'directory': 'database/seeders',
        'registry': 'database/seeders.dart',
      },
    };

    final config = OrmProjectConfig.fromMap(payload);
    expect(config.connections.keys, ['default']);
    expect(config.connectionName, 'default');
    expect(config.driver.option('database'), 'default.sqlite');
    expect(config.migrations.directory, 'database/migrations');
    expect(config.migrations.format, MigrationFormat.sql);
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
    expect(config.migrations.format, MigrationFormat.dart);
    final primary = config.withConnection('default');
    expect(primary.connectionName, 'default');
  });

  test('environment variables expand inside orm.yaml', () async {
    final tmpDir = await Directory.systemTemp.createTemp('ormed_config_test');
    final configFile = File('${tmpDir.path}/orm.yaml');
    final pathValue = Platform.environment['PATH'] ?? '';
    configFile.writeAsStringSync('''
driver:
  type: sqlite
  options:
    database: \${PATH}
    missing: \${NOT_SET_ENV:-fallback}
migrations:
  directory: migrations
  registry: migrations.dart
''');

    final config = loadOrmProjectConfig(configFile);
    expect(config.driver.option('database'), pathValue);
    expect(config.driver.options['missing'], 'fallback');
    await tmpDir.delete(recursive: true);
  });
}
