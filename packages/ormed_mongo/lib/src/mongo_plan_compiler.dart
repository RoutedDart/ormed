import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

import 'mongo_codecs.dart';
import 'mongo_query_plan_metadata.dart';
import 'mongo_update_utils.dart';
import 'mongo_transaction_context.dart';

/// Converts ORM plans into MongoDB command payloads.
class MongoPlanCompiler implements PlanCompiler {
  const MongoPlanCompiler();

  static const _aggregateBuilder = MongoAggregatePipelineBuilder();

  @override
  StatementPreview compileSelect(QueryPlan plan) {
    final sql = _legacySqlForPlan(plan);
    final metadata = metadataForPlan(plan);
    final statementMetadata = <String, Object?>{'sql': sql};
    final relationAggregateMetadata = metadata != null
        ? null
        : serializeRelationAggregates(plan.relationAggregates);
    final metadataJson = metadata?.toJson() ?? <String, Object?>{};
    if (metadataJson.isEmpty && relationAggregateMetadata != null) {
      if (relationAggregateMetadata.isNotEmpty) {
        metadataJson['relation_aggregates'] = relationAggregateMetadata;
      }
    }
    if (metadataJson.isNotEmpty) {
      statementMetadata['mongo_plan'] = metadataJson;
    }
    final sessionId =
        MongoTransactionContext.currentSessionId ?? metadata?.sessionId;
    if (sessionId != null) {
      statementMetadata['session_id'] = sessionId;
    }
    final sessionInfo = _sessionMetadata(metadata);
    if (sessionInfo != null) {
      statementMetadata['session'] = sessionInfo;
    }
    if (_isAggregatePlan(plan)) {
      final pipeline = _aggregateBuilder.build(plan);
      if (pipeline.isNotEmpty) {
        statementMetadata['mongo_pipeline'] = pipeline;
      }
      return StatementPreview(
        payload: DocumentStatementPayload(
          command: 'aggregate',
          arguments: {'pipeline': pipeline},
          metadata: statementMetadata,
        ),
      );
    }
    return StatementPreview(
      payload: DocumentStatementPayload(
        command: 'find',
        arguments: _buildFindArguments(plan),
        metadata: statementMetadata,
      ),
    );
  }

  @override
  StatementPreview compileMutation(MutationPlan plan) {
    switch (plan.operation) {
      case MutationOperation.insert:
        if (plan.rows.isEmpty) break;
        return StatementPreview(
          payload: DocumentStatementPayload(
            command: 'insertMany',
            arguments: {'documents': plan.rows.map(documentFromRow).toList()},
          ),
        );
      case MutationOperation.update:
        final updates = plan.rows
            .map(_buildUpdateEntry)
            .where((entry) => entry != null)
            .cast<Map<String, Object?>>()
            .toList();
        if (updates.isNotEmpty) {
          return StatementPreview(
            payload: DocumentStatementPayload(
              command: 'updateMany',
              arguments: {'updates': updates},
            ),
          );
        }
        break;
      case MutationOperation.delete:
        final deletes = plan.rows
            .map((row) => {'filter': mutationRowFilter(row)})
            .toList();
        if (deletes.isNotEmpty) {
          return StatementPreview(
            payload: DocumentStatementPayload(
              command: 'deleteMany',
              arguments: {'deletes': deletes},
            ),
          );
        }
        break;
      case MutationOperation.queryUpdate:
        final planFilter = filtersForPlan(plan.queryPlan!);
        final updateDoc = buildUpdateDocument(
          plan.queryUpdateValues,
          plan.queryJsonUpdates,
          plan.queryIncrementValues,
        );
        if (updateDoc.isNotEmpty) {
          final metadata = <String, Object?>{};
          final identifier = plan.queryPrimaryKey;
          if (identifier != null) {
            metadata['identifier_column'] = identifier;
          }
          return StatementPreview(
            payload: DocumentStatementPayload(
              command: 'updateMany',
              arguments: {'filter': planFilter, 'update': updateDoc},
              metadata: metadata.isEmpty ? null : metadata,
            ),
          );
        }
        break;
      case MutationOperation.queryDelete:
        final ops = <Map<String, Object?>>[];
        if (plan.queryPlan != null) {
          final planFilter = filtersForPlan(plan.queryPlan!);
          ops.add({
            'deleteOne': {'filter': planFilter},
          });
        } else {
          final planFilter = filtersForPlan(plan.queryPlan!);
          return StatementPreview(
            payload: DocumentStatementPayload(
              command: 'deleteMany',
              arguments: {'filter': planFilter},
            ),
          );
        }
        break;
      case MutationOperation.upsert:
        final operations = plan.rows
            .map(
              (row) => buildUpsertOperation(
                row,
                plan.upsertUniqueColumns,
                plan.upsertUpdateColumns,
              ),
            )
            .where((entry) => entry != null)
            .cast<Map<String, Object?>>()
            .toList();
        if (operations.isNotEmpty) {
          return StatementPreview(
            payload: DocumentStatementPayload(
              command: 'bulkWrite',
              arguments: {'operations': operations},
            ),
          );
        }
        break;
      default:
        break;
    }
    return StatementPreview(
      payload: DocumentStatementPayload(
        command: 'unsupported',
        arguments: {'operation': plan.operation.name},
      ),
    );
  }

