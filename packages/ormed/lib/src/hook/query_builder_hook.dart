import '../blueprint/schema_driver.dart';
import '../blueprint/schema_plan.dart';
import '../model_definition.dart';
import '../query/query.dart';
import '../repository/repository.dart';

/// Extension points that allow adapters to customize query building and
/// schema handling for ORM models.
abstract class QueryBuilderHook {
  /// Returns `true` when this hook can customize the provided [definition].
  bool handles(ModelDefinition<dynamic> definition);

  /// Returns a query that the adapter will execute for [definition].
  ///
  /// Implementations may wrap [defaultQuery] to add filters, joins, or
  /// diagnostics before returning the final [Query].
  Query<T> build<T>(
    ModelDefinition<T> definition,
    QueryContext context,
    Query<T> defaultQuery,
  );
}

/// Extension point for replacing the default repository implementation.
abstract class RepositoryHook {
  /// Returns `true` when this hook should build a repository for [definition].
  bool handles(ModelDefinition<dynamic> definition);

  /// Returns the repository instance that should back the given [definition].
  ///
  /// Hooks typically wrap or replace [defaultRepository] to inject driver-
  /// specific logic or metrics.
  Repository<T> build<T>(
    ModelDefinition<T> definition,
    QueryContext context,
    Repository<T> defaultRepository,
  );
}

/// Allows drivers to intercept schema mutations produced by the Blueprint DSL.
abstract class SchemaMutationHook {
  /// Returns `true` when this hook wants to process [mutation].
  bool handles(SchemaMutation mutation);

  /// Converts [mutation] into a collection of [SchemaStatement] instances.
  ///
  /// Hooks can change the statements produced or add additional steps before
  /// the schema plan renders SQL for the driver.
  List<SchemaStatement> handle(SchemaMutation mutation);
}
