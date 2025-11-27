import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'dart:convert';

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
         capabilities: {
           DriverCapability.schemaIntrospection,
           DriverCapability.queryDeletes,
           DriverCapability.adHocQueryUpdates,
           DriverCapability.increment,
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
    // Register codec for ObjectId type to handle ObjectId <-> int conversion
    // when explicitly working with ObjectId values (e.g., for _id field).
    // Don't register for 'int' globally as that would convert ALL integers.
    final mongoCodecs = codecs.forDriver('mongo');
    mongoCodecs.registerCodec(
      key: 'ObjectId',
      codec: MongoObjectIdToIntCodec(),
    );
    return mongoCodecs;
  }

  final DatabaseConfig _config;
  final ConnectionFactory _connections;
  final ValueCodecRegistry _codecs;
  final DriverMetadata _metadata;
  final PlanCompiler _planCompiler;
  final SchemaPlanCompiler _schemaCompiler;
  ConnectionHandle<Db>? _primaryHandle;
  bool _closed = false;
  final Set<String> _droppedCollections = {};
  static const _unionExecutor = MongoUnionExecutor();
  String? _currentSessionId;
  int _sessionCounter = 0;
  late final MongoSchemaInspector _schemaInspector = MongoSchemaInspector(this);
  static const _aggregateBuilder = MongoAggregatePipelineBuilder();

  static final _dropTablePattern = RegExp(
    r'''DROP\s+TABLE\s+(?:IF\s+EXISTS\s+)?[`"]?([A-Za-z0-9_]+)[`"]?''',
    caseSensitive: false,
  );

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
      _primaryHandle = null;
    }
    _closed = true;
  }

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
      return null;
    }
    final projection = <String, Object>{};
    for (final fieldName in plan.selects) {
      final field = plan.definition.fieldByName(fieldName);
      if (field != null) {
        projection[field.columnName] = 1;
      } else {
        projection[fieldName] = 1;
      }
    }
    
    // Always include _id so we can map it to id
    projection['_id'] = 1;
    
    // Auto-include required fields for hydration
    for (final field in plan.definition.fields) {
      if (!field.isNullable && !projection.containsKey(field.columnName)) {
         projection[field.columnName] = 1;
      }
    }
    
    return projection;
  }

  @override
  Future<void> executeRaw(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    if (await _handleRawInsert(sql, parameters)) {
      return;
    }
    if (await _handleRawDelete(sql)) {
      return;
    }
    if (_handleRawSql(sql)) {
      return;
    }
    final match = _dropTablePattern.firstMatch(sql);
    if (match != null) {
      final collection = match.group(1);
      if (collection != null && collection.isNotEmpty) {
        _droppedCollections.add(collection);
        final db = await _database();
        try {
          await db.dropCollection(collection);
        } on MongoDartError {
          // ignore missing namespace
        }
        return;
      }
    }
    _logRawUnsupported(sql);
  }

  Future<bool> _handleRawInsert(String sql, List<Object?> parameters) async {
    final trimmed = sql.trim();
    final match = RegExp(
      r'''^insert\s+into\s+([`"]?[A-Za-z0-9_]+[`"]?)\s*\(([^)]+)\)\s*values\s*\(([^)]+)\)$''',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (match == null) {
      return false;
    }
    final table = _stripQuotes(match.group(1)!);
    final columns = match
        .group(2)!
        .split(',')
        .map((column) => _stripQuotes(column))
        .toList(growable: false);
    final values = match
        .group(3)!
        .split(',')
        .map((value) => value.trim())
        .toList(growable: false);
    final doc = <String, Object?>{};
    var paramIndex = 0;
    for (var i = 0; i < columns.length && i < values.length; i++) {
      doc[columns[i]] = _parseRawInsertValue(values[i], parameters, () {
        if (paramIndex >= parameters.length) {
          throw StateError('Missing parameter for raw INSERT: $sql');
        }
        return parameters[paramIndex++];
      });
    }
    final collection = await _collection(table);
    await collection.insert(doc);
    return true;
  }

  Future<bool> _handleRawDelete(String sql) async {
    final trimmed = sql.trim();
    final match = RegExp(
      r'^delete\s+from\s+([`"]?[A-Za-z0-9_]+[`"]?)$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (match == null) return false;
    final table = _stripQuotes(match.group(1)!);
    final collection = await _collection(table);
    await collection.remove({});
    return true;
  }

  bool _handleRawSql(String sql) {
    final trimmed = sql.trim();
    if (trimmed.isEmpty) {
      return true;
    }
    final lowered = trimmed.toLowerCase();
    if (lowered.startsWith('show ')) {
      _logRaw('Ignored SHOW', trimmed);
      return true;
    }
    if (lowered.startsWith('describe ') || lowered.startsWith('desc ')) {
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        final table = parts[1];
        _logRaw('Describe collection', table);
      } else {
        _logRaw('Describe ignored', trimmed);
      }
      return true;
    }
    return false;
  }

  void _logRaw(String label, String text) {
    print('[mongo raw] $label: $text');
  }

  void _logRawUnsupported(String sql) {
    print('[mongo raw] Unsupported SQL: $sql');
  }

  @override
  Future<List<Map<String, Object?>>> queryRaw(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    final trimmed = sql.trim();
    final lower = trimmed.toLowerCase();
    if (!lower.startsWith('select ')) {
      throw UnsupportedError('Raw SQL is not supported by the Mongo driver.');
    }
    const fromKeyword = ' from ';
    final fromIndex = lower.indexOf(fromKeyword);
    if (fromIndex < 0) {
      throw UnsupportedError('Raw SQL is not supported by the Mongo driver.');
    }
    final selectClause = trimmed.substring(6, fromIndex).trim();
    var remainder = trimmed.substring(fromIndex + fromKeyword.length).trim();
    String? whereSegment;
    String? orderSegment;
    const orderKeyword = ' order by ';
    final orderIndex = remainder.toLowerCase().indexOf(orderKeyword);
    if (orderIndex >= 0) {
      orderSegment = remainder
          .substring(orderIndex + orderKeyword.length)
          .trim();
      remainder = remainder.substring(0, orderIndex).trim();
    }
    const whereKeyword = ' where ';
    final whereIndex = remainder.toLowerCase().indexOf(whereKeyword);
    final tableSegment = whereIndex >= 0
        ? remainder.substring(0, whereIndex).trim()
        : remainder;
    if (whereIndex >= 0) {
      whereSegment = remainder
          .substring(whereIndex + whereKeyword.length)
          .trim();
    }
    return _executeSelectRaw(
      selectClause: selectClause,
      tableSegment: tableSegment,
      whereSegment: whereSegment,
      orderSegment: orderSegment,
      parameters: parameters,
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
    
    // DEBUG
    
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
    
    // Use modernFind if available, or standard find
    // Assuming modernFind is an extension or method on the collection object in this context
    final cursor = collection.modernFind(
      filter: filter.isNotEmpty ? filter : null,
      sort: sortArguments,
      projection: projection,
      limit: plan.limit,
      skip: skipValue,
    );
    
    final rows = await cursor.toList();
    final mapped = rows.map((row) => Map<String, Object?>.from(row)).toList();
    
    // Map _id to id if needed
    final withId = _mapMongoIdToModelId(mapped);
    
    final enriched = _applyRawSelects(withId, plan.rawSelects);
    return _applyDateWheres(enriched, plan.dateWheres);
  }

  Future<List<Map<String, Object?>>> _executeAggregatePlan(QueryPlan plan) async {
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
  /// Also handles type conversion (ObjectId -> int/String).
  List<Map<String, Object?>> _mapMongoIdToModelId(List<Map<String, Object?>> rows) {
    final codec = MongoObjectIdToIntCodec();
    return rows.map((row) {
      // If _id exists but id doesn't, map it
      if (row.containsKey('_id') && !row.containsKey('id')) {
        final mapped = Map<String, Object?>.from(row);
        var idValue = row['_id'];
        
        // Use the codec to decode the value
        // This handles ObjectId -> int conversion
        mapped['id'] = codec.decode(idValue);
        
        return mapped;
      }
      return row;
    }).toList();
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
      plan.aggregates.isNotEmpty || plan.randomOrder;

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

  Future<List<Map<String, Object?>>> _executeSelectRaw({
    required String selectClause,
    required String tableSegment,
    required String? whereSegment,
    required String? orderSegment,
    required List<Object?> parameters,
  }) async {
    final tableName = _stripQuotes(tableSegment);
    final columns = _splitSelectColumns(selectClause);
    final selector = _parseWhereClause(whereSegment, parameters);
    final orders = _parseOrderClause(orderSegment);
    final rows = await _queryCollection(tableName, selector);
    if (orders.isNotEmpty) {
      rows.sort((a, b) => _compareRows(a, b, orders));
    }
    if (columns.length == 1 && columns.first == '*') {
      return rows;
    }
    return rows
        .map((row) => _projectColumns(row, columns))
        .toList(growable: false);
  }

  Future<List<Map<String, Object?>>> _queryCollection(
    String table,
    Map<String, Object?> selector,
  ) async {
    final collection = await _collection(table);
    final cursor = collection.find(selector);
    final docs = await cursor.toList();
    return docs.map((doc) => Map<String, Object?>.from(doc)).toList();
  }

  Map<String, Object?> _projectColumns(
    Map<String, Object?> row,
    List<String> columns,
  ) {
    final projected = <String, Object?>{};
    for (final column in columns) {
      projected[column] = row[column];
    }
    return projected;
  }

  List<String> _splitSelectColumns(String clause) {
    final columns = clause.split(',');
    return columns
        .map((column) => column.replaceAll(RegExp(r'[`"]'), '').trim())
        .where((column) => column.isNotEmpty)
        .toList(growable: false);
  }

  Map<String, Object?> _parseWhereClause(
    String? clause,
    List<Object?> parameters,
  ) {
    if (clause == null || clause.trim().isEmpty) return const {};
    final selector = <String, Object?>{};
    final parts = clause.split(RegExp(r'\s+and\s+', caseSensitive: false));
    var paramIndex = 0;
    Object? nextParameter() {
      if (paramIndex >= parameters.length) {
        throw StateError('Missing queryRaw parameters for "$clause".');
      }
      return parameters[paramIndex++];
    }

    for (final part in parts) {
      final match = RegExp(
        r'^[`"]?([A-Za-z0-9_]+)[`"]?\s*=\s*(.+)$',
        caseSensitive: false,
      ).firstMatch(part.trim());
      if (match == null) continue;
      var column = match.group(1)!;
      final valueRaw = match.group(2)!.trim();
      Object? value;
      if (valueRaw == '?') {
        value = nextParameter();
      } else if (valueRaw.startsWith("'") && valueRaw.endsWith("'")) {
        value = valueRaw.substring(1, valueRaw.length - 1);
      } else if (valueRaw.startsWith('"') && valueRaw.endsWith('"')) {
        value = valueRaw.substring(1, valueRaw.length - 1);
      } else {
        final parsed = num.tryParse(valueRaw);
        value = parsed ?? valueRaw;
      }

      if (column == 'id') {
        column = '_id';
      }
      if (column == '_id') {
        if (value is int) {
          value = MongoObjectIdToIntCodec().encode(value);
        }
      }

      selector[column] = value;
    }
    return selector;
  }

  List<_RawOrder> _parseOrderClause(String? clause) {
    if (clause == null || clause.trim().isEmpty) return const [];
    return clause
        .split(',')
        .map((entry) {
          final parts = entry.trim().split(RegExp(r'\s+'));
          final column = parts.first.replaceAll(RegExp(r'[`"]'), '').trim();
          final descending =
              parts.length > 1 && parts[1].toLowerCase() == 'desc';
          return _RawOrder(column, descending: descending);
        })
        .toList(growable: false);
  }

  int _compareRows(
    Map<String, Object?> left,
    Map<String, Object?> right,
    List<_RawOrder> orders,
  ) {
    for (final order in orders) {
      final a = left[order.column];
      final b = right[order.column];
      final result = _compareValues(a, b);
      if (result != 0) {
        return order.descending ? -result : result;
      }
    }
    return 0;
  }

  int _compareValues(Object? a, Object? b) {
    if (a == b) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    if (a is Comparable && b is Comparable) {
      return (a as Comparable<Object?>).compareTo(b as Comparable<Object?>);
    }
    return 0;
  }

  String _stripQuotes(String value) =>
      value.replaceAll(RegExp(r'[`"]'), '').trim();

  Object? _parseRawInsertValue(
    String token,
    List<Object?> parameters,
    Object? Function() parameter,
  ) {
    if (token == '?') {
      final value = parameter();
      if (value is String && (value.startsWith('{') || value.startsWith('['))) {
        try {
          return jsonDecode(value);
        } catch (error) {
          // ignore invalid JSON in raw inserts
        }
      }
      return value;
    }
    if (token.startsWith("'") && token.endsWith("'")) {
      return token.substring(1, token.length - 1);
    }
    if (token.startsWith('"') && token.endsWith('"')) {
      return token.substring(1, token.length - 1);
    }
    final parsed = num.tryParse(token);
    return parsed ?? token;
  }

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

  num _secondsSinceMidnight(DateTime date) =>
      date.hour * 3600 + date.minute * 60 + date.second;

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
            .map((row) => MongoPlanCompiler.documentFromRow(row, plan.definition))
            .toList();
        await collection.insertAll(docs);
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
    return MutationResult(affectedRows: _affectedRowsFromResult(result));
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
      Map<String, Object?>.from(row.keys);

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
        final options = args['options'] as Map<String, Object?>?;
        if (options != null) {
          for (final entry in options.entries) {
            final value = entry.value;
            if (value != null) {
              command[entry.key] = value;
            }
          }
        }
        final validator = args['validator'] as Map<String, Object?>?;
        if (validator != null) {
          command['validator'] = validator;
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
      case 'modifyValidator':
        if (collectionName == null) return;
        final validator = args['validator'] as Map<String, Object?>?;
        if (validator == null) return;
        await db.runCommand({
          'collMod': collectionName,
          'validator': validator,
        });
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
  Future<int?> threadCount() async => null;
}

class _RawOrder {
  const _RawOrder(this.column, {this.descending = false});

  final String column;
  final bool descending;
}
