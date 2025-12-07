import 'dart:async';
import 'dart:math';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:ormed/ormed.dart';

import 'mongo_codecs.dart';
import 'mongo_connector.dart';
import 'mongo_plan_compiler.dart';
import 'mongo_hooks.dart';
import 'mongo_query_plan_metadata.dart';
import 'mongo_schema_dialect.dart';
import 'mongo_schema_inspector.dart';
import 'mongo_transaction_context.dart';
import 'mongo_union_helper.dart';
import 'mongo_update_utils.dart';
import 'mongo_relation_hook.dart';

/// MongoDB implementation of the routed ORM driver adapter.
class MongoDriverAdapter implements DriverAdapter, SchemaDriver {
  MongoDriverAdapter.custom({
    required DatabaseConfig config,
    ConnectionFactory? connections,
    ValueCodecRegistry? codecRegistry,
  }) : _config = config,
       _connections =
           connections ??
           ConnectionFactory(connectors: {'mongo': () => MongoConnector()}),
       _codecs = _initializeCodecs(codecRegistry),
       _metadata = const DriverMetadata(
         name: 'mongo',
         supportsTransactions: false,
         supportsQueryDeletes: true,
         identifierQuote: '',
         capabilities: {
           DriverCapability.schemaIntrospection,
           DriverCapability.queryDeletes,
           DriverCapability.adHocQueryUpdates,
           DriverCapability.increment,
           DriverCapability.relationAggregates,
         },
         queryUpdateRowIdentifier: QueryRowIdentifier(
           column: '_id',
           expression: '_id',
         ),
         relationHook: MongoRelationHook(),
         annotationQueryHooks: {DriverModel: MongoQueryBuilderHook()},
         queryBuilderHook: MongoQueryBuilderHook(),
         annotationRepositoryHooks: {DriverModel: MongoRepositoryHook()},
         schemaMutationHooks: [MongoSchemaHook()],
       ),
       _planCompiler = const MongoPlanCompiler(),
       _schemaCompiler = SchemaPlanCompiler(
         MongoSchemaDialect(),
         hooks: const [MongoSchemaHook()],
       );

  static ValueCodecRegistry _initializeCodecs(ValueCodecRegistry? registry) {
    final codecs = registry ?? ValueCodecRegistry.standard();
    // Register codec for ObjectId <-> int conversion for MongoDB driver.
    // This handles MongoDB's _id field which is ObjectId but models expect int.
    // Get a driver-scoped view to register the codec
    final mongoCodecs = codecs.forDriver('mongo');
    mongoCodecs.registerCodec(
      key: 'ObjectId',
      codec: MongoObjectIdToIntCodec(),
    );
    // Also register for 'int' type so it's used for int fields when decoding
    mongoCodecs.registerCodec(
      key: 'int',
      codec: MongoObjectIdToIntCodec(),
    );
    // Return the base registry (not the driver-scoped one)
    // QueryContext will call .forDriver() again
    return codecs;
  }

  final DatabaseConfig _config;
  final ConnectionFactory _connections;
  final ValueCodecRegistry _codecs;
  final DriverMetadata _metadata;
  final PlanCompiler _planCompiler;
  final SchemaPlanCompiler _schemaCompiler;
  final Random _random = Random();
  ConnectionHandle<Db>? _primaryHandle;
  bool _closed = false;
  final Set<String> _droppedCollections = {};
  static const _unionExecutor = MongoUnionExecutor();
  String? _currentSessionId;
  int _sessionCounter = 0;
  late final MongoSchemaInspector _schemaInspector = MongoSchemaInspector(this);
  static const _aggregateBuilder = MongoAggregatePipelineBuilder();

  @override
  DriverMetadata get metadata => _metadata;

  @override
  ValueCodecRegistry get codecs => _codecs;

  @override
  PlanCompiler get planCompiler => _planCompiler;

  @override
  Future<void> close() async {
    if (_closed) return;
    if (_primaryHandle != null) {
      await _primaryHandle!.close();
    }
    _closed = true;
  }

  /// Exposes the underlying MongoDB client for testing purposes.
  Db? get testDb => _primaryHandle?.client;

  Future<Db> _database() async {
    if (_closed) {
      throw StateError('MongoDriverAdapter has been closed.');
    }
    _primaryHandle ??= await _connections.open(_config) as ConnectionHandle<Db>;
    return _primaryHandle!.client;
  }

