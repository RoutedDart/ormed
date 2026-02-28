import 'package:ormed/ormed.dart';

import 'config.dart';

/// Creates a new DataSource using driver-specific helper options.
// #region datasource-create-single
DataSource createDataSource({DataSourceOptions? options, String? connection}) {
  return DataSource(options ?? buildDataSourceOptions(connection: connection));
}
// #endregion datasource-create-single

/// Creates DataSources for every generated connection.
// #region datasource-create-multiple
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
// #endregion datasource-create-multiple

/// Convenience helper for "default" connection.
// #region datasource-create-default
DataSource createDefaultDataSource({DataSourceOptions? options}) {
  return DataSource(options ?? buildDefaultDataSourceOptions());
}

// #endregion datasource-create-default
