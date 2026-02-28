// SQL migration workflows used in documentation.
// ignore_for_file: unused_local_variable

import 'dart:io';

import 'package:ormed/migrations.dart';
import 'package:ormed/ormed.dart';

// #region migration-sql-file-entry
final entry = MigrationEntry(
  id: MigrationId.parse('m_20250101000000_create_users_table'),
  migration: SqlFileMigration(
    upPath: 'migrations/m_20250101000000_create_users_table/up.sql',
    downPath: 'migrations/m_20250101000000_create_users_table/down.sql',
  ),
);
// #endregion migration-sql-file-entry

// #region migration-sql-exporter
Future<void> exportSqlForMigration({
  required SchemaDriver schemaDriver,
  required MigrationDescriptor descriptor,
}) async {
  final exporter = MigrationSqlExporter(schemaDriver);
  await exporter.exportDescriptor(
    descriptor,
    outputRoot: Directory('database/migration_sql'),
  );
}
// #endregion migration-sql-exporter