  static Map<String, Object?> _buildFindArguments(QueryPlan plan) {
    final filter = buildFilter(plan.filters);
    final args = <String, Object?>{'filter': filter};
    final sort = buildSort(plan.orders);
    if (sort.isNotEmpty) {
      args['sort'] = sort;
    }
    if (plan.limit != null) {
      args['limit'] = plan.limit;
    }
    if (plan.offset != null) {
      args['skip'] = plan.offset;
    }
    // Handle explicit select projection
    if (plan.selects.isNotEmpty) {
      final projection = <String, Object?>{};
      projection['_id'] = 1; // Always include MongoDB's _id
      for (final select in plan.selects) {
        final fieldName = select == 'id' ? '_id' : select;
        projection[fieldName] = 1;
      }
      args['projection'] = projection;
    }
    return args;
  }

  static Map<String, Object?> buildFilter(List<FilterClause> filters) {
    final codec = MongoObjectIdToIntCodec();
    final selector = <String, Object?>{};
    for (final clause in filters) {
      var field = clause.field;
      final isIdField = field == 'id' || field == '_id';

      if (field == 'id') {
        field = '_id';
      }

      switch (clause.operator) {
        case FilterOperator.equals:
          final value = isIdField && clause.value is int
              ? codec.encode(clause.value as int)
              : clause.value;
          selector[field] = value;
          break;
        case FilterOperator.inValues:
          var value = clause.value;
          if (isIdField && value is List) {
            value = value.map((e) => e is int ? codec.encode(e) : e).toList();
          }
          selector[field] = {'\$in': value};
          break;
        case FilterOperator.greaterThan:
          final value = isIdField && clause.value is int
              ? codec.encode(clause.value as int)
              : clause.value;
          selector[field] = {'\$gt': value};
          break;
        case FilterOperator.greaterThanOrEqual:
          final value = isIdField && clause.value is int
              ? codec.encode(clause.value as int)
              : clause.value;
          selector[field] = {'\$gte': value};
          break;
        case FilterOperator.lessThan:
          final value = isIdField && clause.value is int
              ? codec.encode(clause.value as int)
              : clause.value;
          selector[field] = {'\$lt': value};
          break;
        case FilterOperator.lessThanOrEqual:
          final value = isIdField && clause.value is int
              ? codec.encode(clause.value as int)
              : clause.value;
          selector[field] = {'\$lte': value};
          break;
        case FilterOperator.contains:
          selector[field] = {'\$regex': clause.value};
          break;
        case FilterOperator.isNull:
          selector[field] = {'\$eq': null};
          break;
        case FilterOperator.isNotNull:
          selector[field] = {'\$ne': null};
          break;
      }
    }
    return selector;
  }

