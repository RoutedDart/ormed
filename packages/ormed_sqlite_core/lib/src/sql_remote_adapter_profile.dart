import 'package:ormed/ormed.dart';

import 'sqlite_codecs.dart';
import 'sqlite_grammar.dart';
import 'sqlite_schema_dialect.dart';
import 'sqlite_type_mapper.dart';

/// Builds a query grammar after the adapter has created its extension registry.
typedef SqlRemoteGrammarFactory =
    QueryGrammar Function(
      Map<String, Object?> options,
      DriverExtensionRegistry extensions,
    );

/// Normalizes values before they are passed to a remote SQL executor.
typedef SqlRemoteParameterNormalizer =
    List<Object?> Function(List<Object?> values);

/// Identifies tables affected by a raw SQL write.
typedef SqlRemoteChangeParser = DatabaseChange? Function(String sql);

/// Builds bindings for schema introspection queries.
typedef SqlRemoteSchemaParameterFactory =
    List<Object?> Function(String operation, String? table, String? schema);

/// Describes the SQL-specific pieces needed by [SqliteRemoteAdapterBase].
///
/// The historical base name is retained for source compatibility with the
/// SQLite adapters. The profile keeps execution and ORM-plan plumbing shared
/// while allowing backends such as PostgreSQL to provide their own grammar,
/// schema dialect, codecs, parameter normalization, and change parser.
class SqlRemoteAdapterProfile {
  const SqlRemoteAdapterProfile({
    required this.createGrammar,
    required this.schemaDialect,
    required this.typeMapper,
    required this.normalizeParameters,
    required this.changeForSql,
    this.prepareSql = _identitySql,
    this.schemaQueryParameters = _emptySchemaParameters,
    this.capabilities = const {},
    this.supportsQueryDeletes = true,
    this.requiresPrimaryKeyForQueryUpdate = false,
    this.queryUpdateRowIdentifier = const QueryRowIdentifier(
      column: 'rowid',
      expression: 'rowid',
    ),
    this.defaultSchema = 'main',
    this.ignoreSystemTables = false,
    this.supportsRealSchemas = false,
    this.dropTablesWithCascade = false,
    this.insertUsesUpdate = false,
    this.insertPrefix = _defaultInsertPrefix,
    this.insertConflictSuffix = _defaultInsertConflictSuffix,
    this.registerCodecs = registerDriverCodecs,
  });

  /// Creates the query grammar for this backend.
  final SqlRemoteGrammarFactory createGrammar;

  /// Schema mutation and introspection dialect.
  final SchemaDialect schemaDialect;

  /// Type mapper used to register the adapter's value codecs.
  final DriverTypeMapper typeMapper;

  /// Parameter normalization applied before execution.
  final SqlRemoteParameterNormalizer normalizeParameters;

  /// Change parser used by raw and proxied executor writes.
  final SqlRemoteChangeParser changeForSql;

  /// Rewrites Ormed's portable placeholders for a concrete executor.
  final String Function(String sql) prepareSql;

  /// Returns bindings for schema introspection operations.
  final SqlRemoteSchemaParameterFactory schemaQueryParameters;

  /// Default driver capabilities for this SQL backend.
  final Set<DriverCapability> capabilities;

  /// Whether query-driven deletes are supported.
  final bool supportsQueryDeletes;

  /// Whether query-driven updates require an explicit primary key.
  final bool requiresPrimaryKeyForQueryUpdate;

  /// Fallback row identifier for tables without a primary key.
  final QueryRowIdentifier? queryUpdateRowIdentifier;

  /// Default namespace used by schema operations.
  final String defaultSchema;

  /// Whether generic table listing should filter backend system tables.
  final bool ignoreSystemTables;

  /// Whether schema operations address real database namespaces.
  final bool supportsRealSchemas;

  /// Whether dropping all tables should include `CASCADE`.
  final bool dropTablesWithCascade;

  /// Whether INSERT statements should use the update path to obtain affected
  /// row counts. Drift's PostgreSQL executor exposes affected rows through
  /// `runUpdate`, while SQLite's `runInsert` has SQLite-specific semantics.
  final bool insertUsesUpdate;

  /// Builds the start of an INSERT statement.
  final String Function(bool ignoreConflicts) insertPrefix;

  /// Builds an optional suffix for an INSERT that ignores conflicts.
  final String Function(bool ignoreConflicts) insertConflictSuffix;

  /// Registers codecs for the adapter's driver name.
  final void Function(String driverName, DriverTypeMapper mapper)
  registerCodecs;