  Future<Db> databaseInstance() => _database();

  Future<DbCollection> _collection(String name) async {
    if (_droppedCollections.contains(name)) {
      throw Exception('Collection $name has been dropped.');
    }
    final db = await _database();
    return db.collection(name);
  }

  Future<void> dropCollectionDirect(String name) async {
    final db = await _database();
    await db.dropCollection(name);
  }

  Map<String, Object>? _projectionForPlan(QueryPlan plan) {
    if (plan.selects.isEmpty) {
      return null; // No projection, return all fields
    }

    final projection = <String, Object>{};
    // Always include _id for MongoDB
    projection['_id'] = 1;
    
    for (final fieldName in plan.selects) {
      // Don't map 'id' to '_id' - they're separate fields
      final field = plan.definition.fieldByName(fieldName);
      if (field != null) {
        projection[field.columnName] = 1;
      } else {
        projection[fieldName] = 1;
      }
    }

    return projection;
  }

  /// Executes raw SQL-like commands with LIMITED support for migration compatibility.
  ///
  /// ⚠️ WARNING: This is NOT true SQL support. Only basic INSERT/DELETE/DROP TABLE
  /// statements are parsed for migration compatibility.
  ///
  /// For native MongoDB operations, use [runMongoCommand] instead.
  ///
  /// Supported patterns:
  /// - INSERT INTO table (cols) VALUES (vals)
  /// - DELETE FROM table [WHERE conditions]
  /// - DROP TABLE table
  /// - SHOW/DESCRIBE (no-op)
  @override
  /// ⚠️ MongoDB does not support raw SQL execution.
  ///
  /// Use [runMongoCommand] instead for native MongoDB operations.
  ///
  /// Example:
  /// ```dart
  /// // Instead of: await adapter.executeRaw('DELETE FROM users WHERE age < 18');
  /// // Use:
  /// await adapter.runMongoCommand('users', (collection) async {
  ///   await collection.remove({'age': {'\$lt': 18}});
  /// });
  /// ```
  Future<void> executeRaw(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    throw UnsupportedError(
      'MongoDB does not support raw SQL. Use runMongoCommand() for native MongoDB operations instead.',
    );
  }

  /// Executes a native MongoDB command on a collection.
  ///
  /// This provides direct access to MongoDB operations without SQL parsing.
  ///
  /// Example:
  /// ```dart
  /// // Get collection and run native operations
  /// await driver.runMongoCommand('users', (collection) async {
  ///   return await collection.find({'age': {'\$gt': 25}}).toList();
  /// });
  /// ```
  Future<T> runMongoCommand<T>(
    String collectionName,
    Future<T> Function(DbCollection collection) command,
  ) async {
    final collection = await _collection(collectionName);
    return await command(collection);
  }

  /// ⚠️ MongoDB does not support raw SQL queries.
  ///
  /// Use [runMongoCommand] instead for native MongoDB operations.
  ///
  /// Example:
  /// ```dart
  /// // Instead of: final rows = await adapter.queryRaw('SELECT * FROM users WHERE age > 18');
  /// // Use:
  /// final rows = await adapter.runMongoCommand('users', (collection) async {
  ///   final docs = await collection.find({'age': {'\$gt': 18}}).toList();
  ///   return docs.cast<Map<String, Object?>>();
  /// });
  /// ```
  @override
  Future<List<Map<String, Object?>>> queryRaw(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    throw UnsupportedError(
      'MongoDB does not support raw SQL. Use runMongoCommand() for native MongoDB operations instead.',
    );
  }

  @override
  Future<List<Map<String, Object?>>> execute(QueryPlan plan) async {
    if (plan.unions.isNotEmpty) {
      return _executeUnionPlan(plan);
    }
    return _executeNonUnion(plan);
  }

