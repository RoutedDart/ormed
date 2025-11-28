/// Supported JOIN clause types applied by the grammar.
///
/// These types correspond to the various SQL JOIN operations that can be
/// performed when building queries.
enum JoinType {
  /// Corresponds to `INNER JOIN`. Returns only the rows that have matching
  /// values in both tables.
  inner,

  /// Corresponds to `LEFT JOIN` (or `LEFT OUTER JOIN`). Returns all rows from
  /// the left table, and the matching rows from the right table. If there is
  /// no match, the right side will have `NULL`s.
  left,

  /// Corresponds to `RIGHT JOIN` (or `RIGHT OUTER JOIN`). Returns all rows from
  /// the right table, and the matching rows from the left table. If there is
  /// no match, the left side will have `NULL`s.
  right,

  /// Corresponds to `CROSS JOIN`. Returns the Cartesian product of the rows
  /// from the joined tables.
  cross,

  /// Corresponds to `STRAIGHT_JOIN`. Forces the optimizer to join tables in
  /// the order in which they are listed in the `FROM` clause. This is a MySQL/MariaDB
  /// specific join type.
  straight,
}
