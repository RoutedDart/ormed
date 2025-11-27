/// SQLite implementation of the routed ORM driver adapter.
library;

import 'dart:convert';
import 'dart:math';

import 'package:ormed/ormed.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'schema_state.dart';
import 'sqlite_codecs.dart';
import 'sqlite_connector.dart';
import 'sqlite_grammar.dart';
import 'sqlite_schema_dialect.dart';

/// Adapter that executes [QueryPlan] objects against SQLite databases.
class SqliteDriverAdapter
    implements DriverAdapter, SchemaDriver, SchemaStateProvider {
  /// Opens an in-memory database connection using the shared connector.
  SqliteDriverAdapter.inMemory({ValueCodecRegistry? codecRegistry})
    : this.custom(
        config: const DatabaseConfig(
          driver: 'sqlite',
          options: {'memory': true},
        ),
        codecRegistry: codecRegistry,
      );

  /// Opens a database stored at [path].
  SqliteDriverAdapter.file(String path, {ValueCodecRegistry? codecRegistry})
    : this.custom(
        config: DatabaseConfig(
          driver: 'sqlite',
          options: {'path': path},
          name: path,
        ),
        codecRegistry: codecRegistry,
      );

  /// Creates an adapter for the provided [config] and [connections].
  SqliteDriverAdapter.custom({
    required DatabaseConfig config,
    ConnectionFactory? connections,
    ValueCodecRegistry? codecRegistry,
  }) : _metadata = const DriverMetadata(
         name: 'sqlite',
         supportsQueryDeletes: true,
         requiresPrimaryKeyForQueryUpdate: false,
         queryUpdateRowIdentifier: QueryRowIdentifier(
           column: 'rowid',
           expression: 'rowid',
         ),
         capabilities: {
           DriverCapability.joins,
           DriverCapability.insertUsing,
           DriverCapability.queryDeletes,
           DriverCapability.schemaIntrospection,
           DriverCapability.threadCount,
           DriverCapability.transactions,
           DriverCapability.adHocQueryUpdates,
         },
       ),
       _schemaCompiler = SchemaPlanCompiler(SqliteSchemaDialect()),
       _grammar = SqliteQueryGrammar(
         supportsWindowFunctions:
             sqlite.sqlite3.version.versionNumber >= 3025000,
       ),
       _connections =
           connections ??
           ConnectionFactory(connectors: {'sqlite': () => SqliteConnector()}),
       _config = config,
       _codecs = augmentSqliteCodecs(
         codecRegistry ?? ValueCodecRegistry.standard(),
       ) {
    _planCompiler = ClosurePlanCompiler(
      compileSelect: _compileSelectPreview,
      compileMutation: _compileMutationPreview,
    );
  }

  final DriverMetadata _metadata;
  final ValueCodecRegistry _codecs;
  final SchemaPlanCompiler _schemaCompiler;
  final SqliteQueryGrammar _grammar;
  final ConnectionFactory _connections;
  final DatabaseConfig _config;
  late final PlanCompiler _planCompiler;
  ConnectionHandle<sqlite.Database>? _primaryHandle;
  final Random _random = Random();
  bool _closed = false;

  @override
  PlanCompiler get planCompiler => _planCompiler;

  @override
  DriverMetadata get metadata => _metadata;

  @override
  ValueCodecRegistry get codecs => _codecs;

  @override
  Future<void> close() async {
    if (_closed) return;
    if (_primaryHandle != null) {
      await _primaryHandle!.close();
      _primaryHandle = null;
    }
    _closed = true;
  }

  @override
  Future<void> executeRaw(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    final database = await _database();
    final stmt = _prepareStatement(database, sql);
    try {
      stmt.execute(normalizeSqliteParameters(parameters));
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, Object?>>> queryRaw(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    final database = await _database();
    final stmt = _prepareStatement(database, sql);
    try {
      final result = stmt.select(normalizeSqliteParameters(parameters));
      final columnNames = result.columnNames;
      final rows = <Map<String, Object?>>[];
      for (final row in result) {
        rows.add(rowToMap(row, columnNames));
      }
      return rows;
    } finally {
      stmt.dispose();
    }
  }

  @override
  Future<List<Map<String, Object?>>> execute(QueryPlan plan) async {
    final database = await _database();
    final compilation = _grammar.compileSelect(plan);
    final stmt = _prepareStatement(database, compilation.sql);
    try {
      final result = stmt.select(
        normalizeSqliteParameters(compilation.bindings),
      );
      final columnNames = result.columnNames;
      final rows = <Map<String, Object?>>[];
      for (final row in result) {
        rows.add(rowToMap(row, columnNames));
      }
      final decodedRows = rows
          .map(
            (row) => _decodeRowValues(plan.definition, row),
          )
          .toList(growable: false);
      if (plan.randomOrder) {
        _shuffleRows(decodedRows, plan.randomSeed);
      }
      return decodedRows;
    } finally {
      stmt.dispose();
    }
  }

  @override
  Stream<Map<String, Object?>> stream(QueryPlan plan) async* {
    final database = await _database();
    final compilation = _grammar.compileSelect(plan);
    final stmt = _prepareStatement(database, compilation.sql);
    try {
      final result = stmt.select(
        normalizeSqliteParameters(compilation.bindings),
      );
      final columnNames = result.columnNames;
      final rows = <Map<String, Object?>>[];
      for (final row in result) {
        rows.add(rowToMap(row, columnNames));
      }
      final decodedRows = rows
          .map(
            (row) => _decodeRowValues(plan.definition, row),
          )
          .toList(growable: false);
      if (plan.randomOrder) {
        _shuffleRows(decodedRows, plan.randomSeed);
      }
      for (final row in decodedRows) {
        yield row;
      }
    } finally {
      stmt.dispose();
    }
  }

  @override
  StatementPreview describeQuery(QueryPlan plan) =>
      _planCompiler.compileSelect(plan);

  @override
  Future<MutationResult> runMutation(MutationPlan plan) async {
    switch (plan.operation) {
      case MutationOperation.insert:
        return _runInsert(plan);
      case MutationOperation.insertUsing:
        return _runInsertUsing(plan);
      case MutationOperation.update:
        return _runUpdate(plan);
      case MutationOperation.delete:
        return _runDelete(plan);
      case MutationOperation.upsert:
        return _runUpsert(plan);
      case MutationOperation.queryDelete:
        return _runQueryDelete(plan);
      case MutationOperation.queryUpdate:
        return _runQueryUpdate(plan);
    }
  }

  @override
  StatementPreview describeMutation(MutationPlan plan) =>
      _planCompiler.compileMutation(plan);

  StatementPreview _compileSelectPreview(QueryPlan plan) {
    final compilation = _grammar.compileSelect(plan);
    final normalized = normalizeSqliteParameters(compilation.bindings);
    final resolved = _grammar.substituteBindingsIntoRawSql(
      compilation.sql,
      _encodePreviewParameters(normalized),
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
    final batches = shape.parameterSets
        .map(normalizeSqliteParameters)
        .toList(growable: false);
    final first = batches.isEmpty ? const <Object?>[] : batches.first;
    final resolved = _grammar.substituteBindingsIntoRawSql(
      shape.sql,
      _encodePreviewParameters(first),
    );
    return StatementPreview(
      payload: SqlStatementPayload(sql: shape.sql, parameters: first),
      parameterSets: batches,
      resolvedText: resolved,
    );
  }

  List<Object?> _encodePreviewParameters(List<Object?> parameters) =>
      parameters.map(_codecs.encodeValue).toList(growable: false);

  @override
  Future<R> transaction<R>(Future<R> Function() action) async {
    final database = await _database();
    database.execute('BEGIN');
    try {
      final result = await action();
      database.execute('COMMIT');
      return result;
    } catch (_) {
      database.execute('ROLLBACK');
      rethrow;
    }
  }

  @override
  Future<void> applySchemaPlan(SchemaPlan plan) async {
    final preview = describeSchemaPlan(plan);

    Future<void> runner() async {
      for (final statement in preview.statements) {
        await executeRaw(statement.sql, statement.parameters);
      }
    }

    if (metadata.supportsTransactions) {
      await transaction<void>(() async {
        await runner();
      });
    } else {
      await runner();
    }
  }

  @override
  SchemaPreview describeSchemaPlan(SchemaPlan plan) {
    return _schemaCompiler.compile(plan);
  }

  @override
  SchemaState? createSchemaState({
    required OrmConnection connection,
    required String ledgerTable,
  }) {
    final path = _config.options['path'] ?? _config.options['database'];
    if (path is! String || path.isEmpty) {
      return null;
    }
    return SqliteSchemaState(database: path, ledgerTable: ledgerTable);
  }

  @override
  Future<int?> threadCount() async {
    return 1;
  }

  @override
  Future<List<SchemaNamespace>> listSchemas() async {
    final database = await _database();
    final result = database.select('PRAGMA database_list;');
    return result
        .map(
          (row) => SchemaNamespace(
            name: row['name'] as String,
            owner: row['file'] as String?,
            isDefault: (row['name'] as String).toLowerCase() == 'main',
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<SchemaTable>> listTables({String? schema}) async {
    final database = await _database();
    final schemas = _schemasToInspect(database, schema);
    final tables = <SchemaTable>[];
    for (final namespace in schemas) {
      final master = _sqliteSchemaTable(namespace);
      final rows = database.select(
        'SELECT name, type, tbl_name, sql '
        'FROM $master WHERE type = ? AND name NOT LIKE ? '
        'ORDER BY name',
        ['table', 'sqlite_%'],
      );
      for (final row in rows) {
        final tableName = row['name'] as String;
        tables.add(
          SchemaTable(
            name: tableName,
            schema: _exposedSchema(namespace),
            type: row['type'] as String?,
            comment: null,
            engine: null,
          ),
        );
      }
    }
    return tables;
  }

  @override
  Future<List<SchemaView>> listViews({String? schema}) async {
    final database = await _database();
    final schemas = _schemasToInspect(database, schema);
    final views = <SchemaView>[];
    for (final namespace in schemas) {
      final master = _sqliteSchemaTable(namespace);
      final rows = database.select(
        'SELECT name, sql FROM $master '
        'WHERE type = ? AND name NOT LIKE ? ORDER BY name',
        ['view', 'sqlite_%'],
      );
      for (final row in rows) {
        views.add(
          SchemaView(
            name: row['name'] as String,
            schema: _exposedSchema(namespace),
            definition: row['sql'] as String?,
          ),
        );
      }
    }
    return views;
  }

  @override
  Future<List<SchemaColumn>> listColumns(String table, {String? schema}) async {
    final database = await _database();
    final pragma = _pragmaFor('table_xinfo', table, schema: schema);
    final rows = database
        .select(pragma)
        .where((row) => (row['cid'] as int? ?? 0) >= 0);
    return rows
        .map(
          (row) => SchemaColumn(
            name: row['name'] as String,
            dataType: (row['type'] as String?) ?? 'TEXT',
            schema: _exposedSchema(_schemaOrDefault(schema)),
            tableName: table,
            length: null,
            numericPrecision: null,
            numericScale: null,
            nullable: (row['notnull'] as int? ?? 0) == 0,
            defaultValue: _normalizeDefault(row['dflt_value']),
            autoIncrement: false,
            primaryKey: (row['pk'] as int? ?? 0) > 0,
            comment: null,
            generatedExpression: null,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<SchemaIndex>> listIndexes(String table, {String? schema}) async {
    final database = await _database();
    final pragma = _pragmaFor('index_list', table, schema: schema);
    final rows = database.select(pragma);
    final indexes = <SchemaIndex>[];
    for (final row in rows) {
      final name = row['name'] as String;
      if (name.startsWith('sqlite_')) {
        continue;
      }
      final columns = _indexColumns(database, name, schema: schema);
      final whereClause = (row['partial'] as int? ?? 0) == 1
          ? _indexWhereClause(database, name, schema: schema)
          : null;
      indexes.add(
        SchemaIndex(
          name: name,
          columns: columns,
          schema: _exposedSchema(_schemaOrDefault(schema)),
          tableName: table,
          unique: (row['unique'] as int? ?? 0) == 1,
          primary: (row['origin'] as String?) == 'pk',
          method: null,
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
    final database = await _database();
    final pragma = _pragmaFor('foreign_key_list', table, schema: schema);
    final rows = database.select(pragma);
    final grouped = <int, List<Map<String, Object?>>>{};
    for (final row in rows) {
      final id = row['id'] as int;
      grouped.putIfAbsent(id, () => []).add({
        'seq': row['seq'],
        'from': row['from'],
        'to': row['to'],
        'table': row['table'],
        'on_update': row['on_update'],
        'on_delete': row['on_delete'],
      });
    }
    final foreignKeys = <SchemaForeignKey>[];
    grouped.forEach((id, entries) {
      entries.sort((a, b) => (a['seq'] as int).compareTo(b['seq'] as int));
      final first = entries.first;
      foreignKeys.add(
        SchemaForeignKey(
          name: 'fk_${table}_$id',
          columns: entries.map((entry) => entry['from'] as String).toList(),
          tableName: table,
          referencedTable: first['table'] as String,
          referencedColumns: entries
              .map((entry) => entry['to'] as String)
              .toList(),
          schema: _exposedSchema(_schemaOrDefault(schema)),
          referencedSchema: null,
          onUpdate: first['on_update'] as String?,
          onDelete: first['on_delete'] as String?,
        ),
      );
    });
    return foreignKeys;
  }

  Future<sqlite.Database> _database() async {
    if (_closed) {
      throw StateError('SqliteDriverAdapter has already been closed.');
    }
    if (_primaryHandle == null) {
      final handle =
          await _connections.open(_config) as ConnectionHandle<sqlite.Database>;
      _primaryHandle = handle;
    }
    return _primaryHandle!.client;
  }

  dynamic _prepareStatement(sqlite.Database database, String sql) {
    return database.prepare(sql);
  }

  Future<MutationResult> _runInsert(MutationPlan plan) async {
    if (plan.returning) {
      throw UnsupportedError('SQLite driver does not yet support RETURNING.');
    }
    final shape = _buildInsertShape(plan);
    if (shape.parameterSets.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }
    final database = await _database();
    final stmt = _prepareStatement(database, shape.sql);
    try {
      var affected = 0;
      for (final parameters in shape.parameterSets) {
        stmt.execute(normalizeSqliteParameters(parameters));
        affected += database.updatedRows;
      }
      return MutationResult(affectedRows: affected);
    } finally {
      stmt.dispose();
    }
  }

  Future<MutationResult> _runInsertUsing(MutationPlan plan) async {
    final shape = _buildInsertUsingShape(plan);
    if (shape.parameterSets.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }
    final database = await _database();
    final stmt = _prepareStatement(database, shape.sql);
    try {
      var affected = 0;
      for (final parameters in shape.parameterSets) {
        stmt.execute(normalizeSqliteParameters(parameters));
        affected += database.updatedRows;
      }
      return MutationResult(affectedRows: affected);
    } finally {
      stmt.dispose();
    }
  }

  Future<MutationResult> _runUpdate(MutationPlan plan) async {
    final shape = _buildUpdateShape(plan);
    if (shape.parameterSets.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }
    final database = await _database();
    final stmt = _prepareStatement(database, shape.sql);
    try {
      var affected = 0;
      for (final parameters in shape.parameterSets) {
        stmt.execute(normalizeSqliteParameters(parameters));
        affected += database.updatedRows;
      }
      return MutationResult(affectedRows: affected);
    } finally {
      stmt.dispose();
    }
  }

  Future<MutationResult> _runDelete(MutationPlan plan) async {
    final shape = _buildDeleteShape(plan);
    if (shape.parameterSets.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }
    final database = await _database();
    final stmt = _prepareStatement(database, shape.sql);
    try {
      var affected = 0;
      for (final parameters in shape.parameterSets) {
        stmt.execute(normalizeSqliteParameters(parameters));
        affected += database.updatedRows;
      }
      return MutationResult(affectedRows: affected);
    } finally {
      stmt.dispose();
    }
  }

  Future<MutationResult> _runUpsert(MutationPlan plan) async {
    if (plan.rows.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }
    if (_usesPrimaryKeyUpsert(plan)) {
      final shape = _buildUpsertShape(plan);
      return _executeShape(shape);
    }
    return _runManualUpsert(plan);
  }

  bool _usesPrimaryKeyUpsert(MutationPlan plan) {
    final pk = plan.definition.primaryKeyField?.columnName;
    return pk != null &&
        plan.upsertUniqueColumns.length == 1 &&
        plan.upsertUniqueColumns.first == pk;
  }

  Future<MutationResult> _executeShape(_SqliteMutationShape shape) async {
    if (shape.parameterSets.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }
    final database = await _database();
    final stmt = _prepareStatement(database, shape.sql);
    try {
      var affected = 0;
      for (final parameters in shape.parameterSets) {
        stmt.execute(normalizeSqliteParameters(parameters));
        affected += database.updatedRows;
      }
      return MutationResult(affectedRows: affected);
    } finally {
      stmt.dispose();
    }
  }

  void _shuffleRows(List<Map<String, Object?>> rows, num? seed) {
    final random = seed != null ? Random(seed.toInt()) : _random;
    rows.shuffle(random);
  }

  Future<MutationResult> _runManualUpsert(MutationPlan plan) async {
    final database = await _database();
    final table = _tableIdentifier(plan.definition);
    final firstRow = plan.rows.first;
    final columns = firstRow.values.keys.toList();
    final columnSql = columns.map(_quote).join(', ');
    final placeholders = List.filled(columns.length, '?').join(', ');
    final insertSql = 'INSERT INTO $table ($columnSql) VALUES ($placeholders)';
    final insertStmt = _prepareStatement(database, insertSql);

    final uniqueColumns = _resolveUpsertUniqueColumns(plan);
    final updateColumns = _resolveUpsertUpdateColumns(
      plan,
      columns,
      uniqueColumns,
    );
    final whereClause = uniqueColumns
        .map((c) => '${_quote(c)} = ?')
        .join(' AND ');
    final selectSql = 'SELECT 1 FROM $table WHERE $whereClause LIMIT 1';
    final selectStmt = _prepareStatement(database, selectSql);

    var updateStmt;
    if (updateColumns.isNotEmpty) {
      final updateClause = updateColumns
          .map((c) => '${_quote(c)} = ?')
          .join(', ');
      final updateSql = 'UPDATE $table SET $updateClause WHERE $whereClause';
      updateStmt = _prepareStatement(database, updateSql);
    }

    var affected = 0;
    for (final row in plan.rows) {
      final insertValues = columns.map((c) => row.values[c]).toList();
      final uniqueValues = uniqueColumns.map((c) => row.values[c]).toList();
      final normalizedInsert = normalizeSqliteParameters(insertValues);
      final normalizedUnique = normalizeSqliteParameters(uniqueValues);

      var updated = false;
      if (updateStmt != null) {
        final updateValues = [
          ...updateColumns.map((c) => row.values[c]),
          ...uniqueValues,
        ];
        updateStmt.execute(normalizeSqliteParameters(updateValues));
        final updatedRows = database.updatedRows;
        if (updatedRows > 0) {
          affected += updatedRows;
          updated = true;
        }
      } else {
        final rows = selectStmt.select(normalizedUnique);
        if (rows.isNotEmpty) {
          continue;
        }
      }

      if (updated) {
        continue;
      }

      insertStmt.execute(normalizedInsert);
      affected += database.updatedRows;
    }

    insertStmt.dispose();
    selectStmt.dispose();
    updateStmt?.dispose();
    return MutationResult(affectedRows: affected);
  }

  Future<MutationResult> _runQueryUpdate(MutationPlan plan) async {
    final shape = _buildQueryUpdateShape(plan);
    if (shape.parameterSets.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }
    final database = await _database();
    final stmt = _prepareStatement(database, shape.sql);
    try {
      var affected = 0;
      for (final parameters in shape.parameterSets) {
        stmt.execute(normalizeSqliteParameters(parameters));
        affected += database.updatedRows;
      }
      return MutationResult(affectedRows: affected);
    } finally {
      stmt.dispose();
    }
  }

  _SqliteMutationShape _shapeForPlan(MutationPlan plan) {
    switch (plan.operation) {
      case MutationOperation.insert:
        return _buildInsertShape(plan);
      case MutationOperation.insertUsing:
        return _buildInsertUsingShape(plan);
      case MutationOperation.update:
        return _buildUpdateShape(plan);
      case MutationOperation.delete:
        return _buildDeleteShape(plan);
      case MutationOperation.upsert:
        return _buildUpsertShape(plan);
      case MutationOperation.queryDelete:
        return _buildQueryDeleteShape(plan);
      case MutationOperation.queryUpdate:
        return _buildQueryUpdateShape(plan);
    }
  }

  Future<MutationResult> _runQueryDelete(MutationPlan plan) async {
    final shape = _buildQueryDeleteShape(plan);
    if (shape.parameterSets.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }
    final database = await _database();
    final stmt = _prepareStatement(database, shape.sql);
    try {
      var affected = 0;
      for (final parameters in shape.parameterSets) {
        stmt.execute(normalizeSqliteParameters(parameters));
        affected += database.updatedRows;
      }
      return MutationResult(affectedRows: affected);
    } finally {
      stmt.dispose();
    }
  }

  _SqliteMutationShape _buildInsertShape(MutationPlan plan) {
    if (plan.rows.isEmpty) {
      return _emptyShape;
    }
    final columns = plan.definition.fields.map((f) => f.columnName).toList();
    final columnSql = columns.map(_quote).join(', ');
    final placeholders = List.filled(columns.length, '?').join(', ');
    final verb = plan.ignoreConflicts ? 'INSERT OR IGNORE' : 'INSERT';
    final sql =
        '$verb INTO ${_tableIdentifier(plan.definition)} ($columnSql) VALUES ($placeholders)';
    final parameters = plan.rows
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
    return _SqliteMutationShape(sql: sql, parameterSets: parameters);
  }

  _SqliteMutationShape _buildInsertUsingShape(MutationPlan plan) {
    final queryPlan = plan.queryPlan;
    if (queryPlan == null || plan.insertColumns.isEmpty) {
      return _emptyShape;
    }
    final compilation = _grammar.compileSelect(queryPlan);
    final verb = plan.ignoreConflicts ? 'INSERT OR IGNORE' : 'INSERT';
    final columns = plan.insertColumns.map(_quote).join(', ');
    final sql = StringBuffer()
      ..write('$verb INTO ${_tableIdentifier(plan.definition)} ($columns) ')
      ..write(compilation.sql);
    return _SqliteMutationShape(
      sql: sql.toString(),
      parameterSets: [compilation.bindings.toList(growable: false)],
    );
  }

  _SqliteMutationShape _buildUpdateShape(MutationPlan plan) {
    if (plan.rows.isEmpty) {
      return _emptyShape;
    }
    final table = _tableIdentifier(plan.definition);
    final firstRow = plan.rows.first;
    final setColumns = firstRow.values.keys.toList();
    final jsonTemplates = _jsonUpdateTemplates(firstRow);
    if (setColumns.isEmpty && jsonTemplates.isEmpty) {
      return _emptyShape;
    }
    final assignments = <String>[];
    if (setColumns.isNotEmpty) {
      assignments.addAll(setColumns.map((c) => '${_quote(c)} = ?'));
    }
    assignments.addAll(jsonTemplates.map((template) => template.sql));
    final whereColumns = firstRow.keys.keys.toList();
    final whereClause = _whereClause(firstRow.keys);
    final sql =
        'UPDATE $table SET ${assignments.join(', ')} WHERE $whereClause';
    final parameters = plan.rows
        .map((row) {
          final values = <Object?>[
            ...setColumns.map(
              (c) => _encodeValueForColumn(
                definition: plan.definition,
                column: c,
                value: row.values[c],
              ),
            ),
          ];
          if (jsonTemplates.isNotEmpty) {
            final clauses = row.jsonUpdates;
            _validateJsonUpdateShape(jsonTemplates, clauses);
            for (final template in jsonTemplates) {
              values.addAll(template.bindings);
            }
          }
          values.addAll(
            whereColumns.map(
              (c) => _encodeValueForColumn(
                definition: plan.definition,
                column: c,
                value: row.keys[c],
              ),
            ),
          );
          return values;
        })
        .toList(growable: false);
    return _SqliteMutationShape(sql: sql, parameterSets: parameters);
  }

  _SqliteMutationShape _buildDeleteShape(MutationPlan plan) {
    if (plan.rows.isEmpty) {
      return _emptyShape;
    }
    final table = _tableIdentifier(plan.definition);
    final firstRow = plan.rows.first;
    final whereColumns = firstRow.keys.keys.toList();
    final whereClause = _whereClause(firstRow.keys);
    final sql = 'DELETE FROM $table WHERE $whereClause';
    final parameters = plan.rows
        .map((row) => whereColumns.map((column) => row.keys[column]).toList())
        .toList(growable: false);
    return _SqliteMutationShape(sql: sql, parameterSets: parameters);
  }

  _SqliteMutationShape _buildQueryDeleteShape(MutationPlan plan) {
    final queryPlan = plan.queryPlan;
    if (queryPlan == null) {
      return _emptyShape;
    }
    final primaryKey =
        plan.queryPrimaryKey ?? plan.definition.primaryKeyField?.columnName;
    if (primaryKey == null || primaryKey.isEmpty) {
      throw StateError(
        'Query deletes on ${plan.definition.modelName} require a primary key.',
      );
    }
    QueryPlan projectionPlan = queryPlan;
    if (plan.definition.primaryKeyField == null) {
      final identifier = _metadata.queryUpdateRowIdentifier;
      if (identifier == null || identifier.column != primaryKey) {
        throw StateError(
          'Query deletes on ${plan.definition.modelName} require a primary key.',
        );
      }
      projectionPlan = _rowIdentifierProjection(queryPlan, primaryKey);
    }
    final compilation = _grammar.compileSelect(projectionPlan);
    final table = _tableIdentifier(plan.definition);
    final pkIdentifier = _quote(primaryKey);
    final sql = StringBuffer('DELETE FROM ')
      ..write(table)
      ..write(' WHERE EXISTS (SELECT 1 FROM (')
      ..write(compilation.sql)
      ..write(') AS "__orm_delete_source" WHERE ')
      ..write(table)
      ..write('.')
      ..write(pkIdentifier)
      ..write(' = "__orm_delete_source".')
      ..write(pkIdentifier)
      ..write(')');
    return _SqliteMutationShape(
      sql: sql.toString(),
      parameterSets: [compilation.bindings.toList(growable: false)],
    );
  }

  _SqliteMutationShape _buildQueryUpdateShape(MutationPlan plan) {
    final queryPlan = plan.queryPlan;
    final hasColumns = plan.queryUpdateValues.isNotEmpty;
    final hasJson = plan.queryJsonUpdates.isNotEmpty;
    if (queryPlan == null || (!hasColumns && !hasJson)) {
      return _emptyShape;
    }
    final key =
        plan.queryPrimaryKey ?? plan.definition.primaryKeyField?.columnName;
    if (key == null) {
      throw StateError(
        'Query updates on ${plan.definition.modelName} require a primary key.',
      );
    }
    final projectionPlan = plan.definition.primaryKeyField == null
        ? _rowIdentifierProjection(queryPlan, key)
        : queryPlan;
    final compilation = _grammar.compileSelect(projectionPlan);
    final assignments = <String>[];
    final parameters = <Object?>[];
    if (hasColumns) {
      assignments.addAll(
        plan.queryUpdateValues.keys.map((column) => '"$column" = ?'),
      );
      parameters.addAll(
        plan.queryUpdateValues.entries.map(
          (entry) => _encodeValueForColumn(
            definition: plan.definition,
            column: entry.key,
            value: entry.value,
          ),
        ),
      );
    }
    if (hasJson) {
      final grouped = <String, List<JsonUpdateClause>>{};
      for (final clause in plan.queryJsonUpdates) {
        grouped
            .putIfAbsent(clause.column, () => <JsonUpdateClause>[])
            .add(clause);
      }
      grouped.forEach((column, clauses) {
        final resolved = '"$column"';
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
      return _emptyShape;
    }
    final table = _tableIdentifier(plan.definition);
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
    parameters.addAll(compilation.bindings);
    return _SqliteMutationShape(
      sql: sql.toString(),
      parameterSets: [parameters],
    );
  }

  _SqliteMutationShape _buildUpsertShape(MutationPlan plan) {
    if (plan.rows.isEmpty) {
      return _emptyShape;
    }
    final table = _tableIdentifier(plan.definition);
    final firstRow = plan.rows.first;
    final columns = firstRow.values.keys.toList();
    final columnSql = columns.map(_quote).join(', ');
    final placeholders = List.filled(columns.length, '?').join(', ');
    final uniqueColumns = _resolveUpsertUniqueColumns(plan);
    final updateColumns = _resolveUpsertUpdateColumns(
      plan,
      columns,
      uniqueColumns,
    );
    final updateClause = updateColumns
        .map((c) => '${_quote(c)} = excluded.${_quote(c)}')
        .join(', ');
    final sql =
        StringBuffer('INSERT INTO $table ($columnSql) VALUES ($placeholders) ')
          ..write('ON CONFLICT(${uniqueColumns.map(_quote).join(', ')}) DO ')
          ..write(
            updateClause.isEmpty ? 'NOTHING' : 'UPDATE SET $updateClause',
          );
    final parameters = plan.rows
        .map((row) => columns.map((column) => row.values[column]).toList())
        .toList(growable: false);
    return _SqliteMutationShape(sql: sql.toString(), parameterSets: parameters);
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
      final sql = '$resolved = $expression';
      templates.add(
        _JsonUpdateTemplate(
          column: column,
          clauses: List.unmodifiable(clauses),
          sql: sql,
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
    return insertColumns.where((c) => !conflicts.contains(c)).toList();
  }

  static const _SqliteMutationShape _emptyShape = _SqliteMutationShape(
    sql: '<no-op>',
    parameterSets: [],
  );

  String _tableIdentifier(ModelDefinition<dynamic> definition) {
    final table = _quote(definition.tableName);
    final schema = definition.schema;
    if (schema == null || schema.isEmpty) {
      return table;
    }
    return '${_quote(schema)}.$table';
  }

  String _baseTableReference(QueryPlan plan) {
    final alias = plan.tableAlias;
    if (alias != null && alias.isNotEmpty) {
      return _quote(alias);
    }
    final schema = plan.definition.schema;
    final table = _quote(plan.definition.tableName);
    if (schema == null || schema.isEmpty || schema == 'main') {
      return table;
    }
    return '${_quote(schema)}.$table';
  }

  QueryPlan _rowIdentifierProjection(QueryPlan plan, String key) {
    final reference = _baseTableReference(plan);
    final expression = '$reference.${_quote(key)}';
    return plan.copyWith(
      selects: const [],
      rawSelects: [RawSelectExpression(sql: expression, alias: key)],
      aggregates: const [],
      projectionOrder: const [ProjectionOrderEntry.raw(0)],
    );
  }

  String _quote(String identifier) {
    final escaped = identifier.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _whereClause(Map<String, Object?> keys) {
    if (keys.isEmpty) {
      throw StateError('Mutation requires keys for WHERE clause.');
    }
    return keys.keys.map((c) => '${_quote(c)} = ?').join(' AND ');
  }

  String _primaryKey(ModelDefinition<dynamic> definition) {
    final key = definition.primaryKeyField?.columnName;
    if (key == null) {
      throw StateError('Primary key required for ${definition.modelName}.');
    }
    return key;
  }

  Iterable<String> _schemasToInspect(
    sqlite.Database database,
    String? schema,
  ) sync* {
    if (schema != null && schema.isNotEmpty) {
      yield schema;
      return;
    }
    final rows = database.select('PRAGMA database_list;');
    for (final row in rows) {
      final name = row['name'] as String;
      yield name;
    }
  }

  String? _exposedSchema(String? schema) {
    if (schema == null || schema.isEmpty || schema == 'main') {
      return null;
    }
    return schema;
  }

  String _schemaOrDefault(String? schema) =>
      schema == null || schema.isEmpty ? 'main' : schema;

  String _sqliteSchemaTable(String schema) {
    if (schema == 'main') return 'sqlite_schema';
    if (schema == 'temp') return 'sqlite_temp_master';
    return '${_quote(schema)}.sqlite_schema';
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

  String? _normalizeDefault(Object? value) => value?.toString();

  List<String> _indexColumns(
    sqlite.Database database,
    String indexName, {
    String? schema,
  }) {
    final pragma = _pragmaFor('index_xinfo', indexName, schema: schema);
    final rows = database.select(pragma);
    final ordered = rows.toList()
      ..sort((a, b) => (a['seqno'] as int).compareTo(b['seqno'] as int));
    return ordered
        .where((row) => (row['cid'] as int) >= 0)
        .map((row) => row['name'])
        .whereType<String>()
        .toList(growable: false);
  }

  String? _indexWhereClause(
    sqlite.Database database,
    String indexName, {
    String? schema,
  }) {
    final master = _sqliteMasterTable(_schemaOrDefault(schema));
    final rows = database.select(
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

  Object? _encodeValueForColumn({
    required ModelDefinition<dynamic> definition,
    required String column,
    required Object? value,
  }) {
    final metadata = definition.metadata;
    final overrideCast = metadata.fieldOverrides[column]?.cast;
    final cast = overrideCast ?? metadata.casts[column];
    if (cast != null) {
      try {
        return _codecs.encodeByKey(cast, value);
      } on TypeError {
        return value;
      }
    }
    if (value is Map || value is List) {
      return jsonEncode(value);
    }
    final field = definition.fieldByColumn(column);
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
    ModelDefinition<dynamic> definition,
    Map<String, Object?> row,
  ) =>
      row.map(
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
    required ModelDefinition<dynamic> definition,
    required String column,
    required Object? value,
  }) {
    final metadata = definition.metadata;
    final overrideCast = metadata.fieldOverrides[column]?.cast;
    final cast = overrideCast ?? metadata.casts[column];
    if (cast != null) {
      try {
        return _codecs.decodeByKey(cast, value);
      } on TypeError {
        return value;
      }
    }
    final field = definition.fieldByColumn(column);
    if (field != null) {
      try {
        return _codecs.decodeField(field, value);
      } on TypeError {
        return value;
      }
    }
    return value;
  }

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

class _SqliteMutationShape {
  const _SqliteMutationShape({required this.sql, required this.parameterSets});

  final String sql;
  final List<List<Object?>> parameterSets;
}

String _assignmentRhs(String sql) {
  final index = sql.indexOf('=');
  if (index == -1) {
    return sql;
  }
  return sql.substring(index + 1).trim();
}