  Future<List<Map<String, Object?>>> _executeNonUnion(QueryPlan plan) async {
    if (_isAggregatePlan(plan)) {
      return _executeAggregatePlan(plan);
    }

    final collection = await _collection(plan.definition.tableName);
    final filter = MongoPlanCompiler.filtersForPlan(plan);
    final sort = MongoPlanCompiler.buildSort(plan.orders);
    final projection = _projectionForPlan(plan);

    final sortArguments = sort.isNotEmpty
        ? Map<String, Object>.fromEntries(
            sort.entries
                .where((entry) => entry.value != null)
                .map((entry) => MapEntry(entry.key, entry.value!)),
          )
        : null;
    final skipValue = (plan.offset != null && plan.offset! > 0)
        ? plan.offset
        : null;

    // Use SelectorBuilder for advanced query options
    final selector = SelectorBuilder();
    if (filter.isNotEmpty) {
      selector.raw(filter);
    }
    if (plan.limit != null) {
      selector.limit(plan.limit!);
    }
    if (skipValue != null) {
      selector.skip(skipValue);
    }
    if (sortArguments != null) {
      for (final entry in sortArguments.entries) {
        if (entry.value == 1) {
          selector.sortBy(entry.key);
        } else {
          selector.sortBy(entry.key, descending: true);
        }
      }
    }
    if (projection != null) {
      selector.fields(projection.keys.toList());
    }

    final cursor = collection.find(selector);

    final rows = await cursor.toList();
    if (plan.randomOrder && rows.length > 1) {
      rows.shuffle(_random);
    }
    final mapped = rows.map((row) => Map<String, Object?>.from(row)).toList();

    // Map _id to id if needed
    final withId = _mapMongoIdToModelId(mapped);

    final enriched = _applyRawSelects(withId, plan.rawSelects);
    return _applyDateWheres(enriched, plan.dateWheres);
  }

  Future<List<Map<String, Object?>>> _executeAggregatePlan(
    QueryPlan plan,
  ) async {
    final collection = await _collection(plan.definition.tableName);
    final pipeline = _aggregateBuilder.build(plan);
    final typedPipeline = pipeline
        .map(
          (stage) => stage.map((key, value) => MapEntry(key, value as Object)),
        )
        .toList();
    final cursor = collection.aggregateToStream(typedPipeline);
    final rows = await cursor.toList();
    final mapped = rows.map((row) => Map<String, Object?>.from(row)).toList();

    // Map _id to id if needed
    final withId = _mapMongoIdToModelId(mapped);

    return _applyRawSelects(withId, plan.rawSelects);
  }

  /// Helper to map MongoDB's _id to the model's id field.
  /// Laravel strategy: Keep both _id and id as separate fields.
  /// If the model expects 'id' but only '_id' exists, copy it over.
  /// For ObjectIds, leave them as-is and let the codec handle conversion during decoding.
  List<Map<String, Object?>> _mapMongoIdToModelId(
    List<Map<String, Object?>> rows,
  ) {
    return rows.map((row) {
      // If row has _id but not id, copy _id to id field
      // The codec registered for the 'id' field will handle type conversion
      if (row.containsKey('_id') && !row.containsKey('id')) {
        row['id'] = row['_id'];
      }
      return row;
    }).toList();
  }

  /// Convert ObjectId to appropriate model ID type
  Object? _convertObjectIdToModelId(Object? value) {
    if (value is ObjectId) {
      // Convert ObjectId to string (like Laravel does)
      // Models can use int autoincrement IDs separately
      return value.oid;
    }
    return value;
  }

  Future<List<Map<String, Object?>>> _executeUnionPlan(QueryPlan plan) async {
    final rows = await _unionExecutor.execute(
      plan,
      (subPlan) => _executeNonUnion(subPlan),
    );
    final mergedMetadata = _unionExecutor.mergeMetadata(plan);
    if (mergedMetadata != null) {
      trackMongoQueryPlan(
        plan,
        relationLoads: mergedMetadata.relationLoads,
        relationAggregates: mergedMetadata.relationAggregates,
        relationOrders: mergedMetadata.relationOrders,
        pipelineStages: mergedMetadata.pipelineStages,
        sessionId: mergedMetadata.sessionId,
        sessionState: mergedMetadata.sessionState,
        sessionStartedAt: mergedMetadata.sessionStartedAt,
        sessionEndedAt: mergedMetadata.sessionEndedAt,
      );
    }
    return rows;
  }

  bool _isAggregatePlan(QueryPlan plan) =>
      plan.aggregates.isNotEmpty ||
      plan.randomOrder ||
      plan.relationAggregates.isNotEmpty;

  String _nextSessionId() =>
      'mongo-tx-${DateTime.now().microsecondsSinceEpoch}-${_sessionCounter++}';