  static Map<String, Object?> buildPredicate(QueryPredicate? predicate) {
    if (predicate == null) return {};
    if (predicate is FieldPredicate) {
      return _buildFieldPredicate(predicate);
    } else if (predicate is PredicateGroup) {
      return _buildPredicateGroup(predicate);
    }
    return {};
  }

  static Map<String, Object?> _buildFieldPredicate(FieldPredicate predicate) {
    final codec = MongoObjectIdToIntCodec();
    var field = predicate.field;
    final isIdField = field == 'id' || field == '_id';

    if (field == 'id') {
      field = '_id';
    }
    final selector = <String, Object?>{};

    switch (predicate.operator) {
      case PredicateOperator.equals:
        final value = isIdField && predicate.value is int
            ? codec.encode(predicate.value as int)
            : predicate.value;
        selector[field] = value;
        break;
      case PredicateOperator.notEquals:
        final value = isIdField && predicate.value is int
            ? codec.encode(predicate.value as int)
            : predicate.value;
        selector[field] = {'\$ne': value};
        break;
      case PredicateOperator.inValues:
      case PredicateOperator.notInValues:
        var values = predicate.values ?? [];
        if (isIdField) {
          values = values.map((e) => e is int ? codec.encode(e) : e).toList();
        }
        selector[field] = {
          predicate.operator == PredicateOperator.inValues ? '\$in' : '\$nin':
              values,
        };
        break;
      case PredicateOperator.greaterThan:
        final value = isIdField && predicate.value is int
            ? codec.encode(predicate.value as int)
            : predicate.value;
        selector[field] = {'\$gt': value};
        break;
      case PredicateOperator.greaterThanOrEqual:
        final value = isIdField && predicate.value is int
            ? codec.encode(predicate.value as int)
            : predicate.value;
        selector[field] = {'\$gte': value};
        break;
      case PredicateOperator.lessThan:
        final value = isIdField && predicate.value is int
            ? codec.encode(predicate.value as int)
            : predicate.value;
        selector[field] = {'\$lt': value};
        break;
      case PredicateOperator.lessThanOrEqual:
        final value = isIdField && predicate.value is int
            ? codec.encode(predicate.value as int)
            : predicate.value;
        selector[field] = {'\$lte': value};
        break;
      case PredicateOperator.between:
      case PredicateOperator.notBetween:
        var lower = predicate.lower;
        var upper = predicate.upper;
        if (isIdField) {
          if (lower is int) lower = codec.encode(lower);
          if (upper is int) upper = codec.encode(upper);
        }
        final range = {'\$gte': lower, '\$lte': upper};
        if (predicate.operator == PredicateOperator.between) {
          selector[field] = range;
        } else {
          selector[field] = {'\$not': range};
        }
        break;
      case PredicateOperator.like:
      case PredicateOperator.iLike:
        // MongoDB regex for LIKE
        // This is a simplification, real implementation needs to escape and convert %/_
        selector[field] = {'\$regex': predicate.value};
        break;
      case PredicateOperator.isNotNull:
        selector[field] = {'\$ne': null};
        break;
      default:
        break;
    }
    return selector;
  }

  static Map<String, Object?> _buildPredicateGroup(PredicateGroup group) {
    final predicates = group.predicates
        .map(buildPredicate)
        .where((p) => p.isNotEmpty)
        .toList();
    if (predicates.isEmpty) return {};

    final op = group.logicalOperator == PredicateLogicalOperator.and
        ? '\$and'
        : '\$or';
    return {op: predicates};
  }

  static Map<String, Object?> buildSort(List<OrderClause> orders) {
    final map = <String, int>{};
    for (final order in orders) {
      var field = order.field;
      if (field == 'id') {
        field = '_id';
      }
      map[field] = order.descending ? -1 : 1;
    }
    return map;
  }

  static bool _isAggregatePlan(QueryPlan plan) =>
      plan.aggregates.isNotEmpty || plan.randomOrder;

  static String _legacySqlForPlan(QueryPlan plan) =>
      const SqliteQueryGrammar().compileSelect(plan).sql;

