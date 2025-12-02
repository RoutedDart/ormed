part of '../query_builder.dart';

/// Extension providing pagination and limit/offset methods for query results.
extension PaginateExtension<T> on Query<T> {
  /// Limits the number of rows returned.
  ///
  /// Example:
  /// ```dart
  /// final firstTenUsers = await context.query<User>()
  ///   .limit(10)
  ///   .get();
  /// ```
  Query<T> limit(int? value) => _copyWith(limit: value);

  /// Skips [value] rows before reading results.
  ///
  /// Example:
  /// ```dart
  /// final usersAfterFirstTen = await context.query<User>()
  ///   .offset(10)
  ///   .limit(10)
  ///   .get();
  /// ```
  Query<T> offset(int? value) => _copyWith(offset: value);

  /// Returns a paginated payload including totals and metadata.
  ///
  /// [perPage] is the number of items to return per page (defaults to 15).
  /// [page] is the current page number (defaults to 1).
  ///
  /// Example:
  /// ```dart
  /// final userPage = await context.query<User>()
  ///   .paginate(perPage: 5, page: 2);
  ///
  /// print('Total users: ${userPage.total}');
  /// print('Users on current page: ${userPage.items.length}');
  /// ```
  Future<PageResult<T>> paginate({int perPage = 15, int page = 1}) async {
    if (perPage <= 0) {
      throw ArgumentError.value(perPage, 'perPage', 'Must be greater than 0.');
    }
    final currentPage = page < 1 ? 1 : page;
    final total = await _countTotalRows();
    final lastPage = total == 0 ? 0 : ((total + perPage - 1) ~/ perPage);
    final offsetValue = (currentPage - 1) * perPage;
    final rows = await limit(perPage).offset(offsetValue).rows();
    return PageResult(
      items: rows,
      total: total,
      perPage: perPage,
      currentPage: currentPage,
      lastPage: lastPage,
    );
  }

  /// Returns a simplified pagination payload without running a count query.
  ///
  /// This is useful when you only need to know if there are more pages,
  /// but not the total number of pages or items.
  ///
  /// [perPage] is the number of items to return per page (defaults to 15).
  /// [page] is the current page number (defaults to 1).
  ///
  /// Example:
  /// ```dart
  /// final userPage = await context.query<User>()
  ///   .simplePaginate(perPage: 5, page: 2);
  ///
  /// print('Has more pages: ${userPage.hasMorePages}');
  /// ```
  Future<SimplePageResult<T>> simplePaginate({
    int perPage = 15,
    int page = 1,
  }) async {
    if (perPage <= 0) {
      throw ArgumentError.value(perPage, 'perPage', 'Must be greater than 0.');
    }
    final currentPage = page < 1 ? 1 : page;
    final offsetValue = (currentPage - 1) * perPage;
    final rows = await limit(perPage + 1).offset(offsetValue).rows();
    final hasMore = rows.length > perPage;
    final items = hasMore ? rows.sublist(0, perPage) : rows;
    return SimplePageResult(
      items: items,
      perPage: perPage,
      currentPage: currentPage,
      hasMorePages: hasMore,
    );
  }

  /// Cursor-based pagination that resumes from [cursor] when present.
  ///
  /// This method is efficient for large datasets as it avoids `OFFSET` and
  /// relies on the value of a specific column to determine the next page.
  ///
  /// [perPage] is the number of items to return per page (defaults to 15).
  /// [cursor] is the value of the [column] from the last item of the previous page.
  /// [column] is the column to use for cursor pagination (defaults to primary key).
  /// [descending] determines the order of pagination.
  ///
  /// Example:
  /// ```dart
  /// // First page
  /// final firstPage = await context.query<User>()
  ///   .cursorPaginate(perPage: 10);
  ///
  /// // Next page using the cursor from the first page
  /// final secondPage = await context.query<User>()
  ///   .cursorPaginate(perPage: 10, cursor: firstPage.nextCursor);
  /// ```
  Future<CursorPageResult<T>> cursorPaginate({
    int perPage = 15,
    Object? cursor,
    String? column,
    bool descending = false,
  }) async {
    if (perPage <= 0) {
      throw ArgumentError.value(perPage, 'perPage', 'Must be greater than 0.');
    }
    final columnName = _resolveCursorColumn(column);
    var builder = this;
    if (cursor != null) {
      builder = builder.where(
        columnName,
        cursor,
        descending ? PredicateOperator.lessThan : PredicateOperator.greaterThan,
      );
    }
    builder = builder.orderBy(columnName, descending: descending);
    final rows = await builder.limit(perPage + 1).rows();
    final hasMore = rows.length > perPage;
    final items = hasMore ? rows.sublist(0, perPage) : rows;
    final nextCursor = hasMore ? items.last.row[columnName] : null;
    return CursorPageResult(
      items: items,
      nextCursor: nextCursor,
      hasMore: hasMore,
    );
  }