  String? get currentSessionId => _currentSessionId;

  List<Map<String, Object?>> _applyDateWheres(
    List<Map<String, Object?>> rows,
    List<DateWhereClause> clauses,
  ) {
    if (clauses.isEmpty) {
      return rows;
    }
    return rows
        .where((row) {
          for (final clause in clauses) {
            if (!_matchesDateClause(row, clause)) {
              return false;
            }
          }
          return true;
        })
        .toList(growable: false);
  }

  bool _matchesDateClause(Map<String, Object?> row, DateWhereClause clause) {
    final value = row[clause.column];
    final date = _coerceDate(value);
    if (date == null) return false;
    final target = _coerceDateComponent(clause.component, clause.value);
    if (target == null) return false;
    final componentValue = switch (clause.component) {
      DateComponent.year => date.year,
      DateComponent.month => date.month,
      DateComponent.day => date.day,
      DateComponent.date => DateTime(
        date.year,
        date.month,
        date.day,
      ).millisecondsSinceEpoch,
      DateComponent.time => _secondsSinceMidnight(date),
    };
    return _compare(componentValue, target, clause.operator);
  }

  List<Map<String, Object?>> _applyRawSelects(
    List<Map<String, Object?>> rows,
    List<RawSelectExpression> rawSelects,
  ) {
    if (rawSelects.isEmpty) return rows;
    return rows
        .map((row) {
          final enriched = Map<String, Object?>.from(row);
          for (final raw in rawSelects) {
            final alias = raw.alias ?? _aliasFromRawSelect(raw.sql) ?? raw.sql;
            final expression = _stripRawSelectAlias(raw.sql);
            enriched[alias] = _evaluateRawSelect(expression, enriched);
          }
          return enriched;
        })
        .toList(growable: false);
  }

  Object? _evaluateRawSelect(String expression, Map<String, Object?> row) {
    final trimmed = expression.trim();
    final upperMatch = RegExp(
      r'^UPPER\(\s*([A-Za-z0-9_]+)\s*\)$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (upperMatch != null) {
      final column = upperMatch.group(1)!;
      final value = row[column];
      if (value is String) {
        return value.toUpperCase();
      }
      return value;
    }
    final lowerMatch = RegExp(
      r'^LOWER\(\s*([A-Za-z0-9_]+)\s*\)$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (lowerMatch != null) {
      final column = lowerMatch.group(1)!;
      final value = row[column];
      if (value is String) {
        return value.toLowerCase();
      }
      return value;
    }
    final simple = RegExp(r'^[`"]?([A-Za-z0-9_]+)[`"]?$').firstMatch(trimmed);
    if (simple != null) {
      return row[simple.group(1)!];
    }
    return null;
  }

  num _secondsSinceMidnight(DateTime date) =>
      date.hour * 3600 + date.minute * 60 + date.second;

  String _stripRawSelectAlias(String sql) {
    final trimmed = sql.trim();
    final aliasMatch = _rawSelectAliasPattern.firstMatch(trimmed);
    if (aliasMatch == null) {
      return trimmed;
    }
    return trimmed.substring(0, aliasMatch.start).trim();
  }

  String? _aliasFromRawSelect(String sql) {
    final trimmed = sql.trim();
    final match = _rawSelectAliasPattern.firstMatch(trimmed);
    return match?.group(1);
  }

  static final _rawSelectAliasPattern = RegExp(
    r'\s+AS\s+([A-Za-z0-9_]+)\s*$',
    caseSensitive: false,
  );

  bool _compare(num left, num right, String operator) {
    switch (operator) {
      case '=':
      case '==':
        return left == right;
      case '!=':
      case '<>':
        return left != right;
      case '>':
        return left > right;
      case '>=':
        return left >= right;
      case '<':
        return left < right;
      case '<=':
        return left <= right;
      default:
        return left == right;
    }
  }

  DateTime? _coerceDate(Object? value) {
    if (value is DateTime) return value.toUtc();
    if (value is String) return DateTime.tryParse(value)?.toUtc();
    if (value is ObjectId) return value.dateTime.toUtc();
    return null;
  }

