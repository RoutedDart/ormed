library;

import '../../connection/connection.dart';
import '../../driver/driver.dart';
import '../../query/query.dart';
import '../../value_codec.dart';
import '../model.dart';

/// Provides access to the connection context that hydrated a model instance.
mixin ModelConnection {
  static final Expando<ConnectionResolver> _resolvers =
      Expando<ConnectionResolver>('_ormConnectionResolver');

  /// The resolver attached to this model, when present.
  ConnectionResolver? get connectionResolver => _resolvers[this];

  /// The driver/connection associated with this model, if any.
  DriverAdapter? get connection => connectionResolver?.driver;

  /// Whether a resolver/connection has been attached.
  bool get hasConnection => connectionResolver != null;

  /// Assigns the resolver responsible for this model instance.
  void attachConnectionResolver(ConnectionResolver resolver) {
    _resolvers[this] = resolver;
  }

  /// Legacy helper for manually attaching a driver outside a resolver.
  @Deprecated('Prefer attachConnectionResolver for full context access.')
  void attachConnection(DriverAdapter driver) {
    _resolvers[this] = _DriverOnlyResolver(driver);
  }

  /// Runs a read [plan] through the attached resolver.
  Future<List<Map<String, Object?>>> runSelect(QueryPlan plan) =>
      _requireResolver().runSelect(plan);

  /// Runs a write [plan] through the attached resolver.
  Future<MutationResult> runMutation(MutationPlan plan) =>
      _requireResolver().runMutation(plan);

  /// Returns the statement preview for a read [plan].
  StatementPreview describeQuery(QueryPlan plan) =>
      _requireResolver().describeQuery(plan);

  /// Returns the statement preview for a write [plan].
  StatementPreview describeMutation(MutationPlan plan) =>
      _requireResolver().describeMutation(plan);

  ConnectionResolver _requireResolver() {
    final resolver = connectionResolver;
    if (resolver != null) return resolver;
    throw StateError(
      'No connection resolver attached to $runtimeType. Ensure the model '
      'was hydrated via a QueryContext or Repository.',
    );
  }
}

class _DriverOnlyResolver implements ConnectionResolver {
  _DriverOnlyResolver(this.driver);

  @override
  final DriverAdapter driver;

  @override
  ValueCodecRegistry get codecRegistry =>
      throw _missingContext('codecRegistry');

  @override
  ModelRegistry get registry => throw _missingContext('registry');

  @override
  StatementPreview describeMutation(MutationPlan plan) =>
      throw _missingContext('describeMutation');

  @override
  StatementPreview describeQuery(QueryPlan plan) =>
      throw _missingContext('describeQuery');

  @override
  Future<MutationResult> runMutation(MutationPlan plan) =>
      Future.error(_missingContext('runMutation'));

  @override
  Future<List<Map<String, Object?>>> runSelect(QueryPlan plan) =>
      Future.error(_missingContext('runSelect'));

  StateError _missingContext(String member) => StateError(
    'Cannot access $member without a full ConnectionResolver. '
    'Hydrate the model via QueryContext to attach one.',
  );
}
