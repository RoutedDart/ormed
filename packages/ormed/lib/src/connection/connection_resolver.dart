import 'package:ormed/src/driver/driver.dart'
    show DriverAdapter, MutationPlan, MutationResult, StatementPreview;
import 'package:ormed/src/model/model_registry.dart' show ModelRegistry;
import 'package:ormed/src/query/query_plan.dart' show QueryPlan;
import 'package:ormed/src/value_codec.dart' show ValueCodecRegistry;

/// Describes a runtime context capable of executing ORM queries.
abstract class ConnectionResolver {
  /// Database adapter backing this resolver.
  DriverAdapter get driver;

  /// Registry of model definitions available to this resolver.
  ModelRegistry get registry;

  /// Codec registry scoped to the current connection.
  ValueCodecRegistry get codecRegistry;

  /// Executes a read [plan] and returns the raw rows.
  Future<List<Map<String, Object?>>> runSelect(QueryPlan plan);

  /// Executes a write [plan] and returns the driver result.
  Future<MutationResult> runMutation(MutationPlan plan);

  /// Provides the statement preview for a read [plan].
  StatementPreview describeQuery(QueryPlan plan);

  /// Provides the statement preview for a write [plan].
  StatementPreview describeMutation(MutationPlan plan);
}
