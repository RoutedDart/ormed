import '../ormed.dart';
import '../src/query/json_path.dart' as json_path;

/// Deterministic driver adapter that evaluates plans against in-memory rows.
class InMemoryQueryExecutor implements DriverAdapter {
  InMemoryQueryExecutor({ValueCodecRegistry? codecRegistry})
    : codecRegistry = codecRegistry ?? ValueCodecRegistry.standard();

  final ValueCodecRegistry codecRegistry;
  final Map<String, List<Map<String, Object?>>> _tables = {};

  @override
  DriverMetadata get metadata => const DriverMetadata(
    name: 'in_memory',
    requiresPrimaryKeyForQueryUpdate: false,
    capabilities: {
      DriverCapability.joins,
      DriverCapability.insertUsing,
      DriverCapability.adHocQueryUpdates,
      DriverCapability.schemaIntrospection,
      DriverCapability.advancedQueryBuilders,
      DriverCapability.sqlPreviews,
    },
  );

  /// Registers [records] for the table described by [definition].
  void register<T>(ModelDefinition<T> definition, Iterable<T> records) {
    final table = _tables.putIfAbsent(
      definition.tableName,
      () => <Map<String, Object?>>[],
    );
    for (final record in records) {
      table.add(definition.toMap(record, registry: codecRegistry));
    }
  }

  /// Removes all registered tables and rows.
  void clear() => _tables.clear();

  @override
  Future<List<Map<String, Object?>>> execute(QueryPlan plan) async {
    final source =
        _tables[plan.definition.tableName] ?? const <Map<String, Object?>>[];
    var rows = source.map((row) => Map<String, Object?>.from(row)).toList();
    rows = rows.where((row) => _matchesFilters(row, plan.filters)).toList();
    if (plan.orders.isNotEmpty) {
      rows.sort((a, b) => _compareByOrder(a, b, plan.orders));
    }
    if (plan.offset != null && plan.offset! < rows.length) {
      rows = rows.sublist(plan.offset!);
    }
    if (plan.limit != null && plan.limit! < rows.length) {
      rows = rows.sublist(0, plan.limit!);
    }
    return rows;
  }

  @override
  Stream<Map<String, Object?>> stream(QueryPlan plan) async* {
    final rows = await execute(plan);
    for (final row in rows) {
      yield row;
    }
  }

  @override
  StatementPreview describeQuery(QueryPlan plan) => const StatementPreview(
    payload: SqlStatementPayload(sql: '<in-memory>', parameters: []),
    resolvedText: '<in-memory>',
  );

  @override
  ValueCodecRegistry get codecs => codecRegistry;

  @override
  PlanCompiler get planCompiler => fallbackPlanCompiler();

  @override
  Future<void> close() async => clear();