  /// Iterates rows in fixed-size chunks, invoking [callback] for each batch.
  ///
  /// This is useful for processing large datasets without loading all records
  /// into memory at once.
  ///
  /// [size] is the number of rows per chunk.
  /// [callback] is a function that receives a list of [QueryRow]s for each chunk.
  /// It should return `true` to continue processing or `false` to stop.
  /// [startPage] is the initial page number to start chunking from.
  ///
  /// Example:
  /// ```dart
  /// await context.query<User>().chunk(100, (users) async {
  ///   for (final user in users) {
  ///     print('Processing user: ${user.model.name}');
  ///   }
  ///   return true; // Continue to next chunk
  /// });
  /// ```
  Future<void> chunk(
    int size,
    ChunkCallback<T> callback, {
    int startPage = 1,
  }) async {
    if (size <= 0) {
      throw ArgumentError.value(size, 'size', 'Must be greater than 0.');
    }
    var page = startPage < 1 ? 1 : startPage;
    while (true) {
      final offsetValue = (page - 1) * size;
      final rows = await limit(size).offset(offsetValue).rows();
      if (rows.isEmpty) {
        break;
      }
      final continueProcessing = await callback(rows);
      if (continueProcessing == false || rows.length < size) {
        break;
      }
      page++;
    }
  }

  /// Iterates rows ordered by [column] (defaults to the primary key).
  ///
  /// This method is similar to [chunk] but ensures that rows are processed
  /// in order of the specified [column] (or primary key), which is crucial
  /// for consistent chunking across multiple runs or when dealing with concurrent
  /// modifications.
  ///
  /// [size] is the number of rows per chunk.
  /// [callback] is a function that receives a list of [QueryRow]s for each chunk.
  /// [column] is the column to use for ordering and identifying chunks.
  ///
  /// Example:
  /// ```dart
  /// await context.query<User>().chunkById(50, (users) async {
  ///   for (final user in users) {
  ///     print('Processing user by ID: ${user.model.id}');
  ///   }
  ///   return true;
  /// });
  /// ```
  Future<void> chunkById(
    int size,
    ChunkCallback<T> callback, {
    String? column,
  }) async {
    if (size <= 0) {
      throw ArgumentError.value(size, 'size', 'Must be greater than 0.');
    }
    final columnName = _resolveCursorColumn(column);
    Object? lastId;
    while (true) {
      var builder = orderBy(columnName);
      if (lastId != null) {
        builder = builder.where(
          columnName,
          lastId,
          PredicateOperator.greaterThan,
        );
      }
      final rows = await builder.limit(size).rows();
      if (rows.isEmpty) {
        break;
      }
      final continueProcessing = await callback(rows);
      if (continueProcessing == false) {
        break;
      }
      if (rows.length < size) {
        break;
      }
      lastId = rows.last.row[columnName];
    }
  }

  /// Visits each row individually in ID order using [chunkById] under the hood.
  ///
  /// This method provides a convenient way to process each row one by one,
  /// while still benefiting from the memory efficiency of chunking.
  ///
  /// [size] is the chunk size used internally.
  /// [callback] is a function that receives a single [QueryRow].
  /// It should return `true` to continue processing or `false` to stop.
  /// [column] is the column to use for ordering.
  ///
  /// Example:
  /// ```dart
  /// await context.query<User>().eachById(100, (user) async {
  ///   print('Processing single user: ${user.model.name}');
  ///   return true;
  /// });
  /// ```
  Future<void> eachById(int size, RowCallback<T> callback, {String? column}) =>
      chunkById(size, (rows) async {
        for (final row in rows) {
          final shouldContinue = await callback(row);
          if (shouldContinue == false) {
            return false;
          }
        }
        return true;
      }, column: column);

  /// Streams rows sequentially (still buffered by the underlying driver).
  ///
  /// This method allows you to process query results as a stream, which can be
  /// more memory-efficient for very large datasets compared to fetching all
  /// rows at once.
  ///
  /// [eagerLoadBatchSize] specifies how many rows to buffer before eager-loading
  /// relations (defaults to 500).
  ///
  /// Example:
  /// ```dart
  /// await for (final userRow in context.query<User>().streamRows()) {
  ///   print('Streaming user: ${userRow.model.name}');
  /// }
  /// ```
  Stream<QueryRow<T>> streamRows({
    int eagerLoadBatchSize = Query._defaultStreamEagerBatchSize,
  }) async* {
    if (eagerLoadBatchSize <= 0) {
      throw ArgumentError.value(
        eagerLoadBatchSize,
        'eagerLoadBatchSize',
        'must be positive',
      );
    }
    final plan = _buildPlan();
    final rowStream = context.streamSelect(plan);
    if (_relations.isEmpty && _relationAggregates.isEmpty) {
      await for (final row in rowStream) {
        yield _hydrateRow(row, plan);
      }
      return;
    }

    final buffer = <QueryRow<T>>[];

    await for (final row in rowStream) {
      buffer.add(_hydrateRow(row, plan));
      if (buffer.length >= eagerLoadBatchSize) {
        await _applyRelationHookBatch(plan, buffer);
        for (final item in buffer) {
          yield item;
        }
        buffer.clear();
      }
    }

    if (buffer.isNotEmpty) {
      await _applyRelationHookBatch(plan, buffer);
      for (final item in buffer) {
        yield item;
      }
    }
  }

  /// Streams models sequentially.
  ///
  /// This is a convenience method that streams models instead of [QueryRow] objects.
  ///
  /// Example:
  /// ```dart
  /// await for (final user in context.query<User>().streamModels()) {
  ///   print('Streaming user: ${user.name}');
  /// }
  /// ```
  Stream<T> streamModels() => streamRows().map((row) => row.model);
}