  /// The standard SQLite profile used by existing adapters.
  factory SqlRemoteAdapterProfile.sqlite() => SqlRemoteAdapterProfile(
    createGrammar: (options, extensions) => SqliteQueryGrammar(
      supportsWindowFunctions: _resolveWindowFunctions(options),
      extensions: extensions,
    ),
    schemaDialect: const SqliteSchemaDialect(),
    typeMapper: SqliteTypeMapper(),
    normalizeParameters: normalizeSqliteParameters,
    changeForSql: sqliteDatabaseChangeForSql,
    capabilities: {
      DriverCapability.joins,
      DriverCapability.insertUsing,
      DriverCapability.queryDeletes,
      DriverCapability.schemaIntrospection,
      DriverCapability.adHocQueryUpdates,
      DriverCapability.rawSQL,
      DriverCapability.increment,
      DriverCapability.relationAggregates,
      DriverCapability.caseInsensitiveLike,
      DriverCapability.transactions,
    },
    defaultSchema: 'main',
    ignoreSystemTables: true,
  );
}

bool _resolveWindowFunctions(Map<String, Object?> options) {
  final override =
      _boolOption(options, 'supportsWindowFunctions') ??
      _boolOption(options, 'windowFunctions') ??
      _boolOption(options, 'supports_window_functions');
  return override ?? true;
}

bool? _boolOption(Map<String, Object?> options, String key) {
  final value = options[key];
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    switch (value.trim().toLowerCase()) {
      case '1':
      case 'true':
      case 'yes':
      case 'on':
        return true;
      case '0':
      case 'false':
      case 'no':
      case 'off':
        return false;
    }
  }
  return null;
}

String _defaultInsertPrefix(bool ignoreConflicts) =>
    ignoreConflicts ? 'INSERT OR IGNORE' : 'INSERT';

String _defaultInsertConflictSuffix(bool ignoreConflicts) => '';

String _identitySql(String sql) => sql;

List<Object?> _emptySchemaParameters(
  String operation,
  String? table,
  String? schema,
) => const [];

/// Returns the tables affected by a SQLite-like write statement.
DatabaseChange? sqliteDatabaseChangeForSql(String sql) {
  final operation = _leadingSqlVerb(sql);
  const writeOperations = {
    'INSERT',
    'REPLACE',
    'UPDATE',
    'DELETE',
    'WITH',
    'CREATE',
    'ALTER',
    'DROP',
    'REINDEX',
    'VACUUM',
  };
  if (!writeOperations.contains(operation)) return null;

  final table = switch (operation) {
    'INSERT' || 'REPLACE' => _captureSqlTable(
      sql,
      RegExp(r'\bINTO\s+([^\s(]+)', caseSensitive: false),
    ),
    'UPDATE' => _captureSqlTable(
      sql,
      RegExp(r'^\s*UPDATE(?:\s+OR\s+\w+)?\s+([^\s(]+)', caseSensitive: false),
    ),
    'DELETE' => _captureSqlTable(
      sql,
      RegExp(r'\bFROM\s+([^\s(]+)', caseSensitive: false),
    ),
    'CREATE' || 'ALTER' || 'DROP' => _captureSqlTable(
      sql,
      RegExp(
        r'\bTABLE(?:\s+IF\s+(?:NOT\s+)?EXISTS)?\s+([^\s(]+)',
        caseSensitive: false,
      ),
    ),
    'REINDEX' => _captureSqlTable(
      sql,
      RegExp(r'^\s*REINDEX(?:\s+[^\s]+)?\s+([^\s;]+)', caseSensitive: false),
    ),
    'VACUUM' => null,
    _ => null,
  };
  if (table == null || table.isEmpty) return DatabaseChange.all();
  return DatabaseChange(tables: [table]);
}

String? _captureSqlTable(String sql, RegExp pattern) =>
    pattern.firstMatch(sql)?.group(1);

String _leadingSqlVerb(String sql) {
  final match = RegExp(r'^\s*([A-Za-z]+)').firstMatch(sql);
  return match?.group(1)?.toUpperCase() ?? '';
}

/// Registers codecs derived from a driver type mapper.
void registerDriverCodecs(String driverName, DriverTypeMapper mapper) {
  final codecs = <String, ValueCodec<dynamic>>{};
  for (final mapping in mapper.typeMappings) {
    final codec = mapping.codec;
    if (codec == null) continue;
    final typeKey = mapping.dartType.toString();
    codecs[typeKey] = codec;
    codecs['$typeKey?'] = codec;
    if (mapping.dartType == Map) {
      codecs['Map<String, Object?>'] = codec;
      codecs['Map<String, Object?>?'] = codec;
      codecs['Map<String, dynamic>'] = codec;
      codecs['Map<String, dynamic>?'] = codec;
    }
  }
  ValueCodecRegistry.instance.registerDriver(driverName, codecs);
}
