part of '../query_builder.dart';

/// Extension providing subquery support for query builder.
extension SubqueryExtension<T extends OrmEntity> on Query<T> {
  /// Adds a WHERE IN subquery predicate.
  ///
  /// This method allows you to filter records where a column's value exists
  /// in the results of a subquery.
  ///
  /// [field] is the column name to check.
  /// [subquery] is the Query that returns values to match against.
  ///
  /// Example:
  /// ```dart
  /// // Find users who have published posts
  /// final users = await context.query<User>()
  ///   .whereInSubquery('id',
  ///     _context.query<Post>()
  ///       .select(['authorId'])
  ///       .where('published', true)
  ///   )
  ///   .get();
  /// ```
  ///
  /// Generated SQL:
  /// ```sql
  /// SELECT * FROM users
  /// WHERE id IN (
  ///   SELECT author_id FROM posts WHERE published = true
  /// )
  /// ```
  Query<T> whereInSubquery(
    String field,
    Query<dynamic> subquery,
  ) {
    return _appendPredicate(
      SubqueryPredicate(
        type: SubqueryType.whereIn,
        subquery: subquery._buildPlan(),
        field: field,
        negate: false,
      ),
      PredicateLogicalOperator.and,
    );
  }

  /// Adds a WHERE NOT IN subquery predicate.
  ///
  /// This is the inverse of [whereInSubquery]. It filters records where
  /// a column's value does NOT exist in the results of a subquery.
  ///
  /// Example:
  /// ```dart
  /// // Find users who have never published posts
  /// final users = await context.query<User>()
  ///   .whereNotInSubquery('id',
  ///     _context.query<Post>()
  ///       .select(['authorId'])
  ///       .where('published', true)
  ///   )
  ///   .get();
  /// ```
  Query<T> whereNotInSubquery(
    String field,
    Query<dynamic> subquery,
  ) {
    return _appendPredicate(
      SubqueryPredicate(
        type: SubqueryType.whereIn,
        subquery: subquery._buildPlan(),
        field: field,
        negate: true,
      ),
      PredicateLogicalOperator.and,
    );
  }

  /// Adds a WHERE EXISTS subquery predicate.
  ///
  /// This method checks if the subquery returns any results. Use [whereColumn]
  /// in the subquery to correlate it with the outer query.
  ///
  /// Example:
  /// ```dart
  /// // Find users who have at least one comment
  /// final users = await context.query<User>()
  ///   .whereExists(
  ///     _context.query<Comment>()
  ///       .whereColumn('comments.userId', 'users.id')
  ///   )
  ///   .get();
  /// ```
  ///
  /// Generated SQL:
  /// ```sql
  /// SELECT * FROM users
  /// WHERE EXISTS (
  ///   SELECT 1 FROM comments WHERE comments.user_id = users.id
  /// )
  /// ```
  Query<T> whereExists(Query<dynamic> subquery) {
    return _appendPredicate(
      SubqueryPredicate(
        type: SubqueryType.exists,
        subquery: subquery._buildPlan(),
        negate: false,
      ),
      PredicateLogicalOperator.and,
    );
  }

  /// Adds a WHERE NOT EXISTS subquery predicate.
  ///
  /// This is the inverse of [whereExists]. It checks if the subquery
  /// returns NO results.
  ///
  /// Example:
  /// ```dart
  /// // Find users who have no comments
  /// final users = await context.query<User>()
  ///   .whereNotExists(
  ///     _context.query<Comment>()
  ///       .whereColumn('comments.userId', 'users.id')
  ///   )
  ///   .get();
  /// ```
  Query<T> whereNotExists(Query<dynamic> subquery) {
    return _appendPredicate(
      SubqueryPredicate(
        type: SubqueryType.exists,
        subquery: subquery._buildPlan(),
        negate: true,
      ),
      PredicateLogicalOperator.and,
    );
  }

  /// Adds an OR WHERE IN subquery predicate.
  ///
  /// This is the OR variant of [whereInSubquery].
  ///
  /// Example:
  /// ```dart
  /// final users = await context.query<User>()
  ///   .where('active', true)
  ///   .orWhereInSubquery('id',
  ///     _context.query<Admin>()
  ///       .select(['userId'])
  ///   )
  ///   .get();
  /// ```
  Query<T> orWhereInSubquery(String field, Query<dynamic> subquery) {
    return _appendPredicate(
      SubqueryPredicate(
        type: SubqueryType.whereIn,
        subquery: subquery._buildPlan(),
        field: field,
        negate: false,
      ),
      PredicateLogicalOperator.or,
    );
  }

  /// Adds an OR WHERE NOT IN subquery predicate.
  ///
  /// This is the OR variant of [whereNotInSubquery].
  Query<T> orWhereNotInSubquery(String field, Query<dynamic> subquery) {
    return _appendPredicate(
      SubqueryPredicate(
        type: SubqueryType.whereIn,
        subquery: subquery._buildPlan(),
        field: field,
        negate: true,
      ),
      PredicateLogicalOperator.or,
    );
  }

  /// Adds an OR WHERE EXISTS subquery predicate.
  ///
  /// This is the OR variant of [whereExists].
  Query<T> orWhereExists(Query<dynamic> subquery) {
    return _appendPredicate(
      SubqueryPredicate(
        type: SubqueryType.exists,
        subquery: subquery._buildPlan(),
        negate: false,
      ),
      PredicateLogicalOperator.or,
    );
  }

  /// Adds an OR WHERE NOT EXISTS subquery predicate.
  ///
  /// This is the OR variant of [whereNotExists].
  Query<T> orWhereNotExists(Query<dynamic> subquery) {
    return _appendPredicate(
      SubqueryPredicate(
        type: SubqueryType.exists,
        subquery: subquery._buildPlan(),
        negate: true,
      ),
      PredicateLogicalOperator.or,
    );
  }
}


