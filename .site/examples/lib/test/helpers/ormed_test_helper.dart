import 'package:ormed/ormed.dart';
import 'package:ormed_examples/src/database/config.dart';
import 'package:ormed_examples/src/database/datasource.dart';

final Map<String, DataSource> _generatedTestDataSources = createDataSources();

final Map<String, OrmedTestConfig> _generatedTestConfigs =
    <String, OrmedTestConfig>{
      for (final entry in _generatedTestDataSources.entries)
        entry.key: setUpOrmed(
          dataSource: entry.value,
          migrations: const [_CreateTestUsersTable()],
        ),
    };

OrmedTestConfig testConfig({String? connection}) {
  final selectedConnection = (connection ?? defaultDataSourceConnection).trim();
  final selectedConfig = _generatedTestConfigs[selectedConnection];
  if (selectedConfig == null) {
    throw ArgumentError.value(
      selectedConnection,
      'connection',
      'Unknown generated datasource connection. Expected one of: default',
    );
  }
  return selectedConfig;
}

OrmConnection testConnection({String? connection}) {
  final selectedConnection = (connection ?? defaultDataSourceConnection).trim();
  if (!_generatedTestConfigs.containsKey(selectedConnection)) {
    throw ArgumentError.value(
      selectedConnection,
      'connection',
      'Unknown generated datasource connection. Expected one of: default',
    );
  }
  return ConnectionManager.instance.connection(selectedConnection);
}

/// Convenience test config for "default" connection.
final OrmedTestConfig defaultTestConfig = testConfig(connection: 'default');

/// Convenience test connection for "default".
OrmConnection defaultTestConnection() {
  return testConnection(connection: 'default');
}

class _CreateTestUsersTable extends Migration {
  const _CreateTestUsersTable();

  @override
  Future<void> up(SchemaBuilder schema) async {
    schema.create('users', (table) {
      table.integer('id').primaryKey().autoIncrement();
      table.string('email').unique();
      table.string('name');
    });
  }

  @override
  Future<void> down(SchemaBuilder schema) async {
    schema.drop('users', ifExists: true);
  }
}
