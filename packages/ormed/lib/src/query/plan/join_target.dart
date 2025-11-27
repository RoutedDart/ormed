/// {@template ormed.query.plan.join_target}
/// Target table or subquery for a JOIN clause.
///
/// Use [JoinTarget.table] for a simple table reference or
/// [JoinTarget.subquery] when joining against raw SQL.
/// {@endtemplate}
class JoinTarget {
  /// {@macro ormed.query.plan.join_target}
  ///
  /// Creates a [JoinTarget] for a table reference.
  ///
  /// [table] is the raw table reference (optionally including schema / alias syntax).
  JoinTarget.table(this.table) : subquery = null, bindings = const [];

  /// {@macro ormed.query.plan.join_target}
  ///
  /// Creates a [JoinTarget] for a subquery.
  ///
  /// [subquery] is the SQL text for the subquery target.
  /// [bindings] are parameter bindings associated with [subquery].
  JoinTarget.subquery(this.subquery, {List<Object?>? bindings})
    : table = null,
      bindings = List.unmodifiable(bindings ?? const []);

  /// Raw table reference (optionally including schema / alias syntax).
  final String? table;

  /// SQL text for a subquery target.
  final String? subquery;

  /// Parameter bindings associated with [subquery].
  final List<Object?> bindings;

  /// Returns `true` if this target is a subquery.
  bool get isSubquery => subquery != null;
}
