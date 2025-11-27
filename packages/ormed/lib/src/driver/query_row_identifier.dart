/// Describes the expression a driver uses to uniquely identify rows for
/// query-driven updates when no primary key is available.
class QueryRowIdentifier {
  const QueryRowIdentifier({required this.column, required this.expression});

  /// Column name used in WHERE/ON clauses (e.g. `rowid`, `ctid`).
  final String column;

  /// SQL expression that projects the identifier from the base table.
  final String expression;
}
