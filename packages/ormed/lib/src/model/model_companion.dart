import 'package:ormed/ormed.dart';

/// Generic base class for model companion objects that provide static helpers.
///
/// Companions are typically exposed by generated code to provide a
/// `YourModel.query()`, `YourModel.repo()`, and other convenience entry points
/// without requiring users to call the `Model.*` static methods directly.
///
/// {@macro ormed.model.connection_setup}
///
/// ```dart
/// final users = await ModelCompanion<$User>().query().limit(10).get();
/// final repo = ModelCompanion<$User>().repo();
/// ```
class ModelCompanion<T extends Model<T>> {
  const ModelCompanion();

  /// Starts a [Query] for [T], optionally targeting [connection].
  Query<T> query([String? connection]) =>
      Model.query<T>(connection: connection);

  /// Finds a record by primary key [id], or returns `null`.
  Future<T?> find(Object id, {String? connection}) =>
      Model.find<T>(id, connection: connection);

  /// Finds a record by primary key [id], or throws when missing.
  Future<T> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<T>(id, connection: connection);

  /// Fetches all records for [T].
  Future<List<T>> all({String? connection}) =>
      Model.all<T>(connection: connection);

  /// Returns the count of records for [T].
  Future<int> count({String? connection}) =>
      Model.count<T>(connection: connection);

  /// Returns `true` when any record exists for [T].
  Future<bool> anyExist({String? connection}) =>
      Model.anyExist<T>(connection: connection);

  /// Starts a query with an initial WHERE clause.
  Query<T> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<T>(column, operator, value, connection: connection);

  /// Starts a query with an initial WHERE IN clause.
  Query<T> whereIn(String column, List<dynamic> values, {String? connection}) =>
      Model.whereIn<T>(column, values, connection: connection);

  /// Starts a query with an initial ORDER BY clause.
  Query<T> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<T>(column, direction: direction, connection: connection);

  /// Starts a query with an initial LIMIT clause.
  Query<T> limit(int count, {String? connection}) =>
      Model.limit<T>(count, connection: connection);

  /// Returns a [Repository] for [T], optionally targeting [connection].
  ///
  /// {@macro ormed.repository}
  Repository<T> repo([String? connection]) =>
      Model.repository<T>(connection: connection);
}
