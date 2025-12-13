part of '../query_builder.dart';

extension JoinExtension<T extends OrmEntity> on Query<T> {
  /// Adds an INNER JOIN clause to the query.
  ///
  /// The [table] parameter can be a table name (String) or a subquery ([Query]).
  /// The [constraint] parameter can be a column name (String) or a [JoinConstraintBuilder]
  /// callback for more complex join conditions.
  ///
  /// Examples:
  /// ```dart
  /// // Join with a simple ON clause
  /// final usersWithProfiles = await context.query<User>()
  ///   .join('profiles', 'users.id', '=', 'profiles.user_id')
  ///   .get();
  ///
  /// // Join with a complex ON clause using a callback
  /// final usersWithActiveProfiles = await context.query<User>()
  ///   .join('profiles', (join) {
  ///     join.on('users.id', '=', 'profiles.user_id')
  ///         .where('profiles.status', '=', 'active');
  ///   })
  ///   .get();
  /// ```
  Query<T> join(
    Object table,
    Object constraint, [
    Object? operator,
    Object? second,
  ]) => _join(
    target: _resolveJoinTarget(table),
    type: JoinType.inner,
    constraint: constraint,
    operator: operator,
    second: second,
  );

  /// Adds a LEFT JOIN clause to the query.
  ///
  /// The [table] parameter can be a table name (String) or a subquery ([Query]).
  /// The [constraint] parameter can be a column name (String) or a [JoinConstraintBuilder]
  /// callback for more complex join conditions.
  ///
  /// Example:
  /// ```dart
  /// final usersWithOptionalProfiles = await context.query<User>()
  ///   .leftJoin('profiles', 'users.id', '=', 'profiles.user_id')
  ///   .get();
  /// ```
  Query<T> leftJoin(
    Object table,
    Object constraint, [
    Object? operator,
    Object? second,
  ]) => _join(
    target: _resolveJoinTarget(table),
    type: JoinType.left,
    constraint: constraint,
    operator: operator,
    second: second,
  );

  /// Adds a RIGHT JOIN clause to the query.
  ///
  /// The [table] parameter can be a table name (String) or a subquery ([Query]).
  /// The [constraint] parameter can be a column name (String) or a [JoinConstraintBuilder]
  /// callback for more complex join conditions.
  ///
  /// Example:
  /// ```dart
  /// final profilesWithOptionalUsers = await context.query<Profile>()
  ///   .rightJoin('users', 'profiles.user_id', '=', 'users.id')
  ///   .get();
  /// ```
  Query<T> rightJoin(
    Object table,
    Object constraint, [
    Object? operator,
    Object? second,
  ]) => _join(
    target: _resolveJoinTarget(table),
    type: JoinType.right,
    constraint: constraint,
    operator: operator,
    second: second,
  );

  /// Adds a CROSS JOIN clause to the query. When [constraint] is omitted,
  /// a simple `CROSS JOIN table` is emitted.
  ///
  /// A cross join produces a Cartesian product of the tables involved in the join.
  ///
  /// Example:
  /// ```dart
  /// final allCombinations = await context.query<Product>()
  ///   .crossJoin('colors')
  ///   .get();
  /// ```
  Query<T> crossJoin(
    Object table, [
    Object? constraint,
    Object? operator,
    Object? second,
  ]) {
    if (constraint == null) {
      return _join(target: _resolveJoinTarget(table), type: JoinType.cross);
    }
    return _join(
      target: _resolveJoinTarget(table),
      type: JoinType.cross,
      constraint: constraint,
      operator: operator,
      second: second,
    );
  }

  /// Adds a STRAIGHT_JOIN clause (MySQL / MariaDB only).
  ///
  /// This join type forces the optimizer to join tables in the order in which
  /// they are listed in the `FROM` clause.
  ///
  /// Example:
  /// ```dart
  /// final orderedJoin = await context.query<User>()
  ///   .straightJoin('profiles', 'users.id', '=', 'profiles.user_id')
  ///   .get();
  /// ```
  Query<T> straightJoin(
    Object table,
    Object constraint, [
    Object? operator,
    Object? second,
  ]) => _join(
    target: _resolveJoinTarget(table),
    type: JoinType.straight,
    constraint: constraint,
    operator: operator,
    second: second,
  );