  static Map<String, Object?> filtersForPlan(QueryPlan plan) {
    // If a predicate is present, it contains the full query logic (including simple wheres).
    // We should use it exclusively to avoid conflicting AND logic from 'filters' which
    // are populated by QueryBuilder for backward compatibility but imply strict AND.
    if (plan.predicate != null) {
      final predicate = buildPredicate(plan.predicate);
      if (predicate.isNotEmpty) {
        return predicate;
      }
    }
    return buildFilter(plan.filters);
  }

  static Map<String, Object?>? _sessionMetadata(
    MongoQueryPlanMetadata? metadata,
  ) {
    final id = MongoTransactionContext.currentSessionId ?? metadata?.sessionId;
    if (id == null) {
      return null;
    }
    final state = MongoTransactionContext.sessionState.name;
    final map = <String, Object?>{'id': id, 'state': state};
    final started =
        MongoTransactionContext.sessionStartedAt ?? metadata?.sessionStartedAt;
    final ended =
        MongoTransactionContext.sessionEndedAt ?? metadata?.sessionEndedAt;
    if (started != null) {
      map['started_at'] = started.toIso8601String();
    }
    if (ended != null) {
      map['ended_at'] = ended.toIso8601String();
    }
    return map;
  }

  static Map<String, Object?> documentFromRow(
    MutationRow row, [
    ModelDefinition? definition,
  ]) {
    final map = Map<String, Object?>.from(row.values);

    if (definition != null) {
      final pk = definition.primaryKeyField;
      if (pk != null && map.containsKey(pk.name)) {
        final value = map.remove(pk.name);
        if (value is int) {
          map['_id'] = MongoObjectIdToIntCodec().encode(value);
        } else {
          map['_id'] = value;
        }
      }
    }

    return map;
  }

  static Map<String, Object?>? _buildUpdateEntry(MutationRow row) {
    final filter = mutationRowFilter(row);
    final values = mutationRowValues(row);
    final updateDoc = buildSetDocument(values, row.jsonUpdates);
    if (updateDoc.isEmpty) {
      return null;
    }
    return {'filter': filter, 'update': updateDoc};
  }
}

class MongoAggregatePipelineBuilder {
  const MongoAggregatePipelineBuilder();

  List<Map<String, Object?>> build(QueryPlan plan) {
    final matchStage = _buildMatch(plan);
    final pipeline = <Map<String, Object?>>[];
    if (matchStage != null) {
      pipeline.add(matchStage);
    }
    
    // Add $lookup stages for relation aggregates
    if (plan.relationAggregates.isNotEmpty) {
      _addRelationAggregateLookups(pipeline, plan);
    }
    
    if (plan.aggregates.isEmpty) {
      return pipeline;
    }
    final targets = _aggregateTargets(plan);
    pipeline.add({'\$group': _buildGroup(plan, targets)});
    final havingStage = _buildHaving(plan, targets);
    if (havingStage != null) {
      pipeline.add(havingStage);
    }
    pipeline.add(_buildProject(plan, targets));
    final metadata = metadataForPlan(plan);
    final stages = metadata?.pipelineStages ?? const <Map<String, Object?>>[];
    if (stages.isNotEmpty) {
      pipeline.addAll(stages);
    }
    if (plan.randomOrder) {
      // Use $sample for random ordering
      // If limit is not set, use a large number to effectively sample all documents
      final size = plan.limit ?? 100000;
      pipeline.add({
        '\$sample': {'size': size},
      });
    } else {
      final sortStage = _buildSort(plan, targets);
      if (sortStage != null) {
        pipeline.add(sortStage);
      }
      if (plan.offset != null && plan.offset! > 0) {
        pipeline.add({'\$skip': plan.offset});
      }
      if (plan.limit != null) {
        pipeline.add({'\$limit': plan.limit});
      }
    }
    return pipeline;
  }
  
