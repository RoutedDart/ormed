import '../query_plan.dart';
import 'join_target.dart';
import 'join_type.dart';

/// {@template ormed.query.plan.join_definition}
/// Representation of a JOIN clause applied during query compilation.
///
/// This class encapsulates all the necessary information to construct a SQL JOIN
/// clause, including the type of join, the target table or subquery, an optional
/// alias, and the conditions for the join.
///
/// Example:
/// ```dart
/// final join = JoinDefinition(
///   type: JoinType.inner,
///   target: JoinTarget.table('profiles'),
///   conditions: [
///     JoinCondition.column(
///       left: 'users.id',
///       operator: '=',
///       right: 'profiles.user_id',
///     ),
///   ],
/// );
/// ```
/// {@endtemplate}
class JoinDefinition {
  /// {@macro ormed.query.plan.join_definition}
  JoinDefinition({
    required this.type,
    required this.target,
    this.alias,
    List<JoinCondition>? conditions,
    this.isLateral = false,
  }) : conditions = List.unmodifiable(conditions ?? const <JoinCondition>[]);

  /// The type of join to perform (e.g., [JoinType.inner], [JoinType.left]).
  final JoinType type;

  /// The target of the join, which can be a table or a subquery.
  final JoinTarget target;

  /// An optional alias for the joined table or subquery.
  final String? alias;

  /// A list of conditions that define how the tables are joined.
  final List<JoinCondition> conditions;

  /// Whether this is a LATERAL JOIN (supported by some SQL dialects).
  final bool isLateral;
}
