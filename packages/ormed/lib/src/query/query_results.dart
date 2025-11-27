part of 'query.dart';

/// Holds the model, its raw row, and any eager-loaded relations.
class QueryRow<T> {
  /// Creates a new [QueryRow].
  QueryRow({
    required this.model,
    required this.row,
    Map<String, dynamic>? relations,
  }) : relations = relations ?? <String, dynamic>{};

  /// Materialized model instance.
  final T model;

  /// Underlying driver row that produced [model].
  final Map<String, Object?> row;

  /// Relation name to resolved value map.
  final Map<String, dynamic> relations;

  /// Whether the relation named [name] exists in [relations].
  ///
  /// Example:
  /// ```dart
  /// if (queryRow.hasRelation('user')) {
  ///   // ...
  /// }
  /// ```
  bool hasRelation(String name) => relations.containsKey(name);

  /// Returns a relation value typed as [R].
  ///
  /// Example:
  /// ```dart
  /// final user = queryRow.relation<User>('user');
  /// ```
  R? relation<R>(String name) => relations[name] as R?;

  /// Returns a list relation typed as [R], or an empty list when absent.
  ///
  /// Example:
  /// ```dart
  /// final posts = queryRow.relationList<Post>('posts');
  /// ```
  List<R> relationList<R>(String name) {
    final value = relations[name];
    if (value is Iterable) {
      return value.cast<R>().toList(growable: false);
    }
    return const [];
  }
}

/// A callback that receives a chunk of [QueryRow]s.
///
/// Return `false` to stop chunking.
typedef ChunkCallback<T> = FutureOr<bool> Function(List<QueryRow<T>> chunk);

/// A callback that receives a single [QueryRow].
///
/// Return `false` to stop processing rows.
typedef RowCallback<T> = FutureOr<bool> Function(QueryRow<T> row);

/// A callback that receives a [PredicateBuilder].
typedef PredicateCallback<T> = void Function(PredicateBuilder<T> builder);

/// A callback that receives a [PredicateBuilder] for a relation.
typedef RelationCallback = void Function(PredicateBuilder<dynamic> builder);

/// Rich pagination payload returned by [Query.paginate].
class PageResult<T> {
  /// Creates a new [PageResult].
  PageResult({
    required List<QueryRow<T>> items,
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
  }) : items = List<QueryRow<T>>.unmodifiable(items);

  /// The items for the current page.
  final List<QueryRow<T>> items;

  /// The total number of items across all pages.
  final int total;

  /// The number of items per page.
  final int perPage;

  /// The current page number.
  final int currentPage;

  /// The last page number.
  final int lastPage;

  /// The models for the current page.
  List<T> get models => items.map((row) => row.model).toList(growable: false);

  /// Whether there are more pages after the current one.
  bool get hasMorePages => currentPage < lastPage;
}

/// Lightweight pagination payload that skips total counting.
class SimplePageResult<T> {
  /// Creates a new [SimplePageResult].
  SimplePageResult({
    required List<QueryRow<T>> items,
    required this.perPage,
    required this.currentPage,
    required this.hasMorePages,
  }) : items = List<QueryRow<T>>.unmodifiable(items);

  /// The items for the current page.
  final List<QueryRow<T>> items;

  /// The number of items per page.
  final int perPage;

  /// The current page number.
  final int currentPage;

  /// Whether there are more pages after the current one.
  final bool hasMorePages;

  /// The models for the current page.
  List<T> get models => items.map((row) => row.model).toList(growable: false);
}

/// Cursor-based pagination payload.
class CursorPageResult<T> {
  /// Creates a new [CursorPageResult].
  CursorPageResult({
    required List<QueryRow<T>> items,
    required this.nextCursor,
    required this.hasMore,
  }) : items = List<QueryRow<T>>.unmodifiable(items);

  /// The items for the current page.
  final List<QueryRow<T>> items;

  /// The cursor for the next page.
  final Object? nextCursor;

  /// Whether there are more pages after the current one.
  final bool hasMore;

  /// The models for the current page.
  List<T> get models => items.map((row) => row.model).toList(growable: false);
}

/// A query that maps its results to a different type.
class MappedAdHocQuery<R> {
  /// Creates a new [MappedAdHocQuery].
  MappedAdHocQuery(this._source, this._mapper);

  final Query<Map<String, Object?>> _source;
  final R Function(Map<String, Object?> row) _mapper;

  /// Executes the query and returns the mapped results.
  Future<List<R>> getMapped() async {
    final models = await _source.get();
    return models.map(_mapper).toList(growable: false);
  }

  /// Executes the query and returns the first mapped result, or `null` if none.
  Future<R?> firstMapped() async {
    final model = await _source.firstOrNull();
    return model == null ? null : _mapper(model);
  }

  /// Paginates the query and returns the mapped results.
  Future<PageResult<R>> paginateMapped({int perPage = 15, int page = 1}) async {
    final pageResult = await _source.paginate(perPage: perPage, page: page);
    return PageResult<R>(
      items: pageResult.items
          .map(
            (row) => QueryRow<R>(
              model: _mapper(row.model),
              row: row.row,
              relations: row.relations,
            ),
          )
          .toList(growable: false),
      total: pageResult.total,
      perPage: pageResult.perPage,
      currentPage: pageResult.currentPage,
      lastPage: pageResult.lastPage,
    );
  }

  /// Simple paginates the query and returns the mapped results.
  Future<SimplePageResult<R>> simplePaginateMapped({
    int perPage = 15,
    int page = 1,
  }) async {
    final result = await _source.simplePaginate(perPage: perPage, page: page);
    return SimplePageResult<R>(
      items: result.items
          .map(
            (row) => QueryRow<R>(
              model: _mapper(row.model),
              row: row.row,
              relations: row.relations,
            ),
          )
          .toList(growable: false),
      perPage: result.perPage,
      currentPage: result.currentPage,
      hasMorePages: result.hasMorePages,
    );
  }

  /// Cursor paginates the query and returns the mapped results.
  Future<CursorPageResult<R>> cursorPaginateMapped({
    Object? cursor,
    int perPage = 15,
    String? column,
    bool descending = false,
  }) async {
    final result = await _source.cursorPaginate(
      cursor: cursor,
      perPage: perPage,
      column: column,
      descending: descending,
    );
    return CursorPageResult<R>(
      items: result.items
          .map(
            (row) => QueryRow<R>(
              model: _mapper(row.model),
              row: row.row,
              relations: row.relations,
            ),
          )
          .toList(growable: false),
      nextCursor: result.nextCursor,
      hasMore: result.hasMore,
    );
  }

  /// Streams the mapped results of the query.
  Stream<R> streamMapped() => _source.streamModels().map(_mapper);
}