  void _addRelationAggregateLookups(
    List<Map<String, Object?>> pipeline,
    QueryPlan plan,
  ) {
    for (final aggregate in plan.relationAggregates) {
      final segment = aggregate.path.segments.first;
      final relation = segment.relation;
      
      // Build lookup stage
      final lookup = <String, Object?>{};
      lookup['from'] = segment.targetDefinition.tableName;
      lookup['as'] = '__${aggregate.alias}_docs';
      
      // Build local and foreign field mappings
      if (relation.kind == RelationKind.hasMany || 
          relation.kind == RelationKind.hasOne) {
        lookup['localField'] = segment.parentKey;
        lookup['foreignField'] = segment.childKey;
      } else if (relation.kind == RelationKind.belongsTo) {
        lookup['localField'] = segment.parentKey;
        lookup['foreignField'] = segment.childKey;
      }
      
      // Add where clause if present
      if (aggregate.where != null) {
        final letVars = <String, String>{};
        letVars['local_key'] = '\$${segment.parentKey}';
        lookup['let'] = letVars;
        
        final subPipeline = <Map<String, Object?>>[];
        // Match the relation key
        subPipeline.add({
          '\$match': {'\$expr': {'\$eq': ['\$${segment.childKey}', '\$\$local_key']}}
        });
        // TODO: Convert aggregate.where to MongoDB filter
        // For now, this basic implementation will work
        lookup['pipeline'] = subPipeline;
      }
      
      pipeline.add({'\$lookup': lookup});
      
      // Add aggregation expression
      final addFields = <String, Object?>{};
      switch (aggregate.type) {
        case RelationAggregateType.count:
          addFields[aggregate.alias] = {'\$size': '\$__${aggregate.alias}_docs'};
          break;
        case RelationAggregateType.sum:
          if (aggregate.column != null) {
            addFields[aggregate.alias] = {
              '\$sum': '\$__${aggregate.alias}_docs.${aggregate.column}'
            };
          }
          break;
        case RelationAggregateType.avg:
          if (aggregate.column != null) {
            addFields[aggregate.alias] = {
              '\$avg': '\$__${aggregate.alias}_docs.${aggregate.column}'
            };
          }
          break;
        case RelationAggregateType.max:
          if (aggregate.column != null) {
            addFields[aggregate.alias] = {
              '\$max': '\$__${aggregate.alias}_docs.${aggregate.column}'
            };
          }
          break;
        case RelationAggregateType.min:
          if (aggregate.column != null) {
            addFields[aggregate.alias] = {
              '\$min': '\$__${aggregate.alias}_docs.${aggregate.column}'
            };
          }
          break;
        case RelationAggregateType.exists:
          addFields[aggregate.alias] = {
            '\$gt': [{'\$size': '\$__${aggregate.alias}_docs'}, 0]
          };
          break;
      }
      
      if (addFields.isNotEmpty) {
        pipeline.add({'\$addFields': addFields});
      }
      
      // Clean up temporary field
      pipeline.add({
        '\$project': {'__${aggregate.alias}_docs': 0}
      });
    }
  }

  Map<String, Object?>? _buildMatch(QueryPlan plan) {
    final selector = MongoPlanCompiler.buildFilter(plan.filters);
    if (selector.isEmpty) {
      return null;
    }
    return {'\$match': selector};
  }

  Map<String, Object?> _buildGroup(
    QueryPlan plan,
    List<_MongoAggregateTarget> targets,
  ) {
    final group = <String, Object?>{};
    group['_id'] = _groupIdExpression(plan.groupBy, plan);

    // Always preserve the original document _id using $first,
    // so we can hydrate the model later.
    // We use a temporary name '__original_id' to avoid conflict with the group key '_id'.
    group['__original_id'] = {'\$first': '\$_id'};

    // Auto-include required fields for hydration using $first
    for (final field in plan.definition.fields) {
      if (field.isPrimaryKey) continue;
      if (!field.isNullable &&
          !plan.groupBy.contains(field.name) &&
          !targets.any((t) => t.alias == field.name)) {
        group[field.columnName] = {'\$first': '\$${field.columnName}'};
      }
    }

    for (final target in targets) {
      group[target.alias] = target.accumulator;
    }
    return group;
  }

