part of '../query_builder.dart';

/// Extension providing row locking methods for transaction safety.
extension LockExtension<T> on Query<T> {
  /// Adds a `FOR UPDATE` lock clause to the query.
  ///
  /// This locks the selected rows for update, preventing other transactions
  /// from modifying or acquiring locks on them until the current transaction commits.
  ///
  /// Example:
  /// ```dart
  /// await context.transaction(() async {
  ///   final user = await context.query<User>()
  ///     .where('id', 1)
  ///     .lockForUpdate()
  ///     .first();
  ///   // ... modify user ...
  ///   // ... save user ...
  /// });
  /// ```
  Query<T> lockForUpdate() => _copyWith(lockClause: LockClauses.forUpdate);

  /// Adds a `SHARED LOCK` clause to the query.
  ///
  /// This acquires a shared lock on the selected rows, allowing other transactions
  /// to read them but preventing them from being modified.
  ///
  /// Example:
  /// ```dart
  /// await context.transaction(() async {
  ///   final user = await context.query<User>()
  ///     .where('id', 1)
  ///     .sharedLock()
  ///     .first();
  ///   // ... read user data ...
  /// });
  /// ```
  Query<T> sharedLock() => _copyWith(lockClause: LockClauses.shared);

  /// Adds a custom lock clause to the query.
  ///
  /// This allows for specifying any database-specific lock clause.
  ///
  /// Example:
  /// ```dart
  /// final user = await context.query<User>()
  ///   .where('id', 1)
  ///   .lock('LOCK IN SHARE MODE') // PostgreSQL specific
  ///   .first();
  /// ```
  Query<T> lock(String clause) => _copyWith(lockClause: clause);
}
