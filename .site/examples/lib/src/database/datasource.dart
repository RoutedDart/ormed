import 'package:ormed/ormed.dart';

import 'config.dart';

/// Creates a new DataSource using driver-specific helper options.
DataSource createDataSource({DataSourceOptions? options, String? connection}) {
  return DataSource(options ?? buildDataSourceOptions(connection: connection));
}

/// Creates DataSources for every generated connection.
Map<String, DataSource> createDataSources({
  Map<String, DataSourceOptions> overrides = const {},
}) {
  final sources = <String, DataSource>{};
  for (final connection in generatedDataSourceConnections) {
    final options =
        overrides[connection] ?? buildDataSourceOptions(connection: connection);
    sources[connection] = DataSource(options);
  }
  return sources;
}

/// Convenience helper for "default" connection.
DataSource createDefaultDataSource({DataSourceOptions? options}) {
  return DataSource(options ?? buildDefaultDataSourceOptions());
}