  Map<String, Object?> _buildProject(
    QueryPlan plan,
    List<_MongoAggregateTarget> targets,
  ) {
    final projection = <String, Object?>{};
    
    // If explicit selects are specified (and not grouping), only project those
    if (plan.selects.isNotEmpty && plan.groupBy.isEmpty) {
      projection['_id'] = 1; // Always include MongoDB's _id
      for (final select in plan.selects) {
        final fieldName = select == 'id' ? '_id' : select;
        projection[fieldName] = 1;
      }
      // Also include any aggregate targets
      for (final target in targets) {
        projection[target.alias] = 1;
      }
      return {'\$project': projection};
    }
    
    // Include _id (MongoDB's primary key) for model hydration
    // If we're grouping, _id contains the group key(s), so we need to project it appropriately
    if (plan.groupBy.isNotEmpty) {
      // When grouping, _id contains the grouped values
      // We need to extract them back to their original field names
      for (final column in plan.groupBy) {
        final field = plan.groupBy.length == 1 ? '\$_id' : '\$_id.$column';
        projection[column] = field;
      }
      // Restore the original _id preserved in __original_id
      projection['_id'] = '\$__original_id';

      // Include required fields that were preserved via $first
      for (final field in plan.definition.fields) {
        if (field.isPrimaryKey) continue;
        if (!field.isNullable &&
            !plan.groupBy.contains(field.name) &&
            !targets.any((t) => t.alias == field.name)) {
          projection[field.columnName] = 1;
        }
      }
    } else {
      // When not grouping, include _id as-is
      projection['_id'] = 1;
    }
    for (final target in targets) {
      projection[target.alias] = 1;
    }
    return {'\$project': projection};
  }

  Map<String, Object?>? _buildSort(
    QueryPlan plan,
    List<_MongoAggregateTarget> targets,
  ) {
    final allowedFields = {
      ...plan.groupBy,
      ...targets.map((target) => target.alias),
    };
    final sort = <String, int>{};
    for (final order in plan.orders) {
      if (!allowedFields.contains(order.field)) {
        continue;
      }
      sort[order.field] = order.descending ? -1 : 1;
    }
    if (sort.isEmpty) {
      return null;
    }
    return {'\$sort': sort};
  }

  Map<String, Object?>? _buildHaving(
    QueryPlan plan,
    List<_MongoAggregateTarget> targets,
  ) {
    final having = plan.having;
    if (having == null) {
      return null;
    }
    final allowedFields = {
      ...plan.groupBy,
      ...targets.map((target) => target.alias),
    };
    final compiled = _compilePredicate(having, allowedFields);
    if (compiled == null || compiled.isEmpty) {
      return null;
    }
    return {'\$match': compiled};
  }

  Map<String, Object?>? _compilePredicate(
    QueryPredicate predicate,
    Set<String> allowedFields,
  ) {
    if (predicate is FieldPredicate) {
      return _compileFieldPredicate(predicate, allowedFields);
    }
    if (predicate is PredicateGroup) {
      final compiled = predicate.predicates
          .map((child) => _compilePredicate(child, allowedFields))
          .where((map) => map != null)
          .cast<Map<String, Object?>>()
          .toList();
      if (compiled.isEmpty) {
        return null;
      }
      final key = predicate.logicalOperator == PredicateLogicalOperator.or
          ? '\$or'
          : '\$and';
      return {key: compiled};
    }
    return null;
  }

