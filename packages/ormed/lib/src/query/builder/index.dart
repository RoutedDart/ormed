part of '../query_builder.dart';

/// Extension providing index hint methods for query optimization.
extension IndexExtension<T> on Query<T> {
  /// Applies a USE INDEX hint (MySQL/MariaDB only).
  ///
  /// This hint suggests to the database optimizer to use a specific index for the query.
  ///
  /// Example:
  /// ```dart
  /// final usersWithIndexHint = await context.query<User>()
  ///   .useIndex(['idx_users_email'])
  ///   .where('email', 'test@example.com')
  ///   .get();
  /// ```
  Query<T> useIndex(List<String> indexes) =>
      _addIndexHint(IndexHint(IndexHintType.use, indexes));

  /// Applies a FORCE INDEX hint (MySQL/MariaDB only).
  ///
  /// This hint forces the database optimizer to use a specific index for the query.
  ///
  /// Example:
  /// ```dart
  /// final usersWithForcedIndex = await context.query<User>()
  ///   .forceIndex(['idx_users_status'])
  ///   .where('status', 'active')
  ///   .get();
  /// ```
  Query<T> forceIndex(List<String> indexes) =>
      _addIndexHint(IndexHint(IndexHintType.force, indexes));

  /// Applies an IGNORE INDEX hint (MySQL/MariaDB only).
  ///
  /// This hint tells the database optimizer to ignore a specific index for the query.
  ///
  /// Example:
  /// ```dart
  /// final usersIgnoringIndex = await context.query<User>()
  ///   .ignoreIndex(['idx_users_old_data'])
  ///   .where('createdAt', '<', DateTime(2020))
  ///   .get();
  /// ```
  Query<T> ignoreIndex(List<String> indexes) =>
      _addIndexHint(IndexHint(IndexHintType.ignore, indexes));
}
