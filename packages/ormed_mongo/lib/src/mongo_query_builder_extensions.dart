import 'package:ormed/ormed.dart';
import 'mongo_operators.dart';

/// MongoDB-specific extensions for the Query Builder.
extension MongoQueryBuilderExtensions<T> on Query<T> {
  /// Set the projection for the query.
  ///
  /// This is an alias for [select].
  Query<T> project(List<String> columns) => select(columns);

  /// Force the query to use a specific index.
  ///
  /// This corresponds to the `hint` method in MongoDB.
  /// Note: This currently only supports index names.
  Query<T> hint(String indexName) => forceIndex([indexName]);

  /// Add a value to an array.
  ///
  /// Uses $push (or $addToSet if unique is true).
  Future<int> push(String column, Object? value, {bool unique = false}) {
    return update({column: MongoPush(value, unique: unique)});
  }

  /// Remove a value from an array.
  ///
  /// Uses $pull.
  Future<int> pull(String column, Object? value) {
    return update({column: MongoPull(value)});
  }

  /// Remove a field from the document.
  ///
  /// Uses $unset.
  Future<int> unset(String column) {
    return update({column: const MongoUnset()});
  }
}
