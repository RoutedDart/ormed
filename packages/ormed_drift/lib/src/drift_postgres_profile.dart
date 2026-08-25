import 'package:ormed/ormed.dart';
import 'package:ormed_postgres/ormed_postgres.dart';
import 'package:ormed_sqlite_core/ormed_sqlite_core.dart';

/// Creates the PostgreSQL profile used by [DriftDriverAdapter.postgres].
SqlRemoteAdapterProfile createDriftPostgresProfile() => SqlRemoteAdapterProfile(
  createGrammar: (_, extensions) =>
      PostgresQueryGrammar(extensions: extensions),
  schemaDialect: const PostgresSchemaDialect(),
  typeMapper: PostgresTypeMapper(),
  normalizeParameters: _normalizePostgresParameters,
  prepareSql: _preparePostgresSql,
  schemaQueryParameters: _postgresSchemaParameters,
  changeForSql: sqliteDatabaseChangeForSql,
  capabilities: {
    DriverCapability.joins,
    DriverCapability.insertUsing,
    DriverCapability.queryDeletes,
    DriverCapability.schemaIntrospection,
    DriverCapability.threadCount,
    DriverCapability.transactions,
    DriverCapability.adHocQueryUpdates,
    DriverCapability.increment,
    DriverCapability.relationAggregates,
    DriverCapability.caseInsensitiveLike,
    DriverCapability.distinctOn,
    DriverCapability.rightJoin,
    DriverCapability.rawSQL,
    DriverCapability.advancedQueryBuilders,
    DriverCapability.sqlPreviews,
    DriverCapability.databaseManagement,
    DriverCapability.foreignKeyConstraintControl,
  },
  requiresPrimaryKeyForQueryUpdate: false,
  queryUpdateRowIdentifier: const QueryRowIdentifier(
    column: 'ctid',
    expression: 'ctid',
  ),
  defaultSchema: 'public',
  supportsRealSchemas: true,
  dropTablesWithCascade: true,
  insertUsesUpdate: true,
  insertPrefix: (_) => 'INSERT',
  insertConflictSuffix: (ignore) => ignore ? ' ON CONFLICT DO NOTHING' : '',
  registerCodecs: (driverName, mapper) {
    registerDriverCodecs(driverName, mapper);
    if (driverName == 'postgres') {
      registerPostgresCodecs();
    }
  },
);

List<Object?> _normalizePostgresParameters(List<Object?> values) =>
    values.map(_normalizePostgresValue).toList(growable: false);

Object? _normalizePostgresValue(Object? value) {
  if (value is TypedValue) return _normalizePostgresValue(value.value);
  if (value is DateTime) return value.toUtc().toIso8601String();
  if (value is BigInt) return value.toInt();
  if (value is Iterable) {
    return value.map(_normalizePostgresValue).toList(growable: false);
  }
  return value;
}

List<Object?> _postgresSchemaParameters(
  String operation,
  String? table,
  String? schema,
) {
  if (operation == 'schemas') {
    return schema == null ? const [] : [schema];
  }
  if (operation == 'tables' || operation == 'views') {
    return schema == null ? const [] : [schema];
  }
  if (table == null) return const [];
  return schema == null ? [table] : [table, schema];
}

String _preparePostgresSql(String sql) {
  final buffer = StringBuffer();
  var index = 0;
  var inLiteral = false;
  for (var i = 0; i < sql.length; i++) {
    final char = sql[i];
    final next = i + 1 < sql.length ? sql[i + 1] : null;
    if (char == "'") {
      if (next == "'") {
        buffer.write("''");
        i++;
        continue;
      }
      inLiteral = !inLiteral;
      buffer.write(char);
      continue;
    }
    if (char == '?' && !inLiteral) {
      index++;
      buffer
        ..write(r'$')
        ..write(index);
    } else {
      buffer.write(char);
    }
  }
  return buffer.toString();
}
