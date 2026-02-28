import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:ormed_examples/src/database/orm_registry.g.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

/// Code-first runtime DataSource configuration used by [createDataSource].
/// Keep `ormed.yaml` for CLI migration/seed workflows when needed.
const String defaultDataSourceConnection = 'default';

/// Connections baked into this generated scaffold.
const List<String> generatedDataSourceConnections = <String>['default'];

DataSourceOptions buildDataSourceOptions({String? connection}) {
  final env = OrmedEnvironment.fromDirectory(Directory.current);
  final registry = bootstrapOrm();
  final selectedConnection = (connection ?? defaultDataSourceConnection).trim();
  switch (selectedConnection) {
    case 'default':
      final path = env.string(
        'DB_PATH',
        fallback: 'database/ormed_examples.sqlite',
      );
      return registry.sqliteFileDataSourceOptions(path: path, name: 'default');
    default:
      throw ArgumentError.value(
        selectedConnection,
        'connection',
        'Unknown generated datasource connection. Expected one of: default',
      );
  }
}

/// Builds DataSource options for all generated connections.
Map<String, DataSourceOptions> buildAllDataSourceOptions() {
  final options = <String, DataSourceOptions>{};
  for (final connection in generatedDataSourceConnections) {
    options[connection] = buildDataSourceOptions(connection: connection);
  }
  return options;
}

/// Convenience helper for "default" connection.
DataSourceOptions buildDefaultDataSourceOptions() {
  return buildDataSourceOptions(connection: 'default');
}