  Map<String, Object?>? _compileFieldPredicate(
    FieldPredicate predicate,
    Set<String> allowedFields,
  ) {
    if (!allowedFields.contains(predicate.field)) {
      return null;
    }
    final field = predicate.field;
    switch (predicate.operator) {
      case PredicateOperator.equals:
        return {field: predicate.value};
      case PredicateOperator.notEquals:
        return {
          field: {'\$ne': predicate.value},
        };
      case PredicateOperator.greaterThan:
        return {
          field: {'\$gt': predicate.value},
        };
      case PredicateOperator.greaterThanOrEqual:
        return {
          field: {'\$gte': predicate.value},
        };
      case PredicateOperator.lessThan:
        return {
          field: {'\$lt': predicate.value},
        };
      case PredicateOperator.lessThanOrEqual:
        return {
          field: {'\$lte': predicate.value},
        };
      case PredicateOperator.between:
        if (predicate.lower == null || predicate.upper == null) {
          return null;
        }
        return {
          field: {'\$gte': predicate.lower, '\$lte': predicate.upper},
        };
      case PredicateOperator.notBetween:
        if (predicate.lower == null || predicate.upper == null) {
          return null;
        }
        return {
          '\$or': [
            {
              field: {'\$lt': predicate.lower},
            },
            {
              field: {'\$gt': predicate.upper},
            },
          ],
        };
      case PredicateOperator.inValues:
        final values =
            predicate.values ??
            (predicate.value is Iterable
                ? List<Object?>.from(predicate.value as Iterable)
                : const <Object?>[]);
        if (values.isEmpty) {
          return null;
        }
        return {
          field: {'\$in': values},
        };
      case PredicateOperator.notInValues:
        final values =
            predicate.values ??
            (predicate.value is Iterable
                ? List<Object?>.from(predicate.value as Iterable)
                : const <Object?>[]);
        if (values.isEmpty) {
          return null;
        }
        return {
          field: {'\$nin': values},
        };
      case PredicateOperator.isNull:
        return {
          field: {'\$eq': null},
        };
      case PredicateOperator.isNotNull:
        return {
          field: {'\$ne': null},
        };
      default:
        return null;
    }
  }

  List<_MongoAggregateTarget> _aggregateTargets(QueryPlan plan) {
    var index = 0;
    return plan.aggregates
        .map((aggregate) {
          final alias = aggregate.alias ?? _defaultAlias(aggregate, index++);
          final accumulator = _accumulatorFor(aggregate, plan);
          return _MongoAggregateTarget(alias: alias, accumulator: accumulator);
        })
        .toList(growable: false);
  }

  String _defaultAlias(AggregateExpression aggregate, int index) {
    final sanitized = aggregate.expression
        .replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_')
        .trim();
    final base = sanitized.isNotEmpty ? sanitized : aggregate.function.name;
    return '${base}_$index';
  }

  Map<String, Object?> _accumulatorFor(
    AggregateExpression aggregate,
    QueryPlan plan,
  ) {
    final expression = aggregate.expression;
    final ref = _fieldReference(expression, plan);
    switch (aggregate.function) {
      case AggregateFunction.count:
        return {'\$sum': 1};
      case AggregateFunction.sum:
        return {'\$sum': ref};
      case AggregateFunction.avg:
        return {'\$avg': ref};
      case AggregateFunction.min:
        return {'\$min': ref};
      case AggregateFunction.max:
        return {'\$max': ref};
    }
  }

  Object _fieldReference(String expression, QueryPlan plan) {
    if (expression == '*') {
      return 1;
    }
    final field = plan.definition.fieldByName(expression);
    final column = field?.columnName ?? expression;
    return '\$$column';
  }

  Object _groupIdExpression(List<String> columns, QueryPlan plan) {
    if (columns.isEmpty) {
      return 0;
    }
    if (columns.length == 1) {
      return _fieldReference(columns.first, plan);
    }
    final id = <String, Object?>{};
    for (final column in columns) {
      // We need to use the field name as the key in _id so we can extract it later
      // But the value must be the column reference
      // Wait, _buildProject expects keys in _id to match what?
      // My _buildProject uses plan.groupBy (which are field names).
      // So keys in _id MUST be field names (or whatever is in plan.groupBy).
      // And values must be column references.

      // plan.groupBy contains field names.
      // So key = column (field name), value = _fieldReference(column, plan) (column name ref).
      id[column] = _fieldReference(column, plan);
    }
    return id;
  }
}

class _MongoAggregateTarget {
  _MongoAggregateTarget({required this.alias, required this.accumulator});

  final String alias;
  final Object accumulator;
}