  num? _coerceDateComponent(DateComponent component, Object? value) {
    switch (component) {
      case DateComponent.year:
      case DateComponent.month:
      case DateComponent.day:
        return value is num ? value.toInt() : int.tryParse(value.toString());
      case DateComponent.date:
        final parsed = value is DateTime
            ? value
            : DateTime.tryParse(value.toString());
        return parsed?.toUtc().millisecondsSinceEpoch;
      case DateComponent.time:
        if (value is num) return value.toDouble();
        final parts = value.toString().split(':');
        if (parts.length < 2) return null;
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = int.tryParse(parts[1]) ?? 0;
        final seconds = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
        return hours * 3600 + minutes * 60 + seconds;
    }
  }

  @override
  Stream<Map<String, Object?>> stream(QueryPlan plan) async* {
    final rows = await execute(plan);
    for (final row in rows) {
      yield row;
    }
  }

  @override
  Future<MutationResult> runMutation(MutationPlan plan) async {
    final tableName = plan.definition.tableName;
    if (_droppedCollections.contains(tableName)) {
      throw Exception('Collection $tableName has been dropped.');
    }
    final collection = await _collection(plan.definition.tableName);
    switch (plan.operation) {
      case MutationOperation.insert:
        if (plan.rows.isEmpty) {
          return const MutationResult(affectedRows: 0);
        }
        final docs = plan.rows
            .map(
              (row) => MongoPlanCompiler.documentFromRow(row, plan.definition),
            )
            .toList();
        await collection.insertAll(docs);

        // If returning is requested, fetch the inserted records
        if (plan.returning) {
          final ids = docs
              .map((doc) => doc['_id'])
              .whereType<Object>()
              .toList();
          if (ids.isNotEmpty) {
            final inserted = await collection
                .find(where.oneFrom('_id', ids))
                .toList();
            final mapped = inserted
                .map((row) => Map<String, Object?>.from(row))
                .toList();
            final withId = _mapMongoIdToModelId(mapped);
            return MutationResult(
              affectedRows: docs.length,
              returnedRows: withId,
            );
          }
        }

        return MutationResult(affectedRows: docs.length);
      case MutationOperation.update:
        return await _applyUpdates(collection, plan.rows);
      case MutationOperation.delete:
        return await _applyDeletes(collection, plan.rows);
      case MutationOperation.queryUpdate:
        return await _applyQueryUpdate(collection, plan);
      case MutationOperation.queryDelete:
        return await _applyQueryDelete(collection, plan);
      case MutationOperation.upsert:
        return await _applyUpserts(collection, plan);
      default:
        throw UnsupportedError(
          'Mongo driver does not support ${plan.operation} yet.',
        );
    }
  }

  Future<MutationResult> _applyQueryUpdate(
    DbCollection collection,
    MutationPlan plan,
  ) async {
    final filter = MongoPlanCompiler.filtersForPlan(plan.queryPlan!);
    final updateDoc = buildUpdateDocument(
      plan.queryUpdateValues,
      plan.queryJsonUpdates,
      plan.queryIncrementValues,
    );
    if (updateDoc.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }
    final result = await collection.updateMany(filter, updateDoc);
    final affectedRows = _affectedRowsFromResult(result);

    // If returning is requested, fetch the updated records
    if (plan.returning && affectedRows > 0) {
      final updated = await collection.find(filter).toList();
      final mapped = updated
          .map((row) => Map<String, Object?>.from(row))
          .toList();
      final withId = _mapMongoIdToModelId(mapped);
      return MutationResult(affectedRows: affectedRows, returnedRows: withId);
    }

    return MutationResult(affectedRows: affectedRows);
  }

  Future<MutationResult> _applyQueryDelete(
    DbCollection collection,
    MutationPlan plan,
  ) async {
    final filter = MongoPlanCompiler.filtersForPlan(plan.queryPlan!);
    final result = await collection.remove(filter);
    return MutationResult(affectedRows: _affectedRowsFromResult(result));
  }

  Future<MutationResult> _applyUpserts(
    DbCollection collection,
    MutationPlan plan,
  ) async {
    if (plan.rows.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }
    var affected = 0;
    for (final row in plan.rows) {
      final filter = upsertFilter(row, plan.upsertUniqueColumns);
      final updates = upsertValues(
        row.values,
        plan.upsertUniqueColumns,
        plan.upsertUpdateColumns,
      );
      final updateDoc = buildSetDocument(updates, row.jsonUpdates);
      if (updateDoc.isEmpty) {
        continue;
      }
      final result = await collection.update(
        filter,
        updateDoc,
        multiUpdate: false,
        upsert: true,
      );
      affected += _affectedRowsFromResult(result);
    }
    return MutationResult(affectedRows: affected);
  }