  /// Adds an INNER JOIN ... WHERE clause to the query.
  ///
  /// This is a convenience method for joining and immediately applying a `WHERE`
  /// condition on the joined table.
  ///
  /// Example:
  /// ```dart
  /// final usersWithActiveProfiles = await context.query<User>()
  ///   .joinWhere('profiles', 'profiles.status', '=', 'active')
  ///   .get();
  /// ```
  Query<T> joinWhere(
    Object table,
    Object column, [
    Object? operator,
    Object? value,
  ]) => _join(
    target: _resolveJoinTarget(table),
    type: JoinType.inner,
    constraint: column,
    operator: operator,
    second: value,
    whereComparison: true,
  );

  /// Adds a LEFT JOIN ... WHERE clause to the query.
  ///
  /// This is a convenience method for left joining and immediately applying a `WHERE`
  /// condition on the joined table.
  ///
  /// Example:
  /// ```dart
  /// final usersWithOptionalActiveProfiles = await context.query<User>()
  ///   .leftJoinWhere('profiles', 'profiles.status', '=', 'active')
  ///   .get();
  /// ```
  Query<T> leftJoinWhere(
    Object table,
    Object column, [
    Object? operator,
    Object? value,
  ]) => _join(
    target: _resolveJoinTarget(table),
    type: JoinType.left,
    constraint: column,
    operator: operator,
    second: value,
    whereComparison: true,
  );

  /// Adds a RIGHT JOIN ... WHERE clause to the query.
  ///
  /// This is a convenience method for right joining and immediately applying a `WHERE`
  /// condition on the joined table.
  ///
  /// Example:
  /// ```dart
  /// final profilesWithOptionalUsers = await context.query<Profile>()
  ///   .rightJoinWhere('users', 'users.status', '=', 'active')
  ///   .get();
  /// ```
  Query<T> rightJoinWhere(
    Object table,
    Object column, [
    Object? operator,
    Object? value,
  ]) => _join(
    target: _resolveJoinTarget(table),
    type: JoinType.right,
    constraint: column,
    operator: operator,
    second: value,
    whereComparison: true,
  );

  /// Adds an INNER JOIN against a subquery.
  ///
  /// [query] is the subquery to join against.
  /// [alias] is the alias for the subquery, which is required.
  /// [constraint] defines the join condition.
  ///
  /// Example:
  /// ```dart
  /// final usersWithRecentOrders = await context.query<User>()
  ///   .joinSub(
  ///     context.query<Order>()
  ///       .whereGreaterThan('createdAt', DateTime.now().subtract(Duration(days: 30))),
  ///     'recentOrders',
  ///     'users.id', '=', 'recentOrders.user_id',
  ///   )
  ///   .get();
  /// ```
  Query<T> joinSub(
    Query<dynamic> query,
    String alias,
    Object constraint, [
    Object? operator,
    Object? second,
  ]) {
    _assertSubqueryAlias(alias);
    return _join(
      target: _subqueryTarget(query),
      type: JoinType.inner,
      constraint: constraint,
      operator: operator,
      second: second,
      alias: alias,
    );
  }

  /// Adds a LEFT JOIN against a subquery.
  ///
  /// [query] is the subquery to join against.
  /// [alias] is the alias for the subquery, which is required.
  /// [constraint] defines the join condition.
  ///
  /// Example:
  /// ```dart
  /// final usersWithOptionalRecentOrders = await context.query<User>()
  ///   .leftJoinSub(
  ///     context.query<Order>()
  ///       .whereGreaterThan('createdAt', DateTime.now().subtract(Duration(days: 30))),
  ///     'recentOrders',
  ///     'users.id', '=', 'recentOrders.user_id',
  ///   )
  ///   .get();
  /// ```
  Query<T> leftJoinSub(
    Query<dynamic> query,
    String alias,
    Object constraint, [
    Object? operator,
    Object? second,
  ]) {
    _assertSubqueryAlias(alias);
    return _join(
      target: _subqueryTarget(query),
      type: JoinType.left,
      constraint: constraint,
      operator: operator,
      second: second,
      alias: alias,
    );
  }

