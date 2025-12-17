import 'package:ormed/src/query/query.dart';
import 'package:ormed/src/repository/repository.dart';

import '../contracts.dart';
import 'model.dart';

/// Helper that binds a generated model definition to a [QueryContext].
///
/// Generated model helpers typically expose this as `YourModel.withConnection`,
/// making it easy to build queries and repositories against a specific
/// connection/context.
///
/// {@macro ormed.model.connection_setup}
///
/// ```dart
/// final ctx = /* obtain a QueryContext */;
///
/// // Query builder.
/// final active = await User.withConnection(ctx).query().where('active', true).get();
///
/// // Repository.
/// final repo = User.withConnection(ctx).repository();
/// final saved = await repo.saveMany([User(name: 'Ada')]);
/// ```
class ModelFactoryConnection<T extends OrmEntity> {
  const ModelFactoryConnection({
    required ModelDefinition<T> definition,
    required QueryContext context,
  }) : _definition = definition,
       _context = context;

  final ModelDefinition<T> _definition;
  final QueryContext _context;

  /// The underlying query context this helper wraps.
  QueryContext get context => _context;

  /// The definition attached to this helper.
  ModelDefinition<T> get definition => _definition;

  /// Returns a query builder bound to this model definition/connection.
  Query<T> query({String? table, String? schema, String? alias}) =>
      _context.queryFromDefinition(
        _definition,
        table: table,
        schema: schema,
        alias: alias,
      );

  /// Returns a repository bound to this model definition/connection.
  Repository<T> repository() => _context.repository<T>();
}
