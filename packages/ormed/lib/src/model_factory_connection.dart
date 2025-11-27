import 'package:ormed/src/model_definition.dart';
import 'package:ormed/src/query/query.dart';
import 'package:ormed/src/repository/repository.dart';

/// Helper that binds a generated model definition to a query context.
class ModelFactoryConnection<T> {
  const ModelFactoryConnection({
    required ModelDefinition<T> definition,
    required QueryContext context,
  })  : _definition = definition,
        _context = context;

  final ModelDefinition<T> _definition;
  final QueryContext _context;

  /// The underlying query context this helper wraps.
  QueryContext get context => _context;

  /// The definition attached to this helper.
  ModelDefinition<T> get definition => _definition;

  /// Returns a query builder bound to this model definition/connection.
  Query<T> query({
    String? table,
    String? schema,
    String? alias,
  }) =>
      _context.queryFromDefinition(
        _definition,
        table: table,
        schema: schema,
        alias: alias,
      );

  /// Returns a repository bound to this model definition/connection.
  Repository<T> repository() => _context.repository<T>();
}
