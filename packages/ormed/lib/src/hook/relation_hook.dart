import 'package:ormed/ormed.dart';


/// Optional hook drivers can use to customize how eager-loaded relations
/// materialize after the base query fetches rows.
abstract class RelationHook {
  /// Populates the [relations] for every item in [parents].
  ///
  /// Implementations may load extra rows via [context], rewrite the
  /// [relations] list, or attach metadata to [parentDefinition] before the
  /// ORM hydrates the final result.
  Future<void> handleRelations<T extends OrmEntity>(
    QueryContext context,
    QueryPlan plan,
    ModelDefinition<T> parentDefinition,
    List<QueryRow<T>> parents,
    List<RelationLoad> relations,
  );
}
