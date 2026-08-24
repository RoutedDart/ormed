import 'dart:async';

import 'query_plan.dart';
import 'plan/join_target.dart';

/// Shared change feed exposed by drivers that can observe external writes.
abstract interface class DriverChangeFeed {
  /// Changes committed by the underlying driver.
  QueryChangeBus get changeBus;
}

/// Describes a set of database tables read by a query.
///
/// Table dependencies let reactive queries refresh only when a relevant table
/// changes. [allTables] is used when a query contains an opaque SQL fragment
/// whose dependencies cannot be determined safely.
class QueryDependencies {
  QueryDependencies({
    Iterable<String> tables = const [],
    this.allTables = false,
  }) : tables = Set.unmodifiable(
         tables
             .map(normalizeDatabaseTableName)
             .where((table) => table.isNotEmpty),
       );

  /// The normalized table names read by the query.
  final Set<String> tables;

  /// Whether this query must refresh for every database change.
  final bool allTables;

  /// Returns whether [change] can affect this query.
  bool isAffectedBy(DatabaseChange change) {
    if (allTables || change.allTables) return true;
    return change.tables.any(tables.contains);
  }

  /// Builds dependencies from an Ormed query plan.
  factory QueryDependencies.fromPlan(
    QueryPlan plan, {
    Iterable<String> additionalTables = const [],
  }) {
    final collector = _QueryDependencyCollector();
    collector.addPlan(plan);
    collector.tables.addAll(additionalTables);
    return QueryDependencies(
      tables: collector.tables,
      allTables: collector.allTables,
    );
  }
}

class _QueryDependencyCollector {
  final Set<String> tables = <String>{};
  bool allTables = false;

  void addPlan(QueryPlan plan) {
    tables
      ..add(plan.definition.tableName)
      ..addAll(plan.readTables);

    for (final join in plan.joins) {
      _addJoinTarget(join.target);
    }
    for (final relation in plan.relationJoins) {
      for (final edge in relation.edges) {
        _addRelationSegment(edge.segment);
      }
    }
    for (final aggregate in plan.relationAggregates) {
      _addRelationPath(aggregate.path);
      addPredicate(aggregate.where);
    }
    for (final order in plan.relationOrders) {
      _addRelationPath(order.path);
      addPredicate(order.where);
    }
    for (final relation in plan.relations) {
      addPredicate(relation.predicate);
      for (final nested in relation.nested) {
        addPredicate(nested.predicate);
      }
    }

    addPredicate(plan.predicate);
    addPredicate(plan.having);

    // Opaque expressions can reference tables outside the structured query
    // model. Refresh conservatively until a driver-specific dependency hint
    // is supplied through QueryPlan.readTables.
    if (plan.rawSelects.isNotEmpty ||
        plan.customSelects.isNotEmpty ||
        plan.rawOrders.isNotEmpty ||
        plan.customOrders.isNotEmpty ||
        plan.rawGroupBy.isNotEmpty ||
        plan.customGroupBy.isNotEmpty) {
      allTables = true;
    }

    for (final union in plan.unions) {
      addPlan(union.plan);
    }
  }

  void addPredicate(QueryPredicate? predicate) {
    if (predicate == null) return;

    if (predicate is PredicateGroup) {
      for (final child in predicate.predicates) {
        addPredicate(child);
      }
      return;
    }
    if (predicate is SubqueryPredicate) {
      addPlan(predicate.subquery);
      return;
    }
    if (predicate is RelationPredicate) {
      _addRelationPath(predicate.path);
      addPredicate(predicate.where);
      return;
    }
    if (predicate is RawPredicate || predicate is CustomPredicate) {
      allTables = true;
    }
  }

  void _addJoinTarget(JoinTarget target) {
    final table = target.table;
    if (table != null) {
      tables.add(table);
    } else {
      // A subquery join is represented by SQL text, so its dependencies are
      // opaque here. Refreshing conservatively is safer than stale results.
      allTables = true;
    }
  }

  void _addRelationPath(RelationPath path) {
    for (final segment in path.segments) {
      _addRelationSegment(segment);
    }
  }

  void _addRelationSegment(RelationSegment segment) {
    tables
      ..add(segment.parentDefinition.tableName)
      ..add(segment.targetDefinition.tableName);
    if (segment.throughDefinition != null) {
      tables.add(segment.throughDefinition!.tableName);
    }
    if (segment.pivotTable != null) {
      tables.add(segment.pivotTable!);
    }
  }
}

/// Describes a committed database change that may invalidate live queries.
class DatabaseChange {
  DatabaseChange({
    Iterable<String> tables = const [],
    this.allTables = false,
    this.transactionId,
  }) : tables = Set.unmodifiable(
         tables
             .map(normalizeDatabaseTableName)
             .where((table) => table.isNotEmpty),
       );

  /// Creates a change that invalidates every query on the connection.
  factory DatabaseChange.all({String? transactionId}) =>
      DatabaseChange(allTables: true, transactionId: transactionId);

  /// The normalized tables changed by the operation.
  final Set<String> tables;

  /// Whether the change invalidates all queries.
  final bool allTables;

  /// The transaction identifier associated with the change, when available.
  final String? transactionId;
}

/// Broadcasts committed database changes to reactive queries.
class QueryChangeBus {
  final StreamController<DatabaseChange> _controller =
      StreamController<DatabaseChange>.broadcast();

  /// Changes emitted by this bus.
  Stream<DatabaseChange> get changes => _controller.stream;

  /// Publishes a committed change.
  void publish(DatabaseChange change) {
    if (!_controller.isClosed) {
      _controller.add(change);
    }
  }

  /// Closes this bus and all active subscriptions.
  Future<void> close() => _controller.close();
}

/// Normalizes table names used for dependency matching.
String normalizeDatabaseTableName(String table) {
  var normalized = table.trim();
  if (normalized.isEmpty) return normalized;

  final parts = normalized.split('.');
  normalized = parts.last.trim();
  if (normalized.length >= 2 &&
      ((normalized.startsWith('"') && normalized.endsWith('"')) ||
          (normalized.startsWith('`') && normalized.endsWith('`')) ||
          (normalized.startsWith('[') && normalized.endsWith(']')))) {
    normalized = normalized.substring(1, normalized.length - 1);
  }
  return normalized.toLowerCase();
}