  /// Adds a RIGHT JOIN against a subquery.
  ///
  /// [query] is the subquery to join against.
  /// [alias] is the alias for the subquery, which is required.
  /// [constraint] defines the join condition.
  ///
  /// Example:
  /// ```dart
  /// final recentOrdersWithOptionalUsers = await context.query<Order>()
  ///   .rightJoinSub(
  ///     context.query<User>().where('isActive', true),
  ///     'activeUsers',
  ///     'orders.user_id', '=', 'activeUsers.id',
  ///   )
  ///   .get();
  /// ```
  Query<T> rightJoinSub(
    Query<dynamic> query,
    String alias,
    Object constraint, [
    Object? operator,
    Object? second,
  ]) {
    _assertSubqueryAlias(alias);
    return _join(
      target: _subqueryTarget(query),
      type: JoinType.right,
      constraint: constraint,
      operator: operator,
      second: second,
      alias: alias,
    );
  }

  /// Adds a CROSS JOIN against a subquery.
  ///
  /// [query] is the subquery to join against.
  /// [alias] is the alias for the subquery, which is required.
  /// [constraint] defines the join condition (optional for cross joins).
  ///
  /// Example:
  /// ```dart
  /// final productCombinations = await context.query<Product>()
  ///   .crossJoinSub(
  ///     context.query<Color>().select(['name as colorName']),
  ///     'colors',
  ///   )
  ///   .get();
  /// ```
  Query<T> crossJoinSub(
    Query<dynamic> query,
    String alias, [
    Object? constraint,
    Object? operator,
    Object? second,
  ]) {
    _assertSubqueryAlias(alias);
    return _join(
      target: _subqueryTarget(query),
      type: JoinType.cross,
      constraint: constraint,
      operator: operator,
      second: second,
      alias: alias,
    );
  }

  /// Adds a (driver-gated) LATERAL JOIN clause.
  ///
  /// LATERAL joins are supported by some SQL dialects (e.g., PostgreSQL) and
  /// allow subqueries to reference columns from the preceding `FROM` item.
  ///
  /// [query] is the subquery to join against.
  /// [alias] is the alias for the subquery, which is required.
  /// [type] is the type of lateral join (defaults to [JoinType.inner]).
  /// [on] is an optional callback to define complex join conditions.
  ///
  /// Example (PostgreSQL):
  /// ```dart
  /// final usersWithLatestPost = await context.query<User>()
  ///   .joinLateral(
  ///     context.query<Post>()
  ///       .whereColumn('posts.user_id', '=', 'users.id')
  ///       .orderBy('createdAt', descending: true)
  ///       .limit(1),
  ///     'latestPost',
  ///   )
  ///   .get();
  /// ```
  Query<T> joinLateral(
    Query<dynamic> query,
    String alias, {
    JoinType type = JoinType.inner,
    JoinConstraintBuilder? on,
  }) {
    _assertSubqueryAlias(alias);
    return _join(
      target: _subqueryTarget(query),
      type: type,
      constraint: on,
      lateral: true,
      alias: alias,
    );
  }

  /// Adds a LEFT JOIN LATERAL clause.
  ///
  /// This is a convenience method for performing a LEFT LATERAL JOIN.
  ///
  /// Example (PostgreSQL):
  /// ```dart
  /// final usersWithOptionalLatestPost = await context.query<User>()
  ///   .leftJoinLateral(
  ///     context.query<Post>()
  ///       .whereColumn('posts.user_id', '=', 'users.id')
  ///       .orderBy('createdAt', descending: true)
  ///       .limit(1),
  ///     'latestPost',
  ///   )
  ///   .get();
  /// ```
  Query<T> leftJoinLateral(
    Query<dynamic> query,
    String alias, {
    JoinConstraintBuilder? on,
  }) => joinLateral(query, alias, type: JoinType.left, on: on);
}