  Future<MutationResult> _applyUpdates(
    DbCollection collection,
    List<MutationRow> rows,
  ) async {
    if (rows.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }
    var affected = 0;
    for (final row in rows) {
      final updates = _updateValues(row);
      final jsonColumns = row.jsonUpdates
          .map((clause) => clause.column)
          .toSet();
      final filteredUpdates = <String, Object?>{};
      for (final entry in updates.entries) {
        if (jsonColumns.contains(entry.key)) {
          continue;
        }
        filteredUpdates[entry.key] = entry.value;
      }
      final updateDoc = buildUpdateDocument(
        filteredUpdates,
        row.jsonUpdates,
        const {},
      );
      if (updateDoc.isEmpty) {
        continue;
      }
      final result = await collection.update(
        _filterForRow(row),
        updateDoc,
        multiUpdate: false,
      );
      affected += _affectedRowsFromResult(result);
    }
    return MutationResult(affectedRows: affected);
  }

  Future<MutationResult> _applyDeletes(
    DbCollection collection,
    List<MutationRow> rows,
  ) async {
    if (rows.isEmpty) {
      return const MutationResult(affectedRows: 0);
    }
    var affected = 0;
    for (final row in rows) {
      final result = await collection.remove(_filterForRow(row));
      affected += _affectedRowsFromResult(result);
    }
    return MutationResult(affectedRows: affected);
  }

  Map<String, Object?> _filterForRow(MutationRow row) =>
      _normalizePrimaryKeyFilter(Map<String, Object?>.from(row.keys));

  Map<String, Object?> _normalizePrimaryKeyFilter(Map<String, Object?> filter) {
    if (filter.isEmpty) {
      return filter;
    }
    // Don't transform id -> _id. Keep them as separate fields.
    // MongoDB uses _id as internal identifier (ObjectId),
    // but models can have their own 'id' field with any type.
    return Map<String, Object?>.from(filter);
  }

  Map<String, Object?> _updateValues(MutationRow row) {
    final values = Map<String, Object?>.from(row.values);
    for (final key in row.keys.keys) {
      values.remove(key);
    }
    return values;
  }

  int _affectedRowsFromResult(Object? result) {
    if (result is Map<String, Object?>) {
      final modified = result['nModified'];
      if (modified is int) return modified;
      final n = result['n'];
      if (n is int) return n;
      final ok = result['ok'];
      if (ok == 1 || ok == 1.0) {
        return 1;
      }
      return 0;
    }
    if (result is WriteResult) {
      if (result.nModified > 0) {
        return result.nModified;
      }
      if (result.nMatched > 0) {
        return result.nMatched;
      }
      if (result.nRemoved > 0) {
        return result.nRemoved;
      }
      if (result.operationSucceeded) {
        return 1;
      }
      return 0;
    }
    return 0;
  }

  /// Schema support
  @override
  Future<void> applySchemaPlan(SchemaPlan plan) async {
    final statements = _schemaCompiler.compile(plan).statements;
    for (final statement in statements) {
      final payload = statement.payload;
      if (payload is DocumentStatementPayload) {
        await _executeSchemaCommand(payload);
      }
    }
  }

  @override
  SchemaPreview describeSchemaPlan(SchemaPlan plan) =>
      _schemaCompiler.compile(plan);

