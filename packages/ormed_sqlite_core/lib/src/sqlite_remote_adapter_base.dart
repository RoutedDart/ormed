library;

import 'dart:convert';

import 'package:ormed/ormed.dart';

import 'sqlite_codecs.dart';
import 'sqlite_grammar.dart';
import 'sqlite_schema_dialect.dart';
import 'sqlite_type_mapper.dart';

/// Registers SQLite-like codecs and type mapper under a custom driver name.
void registerSqliteLikeDriverCodecs(String driverName) {
  final mapper = SqliteTypeMapper();
  TypeMapperRegistry.register(driverName, mapper);

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

/// Resolves whether SQLite window-function SQL should be emitted.
bool resolveSqliteLikeSupportsWindowFunctions(Map<String, Object?> options) {
  final override =
      _boolOption(options, 'supportsWindowFunctions') ??
      _boolOption(options, 'windowFunctions') ??
      _boolOption(options, 'supports_window_functions');
  return override ?? true;
}

/// Resolves whether RETURNING clauses should be emitted.
bool resolveSqliteLikeSupportsReturning(Map<String, Object?> options) {
  final override =
      _boolOption(options, 'supportsReturning') ??
      _boolOption(options, 'returning') ??
      _boolOption(options, 'supports_returning');
  return override ?? true;
}

/// Shared base for SQLite-like adapters that execute compiled SQL remotely.
///
/// Concrete adapters only need to provide:
/// - statement execution (`executeStatement`)
/// - statement querying (`queryStatement`)
/// - backend close (`closeBackend`)
abstract class SqliteRemoteAdapterBase
    implements DriverAdapter, DriverExtensionHost, SchemaDriver {
  SqliteRemoteAdapterBase({
    required String driverName,
    required Map<String, Object?> options,
    required Set<DriverCapability> capabilities,
    required bool supportsQueryDeletes,
    required bool requiresPrimaryKeyForQueryUpdate,
    required QueryRowIdentifier queryUpdateRowIdentifier,
    List<DriverExtension> extensions = const [],
  }) : _driverName = driverName,
       _options = options,
       _extensions = DriverExtensionRegistry(
         driverName: driverName,
         extensions: extensions,
       ),
       _codecs = ValueCodecRegistry.instance.forDriver(driverName) {
    registerSqliteLikeDriverCodecs(driverName);

    final supportsReturning = resolveSqliteLikeSupportsReturning(options);
    _metadata = DriverMetadata(
      name: driverName,
      supportsReturning: supportsReturning,
      supportsQueryDeletes: supportsQueryDeletes,
      requiresPrimaryKeyForQueryUpdate: requiresPrimaryKeyForQueryUpdate,
      queryUpdateRowIdentifier: queryUpdateRowIdentifier,
      identifierQuote: '"',
      capabilities: {
        ...capabilities,
        if (supportsReturning) DriverCapability.returning,
      },
    );

    _grammar = SqliteQueryGrammar(
      supportsWindowFunctions: resolveSqliteLikeSupportsWindowFunctions(
        options,
      ),
      extensions: _extensions,
    );

    _schemaCompiler = SchemaPlanCompiler(const SqliteSchemaDialect());
    _planCompiler = ClosurePlanCompiler(
      compileSelect: _compileSelectPreview,
      compileMutation: _compileMutationPreview,
    );
  }

  final String _driverName;
  final Map<String, Object?> _options;
  final DriverExtensionRegistry _extensions;
  final ValueCodecRegistry _codecs;

  late final DriverMetadata _metadata;
  late final SqliteQueryGrammar _grammar;
  late final SchemaPlanCompiler _schemaCompiler;
  late final PlanCompiler _planCompiler;

  bool _closed = false;
  String _currentSchema = 'main';

  /// Executes a non-query SQL statement.
  Future<int> executeStatement(String sql, List<Object?> parameters);

  /// Executes a query SQL statement and returns raw rows.
  Future<List<Map<String, Object?>>> queryStatement(
    String sql,
    List<Object?> parameters,
  );

  /// Closes backend-specific resources.
  Future<void> closeBackend();

  @override
  PlanCompiler get planCompiler => _planCompiler;

  @override
  DriverMetadata get metadata => _metadata;

  @override
  ValueCodecRegistry get codecs => _codecs;

  @override
  DriverExtensionRegistry get driverExtensions => _extensions;

  /// Driver options used to configure the adapter backend.
  Map<String, Object?> get options => _options;

  /// Name of the current driver instance.
  String get driverName => _driverName;

  @override
  void registerExtensions(Iterable<DriverExtension> extensions) {
    _extensions.registerAll(extensions);
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await closeBackend();
  }

  @override
  Future<void> executeRaw(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    _ensureOpen();
    await executeStatement(sql, normalizeSqliteParameters(parameters));
  }

  @override
  Future<List<Map<String, Object?>>> queryRaw(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    _ensureOpen();
    return queryStatement(sql, normalizeSqliteParameters(parameters));
  }

  @override
  Future<List<Map<String, Object?>>> execute(QueryPlan plan) async {
    _ensureOpen();
    final compilation = _grammar.compileSelect(plan);
    final rows = await queryStatement(
      compilation.sql,
      normalizeSqliteParameters(compilation.bindings),
    );
    return rows
        .map((row) => _decodeRowValues(plan.definition, row))
        .toList(growable: false);
  }

  @override
  Stream<Map<String, Object?>> stream(QueryPlan plan) async* {
    _ensureOpen();
    final compilation = _grammar.compileSelect(plan);
    final rows = await queryStatement(
      compilation.sql,
      normalizeSqliteParameters(compilation.bindings),
    );
    for (final row in rows) {
      yield _decodeRowValues(plan.definition, row);
    }
  }

  @override
  StatementPreview describeQuery(QueryPlan plan) =>
      _planCompiler.compileSelect(plan);

  @override
  StatementPreview describeMutation(MutationPlan plan) =>
      _planCompiler.compileMutation(plan);

  StatementPreview _compileSelectPreview(QueryPlan plan) {
    final compilation = _grammar.compileSelect(plan);
    final normalized = normalizeSqliteParameters(compilation.bindings);
    final resolved = _grammar.substituteBindingsIntoRawSql(
      compilation.sql,
      normalized.map(_codecs.encodeValue).toList(growable: false),
    );
    return StatementPreview(
      payload: SqlStatementPayload(
        sql: compilation.sql,
        parameters: normalized,
      ),
      resolvedText: resolved,
    );
  }

  StatementPreview _compileMutationPreview(MutationPlan plan) {
    final shape = _shapeForPlan(plan);
    final first = shape.parameterSets.isEmpty
        ? const <Object?>[]
        : normalizeSqliteParameters(shape.parameterSets.first);
    final resolved = _grammar.substituteBindingsIntoRawSql(
      shape.sql,
      first.map(_codecs.encodeValue).toList(growable: false),
    );
    return StatementPreview(
      payload: SqlStatementPayload(sql: shape.sql, parameters: first),
      parameterSets: shape.parameterSets,
      resolvedText: resolved,
    );
  }

  @override
  Future<MutationResult> runMutation(MutationPlan plan) async {
    _ensureOpen();
    final shape = _shapeForPlan(plan);
    var affectedRows = 0;
    final returnedRows = <Map<String, Object?>>[];

    for (final parameterSet in shape.parameterSets) {
      final normalized = normalizeSqliteParameters(parameterSet);
      if (shape.returning) {
        final rows = await queryStatement(shape.sql, normalized);
        returnedRows.addAll(
          rows.map((row) => _decodeRowValues(plan.definition, row)),
        );
        affectedRows += rows.length;
      } else {
        affectedRows += await executeStatement(shape.sql, normalized);
      }
    }

    return MutationResult(
      affectedRows: affectedRows,
      returnedRows: returnedRows.isEmpty ? null : returnedRows,
    );
  }

  @override
  Future<R> transaction<R>(Future<R> Function() action) async => action();

  @override
  Future<void> beginTransaction() async {
    throw UnsupportedError('$driverName does not support beginTransaction().');
  }

  @override
  Future<void> commitTransaction() async {
    throw UnsupportedError('$driverName does not support commitTransaction().');
  }

  @override
  Future<void> rollbackTransaction() async {
    throw UnsupportedError(
      '$driverName does not support rollbackTransaction().',
    );
  }

  @override
  Future<void> truncateTable(String tableName) async {
    await withoutForeignKeyConstraints(() async {
      await executeRaw('DELETE FROM ${_quote(tableName)}');
    });
  }

  @override
  Future<void> applySchemaPlan(SchemaPlan plan) async {
    final preview = describeSchemaPlan(plan);
    for (final statement in preview.statements) {
      await executeRaw(statement.sql, statement.parameters);
    }
  }

  @override
  SchemaPreview describeSchemaPlan(SchemaPlan plan) =>
      _schemaCompiler.compile(plan);

  @override
  Future<int?> threadCount() async => null;

  @override
  Future<List<SchemaNamespace>> listSchemas() async {
    final sql = _schemaCompiler.dialect.compileSchemas();
    if (sql == null) {
      return const <SchemaNamespace>[
        SchemaNamespace(name: 'main', isDefault: true),
      ];
    }

    final rows = await queryRaw(sql);
    if (rows.isEmpty) {
      return const <SchemaNamespace>[
        SchemaNamespace(name: 'main', isDefault: true),
      ];
    }

    return rows
        .map((row) {
          final name = (row['name'] as String?) ?? 'main';
          final owner = (row['file'] ?? row['path']) as String?;
          final defaultFlag = row['default'];
          final isDefault = switch (defaultFlag) {
            num value => value != 0,
            bool value => value,
            _ => name.toLowerCase() == 'main',
          };
          return SchemaNamespace(
            name: name,
            owner: owner,
            isDefault: isDefault,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<List<SchemaTable>> listTables({String? schema}) async {
    final targetSchema = _schemaOrDefault(schema);
    final sql = _schemaCompiler.dialect.compileTables(schema: targetSchema);
    if (sql == null) {
      throw UnsupportedError('$driverName should support table listing.');
    }

    final rows = await queryRaw(sql);
    return rows
        .where((row) {
          final name = row['name']?.toString() ?? '';
          return !name.startsWith('sqlite_');
        })
        .map((row) {
          final resolvedSchema = row['schema'] as String? ?? targetSchema;
          return SchemaTable(
            name: row['name'] as String,
            schema: _exposedSchema(_schemaOrDefault(resolvedSchema)),
            type: row['type'] as String?,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<List<SchemaView>> listViews({String? schema}) async {
    final targetSchema = _schemaOrDefault(schema);
    final sql = _schemaCompiler.dialect.compileViews(schema: targetSchema);
    if (sql == null) {
      throw UnsupportedError('$driverName should support view listing.');
    }

    final rows = await queryRaw(sql);
    return rows
        .map((row) {
          final resolvedSchema = row['schema'] as String? ?? targetSchema;
          return SchemaView(
            name: row['name'] as String,
            schema: _exposedSchema(_schemaOrDefault(resolvedSchema)),
            definition: (row['definition'] as String?) ?? row['sql'] as String?,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<List<SchemaColumn>> listColumns(String table, {String? schema}) async {
    final sql = _schemaCompiler.dialect.compileColumns(table, schema: schema);
    if (sql == null) {
      throw UnsupportedError('$driverName should support column listing.');
    }

    final rows = (await queryRaw(
      sql,
    )).where((row) => (row['cid'] as int? ?? 0) >= 0);
    return rows
        .map((row) {
          final nullableFlag = row['nullable'];
          final nullable = switch (nullableFlag) {
            num value => value != 0,
            bool value => value,
            _ => (row['notnull'] as int? ?? 0) == 0,
          };
          final defaultValue = row.containsKey('default')
              ? row['default']
              : row['dflt_value'];
          final primaryFlag = row['primary'];
          final primary = switch (primaryFlag) {
            num value => value != 0,
            bool value => value,
            _ => (row['pk'] as int? ?? 0) > 0,
          };
          return SchemaColumn(
            name: row['name'] as String,
            dataType: (row['type'] as String?) ?? 'TEXT',
            schema: _exposedSchema(_schemaOrDefault(schema)),
            tableName: table,
            nullable: nullable,
            defaultValue: _normalizeDefault(defaultValue),
            autoIncrement: false,
            primaryKey: primary,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<List<SchemaIndex>> listIndexes(String table, {String? schema}) async {
    final sql = _schemaCompiler.dialect.compileIndexes(table, schema: schema);
    if (sql == null) {
      throw UnsupportedError('$driverName should support index listing.');
    }

    final rows = await queryRaw(sql);
    final indexes = <SchemaIndex>[];
    for (final row in rows) {
      final name = row['name'] as String;
      if (name.startsWith('sqlite_')) {
        continue;
      }
      final columns = _splitColumns(row['columns']).isNotEmpty
          ? _splitColumns(row['columns'])
          : await _indexColumns(name, schema: schema);
      final partialFlag = row['partial'];
      final partial = switch (partialFlag) {
        num value => value != 0,
        bool value => value,
        _ => false,
      };
      final whereClause = partial
          ? await _indexWhereClause(name, schema: schema)
          : null;
      final uniqueFlag = row['unique'];
      final unique = switch (uniqueFlag) {
        num value => value != 0,
        bool value => value,
        _ => false,
      };
      final primaryFlag = row['primary'];
      final primary = switch (primaryFlag) {
        num value => value != 0,
        bool value => value,
        _ => false,
      };
      indexes.add(
        SchemaIndex(
          name: name,
          columns: columns,
          schema: _exposedSchema(_schemaOrDefault(schema)),
          tableName: table,
          unique: unique,
          primary: primary,
          whereClause: whereClause,
        ),
      );
    }
    return indexes;
  }

  @override
  Future<List<SchemaForeignKey>> listForeignKeys(
    String table, {
    String? schema,
  }) async {
    final sql = _schemaCompiler.dialect.compileForeignKeys(
      table,
      schema: schema,
    );
    if (sql == null) {
      throw UnsupportedError('$driverName should support foreign key listing.');
    }

    final rows = await queryRaw(sql);
    var counter = 0;
    return rows
        .map((row) {
          counter += 1;
          final columns = _splitColumns(row['columns']);
          final foreignColumns = _splitColumns(row['foreign_columns']);
          final foreignSchema = row['foreign_schema'] as String?;
          return SchemaForeignKey(
            name: 'fk_${table}_$counter',
            columns: columns,
            tableName: table,
            referencedTable: row['foreign_table'] as String,
            referencedColumns: foreignColumns,
            schema: _exposedSchema(_schemaOrDefault(schema)),
            referencedSchema: _exposedSchema(foreignSchema),
            onUpdate: row['on_update'] as String?,
            onDelete: row['on_delete'] as String?,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<bool> createDatabase(
    String name, {
    Map<String, Object?>? options,
  }) async {
    throw UnsupportedError('$driverName manages databases externally.');
  }

  @override
  Future<bool> dropDatabase(String name) async {
    throw UnsupportedError('$driverName manages databases externally.');
  }

  @override
  Future<bool> dropDatabaseIfExists(String name) async {
    throw UnsupportedError('$driverName manages databases externally.');
  }

  @override
  Future<List<String>> listDatabases() async {
    throw UnsupportedError(
      '$driverName does not expose database catalog listing here.',
    );
  }

  @override
  Future<bool> createSchema(String name) async {
    _currentSchema = name;
    return true;
  }

  @override
  Future<bool> dropSchemaIfExists(String name) async {
    if (_currentSchema == name) {
      _currentSchema = 'main';
    }
    return false;
  }

  @override
  Future<void> setCurrentSchema(String name) async {
    _currentSchema = name;
  }

  @override
  Future<String> getCurrentSchema() async => _currentSchema;

  @override
  Future<bool> enableForeignKeyConstraints() async {
    final sql = _schemaCompiler.dialect.compileEnableForeignKeyConstraints();
    if (sql == null) {
      throw UnsupportedError(
        '$driverName should support FK constraint management.',
      );
    }
    await executeRaw(sql);
    return true;
  }

  @override
  Future<bool> disableForeignKeyConstraints() async {
    final sql = _schemaCompiler.dialect.compileDisableForeignKeyConstraints();
    if (sql == null) {
      throw UnsupportedError(
        '$driverName should support FK constraint management.',
      );
    }
    await executeRaw(sql);
    return true;
  }

  @override
  Future<T> withoutForeignKeyConstraints<T>(
    Future<T> Function() callback,
  ) async {
    await disableForeignKeyConstraints();
    try {
      return await callback();
    } finally {
      await enableForeignKeyConstraints();
    }
  }

  @override
  Future<void> dropAllTables({String? schema}) async {
    final tables = await listTables(schema: schema);
    if (tables.isEmpty) return;
    await disableForeignKeyConstraints();
    try {
      for (final table in tables) {
        await executeRaw('DROP TABLE IF EXISTS ${_quote(table.name)}');
      }
    } finally {
      await enableForeignKeyConstraints();
    }
  }

  @override
  Future<bool> hasTable(String table, {String? schema}) async {
    final tables = await listTables(schema: schema);
    return tables.any((t) => t.name.toLowerCase() == table.toLowerCase());
  }

  @override
  Future<bool> hasView(String view, {String? schema}) async {
    final views = await listViews(schema: schema);
    return views.any((v) => v.name.toLowerCase() == view.toLowerCase());
  }

  @override
  Future<bool> hasColumn(String table, String column, {String? schema}) async {
    final columns = await listColumns(table, schema: schema);
    return columns.any((c) => c.name.toLowerCase() == column.toLowerCase());
  }

  @override
  Future<bool> hasColumns(
    String table,
    List<String> columns, {
    String? schema,
  }) async {
    final tableColumns = await listColumns(table, schema: schema);
    final lowerCaseColumns = tableColumns
        .map((c) => c.name.toLowerCase())
        .toSet();
    for (final column in columns) {
      if (!lowerCaseColumns.contains(column.toLowerCase())) {
        return false;
      }
    }
    return true;
  }

  @override
  Future<bool> hasIndex(
    String table,
    String index, {
    String? schema,
    String? type,
  }) async {
    final indexes = await listIndexes(table, schema: schema);
    for (final idx in indexes) {
      final typeMatches =
          type == null ||
          (type == 'primary' && idx.primary) ||
          (type == 'unique' && idx.unique) ||
          type.toLowerCase() == idx.type?.toLowerCase();
      if (idx.name.toLowerCase() == index.toLowerCase() && typeMatches) {
        return true;
      }
    }
    return false;
  }

  _SqliteLikeMutationShape _shapeForPlan(MutationPlan plan) {
    switch (plan.operation) {
      case MutationOperation.insert:
        return _buildInsertShape(plan);
      case MutationOperation.insertUsing:
        return _buildInsertUsingShape(plan);
      case MutationOperation.update:
        return _buildUpdateShape(plan);
      case MutationOperation.delete:
        return _buildDeleteShape(plan);
      case MutationOperation.queryDelete:
        return _buildQueryDeleteShape(plan);
      case MutationOperation.queryUpdate:
        return _buildQueryUpdateShape(plan);
      case MutationOperation.upsert:
        return _buildUpsertShape(plan);
    }
  }

  _SqliteLikeMutationShape _buildInsertShape(MutationPlan plan) {
    if (plan.rows.isEmpty) {
      return const _SqliteLikeMutationShape(
        sql: '',
        parameterSets: <List<Object?>>[],
        returning: false,
      );
    }

    final columns = plan.definition.fields
        .where((field) {
          var provided = false;
          var hasNonZeroAuto = false;
          for (final row in plan.rows) {
            if (!row.values.containsKey(field.columnName)) {
              continue;
            }
            provided = true;
            if (field.autoIncrement) {
              final value = row.values[field.columnName];
              if (value != null && value != 0) {
                hasNonZeroAuto = true;
                break;
              }
            }
          }
          if (!provided) return false;
          if (!field.autoIncrement) return true;
          return hasNonZeroAuto;
        })
        .map((field) => field.columnName)
        .toList(growable: false);

    if (columns.isEmpty) {
      return const _SqliteLikeMutationShape(
        sql: '',
        parameterSets: <List<Object?>>[],
        returning: false,
      );
    }

    final table = _qualifiedTable(
      plan.definition.tableName,
      plan.definition.schema,
    );
    final ignore = plan.ignoreConflicts ? ' OR IGNORE' : '';
    final placeholders = List.filled(columns.length, '?').join(', ');
    final returning = plan.returning ? ' RETURNING *' : '';
    final sql =
        'INSERT$ignore INTO $table (${columns.map(_quote).join(', ')}) VALUES ($placeholders)$returning';

    final parameterSets = plan.rows
        .map(
          (row) => columns
              .map(
                (column) => _encodeValueForColumn(
                  definition: plan.definition,
                  column: column,
                  value: row.values[column],
                ),
              )
              .toList(growable: false),
        )
        .toList(growable: false);

    return _SqliteLikeMutationShape(
      sql: sql,
      parameterSets: parameterSets,
      returning: plan.returning,
    );
  }

  _SqliteLikeMutationShape _buildInsertUsingShape(MutationPlan plan) {
    final queryPlan = plan.queryPlan;
    if (queryPlan == null || plan.insertColumns.isEmpty) {
      return const _SqliteLikeMutationShape(
        sql: '',
        parameterSets: <List<Object?>>[],
        returning: false,
      );
    }
    final compilation = _grammar.compileSelect(queryPlan);
    final table = _qualifiedTable(
      plan.definition.tableName,
      plan.definition.schema,
    );
    final ignore = plan.ignoreConflicts ? ' OR IGNORE' : '';
    final columns = plan.insertColumns.map(_quote).join(', ');
    final projectedColumns = plan.insertColumns.map(_quote).join(', ');
    final wrappedSelect =
        'SELECT $projectedColumns FROM (${compilation.sql}) AS __source__';
    final sql = StringBuffer()
      ..write('INSERT$ignore INTO $table ($columns) ')
      ..write(wrappedSelect);
    return _SqliteLikeMutationShape(
      sql: sql.toString(),
      parameterSets: <List<Object?>>[
        compilation.bindings.toList(growable: false),
      ],
      returning: false,
    );
  }

  _SqliteLikeMutationShape _buildUpdateShape(MutationPlan plan) {
    if (plan.rows.isEmpty) {
      return const _SqliteLikeMutationShape(
        sql: '',
        parameterSets: <List<Object?>>[],
        returning: false,
      );
    }

    final first = plan.rows.first;
    final table = _qualifiedTable(
      plan.definition.tableName,
      plan.definition.schema,
    );
    final setColumns = first.values.keys.toList(growable: false);
    final jsonTemplates = _jsonUpdateTemplates(first);
    if (setColumns.isEmpty && jsonTemplates.isEmpty) {
      return const _SqliteLikeMutationShape(
        sql: '',
        parameterSets: <List<Object?>>[],
        returning: false,
      );
    }

    final assignments = <String>[];
    if (setColumns.isNotEmpty) {
      assignments.addAll(setColumns.map((column) => '${_quote(column)} = ?'));
    }
    assignments.addAll(jsonTemplates.map((template) => template.sql));
    final keyColumns = first.keys.keys.toList(growable: false);
    final whereSql = _whereClause(first.keys);
    final returning = plan.returning ? ' RETURNING *' : '';
    final sql =
        'UPDATE $table SET ${assignments.join(', ')} WHERE $whereSql$returning';

    final parameterSets = plan.rows
        .map((row) {
          final params = <Object?>[];
          for (final column in setColumns) {
            params.add(
              _encodeValueForColumn(
                definition: plan.definition,
                column: column,
                value: row.values[column],
              ),
            );
          }
          if (jsonTemplates.isNotEmpty) {
            final clauses = row.jsonUpdates;
            _validateJsonUpdateShape(jsonTemplates, clauses);
            final grouped = <String, List<JsonUpdateClause>>{};
            for (final clause in clauses) {
              grouped
                  .putIfAbsent(clause.column, () => <JsonUpdateClause>[])
                  .add(clause);
            }
            for (final template in jsonTemplates) {
              final columnClauses = grouped[template.column]!;
              var expression = _quote(template.column);
              for (final clause in columnClauses) {
                final compiled = clause.patch
                    ? _grammar.compileJsonPatch(
                        clause.column,
                        expression,
                        clause.value,
                      )
                    : _grammar.compileJsonUpdate(
                        clause.column,
                        expression,
                        clause.path,
                        clause.value,
                      );
                expression = _assignmentRhs(compiled.sql);
                params.addAll(compiled.bindings);
              }
            }
          }
          for (final column in keyColumns) {
            params.add(
              _encodeValueForColumn(
                definition: plan.definition,
                column: column,
                value: row.keys[column],
              ),
            );
          }
          return params;
        })
        .toList(growable: false);

    return _SqliteLikeMutationShape(
      sql: sql,
      parameterSets: parameterSets,
      returning: plan.returning,
    );
  }

  _SqliteLikeMutationShape _buildDeleteShape(MutationPlan plan) {
    if (plan.rows.isEmpty) {
      return const _SqliteLikeMutationShape(
        sql: '',
        parameterSets: <List<Object?>>[],
        returning: false,
      );
    }

    final first = plan.rows.first;
    if (first.keys.isEmpty) {
      throw StateError('Delete rows require keys.');
    }

    final table = _qualifiedTable(
      plan.definition.tableName,
      plan.definition.schema,
    );
    final keyColumns = first.keys.keys.toList(growable: false);
    final whereSql = _whereClause(first.keys);
    final returning = plan.returning ? ' RETURNING *' : '';
    final sql = 'DELETE FROM $table WHERE $whereSql$returning';

    final parameterSets = plan.rows
        .map(
          (row) => keyColumns
              .map(
                (column) => _encodeValueForColumn(
                  definition: plan.definition,
                  column: column,
                  value: row.keys[column],
                ),
              )
              .toList(growable: false),
        )
        .toList(growable: false);

    return _SqliteLikeMutationShape(
      sql: sql,
      parameterSets: parameterSets,
      returning: plan.returning,
    );
  }

  _SqliteLikeMutationShape _buildQueryDeleteShape(MutationPlan plan) {
    final queryPlan = plan.queryPlan;
    if (queryPlan == null) {
      return const _SqliteLikeMutationShape(
        sql: '',
        parameterSets: <List<Object?>>[],
        returning: false,
      );
    }

    String? primaryKey =
        plan.queryPrimaryKey ?? plan.definition.primaryKeyField?.columnName;
    QueryPlan projectionPlan = queryPlan;
    if (primaryKey == null || primaryKey.isEmpty) {
      final identifier = _metadata.queryUpdateRowIdentifier;
      if (identifier == null) {
        throw StateError(
          'Query deletes on ${plan.definition.modelName} require a primary key.',
        );
      }
      primaryKey = identifier.column;
      projectionPlan = _rowIdentifierProjection(
        queryPlan,
        primaryKey,
        expression: identifier.expression,
      );
    } else if (plan.definition.primaryKeyField == null) {
      projectionPlan = _rowIdentifierProjection(queryPlan, primaryKey);
    }

    final compilation = _grammar.compileSelect(projectionPlan);
    final table = _qualifiedTable(
      plan.definition.tableName,
      plan.definition.schema,
    );
    final pkSql = _quote(primaryKey);
    final outerRef = primaryKey == 'rowid' ? 'ROWID' : pkSql;
    final sql = StringBuffer('DELETE FROM ')
      ..write(table)
      ..write(' WHERE ')
      ..write(outerRef)
      ..write(' IN (SELECT ')
      ..write(pkSql)
      ..write(' FROM (')
      ..write(compilation.sql)
      ..write(') AS "__orm_delete_source")');
    if (plan.returning) {
      sql.write(' RETURNING *');
    }

    return _SqliteLikeMutationShape(
      sql: sql.toString(),
      parameterSets: <List<Object?>>[
        compilation.bindings.toList(growable: false),
      ],
      returning: plan.returning,
    );
  }

  _SqliteLikeMutationShape _buildQueryUpdateShape(MutationPlan plan) {
    final queryPlan = plan.queryPlan;
    final hasColumns = plan.queryUpdateValues.isNotEmpty;
    final hasJson = plan.queryJsonUpdates.isNotEmpty;
    final hasIncrements = plan.queryIncrementValues.isNotEmpty;
    if (queryPlan == null || (!hasColumns && !hasJson && !hasIncrements)) {
      return const _SqliteLikeMutationShape(
        sql: '',
        parameterSets: <List<Object?>>[],
        returning: false,
      );
    }

    String? key =
        plan.queryPrimaryKey ?? plan.definition.primaryKeyField?.columnName;
    QueryPlan projectionPlan = queryPlan;
    if (key == null) {
      final identifier = _metadata.queryUpdateRowIdentifier;
      if (_metadata.requiresPrimaryKeyForQueryUpdate || identifier == null) {
        throw StateError(
          'Query updates on ${plan.definition.modelName} require a primary key.',
        );
      }
      key = identifier.column;
      projectionPlan = _rowIdentifierProjection(
        queryPlan,
        key,
        expression: identifier.expression,
      );
    } else if (plan.definition.primaryKeyField == null) {
      projectionPlan = _rowIdentifierProjection(queryPlan, key);
    }

    final compilation = _grammar.compileSelect(projectionPlan);
    final assignments = <String>[];
    final parameters = <Object?>[];

    plan.queryUpdateValues.forEach((column, value) {
      assignments.add('${_quote(column)} = ?');
      parameters.add(
        _encodeValueForColumn(
          definition: plan.definition,
          column: column,
          value: value,
        ),
      );
    });

    plan.queryIncrementValues.forEach((column, increment) {
      assignments.add('${_quote(column)} = ${_quote(column)} + ?');
      parameters.add(increment);
    });

    if (hasJson) {
      final grouped = <String, List<JsonUpdateClause>>{};
      for (final clause in plan.queryJsonUpdates) {
        grouped
            .putIfAbsent(clause.column, () => <JsonUpdateClause>[])
            .add(clause);
      }
      grouped.forEach((column, clauses) {
        final resolved = _quote(column);
        var expression = resolved;
        final clauseBindings = <Object?>[];
        for (final clause in clauses) {
          final clauseValue = _encodeValueForColumn(
            definition: plan.definition,
            column: clause.column,
            value: clause.value,
          );
          final compiled = clause.patch
              ? _grammar.compileJsonPatch(
                  clause.column,
                  expression,
                  clauseValue,
                )
              : _grammar.compileJsonUpdate(
                  clause.column,
                  expression,
                  clause.path,
                  clauseValue,
                );
          expression = _assignmentRhs(compiled.sql);
          clauseBindings.addAll(compiled.bindings);
        }
        assignments.add('$resolved = $expression');
        parameters.addAll(clauseBindings);
      });
    }

    if (assignments.isEmpty) {
      return const _SqliteLikeMutationShape(
        sql: '',
        parameterSets: <List<Object?>>[],
        returning: false,
      );
    }

    final table = _qualifiedTable(
      plan.definition.tableName,
      plan.definition.schema,
    );
    final quotedKey = _quote(key);
    final sql = StringBuffer('UPDATE $table SET ')
      ..write(assignments.join(', '))
      ..write(' WHERE EXISTS (SELECT 1 FROM (')
      ..write(compilation.sql)
      ..write(') AS "__orm_update_source" WHERE ')
      ..write(table)
      ..write('.')
      ..write(quotedKey)
      ..write(' = "__orm_update_source".')
      ..write(quotedKey)
      ..write(')');
    if (plan.returning) {
      sql.write(' RETURNING *');
    }

    return _SqliteLikeMutationShape(
      sql: sql.toString(),
      parameterSets: <List<Object?>>[
        <Object?>[...parameters, ...compilation.bindings],
      ],
      returning: plan.returning,
    );
  }

  _SqliteLikeMutationShape _buildUpsertShape(MutationPlan plan) {
    if (plan.rows.isEmpty) {
      return const _SqliteLikeMutationShape(
        sql: '',
        parameterSets: <List<Object?>>[],
        returning: false,
      );
    }

    final table = _qualifiedTable(
      plan.definition.tableName,
      plan.definition.schema,
    );
    final firstRow = plan.rows.first;
    final columns = firstRow.values.keys.toList(growable: false);
    final columnSql = columns.map(_quote).join(', ');
    final placeholders = List.filled(columns.length, '?').join(', ');
    final uniqueColumns = _resolveUpsertUniqueColumns(plan);
    final updateColumns = _resolveUpsertUpdateColumns(
      plan,
      columns,
      uniqueColumns,
    );
    final jsonTemplates = _jsonUpdateTemplates(firstRow);
    final jsonColumns = jsonTemplates
        .map((template) => template.column)
        .toSet();
    final updateAssignments = <String>[];
    updateAssignments.addAll(
      updateColumns
          .where((column) => !jsonColumns.contains(column))
          .map((column) => '${_quote(column)} = excluded.${_quote(column)}'),
    );
    updateAssignments.addAll(jsonTemplates.map((template) => template.sql));
    final updateClause = updateAssignments.join(', ');
    final sql =
        StringBuffer('INSERT INTO $table ($columnSql) VALUES ($placeholders) ')
          ..write('ON CONFLICT(${uniqueColumns.map(_quote).join(', ')}) DO ')
          ..write(
            updateClause.isEmpty ? 'NOTHING' : 'UPDATE SET $updateClause',
          );
    if (plan.returning) {
      sql.write(' RETURNING *');
    }

    final parameters = plan.rows
        .map((row) {
          final values = columns
              .map(
                (column) => _encodeValueForColumn(
                  definition: plan.definition,
                  column: column,
                  value: row.values[column],
                ),
              )
              .toList(growable: true);
          if (jsonTemplates.isNotEmpty) {
            final clauses = row.jsonUpdates;
            _validateJsonUpdateShape(jsonTemplates, clauses);
            final grouped = <String, List<JsonUpdateClause>>{};
            for (final clause in clauses) {
              grouped
                  .putIfAbsent(clause.column, () => <JsonUpdateClause>[])
                  .add(clause);
            }
            for (final template in jsonTemplates) {
              final columnClauses = grouped[template.column]!;
              var expression = _quote(template.column);
              for (final clause in columnClauses) {
                final compiled = clause.patch
                    ? _grammar.compileJsonPatch(
                        clause.column,
                        expression,
                        clause.value,
                      )
                    : _grammar.compileJsonUpdate(
                        clause.column,
                        expression,
                        clause.path,
                        clause.value,
                      );
                expression = _assignmentRhs(compiled.sql);
                values.addAll(compiled.bindings);
              }
            }
          }
          return values;
        })
        .toList(growable: false);

    return _SqliteLikeMutationShape(
      sql: sql.toString(),
      parameterSets: parameters,
      returning: plan.returning,
    );
  }

  List<_JsonUpdateTemplate> _jsonUpdateTemplates(MutationRow row) {
    if (row.jsonUpdates.isEmpty) {
      return const <_JsonUpdateTemplate>[];
    }
    final grouped = <String, List<JsonUpdateClause>>{};
    for (final clause in row.jsonUpdates) {
      grouped
          .putIfAbsent(clause.column, () => <JsonUpdateClause>[])
          .add(clause);
    }
    final templates = <_JsonUpdateTemplate>[];
    grouped.forEach((column, clauses) {
      final resolved = _quote(column);
      var expression = resolved;
      final bindings = <Object?>[];
      for (final clause in clauses) {
        final compiled = clause.patch
            ? _grammar.compileJsonPatch(clause.column, expression, clause.value)
            : _grammar.compileJsonUpdate(
                clause.column,
                expression,
                clause.path,
                clause.value,
              );
        expression = _assignmentRhs(compiled.sql);
        bindings.addAll(compiled.bindings);
      }
      templates.add(
        _JsonUpdateTemplate(
          column: column,
          clauses: List.unmodifiable(clauses),
          sql: '$resolved = $expression',
          bindings: List.unmodifiable(bindings),
        ),
      );
    });
    return templates;
  }

  void _validateJsonUpdateShape(
    List<_JsonUpdateTemplate> templates,
    List<JsonUpdateClause> clauses,
  ) {
    if (templates.isEmpty) {
      return;
    }
    final flattened = templates.expand((template) => template.clauses).toList();
    if (flattened.length != clauses.length) {
      throw StateError(
        'All mutation rows must provide ${flattened.length} JSON update clauses.',
      );
    }
    for (var i = 0; i < clauses.length; i++) {
      final templateClause = flattened[i];
      final clause = clauses[i];
      if (templateClause.column != clause.column ||
          templateClause.path != clause.path ||
          templateClause.patch != clause.patch) {
        throw StateError(
          'JSON update clauses must match the first row ordering and paths.',
        );
      }
    }
  }

  List<String> _resolveUpsertUniqueColumns(MutationPlan plan) {
    if (plan.upsertUniqueColumns.isNotEmpty) {
      return plan.upsertUniqueColumns;
    }
    final pk = plan.definition.primaryKeyField?.columnName;
    if (pk != null) {
      return [pk];
    }
    throw StateError(
      'Upserts on ${plan.definition.modelName} require a primary key or uniqueBy columns.',
    );
  }

  List<String> _resolveUpsertUpdateColumns(
    MutationPlan plan,
    List<String> insertColumns,
    List<String> uniqueColumns,
  ) {
    if (plan.upsertUpdateColumns.isNotEmpty) {
      final normalized = <String>[];
      for (final column in plan.upsertUpdateColumns) {
        if (!insertColumns.contains(column)) {
          throw StateError(
            'Unknown upsert update column $column for ${plan.definition.modelName}.',
          );
        }
        normalized.add(column);
      }
      return normalized;
    }

    final conflicts = uniqueColumns.toSet();
    final pkColumn = plan.definition.primaryKeyField?.columnName;
    final excludeFromUpdate = <String>{...conflicts};
    if (pkColumn != null && !conflicts.contains(pkColumn)) {
      excludeFromUpdate.add(pkColumn);
    }

    return insertColumns
        .where((column) => !excludeFromUpdate.contains(column))
        .toList(growable: false);
  }

  String _whereClause(Map<String, Object?> keys) {
    if (keys.isEmpty) {
      throw StateError('Mutation requires keys for WHERE clause.');
    }
    return keys.keys.map((column) => '${_quote(column)} = ?').join(' AND ');
  }

  String _baseTableReference(QueryPlan plan) {
    final alias = plan.tableAlias;
    if (alias != null && alias.isNotEmpty) {
      return _quote(alias);
    }
    return _qualifiedTable(plan.definition.tableName, plan.definition.schema);
  }

  QueryPlan _rowIdentifierProjection(
    QueryPlan plan,
    String key, {
    String? expression,
  }) {
    final reference = _baseTableReference(plan);
    final sqlExpression = expression ?? '$reference.${_quote(key)}';
    return plan.copyWith(
      selects: const [],
      rawSelects: [RawSelectExpression(sql: sqlExpression, alias: key)],
      customSelects: const [],
      aggregates: const [],
      projectionOrder: const [ProjectionOrderEntry.raw(0)],
    );
  }

  Object? _encodeValueForColumn({
    required ModelDefinition<OrmEntity> definition,
    required String column,
    required Object? value,
  }) {
    final metadata = definition.metadata;
    final overrideCast = metadata.fieldOverrides[column]?.cast;
    final cast = overrideCast ?? metadata.casts[column];
    final field = definition.fieldByColumn(column);
    if (cast != null) {
      try {
        final normalizedCast = cast.trim().toLowerCase();
        if ((normalizedCast == 'json' || normalizedCast == 'object') &&
            value is String) {
          return value;
        }
        return _codecs.encodeCast(cast, value, field: field);
      } on TypeError {
        return value;
      }
    }
    if (value is Map || value is List) {
      return jsonEncode(value);
    }
    if (field != null) {
      try {
        return _codecs.encodeField(field, value);
      } on TypeError {
        return value;
      }
    }
    return _codecs.encodeValue(value);
  }

  Map<String, Object?> _decodeRowValues(
    ModelDefinition<OrmEntity> definition,
    Map<String, Object?> row,
  ) => row.map(
    (column, value) => MapEntry(
      column,
      _decodeValueForColumn(
        definition: definition,
        column: column,
        value: value,
      ),
    ),
  );

  Object? _decodeValueForColumn({
    required ModelDefinition<OrmEntity> definition,
    required String column,
    required Object? value,
  }) {
    final metadata = definition.metadata;
    final overrideCast = metadata.fieldOverrides[column]?.cast;
    final cast = overrideCast ?? metadata.casts[column];
    final field = definition.fieldByColumn(column);
    if (cast != null) {
      try {
        return _codecs.decodeCast(cast, value, field: field);
      } on TypeError {
        return value;
      }
    }
    if (field != null) {
      try {
        return _codecs.decodeField(field, value);
      } on TypeError {
        return value;
      }
    }
    return value;
  }

  String _qualifiedTable(String table, String? schema) {
    final wrappedTable = _quote(table);
    if (schema == null || schema.isEmpty) {
      return wrappedTable;
    }
    return '${_quote(schema)}.$wrappedTable';
  }

  String _quote(String value) => '"${value.replaceAll('"', '""')}"';

  String _schemaOrDefault(String? schema) =>
      schema == null || schema.isEmpty ? 'main' : schema;

  String? _exposedSchema(String? schema) {
    if (schema == null || schema.isEmpty || schema == 'main') {
      return null;
    }
    return schema;
  }

  String _sqliteMasterTable(String schema) {
    if (schema == 'main') return 'sqlite_master';
    if (schema == 'temp') return 'sqlite_temp_master';
    return '${_quote(schema)}.sqlite_master';
  }

  String _pragmaFor(String pragma, String identifier, {String? schema}) {
    final namespace = schema == null || schema.isEmpty ? null : schema;
    final buffer = StringBuffer('PRAGMA ');
    if (namespace != null) {
      if (namespace == 'temp') {
        buffer.write('temp.');
      } else {
        buffer
          ..write(_quote(namespace))
          ..write('.');
      }
    }
    buffer
      ..write(pragma)
      ..write('(')
      ..write(_stringLiteral(identifier))
      ..write(')');
    return buffer.toString();
  }

  String _stringLiteral(String value) {
    final escaped = value.replaceAll("'", "''");
    return "'$escaped'";
  }

  List<String> _splitColumns(Object? value) {
    if (value == null) return const [];
    return value
        .toString()
        .split(',')
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList(growable: false);
  }

  String? _normalizeDefault(Object? value) => value?.toString();

  Future<List<String>> _indexColumns(String indexName, {String? schema}) async {
    final pragma = _pragmaFor('index_xinfo', indexName, schema: schema);
    final rows = await queryRaw(pragma);
    final ordered = [...rows]
      ..sort((a, b) => (a['seqno'] as int).compareTo(b['seqno'] as int));
    return ordered
        .where((row) => (row['cid'] as int) >= 0)
        .map((row) => row['name'])
        .whereType<String>()
        .toList(growable: false);
  }

  Future<String?> _indexWhereClause(String indexName, {String? schema}) async {
    final master = _sqliteMasterTable(_schemaOrDefault(schema));
    final rows = await queryRaw(
      'SELECT sql FROM $master WHERE type = ? AND name = ?',
      ['index', indexName],
    );
    if (rows.isEmpty) {
      return null;
    }
    final sql = rows.first['sql'] as String?;
    if (sql == null) return null;
    final match = RegExp(
      r'\bWHERE\b(.*)$',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(sql);
    return match?.group(1)?.trim();
  }

  void _ensureOpen() {
    if (_closed) {
      throw StateError('$driverName adapter has already been closed.');
    }
  }
}

class _SqliteLikeMutationShape {
  const _SqliteLikeMutationShape({
    required this.sql,
    required this.parameterSets,
    required this.returning,
  });

  final String sql;
  final List<List<Object?>> parameterSets;
  final bool returning;
}

class _JsonUpdateTemplate {
  const _JsonUpdateTemplate({
    required this.column,
    required this.clauses,
    required this.sql,
    required this.bindings,
  });

  final String column;
  final List<JsonUpdateClause> clauses;
  final String sql;
  final List<Object?> bindings;
}

bool? _boolOption(Map<String, Object?> source, String key) {
  final value = source[key];
  if (value == null) return null;
  if (value is bool) return value;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  if (value is num) {
    if (value == 1) return true;
    if (value == 0) return false;
  }
  return null;
}

String _assignmentRhs(String sql) {
  final index = sql.indexOf('=');
  if (index == -1) {
    return sql;
  }
  return sql.substring(index + 1).trim();
}
