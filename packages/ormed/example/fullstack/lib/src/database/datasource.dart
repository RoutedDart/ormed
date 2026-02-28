import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:ormed_fullstack_example/src/database/orm_registry.g.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

// #region datasource-helper
/// Creates a new DataSource instance using generated helper options.
DataSource createDataSource() {
  final env = OrmedEnvironment.fromDirectory(Directory.current);
  final registry = bootstrapOrm();
  final path = env.string(
    'DB_PATH',
    fallback: 'database/ormed_fullstack_example.sqlite',
  );
  return DataSource(
    registry.sqliteFileDataSourceOptions(path: path, name: 'default'),
  );
}

// #endregion datasource-helper