  @override
  Future<void> executeRaw(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {}

  @override
  Future<List<Map<String, Object?>>> queryRaw(
    String sql, [
    List<Object?> parameters = const [],
  ]) =>
      throw UnsupportedError('InMemoryQueryExecutor does not support raw SQL.');

  @override
  Future<MutationResult> runMutation(MutationPlan plan) async {
    switch (plan.operation) {
      case MutationOperation.insert:
        final table = _table(plan.definition);
        var affected = 0;
        for (final row in plan.rows) {
          if (_shouldSkipInsert(plan, row.values)) {
            continue;
          }
          table.add(Map<String, Object?>.from(row.values));
          affected++;
        }
        return MutationResult(
          affectedRows: plan.ignoreConflicts ? affected : plan.rows.length,
        );
      case MutationOperation.insertUsing:
        final queryPlan = plan.queryPlan;
        if (queryPlan == null || plan.insertColumns.isEmpty) {
          return const MutationResult(affectedRows: 0);
        }
        final sourceRows = _queryMatches(queryPlan);
        final table = _table(plan.definition);
        var affected = 0;
        for (final source in sourceRows) {
          final values = <String, Object?>{
            for (final column in plan.insertColumns) column: source[column],
          };
          if (_shouldSkipInsert(plan, values)) {
            continue;
          }
          table.add(Map<String, Object?>.from(values));
          affected++;
        }
        return MutationResult(
          affectedRows: plan.ignoreConflicts ? affected : sourceRows.length,
        );
      case MutationOperation.update:
        final table = _table(plan.definition);
        var affected = 0;
        for (final row in plan.rows) {
          final match = table.firstWhere(
            (candidate) => _matches(candidate, row.keys),
            orElse: () => const {},
          );
          if (match.isEmpty) continue;
          match.addAll(row.values);
          _applyJsonUpdates(match, row.jsonUpdates);
          affected++;
        }
        return MutationResult(affectedRows: affected);
      case MutationOperation.delete:
        final table = _table(plan.definition);
        table.removeWhere(
          (candidate) => plan.rows.any((row) => _matches(candidate, row.keys)),
        );
        return MutationResult(affectedRows: plan.rows.length);
      case MutationOperation.upsert:
        final table = _table(plan.definition);
        var affected = 0;
        for (final row in plan.rows) {
          final selector = _upsertSelector(plan, row);
          final index = table.indexWhere(
            (candidate) => _matches(candidate, selector),
          );
          if (index == -1) {
            table.add(Map<String, Object?>.from(row.values));
          } else {
            final updates = _upsertColumnsToUpdate(
              plan,
              row.values.keys,
              selector.keys,
            );
            if (updates.isEmpty) {
              table[index].addAll(row.values);
            } else {
              for (final column in updates) {
                table[index][column] = row.values[column];
              }
            }
            _applyJsonUpdates(table[index], row.jsonUpdates);
          }
          affected++;
        }
        return MutationResult(affectedRows: affected);
      case MutationOperation.queryDelete:
        throw UnsupportedError('Query deletes are not supported in-memory');
      case MutationOperation.queryUpdate:
        final queryPlan = plan.queryPlan;
        if (queryPlan == null ||
            (plan.queryUpdateValues.isEmpty &&
                plan.queryJsonUpdates.isEmpty &&
                plan.queryIncrementValues.isEmpty)) {
          return const MutationResult(affectedRows: 0);
        }
        final matches = _queryMatches(queryPlan);
        for (final row in matches) {
          if (plan.queryUpdateValues.isNotEmpty) {
            row.addAll(plan.queryUpdateValues);
          }
          if (plan.queryIncrementValues.isNotEmpty) {
            for (final entry in plan.queryIncrementValues.entries) {
              final column = entry.key;
              final amount = entry.value;
              final current = row[column];
              if (current is num) {
                row[column] = current + amount;
              } else {
                row[column] = amount;
              }
            }
          }
          _applyJsonUpdates(row, plan.queryJsonUpdates);
        }
        return MutationResult(affectedRows: matches.length);
    }
  }

  @override
  StatementPreview describeMutation(MutationPlan plan) =>
      const StatementPreview(
        payload: SqlStatementPayload(sql: '<in-memory>', parameters: []),
        resolvedText: '<in-memory>',
      );

  @override
  Future<int?> threadCount() async => null;

  List<Map<String, Object?>> _queryMatches(QueryPlan plan) {
    final table = _table(plan.definition);
    var rows = table
        .where((row) => _matchesFilters(row, plan.filters))
        .toList();
    if (plan.orders.isNotEmpty) {
      rows.sort((a, b) => _compareByOrder(a, b, plan.orders));
    }
    if (plan.offset != null && plan.offset! < rows.length) {
      rows = rows.sublist(plan.offset!);
    }
    if (plan.limit != null && plan.limit! < rows.length) {
      rows = rows.sublist(0, plan.limit!);
    }
    return rows;
  }

  List<Map<String, Object?>> _table(ModelDefinition<dynamic> definition) =>
      _tables.putIfAbsent(definition.tableName, () => <Map<String, Object?>>[]);

  bool _matches(Map<String, Object?> candidate, Map<String, Object?> keys) {
    if (keys.isEmpty) return false;
    for (final entry in keys.entries) {
      if (candidate[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  Future<R> transaction<R>(Future<R> Function() action) => Future.sync(action);

  bool _matchesFilters(Map<String, Object?> row, List<FilterClause> filters) {
    for (final filter in filters) {
      final value = row[filter.field];
      switch (filter.operator) {
        case FilterOperator.equals:
          if (value != filter.value) return false;
          break;
        case FilterOperator.greaterThan:
          if (!_compareComparable(value, filter.value, (c) => c > 0)) {
            return false;
          }
          break;
        case FilterOperator.greaterThanOrEqual:
          if (!_compareComparable(value, filter.value, (c) => c >= 0)) {
            return false;
          }
          break;
        case FilterOperator.lessThan:
          if (!_compareComparable(value, filter.value, (c) => c < 0)) {
            return false;
          }
          break;
        case FilterOperator.lessThanOrEqual:
          if (!_compareComparable(value, filter.value, (c) => c <= 0)) {
            return false;
          }
          break;
        case FilterOperator.contains:
          final target = value?.toString();
          final needle = filter.value?.toString() ?? '';
          if (target == null || !target.contains(needle)) return false;
          break;
        case FilterOperator.inValues:
          final values = (filter.value as Iterable?)?.toSet() ?? const {};
          if (!values.contains(value)) return false;
          break;
        case FilterOperator.isNull:
          if (value != null) return false;
          break;
        case FilterOperator.isNotNull:
          if (value == null) return false;
          break;
      }
    }
    return true;
  }

  bool _compareComparable(
    Object? left,
    Object? right,
    bool Function(int result) evaluation,
  ) {
    if (left is Comparable && right is Comparable) {
      final result = left.compareTo(right);
      return evaluation(result);
    }
    return false;
  }

  int _compareByOrder(
    Map<String, Object?> a,
    Map<String, Object?> b,
    List<OrderClause> orders,
  ) {
    for (final clause in orders) {
      final left = a[clause.field];
      final right = b[clause.field];
      int result = 0;
      if (left is Comparable && right is Comparable) {
        result = left.compareTo(right);
      } else if (left == right) {
        result = 0;
      } else if (left == null) {
        result = -1;
      } else if (right == null) {
        result = 1;
      }
      if (result != 0) {
        return clause.descending ? -result : result;
      }
    }
    return 0;
  }

  bool _shouldSkipInsert(MutationPlan plan, Map<String, Object?> values) {
    if (!plan.ignoreConflicts) {
      return false;
    }
    final pk = plan.definition.primaryKeyField?.columnName;
    if (pk == null) {
      return false;
    }
    final table = _table(plan.definition);
    return table.any((existing) => existing[pk] == values[pk]);
  }

  Map<String, Object?> _upsertSelector(MutationPlan plan, MutationRow row) {
    if (plan.upsertUniqueColumns.isNotEmpty) {
      return {
        for (final column in plan.upsertUniqueColumns)
          column: row.values[column],
      };
    }
    return row.keys;
  }

  List<String> _upsertColumnsToUpdate(
    MutationPlan plan,
    Iterable<String> valueColumns,
    Iterable<String> selectorColumns,
  ) {
    if (plan.upsertUpdateColumns.isNotEmpty) {
      return plan.upsertUpdateColumns;
    }
    final selectors = selectorColumns.toSet();
    return valueColumns.where((column) => !selectors.contains(column)).toList();
  }

  void _applyJsonUpdates(
    Map<String, Object?> row,
    List<JsonUpdateClause> updates,
  ) {
    if (updates.isEmpty) return;
    for (final clause in updates) {
      final segments = json_path.jsonPathSegments(clause.path);
      if (segments.isEmpty) {
        row[clause.column] = clause.value;
        continue;
      }
      final current = row[clause.column];
      final updated = _applyJsonValue(current, segments, clause.value);
      row[clause.column] = updated;
    }
  }

  Object? _applyJsonValue(
    Object? current,
    List<String> segments,
    Object? value,
  ) {
    if (segments.isEmpty) {
      return value;
    }
    final head = segments.first;
    final remaining = segments.length == 1
        ? const <String>[]
        : segments.sublist(1);
    final index = int.tryParse(head);
    if (index != null) {
      final list = _prepareList(current);
      while (list.length <= index) {
        list.add(null);
      }
      list[index] = _applyJsonValue(list[index], remaining, value);
      return list;
    }
    final map = _prepareMap(current);
    map[head] = _applyJsonValue(map[head], remaining, value);
    return map;
  }

  Map<String, Object?> _prepareMap(Object? current) {
    if (current is Map<String, Object?>) {
      return current;
    }
    if (current is Map) {
      final converted = <String, Object?>{};
      current.forEach((key, value) {
        final normalizedKey = key is String
            ? key
            : (key == null ? '' : key.toString());
        converted[normalizedKey] = value;
      });
      return converted;
    }
    return <String, Object?>{};
  }

  List<Object?> _prepareList(Object? current) {
    if (current is List<Object?>) {
      return current;
    }
    if (current is List) {
      return current.cast<Object?>();
    }
    return <Object?>[];
  }
}
