import 'dart:async';
import 'dart:convert';

import 'package:mysql_client_plus/mysql_client_plus.dart';
import 'package:ormed/ormed.dart';

import 'mysql_codecs.dart';
import 'mysql_connector.dart';
import 'mysql_grammar.dart';
import 'mysql_schema_dialect.dart';
import 'schema_state.dart';

/// Shared MySQL/MariaDB implementation of the routed ORM driver adapter.
class MySqlDriverAdapter
    implements DriverAdapter, SchemaDriver, SchemaStateProvider {
  MySqlDriverAdapter.custom({
    required DatabaseConfig config,
    ConnectionFactory? connections,
    ValueCodecRegistry? codecRegistry,
    String driverName = 'mysql',
    bool isMariaDb = false,
  }) : _driverName = driverName,
       _metadata = DriverMetadata(
         name: driverName,
         supportsQueryDeletes: true,
         requiresPrimaryKeyForQueryUpdate: false,
         queryUpdateRowIdentifier: QueryRowIdentifier(
           column: 'id',
           expression: 'id',
         ),
         identifierQuote: '`',
         capabilities: {
           DriverCapability.joins,
           DriverCapability.insertUsing,
           DriverCapability.queryDeletes,
           DriverCapability.schemaIntrospection,
           DriverCapability.threadCount,
           DriverCapability.transactions,
           DriverCapability.adHocQueryUpdates,
           DriverCapability.increment,
           DriverCapability.rightJoin,
         },
       ),
       _schemaCompiler = SchemaPlanCompiler(
         MySqlSchemaDialect(isMariaDb: isMariaDb),
       ),
       _grammar = const MySqlQueryGrammar(),
       _connections =
           connections ??
           ConnectionFactory(
             connectors: {
               'mysql': () => MySqlConnector(),
               'mariadb': () => MySqlConnector(),
             },
           ),
       _config = config,
       _codecs = augmentMySqlCodecs(
         codecRegistry ?? ValueCodecRegistry.standard(),
       ) {
    _planCompiler = ClosurePlanCompiler(
      compileSelect: _compileSelectPreview,
      compileMutation: _compileMutationPreview,
    );
  }

  factory MySqlDriverAdapter.fromUrl(
    String url, {
    ValueCodecRegistry? codecRegistry,
    ConnectionFactory? connections,
  }) => MySqlDriverAdapter.custom(
    config: DatabaseConfig(driver: 'mysql', options: {'url': url}),
    codecRegistry: codecRegistry,
    connections: connections,
  );

  factory MySqlDriverAdapter.insecureLocal({
    String database = 'orm_test',
    String username = 'root',
    String? password,
    int port = 3306,
    String host = '127.0.0.1',
    ValueCodecRegistry? codecRegistry,
    ConnectionFactory? connections,
  }) => MySqlDriverAdapter.custom(
    config: DatabaseConfig(
      driver: 'mysql',
      options: {
        'host': host,
        'port': port,
        'database': database,
        'username': username,
        if (password != null) 'password': password,
      },
    ),
    codecRegistry: codecRegistry,
    connections: connections,
  );

  // ignore: unused_field
  final String _driverName;
  final DriverMetadata _metadata;
  final ValueCodecRegistry _codecs;
  final SchemaPlanCompiler _schemaCompiler;
  final MySqlQueryGrammar _grammar;
  final ConnectionFactory _connections;
  final DatabaseConfig _config;
  late final PlanCompiler _planCompiler;
  ConnectionHandle<MySQLConnection>? _primaryHandle;
  bool _closed = false;
  int _transactionDepth = 0;
  @override
  PlanCompiler get planCompiler => _planCompiler;

  @override
  DriverMetadata get metadata => _metadata;

  @override
  ValueCodecRegistry get codecs => _codecs;

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    if (_primaryHandle != null) {
      await _primaryHandle!.close();
      _primaryHandle = null;
    }
  }

  @override
  Future<void> executeRaw(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    await _executeStatement(sql, parameters);
  }

  @override
  Future<List<Map<String, Object?>>> queryRaw(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    final result = await _executeStatement(sql, parameters);
    return _collectRows(result);
  }

  @override
  Future<List<Map<String, Object?>>> execute(QueryPlan plan) async {
    final compilation = _grammar.compileSelect(plan);
    final result = await _executeStatement(
      compilation.sql,
      compilation.bindings,
    );
    return _collectRows(result);
  }

  @override
  Stream<Map<String, Object?>> stream(QueryPlan plan) async* {
    final compilation = _grammar.compileSelect(plan);
    final result = await _executeStatement(
      compilation.sql,
      compilation.bindings,
    );
    for (final row in _rowIterable(result)) {
      yield row;
    }
  }

  @override
  StatementPreview describeQuery(QueryPlan plan) =>
      _planCompiler.compileSelect(plan);

  @override
  Future<MutationResult> runMutation(MutationPlan plan) async {
    // MySQL/MariaDB don't support native RETURNING clause
    // For INSERT operations, we simulate it by returning the lastInsertID
    // For other operations (UPDATE, DELETE, UPSERT), returning is silently ignored
    // since we can't efficiently implement it without re-querying
    
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
    final normalized = normalizeMySqlParameters(compilation.bindings);
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
    final normalized = shape.parameterSets
        .map(normalizeMySqlParameters)
        .toList(growable: false);
    final sql = shape.parameterSets.isEmpty
        ? shape.sql
        : _formatPreviewSql(shape.sql, normalized.first.length);
    final first = normalized.isEmpty ? const <Object?>[] : normalized.first;
    final resolved = _grammar.substituteBindingsIntoRawSql(
      shape.sql,
      _encodePreviewParameters(first),
    );
    return StatementPreview(
      payload: SqlStatementPayload(sql: sql, parameters: first),
      parameterSets: normalized,
      resolvedText: resolved,
    );
  }

  List<Object?> _encodePreviewParameters(List<Object?> parameters) =>
      parameters.map(_codecs.encodeValue).toList(growable: false);

  @override
  Future<int?> threadCount() async {
    try {
      final sql = _grammar.compileThreadCount();
      if (sql == null) {
        return null;
      }
      final rows = await queryRaw(sql);
      if (rows.isEmpty) {
        return null;
      }
      final row = rows.first;
      final value =
          row['Value'] ??
          row['VALUE'] ??
          row['variable_value'] ??
          row['VARIABLE_VALUE'];
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        return int.tryParse(value);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<R> transaction<R>(Future<R> Function() action) async {
    final connection = await _connection();
    if (_transactionDepth == 0) {
      _transactionDepth++;
      await connection.execute('START TRANSACTION');
      try {
        final result = await action();
        await connection.execute('COMMIT');
        return result;
      } catch (error) {
        await connection.execute('ROLLBACK');
        rethrow;
      } finally {
        _transactionDepth--;
      }
    } else {
      final savepoint = 'sp_${_transactionDepth + 1}';
      _transactionDepth++;
      await connection.execute('SAVEPOINT $savepoint');
      try {
        final result = await action();
        await connection.execute('RELEASE SAVEPOINT $savepoint');
        return result;
      } catch (error) {
        await connection.execute('ROLLBACK TO SAVEPOINT $savepoint');
        rethrow;
      } finally {
        _transactionDepth--;
      }
    }
  }

  @override
  Future<void> beginTransaction() async {
    final connection = await _connection();
    if (_transactionDepth == 0) {
      await connection.execute('START TRANSACTION');
      _transactionDepth++;
    } else {
      // Use savepoint for nested transactions
      final savepoint = 'sp_${_transactionDepth + 1}';
      await connection.execute('SAVEPOINT $savepoint');
      _transactionDepth++;
    }
  }

  @override
  Future<void> commitTransaction() async {
    if (_transactionDepth == 0) {
      throw StateError('No active transaction to commit');
    }

    final connection = await _connection();
    if (_transactionDepth == 1) {
      await connection.execute('COMMIT');
      _transactionDepth--;
    } else {
      // Release savepoint for nested transactions
      final savepoint = 'sp_$_transactionDepth';
      await connection.execute('RELEASE SAVEPOINT $savepoint');
      _transactionDepth--;
    }
  }

  @override
  Future<void> rollbackTransaction() async {
    if (_transactionDepth == 0) {
      throw StateError('No active transaction to rollback');
    }

    final connection = await _connection();
    if (_transactionDepth == 1) {
      await connection.execute('ROLLBACK');
      _transactionDepth--;
    } else {
      // Rollback to savepoint for nested transactions
      final savepoint = 'sp_$_transactionDepth';
      await connection.execute('ROLLBACK TO SAVEPOINT $savepoint');
      _transactionDepth--;
    }
  }

  @override
  Future<void> truncateTable(String tableName) async {
    final connection = await _connection();
    // MySQL supports TRUNCATE TABLE which is faster and resets auto-increment
    await connection.execute('TRUNCATE TABLE $tableName');
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
      await transaction(runner);
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
    return MySqlSchemaState(
      config: _config,
      connection: connection,
      ledgerTable: ledgerTable,
    );
  }

  @override
  Future<List<SchemaNamespace>> listSchemas() async {
    final rows = await queryRaw(
      'SELECT schema_name AS name, schema_name = DATABASE() AS is_default '
      'FROM information_schema.schemata '
      "WHERE schema_name NOT IN ('information_schema','mysql','performance_schema','sys','ndbinfo') "
      'ORDER BY schema_name',
    );
    return rows
        .map(
          (row) => SchemaNamespace(
            name: row['name'] as String,
            isDefault: _asBool(row['is_default']),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<SchemaTable>> listTables({String? schema}) async {
    final filter = schema == null
        ? "table_schema NOT IN ('information_schema','mysql','performance_schema','sys','ndbinfo')"
        : 'table_schema = ?';
    final rows = await queryRaw(
      'SELECT table_schema, table_name, table_type, table_comment, engine, '
      'COALESCE(data_length, 0) + COALESCE(index_length, 0) AS size_bytes '
      'FROM information_schema.tables '
      "WHERE table_type IN ('BASE TABLE','SYSTEM VERSIONED') AND $filter "
      'ORDER BY table_schema, table_name',
      schema == null ? const [] : [schema],
    );
    return rows
        .map(
          (row) => SchemaTable(
            name: _stringValue(row, 'table_name')!,
            schema: _stringValue(row, 'table_schema'),
            type: _stringValue(row, 'table_type'),
            sizeBytes: _asInt(row['size_bytes']),
            comment: _stringValue(row, 'table_comment'),
            engine: _stringValue(row, 'engine'),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<SchemaView>> listViews({String? schema}) async {
    final filter = schema == null
        ? "table_schema NOT IN ('information_schema','mysql','performance_schema','sys','ndbinfo')"
        : 'table_schema = ?';
    final rows = await queryRaw(
      'SELECT table_schema, table_name, view_definition '
      'FROM information_schema.views '
      'WHERE $filter '
      'ORDER BY table_schema, table_name',
      schema == null ? const [] : [schema],
    );
    return rows
        .map(
          (row) => SchemaView(
            name: _stringValue(row, 'table_name')!,
            schema: _stringValue(row, 'table_schema'),
            definition: _stringValue(row, 'view_definition'),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<SchemaColumn>> listColumns(String table, {String? schema}) async {
    final clause = schema == null
        ? 'table_schema = DATABASE()'
        : 'table_schema = ?';
    final rows = await queryRaw(
      'SELECT table_schema, column_name, column_type, data_type, column_default, '
      'is_nullable, column_comment, character_maximum_length, numeric_precision, '
      'numeric_scale, extra '
      'FROM information_schema.columns '
      'WHERE table_name = ? AND $clause '
      'ORDER BY ordinal_position',
      schema == null ? [table] : [table, schema],
    );
    final pkColumns = await _primaryKeyColumns(table, schema: schema);
    return rows
        .map(
          (row) => SchemaColumn(
            name: row['column_name'] as String,
            dataType:
                (row['column_type'] as String?) ?? row['data_type'] as String,
            schema: row['table_schema'] as String?,
            tableName: table,
            length: _asInt(row['character_maximum_length']),
            numericPrecision: _asInt(row['numeric_precision']),
            numericScale: _asInt(row['numeric_scale']),
            nullable: (row['is_nullable'] as String?) != 'NO',
            defaultValue: row['column_default'] as String?,
            autoIncrement: _containsText(row['extra'], 'auto_increment'),
            primaryKey: pkColumns.contains(row['column_name'] as String),
            comment: row['column_comment'] as String?,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<SchemaIndex>> listIndexes(String table, {String? schema}) async {
    final clause = schema == null
        ? 'table_schema = DATABASE()'
        : 'table_schema = ?';
    final rows = await queryRaw(
      'SELECT index_name, non_unique, index_type, '
      'GROUP_CONCAT(column_name ORDER BY seq_in_index) AS columns '
      'FROM information_schema.statistics '
      'WHERE table_name = ? AND $clause '
      'GROUP BY index_name, non_unique, index_type '
      'ORDER BY index_name',
      schema == null ? [table] : [table, schema],
    );
    return rows
        .map((row) {
          final name = row['index_name'] as String;
          final columns = _splitColumns(row['columns'] as String?);
          final isPrimary = name.toUpperCase() == 'PRIMARY';
          return SchemaIndex(
            name: name,
            columns: columns,
            schema: schema,
            tableName: table,
            unique: !isPrimary && _asBool(row['non_unique']) == false,
            primary: isPrimary,
            method: row['index_type'] as String?,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<List<SchemaForeignKey>> listForeignKeys(
    String table, {
    String? schema,
  }) async {
    final clause = schema == null
        ? 'kc.table_schema = DATABASE()'
        : 'kc.table_schema = ?';
    final rows = await queryRaw(
      'SELECT kc.constraint_name, '
      'GROUP_CONCAT(kc.column_name ORDER BY kc.ordinal_position) AS columns, '
      'kc.referenced_table_schema, kc.referenced_table_name, '
      'GROUP_CONCAT(kc.referenced_column_name ORDER BY kc.ordinal_position) AS referenced_columns, '
      'rc.update_rule, rc.delete_rule '
      'FROM information_schema.key_column_usage kc '
      'JOIN information_schema.referential_constraints rc '
      '  ON kc.constraint_schema = rc.constraint_schema '
      ' AND kc.constraint_name = rc.constraint_name '
      'WHERE kc.table_name = ? AND $clause '
      'AND kc.referenced_table_name IS NOT NULL '
      'GROUP BY kc.constraint_name, kc.referenced_table_schema, kc.referenced_table_name, rc.update_rule, rc.delete_rule '
      'ORDER BY kc.constraint_name',
      schema == null ? [table] : [table, schema],
    );
    return rows
        .map(
          (row) => SchemaForeignKey(
            name: row['constraint_name'] as String,
            columns: _splitColumns(row['columns'] as String?),
            referencedTable: row['referenced_table_name'] as String,
            referencedColumns: _splitColumns(
              row['referenced_columns'] as String?,
            ),
            schema: schema,
            referencedSchema: row['referenced_table_schema'] as String?,
            onDelete: row['delete_rule'] as String?,
            onUpdate: row['update_rule'] as String?,
            tableName: table,
          ),
        )
        .toList(growable: false);
  }

  Future<MutationResult> _runInsert(MutationPlan plan) async {
    final shape = _buildInsertShape(plan);
    return _executeMutation(shape);
  }

  Future<MutationResult> _runInsertUsing(MutationPlan plan) async {
    final shape = _buildInsertUsingShape(plan);
    return _executeMutation(shape);
  }

  Future<MutationResult> _runUpdate(MutationPlan plan) async {
    final shape = _buildUpdateShape(plan);
    return _executeMutation(shape);
  }

  Future<MutationResult> _runDelete(MutationPlan plan) async {
    final shape = _buildDeleteShape(plan);
    return _executeMutation(shape);
  }

  Future<MutationResult> _runQueryDelete(MutationPlan plan) async {
    final shape = _buildQueryDeleteShape(plan);
    return _executeMutation(shape);
  }

  Future<MutationResult> _runUpsert(MutationPlan plan) async {
    if (plan.rows.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }
    if (_usesPrimaryKeyUpsert(plan)) {
      final shape = _buildUpsertShape(plan);
      return _executeMutation(shape);
    }
    return _runManualUpsert(plan);
  }

  Future<MutationResult> _runQueryUpdate(MutationPlan plan) async {
    final shape = _buildQueryUpdateShape(plan);
    return _executeMutation(shape);
  }

  Future<MutationResult> _executeMutation(_MySqlMutationShape shape) async {
    if (shape.parameterSets.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }
    final connection = await _connection();
    var affected = 0;
    final returnedRows = <Map<String, Object?>>[];

    for (final parameters in shape.parameterSets) {
      final statement = _prepareStatement(shape.sql, parameters);
      final result = await connection.execute(
        statement.sql,
        statement.parameters.isEmpty ? null : statement.parameters,
      );
      affected += result.affectedRows.toInt();

      // For INSERTs with RETURNING, capture the last insert ID as a returned row
      // MySQL doesn't support native RETURNING, so we simulate it for INSERTs only
      if (shape.isInsert &&
          shape.returning &&
          result.lastInsertID.toInt() > 0 &&
          shape.definition != null) {
        // Find the primary key field name from the plan
        try {
          final pkField = shape.definition!.fields.firstWhere(
            (f) => f.isPrimaryKey,
          );
          returnedRows.add({pkField.columnName: result.lastInsertID.toInt()});
        } catch (_) {
          // No primary key found, skip
        }
      }
    }

    return MutationResult(
      affectedRows: affected,
      returnedRows: shape.returning && returnedRows.isNotEmpty ? returnedRows : null,
    );
  }

  _MySqlMutationShape _shapeForPlan(MutationPlan plan) {
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

  _MySqlMutationShape _buildInsertShape(MutationPlan plan) {
    if (plan.rows.isEmpty) {
      return _MySqlMutationShape.empty();
    }
    // Use columns from the first row to determine which fields are actually being inserted
    // This handles cases where auto-increment PKs are filtered out
    final columns = plan.rows.first.values.keys.toList();
    final columnSql = columns.map(_quote).join(', ');
    final placeholders = List.filled(columns.length, '?').join(', ');
    final verb = plan.ignoreConflicts ? 'INSERT IGNORE' : 'INSERT';
    final sql =
        '$verb INTO ${_tableIdentifier(plan.definition)} ($columnSql) VALUES ($placeholders)';
    final parameterSets = plan.rows
        .map((row) => columns.map((column) => row.values[column]).toList())
        .toList(growable: false);
    return _MySqlMutationShape(
      sql: sql,
      parameterSets: parameterSets,
      isInsert: true,
      definition: plan.definition,
      returning: plan.returning,
    );
  }

  _MySqlMutationShape _buildInsertUsingShape(MutationPlan plan) {
    final queryPlan = plan.queryPlan;
    if (queryPlan == null || plan.insertColumns.isEmpty) {
      return _MySqlMutationShape.empty();
    }
    final compilation = _grammar.compileSelect(queryPlan);
    final verb = plan.ignoreConflicts ? 'INSERT IGNORE' : 'INSERT';
    final columns = plan.insertColumns.map(_quote).join(', ');
    final sql = StringBuffer()
      ..write('$verb INTO ${_tableIdentifier(plan.definition)} ($columns) ')
      ..write(compilation.sql);
    return _MySqlMutationShape(
      sql: sql.toString(),
      parameterSets: [compilation.bindings.toList(growable: false)],
      isInsert: true,
      definition: plan.definition,
      returning: plan.returning,
    );
  }

  _MySqlMutationShape _buildUpdateShape(MutationPlan plan) {
    if (plan.rows.isEmpty) {
      return _MySqlMutationShape.empty();
    }
    final table = _tableIdentifier(plan.definition);
    final firstRow = plan.rows.first;
    final setColumns = firstRow.values.keys.toList();
    final jsonTemplates = _jsonUpdateTemplates(firstRow);
    if (setColumns.isEmpty && jsonTemplates.isEmpty) {
      return _MySqlMutationShape.empty();
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
    final parameterSets = plan.rows
        .map((row) {
          final parameters = <Object?>[...setColumns.map((c) => row.values[c])];
          if (jsonTemplates.isNotEmpty) {
            final clauses = row.jsonUpdates;
            _validateJsonUpdateShape(jsonTemplates, clauses);
            for (var i = 0; i < jsonTemplates.length; i++) {
              final template = jsonTemplates[i];
              final clause = clauses[i];
              final compiled = template.patch
                  ? _grammar.compileJsonPatch(
                      clause.column,
                      template.resolvedColumn,
                      clause.value,
                    )
                  : _grammar.compileJsonUpdate(
                      clause.column,
                      template.resolvedColumn,
                      clause.path,
                      clause.value,
                    );
              if (compiled.sql != template.sql) {
                throw StateError(
                  'JSON update clause mismatch for ${clause.column} ${clause.path}.',
                );
              }
              parameters.addAll(compiled.bindings);
            }
          }
          parameters.addAll(whereColumns.map((c) => row.keys[c]));
          return parameters;
        })
        .toList(growable: false);
    return _MySqlMutationShape(sql: sql, parameterSets: parameterSets);
  }

  _MySqlMutationShape _buildDeleteShape(MutationPlan plan) {
    if (plan.rows.isEmpty) {
      return _MySqlMutationShape.empty();
    }
    final table = _tableIdentifier(plan.definition);
    final firstRow = plan.rows.first;
    final whereColumns = firstRow.keys.keys.toList();
    final whereClause = _whereClause(firstRow.keys);
    final sql = 'DELETE FROM $table WHERE $whereClause';
    final parameterSets = plan.rows
        .map((row) => whereColumns.map((c) => row.keys[c]).toList())
        .toList(growable: false);
    return _MySqlMutationShape(sql: sql, parameterSets: parameterSets);
  }

  _MySqlMutationShape _buildQueryDeleteShape(MutationPlan plan) {
    final queryPlan = plan.queryPlan;
    if (queryPlan == null) {
      return _MySqlMutationShape.empty();
    }
    final primaryKey =
        plan.queryPrimaryKey ?? plan.definition.primaryKeyField?.columnName;
    if (primaryKey == null || primaryKey.isEmpty) {
      throw StateError(
        'Query deletes on ${plan.definition.modelName} require a primary key.',
      );
    }
    final compilation = _grammar.compileSelect(queryPlan);
    final table = _tableIdentifier(plan.definition);
    final targetAlias = _quote('__orm_delete_target');
    final sourceAlias = _quote('__orm_delete_source');
    final pkIdentifier = _quote(primaryKey);
    final sql = StringBuffer('DELETE ')
      ..write(targetAlias)
      ..write(' FROM ')
      ..write('$table AS $targetAlias JOIN (')
      ..write(compilation.sql)
      ..write(') AS $sourceAlias ON ')
      ..write('$sourceAlias.$pkIdentifier = $targetAlias.$pkIdentifier');
    return _MySqlMutationShape(
      sql: sql.toString(),
      parameterSets: [compilation.bindings.toList(growable: false)],
    );
  }

  _MySqlMutationShape _buildQueryUpdateShape(MutationPlan plan) {
    final queryPlan = plan.queryPlan;
    final hasColumns = plan.queryUpdateValues.isNotEmpty;
    final hasJson = plan.queryJsonUpdates.isNotEmpty;
    final hasIncrements = plan.queryIncrementValues.isNotEmpty;
    if (queryPlan == null || (!hasColumns && !hasJson && !hasIncrements)) {
      return _MySqlMutationShape.empty();
    }
    final metadata = _metadata;
    final pk =
        plan.queryPrimaryKey ??
        plan.definition.primaryKeyField?.columnName ??
        metadata.queryUpdateRowIdentifier?.column;
    if (pk == null) {
      throw StateError(
        'Query updates on ${plan.definition.modelName} require a primary key.',
      );
    }
    final compilation = _grammar.compileSelect(queryPlan);
    final assignments = <String>[];
    final parameters = <Object?>[];
    if (hasColumns) {
      assignments.addAll(
        plan.queryUpdateValues.keys.map((column) => '${_quote(column)} = ?'),
      );
      parameters.addAll(plan.queryUpdateValues.values);
    }
    if (hasIncrements) {
      for (final entry in plan.queryIncrementValues.entries) {
        final column = entry.key;
        final amount = entry.value;
        assignments.add('${_quote(column)} = ${_quote(column)} + ?');
        parameters.add(amount);
      }
    }
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
          final compiledJson = clause.patch
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
          expression = _assignmentRhs(compiledJson.sql);
          clauseBindings.addAll(compiledJson.bindings);
        }
        assignments.add('$resolved = $expression');
        parameters.addAll(clauseBindings);
      });
    }
    if (assignments.isEmpty) {
      return _MySqlMutationShape.empty();
    }
    final derivedAlias = '__orm_update';
    final sql = StringBuffer('UPDATE ${_tableIdentifier(plan.definition)} SET ')
      ..write(assignments.join(', '))
      ..write(' WHERE ${_quote(pk)} IN (SELECT ')
      ..write('$derivedAlias.${_quote(pk)}')
      ..write(' FROM (')
      ..write(compilation.sql)
      ..write(') AS $derivedAlias)');
    parameters.addAll(compilation.bindings);
    return _MySqlMutationShape(
      sql: sql.toString(),
      parameterSets: [parameters],
    );
  }

  _MySqlMutationShape _buildUpsertShape(MutationPlan plan) {
    if (plan.rows.isEmpty) {
      return _MySqlMutationShape.empty();
    }
    final table = _tableIdentifier(plan.definition);
    final firstRow = plan.rows.first;
    final columns = firstRow.values.keys.toList();
    if (columns.isEmpty) {
      return _MySqlMutationShape.empty();
    }
    final uniqueColumns = _resolveUpsertUniqueColumns(plan);
    final updateColumns = _resolveUpsertUpdateColumns(
      plan,
      columns,
      uniqueColumns,
    );
    final columnSql = columns.map(_quote).join(', ');
    final placeholders = List.filled(columns.length, '?').join(', ');
    final updateClause = updateColumns
        .map((c) => '${_quote(c)} = VALUES(${_quote(c)})')
        .join(', ');
    final buffer = StringBuffer(
      'INSERT INTO $table ($columnSql) VALUES ($placeholders) ON DUPLICATE KEY UPDATE ',
    );
    if (updateClause.isEmpty) {
      final column = uniqueColumns.isNotEmpty
          ? uniqueColumns.first
          : columns.first;
      buffer.write('${_quote(column)} = ${_quote(column)}');
    } else {
      buffer.write(updateClause);
    }
    final parameterSets = plan.rows
        .map((row) => columns.map((column) => row.values[column]).toList())
        .toList(growable: false);
    return _MySqlMutationShape(
      sql: buffer.toString(),
      parameterSets: parameterSets,
    );
  }

  bool _usesPrimaryKeyUpsert(MutationPlan plan) {
    final pk = plan.definition.primaryKeyField?.columnName;
    return pk != null &&
        plan.upsertUniqueColumns.length == 1 &&
        plan.upsertUniqueColumns.first == pk;
  }

  Future<MutationResult> _runManualUpsert(MutationPlan plan) async {
    final table = _tableIdentifier(plan.definition);
    final firstRow = plan.rows.first;
    final columns = firstRow.values.keys.toList();
    final columnSql = columns.map(_quote).join(', ');
    final placeholders = List.filled(columns.length, '?').join(', ');
    final insertSql = 'INSERT INTO $table ($columnSql) VALUES ($placeholders)';
    final uniqueColumns = _resolveUpsertUniqueColumns(plan);
    final updateColumns = _resolveUpsertUpdateColumns(
      plan,
      columns,
      uniqueColumns,
    );
    final whereClause = uniqueColumns
        .map((column) => '${_quote(column)} = ?')
        .join(' AND ');
    final selectSql = 'SELECT 1 FROM $table WHERE $whereClause LIMIT 1';
    final updateClause = updateColumns
        .map((column) => '${_quote(column)} = ?')
        .join(', ');
    final updateSql = updateClause.isEmpty
        ? null
        : 'UPDATE $table SET $updateClause WHERE $whereClause';

    var affected = 0;
    for (final row in plan.rows) {
      final selectors = uniqueColumns
          .map((column) => row.values[column])
          .toList(growable: false);
      final selectResult = await _executeStatement(selectSql, selectors);
      final exists = selectResult.rows.isNotEmpty;
      if (exists) {
        if (updateSql != null) {
          final updateParams = <Object?>[];
          for (final column in updateColumns) {
            updateParams.add(row.values[column]);
          }
          updateParams.addAll(selectors);
          final result = await _executeStatement(updateSql, updateParams);
          affected += result.affectedRows.toInt();
        }
        continue;
      }
      final values = columns
          .map((column) => row.values[column])
          .toList(growable: false);
      final result = await _executeStatement(insertSql, values);
      affected += result.affectedRows.toInt();
    }
    return MutationResult(affectedRows: affected);
  }

  List<_JsonUpdateTemplate> _jsonUpdateTemplates(MutationRow row) {
    if (row.jsonUpdates.isEmpty) {
      return const <_JsonUpdateTemplate>[];
    }
    final templates = <_JsonUpdateTemplate>[];
    for (final clause in row.jsonUpdates) {
      final resolved = _quote(clause.column);
      final compiled = clause.patch
          ? _grammar.compileJsonPatch(clause.column, resolved, clause.value)
          : _grammar.compileJsonUpdate(
              clause.column,
              resolved,
              clause.path,
              clause.value,
            );
      templates.add(
        _JsonUpdateTemplate(
          column: clause.column,
          path: clause.path,
          sql: compiled.sql,
          resolvedColumn: resolved,
          patch: clause.patch,
        ),
      );
    }
    return templates;
  }

  void _validateJsonUpdateShape(
    List<_JsonUpdateTemplate> templates,
    List<JsonUpdateClause> clauses,
  ) {
    if (templates.isEmpty) {
      return;
    }
    if (templates.length != clauses.length) {
      throw StateError(
        'All mutation rows must provide ${templates.length} JSON update clauses.',
      );
    }
    for (var i = 0; i < templates.length; i++) {
      final template = templates[i];
      final clause = clauses[i];
      if (template.column != clause.column ||
          template.path != clause.path ||
          template.patch != clause.patch) {
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
    final uniques = uniqueColumns.toSet();
    return insertColumns.where((c) => !uniques.contains(c)).toList();
  }

  Future<MySQLConnection> _connection() async {
    if (_closed) {
      throw StateError('MySqlDriverAdapter has already been closed.');
    }
    if (_primaryHandle == null) {
      final handle =
          await _connections.open(_config) as ConnectionHandle<MySQLConnection>;
      _primaryHandle = handle;
    }
    return _primaryHandle!.client;
  }

  Future<IResultSet> _executeStatement(
    String sql,
    List<Object?> parameters,
  ) async {
    final connection = await _connection();
    final statement = _prepareStatement(sql, parameters);
    return connection.execute(
      statement.sql,
      statement.parameters.isEmpty ? null : statement.parameters,
    );
  }

  _MySqlStatement _prepareStatement(String sql, List<Object?> values) {
    if (values.isEmpty) {
      return _MySqlStatement(sql: sql, parameters: const {});
    }
    final normalized = normalizeMySqlParameters(values);
    final buffer = StringBuffer();
    final params = <String, Object?>{};
    var index = 0;
    for (var i = 0; i < sql.length; i++) {
      final char = sql[i];
      if (char == '?') {
        index++;
        final name = 'p$index';
        buffer
          ..write(':')
          ..write(name);
        params[name] = normalized[index - 1];
      } else {
        buffer.write(char);
      }
    }
    if (index != normalized.length) {
      throw StateError(
        'Expected $index placeholders but got ${normalized.length}.',
      );
    }
    return _MySqlStatement(sql: buffer.toString(), parameters: params);
  }

  List<Map<String, Object?>> _collectRows(IResultSet result) =>
      _rowIterable(result).toList(growable: false);

  Iterable<Map<String, Object?>> _rowIterable(IResultSet result) sync* {
    IResultSet? current = result;
    while (current != null) {
      for (final row in current.rows) {
        yield _decodeRow(row);
      }
      current = current.next;
    }
  }

  Map<String, Object?> _decodeRow(dynamic row) {
    final typed = Map<String, Object?>.from(row.typedAssoc());
    return typed.map((key, value) => MapEntry(key, _decodeResultValue(value)));
  }

  String _tableIdentifier(ModelDefinition<dynamic> definition) {
    final table = _quote(definition.tableName);
    final schema = definition.schema;
    if (schema == null || schema.isEmpty) {
      return table;
    }
    return '${_quote(schema)}.$table';
  }

  String _quote(String identifier) {
    final escaped = identifier.replaceAll('`', '``');
    return '`$escaped`';
  }

  String _whereClause(Map<String, Object?> keys) {
    if (keys.isEmpty) {
      throw StateError('Mutation requires keys for WHERE clause.');
    }
    return keys.keys.map((c) => '${_quote(c)} = ?').join(' AND ');
  }

  Future<Set<String>> _primaryKeyColumns(String table, {String? schema}) async {
    final clause = schema == null
        ? 'table_schema = DATABASE()'
        : 'table_schema = ?';
    final rows = await queryRaw(
      'SELECT kcu.column_name '
      'FROM information_schema.table_constraints tc '
      'JOIN information_schema.key_column_usage kcu '
      ' ON tc.constraint_name = kcu.constraint_name '
      ' AND tc.table_schema = kcu.table_schema '
      "WHERE tc.constraint_type = 'PRIMARY KEY' AND tc.table_name = ? AND $clause "
      'ORDER BY kcu.ordinal_position',
      schema == null ? [table] : [table, schema],
    );
    return rows.map((row) => row['column_name'] as String).toSet();
  }

  List<String> _splitColumns(String? value) {
    if (value == null || value.isEmpty) {
      return const [];
    }
    return value.split(',').map((part) => part.trim()).toList(growable: false);
  }

  bool _containsText(Object? source, String needle) {
    if (source == null) return false;
    return source.toString().toLowerCase().contains(needle);
  }

  bool _asBool(Object? value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value.toString() == '1';
  }

  int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is BigInt) return value.toInt();
    return int.tryParse(value.toString());
  }

  Object? _valueForColumn(Map<String, Object?> row, String column) {
    if (row.containsKey(column)) {
      return row[column];
    }
    final normalized = column.toLowerCase();
    for (final entry in row.entries) {
      if (entry.key.toLowerCase() == normalized) {
        return entry.value;
      }
    }
    return null;
  }

  String? _stringValue(Map<String, Object?> row, String column) {
    final value = _valueForColumn(row, column);
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  String _formatPreviewSql(String sql, int parameterCount) {
    final buffer = StringBuffer();
    var index = 0;
    for (var i = 0; i < sql.length; i++) {
      final char = sql[i];
      if (char == '?') {
        index++;
        buffer
          ..write(':p')
          ..write(index);
      } else {
        buffer.write(char);
      }
    }
    if (index != parameterCount) {
      throw StateError(
        'Expected $parameterCount placeholders but found $index.',
      );
    }
    return buffer.toString();
  }
}

class _JsonUpdateTemplate {
  const _JsonUpdateTemplate({
    required this.column,
    required this.path,
    required this.sql,
    required this.resolvedColumn,
    required this.patch,
  });

  final String column;
  final String path;
  final String sql;
  final String resolvedColumn;
  final bool patch;
}

/// Adapter wrapper that mirrors Laravel's `MariaDbConnection`.
class MariaDbDriverAdapter extends MySqlDriverAdapter {
  MariaDbDriverAdapter.custom({
    required super.config,
    super.connections,
    super.codecRegistry,
  }) : super.custom(driverName: 'mariadb', isMariaDb: true);

  factory MariaDbDriverAdapter.fromUrl(
    String url, {
    ValueCodecRegistry? codecRegistry,
    ConnectionFactory? connections,
  }) => MariaDbDriverAdapter.custom(
    config: DatabaseConfig(driver: 'mariadb', options: {'url': url}),
    codecRegistry: codecRegistry,
    connections: connections,
  );

  factory MariaDbDriverAdapter.insecureLocal({
    String database = 'orm_test',
    String username = 'root',
    String? password,
    int port = 3306,
    String host = '127.0.0.1',
    ValueCodecRegistry? codecRegistry,
    ConnectionFactory? connections,
  }) => MariaDbDriverAdapter.custom(
    config: DatabaseConfig(
      driver: 'mariadb',
      options: {
        'host': host,
        'port': port,
        'database': database,
        'username': username,
        if (password != null) 'password': password,
      },
    ),
    codecRegistry: codecRegistry,
    connections: connections,
  );
}

class _MySqlStatement {
  const _MySqlStatement({required this.sql, required this.parameters});

  final String sql;
  final Map<String, Object?> parameters;
}

class _MySqlMutationShape {
  const _MySqlMutationShape({
    required this.sql,
    required this.parameterSets,
    this.isInsert = false,
    this.definition,
    this.returning = false,
  });

  final String sql;
  final List<List<Object?>> parameterSets;
  final bool isInsert;
  final ModelDefinition<dynamic>? definition;
  final bool returning;

  static _MySqlMutationShape empty() =>
      const _MySqlMutationShape(sql: '<no-op>', parameterSets: []);
}

String _assignmentRhs(String sql) {
  final index = sql.indexOf('=');
  if (index == -1) {
    return sql;
  }
  return sql.substring(index + 1).trim();
}

List<Object?> normalizeMySqlParameters(List<Object?> values) =>
    values.map(_normalizeMySqlValue).toList(growable: false);

Object? _normalizeMySqlValue(Object? value) {
  if (value == null) return null;
  if (value is bool) return value ? 1 : 0;
  if (value is DateTime) return _formatDateTime(value);
  if (value is Duration) return value.inMicroseconds;
  if (value is BigInt) return value.toInt();
  if (value is Iterable) {
    return value.map(_normalizeMySqlValue).toList();
  }
  return value;
}

String _formatDateTime(DateTime value) {
  final utc = value.toUtc();
  final buffer = StringBuffer()
    ..write(_padNumber(utc.year, 4))
    ..write('-')
    ..write(_padNumber(utc.month, 2))
    ..write('-')
    ..write(_padNumber(utc.day, 2))
    ..write(' ')
    ..write(_padNumber(utc.hour, 2))
    ..write(':')
    ..write(_padNumber(utc.minute, 2))
    ..write(':')
    ..write(_padNumber(utc.second, 2))
    ..write('.')
    ..write(_padNumber(utc.microsecond, 6));
  return buffer.toString();
}

String _padNumber(int value, int width) => value.toString().padLeft(width, '0');

Object? _decodeResultValue(Object? value) {
  if (value == null) return null;
  if (value is String) {
    final intValue = int.tryParse(value);
    if (intValue != null) return intValue;
    final doubleValue = double.tryParse(value);
    if (doubleValue != null) return doubleValue;
    return value;
  }
  if (value is List<int>) {
    try {
      final decoded = utf8.decode(value);
      final trimmed = decoded.trimLeft();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        return jsonDecode(decoded);
      }
      return decoded;
    } catch (_) {
      return value;
    }
  }
  return value;
}
