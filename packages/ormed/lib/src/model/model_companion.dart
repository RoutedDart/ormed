import 'package:ormed/ormed.dart';

/// Generic base class for model companion objects that provide static query methods
class ModelCompanion<T extends Model<T>> {
  const ModelCompanion();

  Query<T> query([String? connection]) =>
      Model.query<T>(connection: connection);

  Future<T?> find(Object id, {String? connection}) =>
      Model.find<T>(id, connection: connection);

  Future<T> findOrFail(Object id, {String? connection}) =>
      Model.findOrFail<T>(id, connection: connection);

  Future<List<T>> all({String? connection}) =>
      Model.all<T>(connection: connection);

  Future<int> count({String? connection}) =>
      Model.count<T>(connection: connection);

  Future<bool> anyExist({String? connection}) =>
      Model.anyExist<T>(connection: connection);

  Query<T> where(
    String column,
    String operator,
    dynamic value, {
    String? connection,
  }) => Model.where<T>(column, operator, value, connection: connection);

  Query<T> whereIn(String column, List<dynamic> values, {String? connection}) =>
      Model.whereIn<T>(column, values, connection: connection);

  Query<T> orderBy(
    String column, {
    String direction = "asc",
    String? connection,
  }) => Model.orderBy<T>(column, direction: direction, connection: connection);

  Query<T> limit(int count, {String? connection}) =>
      Model.limit<T>(count, connection: connection);

  Repository<T> repo([String? connection]) =>
      Model.repository<T>(connection: connection);
}
