part of '../query_builder.dart';

extension StreamingExtension<T extends OrmEntity> on Query<T> {
  /// Returns an async stream of query results.
  ///
  /// This method efficiently streams large result sets without loading
  /// everything into memory at once.
  ///
  /// Example:
  /// ```dart
  /// await for (final user in context.query<User>().stream()) {
  ///   print(user.email);
  /// }
  /// ```
  Stream<T> stream({int chunkSize = 100}) async* {
    int offset = 0;
    bool hasMore = true;

    while (hasMore) {
      final chunk = await limit(chunkSize).offset(offset).get();

      if (chunk.isEmpty) {
        hasMore = false;
        break;
      }

      for (final model in chunk) {
        yield model;
      }

      offset += chunkSize;

      if (chunk.length < chunkSize) {
        hasMore = false;
      }
    }
  }

  /// Iterates over query results with a callback.
  ///
  /// Processes records in chunks for memory efficiency. The callback is called
  /// for each record in the result set.
  ///
  /// Example:
  /// ```dart
  /// await context.query<User>().each((user) async {
  ///   print('Processing ${user.email}');
  /// });
  /// ```
  Future<void> each(
    Future<void> Function(T model) callback, {
    int chunkSize = 100,
  }) async {
    await for (final model in stream(chunkSize: chunkSize)) {
      await callback(model);
    }
  }
}