  Future<void> _executeSchemaCommand(DocumentStatementPayload payload) async {
    final db = await _database();
    final args = payload.arguments;
    final collectionName = args['collection'] as String?;
    switch (payload.command) {
      case 'createCollection':
        if (collectionName == null) return;
        final command = <String, Object>{'create': collectionName};

        // Add validator
        final validator = args['validator'] as Map<String, Object?>?;
        if (validator != null) {
          command['validator'] = validator;
        }

        // Add validation options directly to command (validationLevel, validationAction)
        final options = args['options'] as Map<String, Object?>?;
        if (options != null) {
          for (final entry in options.entries) {
            final value = entry.value;
            if (value != null) {
              command[entry.key] = value;
            }
          }
        }

        await db.runCommand(command);
        break;
      case 'dropCollection':
        if (collectionName == null) return;
        await db.runCommand({'drop': collectionName});
        break;
      case 'createIndex':
        if (collectionName == null) return;
        final keys = args['keys'] as Map<String, Object?>?;
        if (keys == null) return;
        final indexDoc = <String, Object>{'key': keys};
        final name = args['name'] as String?;
        if (name != null) {
          indexDoc['name'] = name;
        }
        final indexOptions = args['options'] as Map<String, Object?>?;
        if (indexOptions != null) {
          for (final entry in indexOptions.entries) {
            final value = entry.value;
            if (value != null) {
              indexDoc[entry.key] = value;
            }
          }
        }
        await db.runCommand({
          'createIndexes': collectionName,
          'indexes': [indexDoc],
        });
        break;
      case 'dropIndex':
        if (collectionName == null) return;
        final name = args['name'] as String?;
        if (name == null) return;
        await db.runCommand({'dropIndexes': collectionName, 'index': name});
        break;
      case 'createSearchIndex':
        if (collectionName == null) return;
        final name = args['name'] as String?;
        final definition = args['definition'] as Map<String, Object?>?;
        final type = args['type'] as String?;
        if (definition == null) return;

        final command = <String, Object>{
          'createSearchIndexes': collectionName,
          'indexes': [
            {
              'name': name ?? 'default',
              'definition': definition,
              if (type == 'vectorSearch') 'type': 'vectorSearch',
            },
          ],
        };
        await db.runCommand(command);
        break;
      case 'dropSearchIndex':
        if (collectionName == null) return;
        final name = args['name'] as String?;
        if (name == null) return;
        await db.runCommand({'dropSearchIndex': collectionName, 'name': name});
        break;
      case 'modifyValidator':
        if (collectionName == null) return;
        final validator = args['validator'] as Map<String, Object?>?;
        final options = args['options'] as Map<String, Object?>?;
        if (validator == null && options == null) return;

        final command = <String, Object?>{'collMod': collectionName};
        if (validator != null) {
          command['validator'] = validator;
        }
        if (options != null) {
          command.addAll(options);
        }
        await db.runCommand(command as Map<String, Object>);
        break;
      default:
        break;
    }
  }

  @override
  Future<List<SchemaNamespace>> listSchemas() async => const [];

  @override
  Future<List<SchemaTable>> listTables({String? schema}) async =>
      _schemaInspector.listTables();

  @override
  Future<List<SchemaView>> listViews({String? schema}) async => const [];

  @override
  Future<List<SchemaColumn>> listColumns(
    String table, {
    String? schema,
  }) async => const [];

  @override
  Future<List<SchemaIndex>> listIndexes(String table, {String? schema}) async =>
      _schemaInspector.listIndexes(table);

  @override
  Future<List<SchemaForeignKey>> listForeignKeys(
    String table, {
    String? schema,
  }) async => const [];

  @override
  StatementPreview describeQuery(QueryPlan plan) =>
      _planCompiler.compileSelect(plan);

  @override
  StatementPreview describeMutation(MutationPlan plan) =>
      _planCompiler.compileMutation(plan);

  @override
  Future<R> transaction<R>(Future<R> Function() action) async {
    final previous = _currentSessionId;
    final sessionId = _nextSessionId();
    _currentSessionId = sessionId;
    MongoTransactionContext.beginSession(sessionId);
    try {
      final result = await action();
      MongoTransactionContext.commitSession();
      return result;
    } catch (error) {
      MongoTransactionContext.abortSession();
      rethrow;
    } finally {
      _currentSessionId = previous;
      if (previous != null) {
        MongoTransactionContext.currentSessionId = previous;
        MongoTransactionContext.sessionState = MongoTransactionState.active;
      }
    }
  }

  @override
  Future<void> beginTransaction() async {
    // MongoDB transactions require sessions and are more complex
    // For now, this is a no-op
  }

  @override
  Future<void> commitTransaction() async {
    // MongoDB transactions require sessions
    // For now, this is a no-op
  }

  @override
  Future<void> rollbackTransaction() async {
    // MongoDB transactions require sessions
    // For now, this is a no-op
  }

  @override
  Future<void> truncateTable(String tableName) async {
    final db = await _database();
    // MongoDB: drop all documents from collection
    await db.collection(tableName).deleteMany({});
  }

  @override
  Future<int?> threadCount() async => null;
}
