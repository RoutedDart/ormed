part of 'query.dart';

/// Fluent builder for filtering, ordering, paginating, and eager-loading
/// models of type [T].
///
/// The [Query] class provides a powerful and flexible API for constructing
/// database queries in a fluent manner. It supports a wide range of operations
/// including `WHERE` clauses, `JOIN`s, `ORDER BY`, `LIMIT`, `OFFSET`,
/// eager loading of relations, and various aggregation functions.
///
/// Queries are executed against a [QueryContext] which provides the underlying
/// database driver and model definitions.
///
/// Example:
/// ```dart
/// final users = await context.query<User>()
///   .where('active', equals: true)
///   .orderBy('name')
///   .get();
///
/// final activePosts = await context.query<Post>()
///   .joinRelation('author')
///   .where('author.isActive', true)
///   .get();
/// ```
class Query<T> {
  Query._({
    required this.definition,
    required this.context,
    List<FilterClause>? filters,
    List<OrderClause>? orders,
    List<RelationLoad>? relations,
    List<JoinDefinition>? joins,
    List<IndexHint>? indexHints,
    List<FullTextWhere>? fullTextWheres,
    List<JsonWhereClause>? jsonWheres,
    List<DateWhereClause>? dateWheres,
    bool randomOrder = false,
    num? randomSeed,
    String? lockClause,
    int? limit,
    int? offset,
    QueryPredicate? predicate,
    List<String>? selects,
    List<RawSelectExpression>? rawSelects,
    List<ProjectionOrderEntry>? projectionOrder,
    List<AggregateExpression>? aggregates,
    List<String>? groupBy,
    QueryPredicate? having,
    List<RelationAggregate>? relationAggregates,
    List<RelationOrder>? relationOrders,
    Map<String, RelationPath>? relationPaths,
    Set<String>? ignoredScopes,
    bool globalScopesApplied = false,
    bool ignoreAllGlobalScopes = false,
    String? tableAlias,
    List<String>? adHocScopes,
    Map<String, _RelationJoinRequest>? relationJoinRequests,
    GroupLimit? groupLimit,
    bool distinct = false,
    List<DistinctOnClause>? distinctOn,
    List<QueryUnion>? unions,
  }) : _filters = filters ?? <FilterClause>[],
       _orders = orders ?? <OrderClause>[],
       _relations = relations ?? <RelationLoad>[],
       _joins = joins ?? <JoinDefinition>[],
       _indexHints = indexHints ?? <IndexHint>[],
       _fullTextWheres = fullTextWheres ?? <FullTextWhere>[],
       _jsonWheres = jsonWheres ?? <JsonWhereClause>[],
       _dateWheres = dateWheres ?? <DateWhereClause>[],
       _randomOrder = randomOrder,
       _randomSeed = randomSeed,
       _lockClause = lockClause,
       _limit = limit,
       _offset = offset,
       _predicate = predicate,
       _selects = selects ?? <String>[],
       _rawSelects = rawSelects ?? <RawSelectExpression>[],
       _projectionOrder = projectionOrder ?? <ProjectionOrderEntry>[],
       _aggregates = aggregates ?? <AggregateExpression>[],
       _groupBy = groupBy ?? <String>[],
       _having = having,
       _relationAggregates = relationAggregates ?? <RelationAggregate>[],
       _relationOrders = relationOrders ?? <RelationOrder>[],
       _relationPaths = relationPaths != null
           ? Map<String, RelationPath>.from(relationPaths)
           : <String, RelationPath>{},
       _relationJoinRequests = relationJoinRequests != null
           ? Map<String, _RelationJoinRequest>.from(relationJoinRequests)
           : <String, _RelationJoinRequest>{},
       _ignoredGlobalScopes = ignoredScopes ?? <String>{},
       _globalScopesApplied = globalScopesApplied,
       _ignoreAllGlobalScopes = ignoreAllGlobalScopes,
       _tableAlias = tableAlias,
       _adHocScopes = List<String>.from(adHocScopes ?? const <String>[]),
       _groupLimit = groupLimit,
       _distinct = distinct,
       _distinctOn = List<DistinctOnClause>.from(
         distinctOn ?? const <DistinctOnClause>[],
       ),
       _unions = unions ?? const <QueryUnion>[];

  final ModelDefinition<T> definition;
  final QueryContext context;
  final List<FilterClause> _filters;
  final List<OrderClause> _orders;
  final List<RelationLoad> _relations;
  final List<JoinDefinition> _joins;
  final List<IndexHint> _indexHints;
  final List<FullTextWhere> _fullTextWheres;
  final List<JsonWhereClause> _jsonWheres;
  final List<DateWhereClause> _dateWheres;
  final bool _randomOrder;
  final num? _randomSeed;
  final String? _lockClause;
  final int? _limit;
  final int? _offset;
  final QueryPredicate? _predicate;
  final List<String> _selects;
  final List<RawSelectExpression> _rawSelects;
  final List<ProjectionOrderEntry> _projectionOrder;
  final List<AggregateExpression> _aggregates;
  final List<String> _groupBy;
  final QueryPredicate? _having;
  final List<RelationAggregate> _relationAggregates;
  final List<RelationOrder> _relationOrders;
  final Map<String, RelationPath> _relationPaths;
  final Map<String, _RelationJoinRequest> _relationJoinRequests;
  final Set<String> _ignoredGlobalScopes;
  final bool _globalScopesApplied;
  final bool _ignoreAllGlobalScopes;
  final String? _tableAlias;
  final List<String> _adHocScopes;
  final GroupLimit? _groupLimit;
  final bool _distinct;
  final List<DistinctOnClause> _distinctOn;
  final List<QueryUnion> _unions;

  static const String _softDeleteScope =
      ScopeRegistry.softDeleteScopeIdentifier;
  static const int _defaultStreamEagerBatchSize = 500;
  static const Object _unset = Object();

  /// Adds an equality comparison for the column mapped by [field].
  ///
  /// This method adds a `WHERE field = value` clause to the query.
  ///
  /// Example:
  /// ```dart
  /// final activeUsers = await context.query<User>()
  ///   .whereEquals('isActive', true)
  ///   .get();
  /// ```
  Query<T> whereEquals(String field, Object? value) =>
      _appendSimpleCondition(field, FilterOperator.equals, value);

  /// Adds an `IN` comparison for [field] using [values].
  ///
  /// This method adds a `WHERE field IN (value1, value2, ...)` clause to the query.
  ///
  /// Example:
  /// ```dart
  /// final usersInCities = await context.query<User>()
  ///   .whereIn('city', ['New York', 'London'])
  ///   .get();
  /// ```
  Query<T> whereIn(String field, Iterable<Object?> values) =>
      _appendSimpleCondition(field, FilterOperator.inValues, values.toList());

  /// Adds a `NOT IN` comparison for [field] using [values].
  ///
  /// This method adds a `WHERE field NOT IN (value1, value2, ...)` clause to the query.
  ///
  /// Example:
  /// ```dart
  /// final usersNotInCities = await context.query<User>()
  ///   .whereNotIn('city', ['Paris', 'Tokyo'])
  ///   .get();
  /// ```
  Query<T> whereNotIn(String field, Iterable<Object?> values) {
    final column = _ensureField(field).columnName;
    return _appendPredicate(
      FieldPredicate(
        field: column,
        operator: PredicateOperator.notInValues,
        values: List<Object?>.from(values),
      ),
      PredicateLogicalOperator.and,
    );
  }

  /// Adds a `>` comparison for [field].
  ///
  /// This method adds a `WHERE field > value` clause to the query.
  ///
  /// Example:
  /// ```dart
  /// final usersOlderThan18 = await context.query<User>()
  ///   .whereGreaterThan('age', 18)
  ///   .get();
  /// ```
  Query<T> whereGreaterThan(String field, Object value) =>
      _appendSimpleCondition(field, FilterOperator.greaterThan, value);

  /// Adds a `>=` comparison for [field].
  ///
  /// This method adds a `WHERE field >= value` clause to the query.
  ///
  /// Example:
  /// ```dart
  /// final usersAtLeast18 = await context.query<User>()
  ///   .whereGreaterThanOrEqual('age', 18)
  ///   .get();
  /// ```
  Query<T> whereGreaterThanOrEqual(String field, Object value) =>
      _appendSimpleCondition(field, FilterOperator.greaterThanOrEqual, value);

  /// Adds a `<` comparison for [field].
  ///
  /// This method adds a `WHERE field < value` clause to the query.
  ///
  /// Example:
  /// ```dart
  /// final usersYoungerThan18 = await context.query<User>()
  ///   .whereLessThan('age', 18)
  ///   .get();
  /// ```
  Query<T> whereLessThan(String field, Object value) =>
      _appendSimpleCondition(field, FilterOperator.lessThan, value);

  /// Adds a `<=` comparison for [field].
  ///
  /// This method adds a `WHERE field <= value` clause to the query.
  ///
  /// Example:
  /// ```dart
  /// final usersUpTo18 = await context.query<User>()
  ///   .whereLessThanOrEqual('age', 18)
  ///   .get();
  /// ```
  Query<T> whereLessThanOrEqual(String field, Object value) =>
      _appendSimpleCondition(field, FilterOperator.lessThanOrEqual, value);

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

  /// Joins a relation path without eager loading it.
  ///
  /// This method allows you to join related tables to the main query without
  /// necessarily loading the related models into the result. This is useful
  /// for filtering or ordering based on related data.
  ///
  /// [relation] is the name of the relation to join (e.g., 'posts', 'author.profile').
  /// [type] is the type of join to perform (defaults to [JoinType.inner]).
  ///
  /// Example:
  /// ```dart
  /// final usersWithPosts = await context.query<User>()
  ///   .joinRelation('posts')
  ///   .where('posts.title', 'LIKE', '%Dart%')
  ///   .get();
  /// ```
  Query<T> joinRelation(String relation, {JoinType type = JoinType.inner}) {
    _resolveRelationPath(relation);
    final updated = Map<String, _RelationJoinRequest>.from(
      _relationJoinRequests,
    )..[relation] = _RelationJoinRequest(joinType: type);
    return _copyWith(relationJoinRequests: updated);
  }

  /// Adds a `!=` comparison for the column mapped by [field].
  ///
  /// This method adds a `WHERE field != value` clause to the query.
  ///
  /// Example:
  /// ```dart
  /// final usersNotActive = await context.query<User>()
  ///   .whereNotEquals('isActive', true)
  ///   .get();
  /// ```
  Query<T> whereNotEquals(String field, Object? value) =>
      where(field, value, PredicateOperator.notEquals);

  /// Generic `where` that accepts either a column comparison or a grouped
  /// predicate callback.
  ///
  /// When [fieldOrCallback] is a [String], it represents the column name.
  /// [value] and [operator] are used for simple comparisons.
  ///
  /// When [fieldOrCallback] is a [PredicateCallback], it allows for grouping
  /// multiple `WHERE` conditions using `AND` logic.
  ///
  /// Examples:
  /// ```dart
  /// // Simple equality comparison
  /// final activeUsers = await context.query<User>()
  ///   .where('isActive', true)
  ///   .get();
  ///
  /// // Comparison with a different operator
  /// final usersOlderThan18 = await context.query<User>()
  ///   .where('age', 18, PredicateOperator.greaterThan)
  ///   .get();
  ///
  /// // Grouped conditions
  /// final complexUsers = await context.query<User>()
  ///   .where((query) {
  ///     query.where('age', 18, PredicateOperator.greaterThan)
  ///          .orWhere('status', 'admin');
  ///   })
  ///   .get();
  /// ```
  Query<T> where(
    Object fieldOrCallback, [
    Object? value,
    PredicateOperator operator = PredicateOperator.equals,
  ]) {
    return _addWhere(
      fieldOrCallback,
      value,
      operator,
      logical: PredicateLogicalOperator.and,
    );
  }

  /// `OR` variant of [where].
  ///
  /// This method is similar to [where] but applies `OR` logic when grouping
  /// conditions or combining with previous `WHERE` clauses.
  ///
  /// Examples:
  /// ```dart
  /// // Simple OR comparison
  /// final activeOrAdminUsers = await context.query<User>()
  ///   .where('isActive', true)
  ///   .orWhere('role', 'admin')
  ///   .get();
  ///
  /// // Grouped OR conditions
  /// final complexUsers = await context.query<User>()
  ///   .where('status', 'pending')
  ///   .orWhere((query) {
  ///     query.where('age', 60, PredicateOperator.greaterThanOrEqual)
  ///          .where('isRetired', true);
  ///   })
  ///   .get();
  /// ```
  Query<T> orWhere(
    Object fieldOrCallback, [
    Object? value,
    PredicateOperator operator = PredicateOperator.equals,
  ]) {
    return _addWhere(
      fieldOrCallback,
      value,
      operator,
      logical: PredicateLogicalOperator.or,
    );
  }

  /// Adds a `WHERE BETWEEN` predicate.
  ///
  /// This method adds a `WHERE field BETWEEN lower AND upper` clause to the query.
  ///
  /// Example:
  /// ```dart
  /// final usersInAgeRange = await context.query<User>()
  ///   .whereBetween('age', 18, 30)
  ///   .get();
  /// ```
  Query<T> whereBetween(String field, Object lower, Object upper) {
    final resolved = _resolvePredicateField(field);
    return _appendPredicate(
      FieldPredicate(
        field: resolved.column,
        operator: PredicateOperator.between,
        lower: lower,
        upper: upper,
        jsonSelector: resolved.jsonSelector,
      ),
      PredicateLogicalOperator.and,
    );
  }

  /// Adds a `WHERE NOT BETWEEN` predicate.
  ///
  /// This method adds a `WHERE field NOT BETWEEN lower AND upper` clause to the query.
  ///
  /// Example:
  /// ```dart
  /// final usersOutsideAgeRange = await context.query<User>()
  ///   .whereNotBetween('age', 18, 30)
  ///   .get();
  /// ```
  Query<T> whereNotBetween(String field, Object lower, Object upper) {
    final resolved = _resolvePredicateField(field);
    return _appendPredicate(
      FieldPredicate(
        field: resolved.column,
        operator: PredicateOperator.notBetween,
        lower: lower,
        upper: upper,
        jsonSelector: resolved.jsonSelector,
      ),
      PredicateLogicalOperator.and,
    );
  }

  /// Adds a predicate comparing two columns.
  ///
  /// This method adds a `WHERE left_column OPERATOR right_column` clause to the query.
  ///
  /// Example:
  /// ```dart
  /// final usersWithMatchingIds = await context.query<User>()
  ///   .whereColumn('users.id', 'profiles.user_id')
  ///   .get();
  ///
  /// final usersWithDifferentNames = await context.query<User>()
  ///   .whereColumn('firstName', 'lastName', operator: PredicateOperator.columnNotEquals)
  ///   .get();
  /// ```
  Query<T> whereColumn(
    String left,
    String right, {
    PredicateOperator operator = PredicateOperator.columnEquals,
  }) {
    final leftResolved = _resolvePredicateField(left);
    final rightColumn = _ensureField(right).columnName;
    return _appendPredicate(
      FieldPredicate(
        field: leftResolved.column,
        compareField: rightColumn,
        operator: operator,
        jsonSelector: leftResolved.jsonSelector,
      ),
      PredicateLogicalOperator.and,
    );
  }

  /// Adds a NULL predicate.
  ///
  /// This method adds a `WHERE field IS NULL` clause to the query.
  ///
  /// Example:
  /// ```dart
  /// final usersWithoutEmail = await context.query<User>()
  ///   .whereNull('email')
  ///   .get();
  /// ```
  Query<T> whereNull(String field) {
    final resolved = _resolvePredicateField(field);
    final predicate = FieldPredicate(
      field: resolved.column,
      operator: PredicateOperator.isNull,
      jsonSelector: resolved.jsonSelector,
    );
    final updated = _appendPredicate(predicate, PredicateLogicalOperator.and);
    if (resolved.jsonSelector != null) {
      return updated;
    }
    return updated._withFilter(
      _buildFieldFilter(field, FilterOperator.isNull, null),
    );
  }

  /// Adds a NOT NULL predicate.
  Query<T> whereNotNull(String field) {
    final resolved = _resolvePredicateField(field);
    final predicate = FieldPredicate(
      field: resolved.column,
      operator: PredicateOperator.isNotNull,
      jsonSelector: resolved.jsonSelector,
    );
    final updated = _appendPredicate(predicate, PredicateLogicalOperator.and);
    if (resolved.jsonSelector != null) {
      return updated;
    }
    return updated._withFilter(
      _buildFieldFilter(field, FilterOperator.isNotNull, null),
    );
  }

  /// Adds a JSON containment predicate (dialect-aware).
  ///
  /// This method checks if a JSON column contains a specific value at a given path.
  ///
  /// [field] is the name of the JSON column.
  /// [value] is the value to check for containment.
  /// [path] is an optional JSON path expression (defaults to root '$').
  ///
  /// Example:
  /// ```dart
  /// final usersWithSpecificSkill = await context.query<User>()
  ///   .whereJsonContains('skills', 'Dart', path: r'$.languages')
  ///   .get();
  /// ```
  Query<T> whereJsonContains(String field, Object? value, {String? path}) {
    final reference = _resolveJsonReference(field, overridePath: path);
    final clause = JsonWhereClause.contains(
      column: reference.column,
      path: reference.path,
      value: value,
    );
    return _copyWith(jsonWheres: [..._jsonWheres, clause]);
  }

  /// Adds a JSON overlaps predicate (at least one shared array element).
  ///
  /// This method checks if two JSON arrays have at least one element in common.
  ///
  /// [field] is the name of the JSON column.
  /// [value] is the array of values to check for overlap.
  /// [path] is an optional JSON path expression (defaults to root '$').
  ///
  /// Example:
  /// ```dart
  /// final usersWithAnyOfSkills = await context.query<User>()
  ///   .whereJsonOverlaps('skills', ['Dart', 'Flutter'], path: r'$.languages')
  ///   .get();
  /// ```
  Query<T> whereJsonOverlaps(String field, Object value, {String? path}) {
    final reference = _resolveJsonReference(field, overridePath: path);
    final clause = JsonWhereClause.overlaps(
      column: reference.column,
      path: reference.path,
      value: value,
    );
    return _copyWith(jsonWheres: [..._jsonWheres, clause]);
  }

  /// Adds a JSON contains key predicate.
  ///
  /// This method checks if a JSON object contains a specific key at a given path.
  ///
  /// [field] is the name of the JSON column.
  /// [path] is an optional JSON path expression (defaults to root '$').
  ///
  /// Example:
  /// ```dart
  /// final usersWithAddress = await context.query<User>()
  ///   .whereJsonContainsKey('profile', r'$.address')
  ///   .get();
  /// ```
  Query<T> whereJsonContainsKey(String field, [String? path]) {
    final reference = _resolveJsonReference(field, overridePath: path);
    final clause = JsonWhereClause.containsKey(
      column: reference.column,
      path: reference.path,
    );
    return _copyWith(jsonWheres: [..._jsonWheres, clause]);
  }

  /// Adds a JSON length comparison predicate.
  ///
  /// This method compares the length of a JSON array or object at a given path.
  ///
  /// [field] is the name of the JSON column.
  /// [operatorOrLength] can be an integer for equality comparison, or a string
  /// operator (e.g., '>', '<=') when [length] is also provided.
  /// [length] is the target length for comparison.
  ///
  /// Examples:
  /// ```dart
  /// // Check if 'tags' array has exactly 3 elements
  /// final postsWithThreeTags = await context.query<Post>()
  ///   .whereJsonLength('tags', 3)
  ///   .get();
  ///
  /// // Check if 'comments' array has more than 5 elements
  /// final popularPosts = await context.query<Post>()
  ///   .whereJsonLength('comments', '>', 5)
  ///   .get();
  /// ```
  Query<T> whereJsonLength(
    String field,
    Object operatorOrLength, [
    int? length,
  ]) {
    String compare;
    int target;
    if (operatorOrLength is int && length == null) {
      compare = '=';
      target = operatorOrLength;
    } else if (operatorOrLength is String && length != null) {
      compare = operatorOrLength;
      target = length;
    } else {
      throw ArgumentError(
        'Provide either a length value or an operator + length pair.',
      );
    }
    final normalizedOperator = _normalizeLengthOperator(compare);
    final reference = _resolveJsonReference(field);
    final clause = JsonWhereClause.length(
      column: reference.column,
      path: reference.path,
      lengthOperator: normalizedOperator,
      lengthValue: target,
    );
    return _copyWith(jsonWheres: [..._jsonWheres, clause]);
  }

  /// Compares the DATE portion of [field]. Defaults to equality comparisons
  /// when only a single value is supplied.
  ///
  /// This method adds a `WHERE DATE(field) OPERATOR value` clause to the query.
  ///
  /// Examples:
  /// ```dart
  /// // Find posts created on a specific date
  /// final postsOnDate = await context.query<Post>()
  ///   .whereDate('createdAt', DateTime(2023, 1, 1))
  ///   .get();
  ///
  /// // Find posts created after a specific date
  /// final recentPosts = await context.query<Post>()
  ///   .whereDate('createdAt', '>', DateTime(2023, 1, 1))
  ///   .get();
  /// ```
  Query<T> whereDate(String field, Object valueOrOperator, [Object? value]) =>
      _appendDatePredicate(field, DateComponent.date, valueOrOperator, value);

  /// Filters by calendar day (1-31) regardless of timezone.
  ///
  /// This method adds a `WHERE DAY(field) OPERATOR value` clause to the query.
  ///
  /// Examples:
  /// ```dart
  /// // Find posts created on the 15th day of any month
  /// final postsOn15th = await context.query<Post>()
  ///   .whereDay('createdAt', 15)
  ///   .get();
  /// ```
  Query<T> whereDay(String field, Object valueOrOperator, [Object? value]) =>
      _appendDatePredicate(field, DateComponent.day, valueOrOperator, value);

  /// Filters by calendar month (1-12).
  ///
  /// This method adds a `WHERE MONTH(field) OPERATOR value` clause to the query.
  ///
  /// Examples:
  /// ```dart
  /// // Find posts created in January (month 1)
  /// final januaryPosts = await context.query<Post>()
  ///   .whereMonth('createdAt', 1)
  ///   .get();
  /// ```
  Query<T> whereMonth(String field, Object valueOrOperator, [Object? value]) =>
      _appendDatePredicate(field, DateComponent.month, valueOrOperator, value);

  /// Filters by four-digit calendar year.
  ///
  /// This method adds a `WHERE YEAR(field) OPERATOR value` clause to the query.
  ///
  /// Examples:
  /// ```dart
  /// // Find posts created in 2023
  /// final postsIn2023 = await context.query<Post>()
  ///   .whereYear('createdAt', 2023)
  ///   .get();
  /// ```
  Query<T> whereYear(String field, Object valueOrOperator, [Object? value]) =>
      _appendDatePredicate(field, DateComponent.year, valueOrOperator, value);

  /// Compares the HH:mm:ss component of [field].
  ///
  /// This method adds a `WHERE TIME(field) OPERATOR value` clause to the query.
  /// The [value] should be a [String] in 'HH:mm:ss' format.
  ///
  /// Examples:
  /// ```dart
  /// // Find posts created at exactly 10:00:00
  /// final postsAt10AM = await context.query<Post>()
  ///   .whereTime('createdAt', '10:00:00')
  ///   .get();
  /// ```
  Query<T> whereTime(String field, Object valueOrOperator, [Object? value]) =>
      _appendDatePredicate(field, DateComponent.time, valueOrOperator, value);

  /// Adds a `LIKE` predicate.
  ///
  /// This method adds a `WHERE field LIKE value` clause to the query.
  /// Use `%` as a wildcard character in [value].
  ///
  /// [caseInsensitive] (defaults to `false`) can be set to `true` to use `ILIKE`
  /// or a dialect-specific case-insensitive LIKE operator.
  ///
  /// Examples:
  /// ```dart
  /// // Find users whose name starts with 'J'
  /// final usersStartingWithJ = await context.query<User>()
  ///   .whereLike('name', 'J%')
  ///   .get();
  ///
  /// // Case-insensitive search for names containing 'smith'
  /// final smithUsers = await context.query<User>()
  ///   .whereLike('name', '%smith%', caseInsensitive: true)
  ///   .get();
  /// ```
  Query<T> whereLike(
    String field,
    Object value, {
    bool caseInsensitive = false,
  }) {
    final resolved = _resolvePredicateField(field);
    return _appendPredicate(
      FieldPredicate(
        field: resolved.column,
        operator: caseInsensitive
            ? PredicateOperator.iLike
            : PredicateOperator.like,
        value: value,
        caseInsensitive: caseInsensitive,
        jsonSelector: resolved.jsonSelector,
      ),
      PredicateLogicalOperator.and,
    );
  }

  /// Adds a NOT LIKE predicate.
  ///
  /// This method adds a `WHERE field NOT LIKE value` clause to the query.
  /// Use `%` as a wildcard character in [value].
  ///
  /// [caseInsensitive] (defaults to `false`) can be set to `true` to use `NOT ILIKE`
  /// or a dialect-specific case-insensitive NOT LIKE operator.
  ///
  /// Examples:
  /// ```dart
  /// // Find users whose name does not start with 'J'
  /// final usersNotStartingWithJ = await context.query<User>()
  ///   .whereNotLike('name', 'J%')
  ///   .get();
  /// ```
  Query<T> whereNotLike(
    String field,
    Object value, {
    bool caseInsensitive = false,
  }) {
    final resolved = _resolvePredicateField(field);
    return _appendPredicate(
      FieldPredicate(
        field: resolved.column,
        operator: caseInsensitive
            ? PredicateOperator.notILike
            : PredicateOperator.notLike,
        value: value,
        caseInsensitive: caseInsensitive,
        jsonSelector: resolved.jsonSelector,
      ),
      PredicateLogicalOperator.and,
    );
  }

  /// Adds an ILIKE predicate.
  ///
  /// This is a convenience method for [whereLike] with `caseInsensitive` set to `true`.
  ///
  /// Example:
  /// ```dart
  /// final smithUsers = await context.query<User>()
  ///   .whereILike('name', '%smith%')
  ///   .get();
  /// ```
  Query<T> whereILike(String field, Object value) =>
      whereLike(field, value, caseInsensitive: true);

  /// Adds a NOT ILIKE predicate.
  ///
  /// This is a convenience method for [whereNotLike] with `caseInsensitive` set to `true`.
  ///
  /// Example:
  /// ```dart
  /// final nonSmithUsers = await context.query<User>()
  ///   .whereNotILike('name', '%smith%')
  ///   .get();
  /// ```
  Query<T> whereNotILike(String field, Object value) =>
      whereNotLike(field, value, caseInsensitive: true);

  /// Adds a raw predicate fragment.
  ///
  /// This method allows you to inject raw SQL into the `WHERE` clause.
  /// Use `?` for parameter placeholders, and provide [bindings] for security.
  ///
  /// Example:
  /// ```dart
  /// final customFilteredUsers = await context.query<User>()
  ///   .whereRaw('LENGTH(name) > ?', [5])
  ///   .get();
  /// ```
  Query<T> whereRaw(String sql, [List<Object?> bindings = const []]) =>
      _appendPredicate(
        RawPredicate(sql: sql, bindings: bindings),
        PredicateLogicalOperator.and,
      );

  /// Adds a bitwise predicate.
  ///
  /// This method allows you to apply bitwise operations (e.g., `&`, `|`, `^`)
  /// in the `WHERE` clause.
  ///
  /// [field] is the column to apply the bitwise operation on.
  /// [operator] is the bitwise operator (e.g., '&', '|', '^').
  /// [value] is the value to compare with.
  ///
  /// Example:
  /// ```dart
  /// // Find users with a specific permission bit set
  /// final usersWithPermission = await context.query<User>()
  ///   .whereBitwise('permissions', '&', 4) // Assuming 4 is a permission bit
  ///   .get();
  /// ```
  Query<T> whereBitwise(String field, String operator, Object value) =>
      _appendPredicate(
        BitwisePredicate(
          field: _ensureField(field).columnName,
          operator: _normalizeBitwiseOperator(operator),
          value: value,
        ),
        PredicateLogicalOperator.and,
      );

  /// Adds a bitwise predicate with `OR` chaining.
  ///
  /// This method is similar to [whereBitwise] but applies `OR` logic when
  /// combining with previous `WHERE` clauses.
  ///
  /// Example:
  /// ```dart
  /// // Find users with permission A or permission B
  /// final usersWithPermissionAOrB = await context.query<User>()
  ///   .whereBitwise('permissions', '&', 1)
  ///   .orWhereBitwise('permissions', '&', 2)
  ///   .get();
  /// ```
  Query<T> orWhereBitwise(String field, String operator, Object value) =>
      _appendPredicate(
        BitwisePredicate(
          field: _ensureField(field).columnName,
          operator: _normalizeBitwiseOperator(operator),
          value: value,
        ),
        PredicateLogicalOperator.or,
      );

  /// Orders results by [field]. Set [descending] to sort in reverse.
  ///
  /// [field] can be a simple column name or a JSON path expression (e.g., 'data->name').
  ///
  /// Examples:
  /// ```dart
  /// // Order users by name ascending
  /// final usersByName = await context.query<User>()
  ///   .orderBy('name')
  ///   .get();
  ///
  /// // Order users by creation date descending
  /// final recentUsers = await context.query<User>()
  ///   .orderBy('createdAt', descending: true)
  ///   .get();
  ///
  /// // Order by a JSON field
  /// final usersByJsonName = await context.query<User>()
  ///   .orderBy('profile->name')
  ///   .get();
  /// ```
  Query<T> orderBy(String field, {bool descending = false}) {
    if (json_path.hasJsonSelector(field)) {
      final selector = json_path.parseJsonSelectorExpression(field);
      if (selector == null) {
        throw ArgumentError.value(field, 'field', 'Invalid JSON selector.');
      }
      final resolved = _ensureField(selector.column).columnName;
      final normalizedSelector = json_path.JsonSelector(
        resolved,
        selector.path,
        selector.extractsText,
      );
      return _copyWith(
        orders: [
          ..._orders,
          OrderClause(
            field: resolved,
            descending: descending,
            jsonSelector: normalizedSelector,
          ),
        ],
      );
    }
    final column = _ensureField(field).columnName;
    return _copyWith(
      orders: [
        ..._orders,
        OrderClause(field: column, descending: descending),
      ],
    );
  }

  List<DistinctOnClause> _normalizeDistinctColumns(Iterable<String> columns) {
    if (columns.isEmpty) {
      return const <DistinctOnClause>[];
    }
    final clauses = <DistinctOnClause>[];
    for (final column in columns) {
      if (json_path.hasJsonSelector(column)) {
        final selector = json_path.parseJsonSelectorExpression(column);
        if (selector == null) {
          throw ArgumentError.value(column, 'columns', 'Invalid JSON selector');
        }
        final resolved = _ensureField(selector.column).columnName;
        final normalizedSelector = json_path.JsonSelector(
          resolved,
          selector.path,
          selector.extractsText,
        );
        clauses.add(
          DistinctOnClause(field: resolved, jsonSelector: normalizedSelector),
        );
      } else {
        final resolved = _ensureField(column).columnName;
        clauses.add(DistinctOnClause(field: resolved));
      }
    }
    return clauses;
  }

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

  /// Selects a subset of columns for the result projection.
  ///
  /// Only the specified [columns] will be retrieved from the database.
  ///
  /// Example:
  /// ```dart
  /// final userNames = await context.query<User>()
  ///   .select(['name', 'email'])
  ///   .get();
  /// ```
  Query<T> select(List<String> columns) {
    final mapped = columns
        .map((field) => _ensureField(field).columnName)
        .toList();
    final preservedRaw = _projectionOrder
        .where((entry) => entry.kind == ProjectionKind.raw)
        .toList(growable: false);
    final order = <ProjectionOrderEntry>[
      for (var i = 0; i < mapped.length; i++) ProjectionOrderEntry.column(i),
      ...preservedRaw,
    ];
    return _copyWith(selects: mapped, projectionOrder: order);
  }

  /// Adds a single column to the select projection.
  ///
  /// This method allows you to incrementally add columns to the select list.
  ///
  /// Example:
  /// ```dart
  /// final userNamesAndEmails = await context.query<User>()
  ///   .select(['id'])
  ///   .addSelect('name')
  ///   .addSelect('email')
  ///   .get();
  /// ```
  Query<T> addSelect(String column) {
    final mapped = _ensureField(column).columnName;
    final newSelects = [..._selects, mapped];
    final order = [
      ..._projectionOrder,
      ProjectionOrderEntry.column(newSelects.length - 1),
    ];
    return _copyWith(selects: newSelects, projectionOrder: order);
  }

  /// Adds a raw select expression with optional bindings.
  ///
  /// This method allows you to include custom SQL expressions in the `SELECT` clause.
  /// Use `?` for parameter placeholders, and provide [bindings] for security.
  ///
  /// [sql] is the raw SQL expression.
  /// [alias] is an optional alias for the expression in the result.
  /// [bindings] are parameters for the raw SQL expression.
  ///
  /// Example:
  /// ```dart
  /// final usersWithFullName = await context.query<User>()
  ///   .selectRaw("CONCAT(firstName, ' ', lastName) AS fullName", alias: 'fullName')
  ///   .get();
  /// ```
  Query<T> selectRaw(
    String sql, {
    String? alias,
    List<Object?> bindings = const [],
  }) {
    final expression = RawSelectExpression(
      sql: sql,
      alias: alias,
      bindings: bindings,
    );
    final newRaw = [..._rawSelects, expression];
    final order = [
      ..._projectionOrder,
      ProjectionOrderEntry.raw(newRaw.length - 1),
    ];
    return _copyWith(rawSelects: newRaw, projectionOrder: order);
  }

  /// Registers an aggregate projection, e.g. `count('*')`.
  ///
  /// This method allows you to include aggregate functions in the `SELECT` clause.
  ///
  /// [function] is the aggregate function to use (e.g., [AggregateFunction.count]).
  /// [expression] is the column or expression to aggregate.
  /// [alias] is an optional alias for the aggregate result.
  ///
  /// Example:
  /// ```dart
  /// final userCount = await context.query<User>()
  ///   .withAggregate(AggregateFunction.count, '*', alias: 'totalUsers')
  ///   .first()
  ///   .then((row) => row?.row['totalUsers']);
  /// ```
  Query<T> withAggregate(
    AggregateFunction function,
    String expression, {
    String? alias,
  }) {
    final expr = _resolveExpression(expression);
    return _copyWith(
      aggregates: [
        ..._aggregates,
        AggregateExpression(function: function, expression: expr, alias: alias),
      ],
    );
  }

  /// Adds a `COUNT` aggregate to the select projection.
  ///
  /// This is a convenience method for `withAggregate(AggregateFunction.count, ...)`.
  ///
  /// [expression] is the column or expression to count (defaults to '*').
  /// [alias] is an optional alias for the count result.
  ///
  /// Example:
  /// ```dart
  /// final totalUsers = await context.query<User>()
  ///   .countAggregate(alias: 'total')
  ///   .first()
  ///   .then((row) => row?.row['total']);
  /// ```
  Query<T> countAggregate({String expression = '*', String? alias}) =>
      withAggregate(AggregateFunction.count, expression, alias: alias);

  /// Adds a `SUM` aggregate to the select projection.
  ///
  /// Example:
  /// ```dart
  /// final totalOrdersAmount = await context.query<Order>()
  ///   .sum('amount', alias: 'totalAmount')
  ///   .first()
  ///   .then((row) => row?.row['totalAmount']);
  /// ```
  Query<T> sum(String expression, {String? alias}) =>
      withAggregate(AggregateFunction.sum, expression, alias: alias);

  /// Executes a `SUM` aggregate and returns the result.
  ///
  /// This is a convenience method that builds and executes a query
  /// to get the sum of an [expression].
  ///
  /// Example:
  /// ```dart
  /// final totalSales = await context.query<Order>()
  ///   .sumValue('amount');
  /// print('Total sales: $totalSales');
  /// ```
  Future<num?> sumValue(String expression, {String? alias}) =>
      _aggregateScalar(AggregateFunction.sum, expression, alias: alias);

  /// Adds an `AVG` aggregate to the select projection.
  ///
  /// Example:
  /// ```dart
  /// final averageRating = await context.query<Product>()
  ///   .avg('rating', alias: 'avgRating')
  ///   .first()
  ///   .then((row) => row?.row['avgRating']);
  /// ```
  Query<T> avg(String expression, {String? alias}) =>
      withAggregate(AggregateFunction.avg, expression, alias: alias);

  /// Executes an `AVG` aggregate and returns the result.
  ///
  /// This is a convenience method that builds and executes a query
  /// to get the average value of an [expression].
  ///
  /// Example:
  /// ```dart
  /// final averageRating = await context.query<Product>()
  ///   .avgValue('rating');
  /// print('The average rating is: $averageRating');
  /// ```
  Future<num?> avgValue(String expression, {String? alias}) =>
      _aggregateScalar(AggregateFunction.avg, expression, alias: alias);

  /// Adds a `MIN` aggregate to the select projection.
  ///
  /// Example:
  /// ```dart
  /// final lowestPrice = await context.query<Product>()
  ///   .min('price', alias: 'minPrice')
  ///   .first()
  ///   .then((row) => row?.row['minPrice']);
  /// ```
  Query<T> min(String expression, {String? alias}) =>
      withAggregate(AggregateFunction.min, expression, alias: alias);

  /// Executes a `MIN` aggregate and returns the result.
  ///
  /// This is a convenience method that builds and executes a query
  /// to get the minimum value of an [expression].
  ///
  /// Example:
  /// ```dart
  /// final lowestPrice = await context.query<Product>()
  ///   .minValue('price');
  /// print('The lowest price is: $lowestPrice');
  /// ```
  Future<num?> minValue(String expression, {String? alias}) =>
      _aggregateScalar(AggregateFunction.min, expression, alias: alias);

  /// Adds a `MAX` aggregate to the select projection.
  ///
  /// Example:
  /// ```dart
  /// final highestPrice = await context.query<Product>()
  ///   .max('price', alias: 'maxPrice')
  ///   .first()
  ///   .then((row) => row?.row['maxPrice']);
  /// ```
  Query<T> max(String expression, {String? alias}) =>
      withAggregate(AggregateFunction.max, expression, alias: alias);

  /// Executes a `MAX` aggregate and returns the result.
  ///
  /// This is a convenience method that builds and executes a query
  /// to get the maximum value of an [expression].
  ///
  /// Example:
  /// ```dart
  /// final highestPrice = await context.query<Product>()
  ///   .maxValue('price');
  /// print('The highest price is: $highestPrice');
  /// ```
  Future<num?> maxValue(String expression, {String? alias}) =>
      _aggregateScalar(AggregateFunction.max, expression, alias: alias);

  String _resolveExpression(String expression) {
    final field = definition.fields.firstWhereOrNull(
      (f) => f.name == expression || f.columnName == expression,
    );
    return field?.columnName ?? expression;
  }

  /// Groups rows by the provided [columns].
  ///
  /// This method adds a `GROUP BY` clause to the query, often used in conjunction
  /// with aggregate functions.
  ///
  /// Example:
  /// ```dart
  /// final userCountsByCity = await context.query<User>()
  ///   .select(['city'])
  ///   .countAggregate(alias: 'userCount')
  ///   .groupBy(['city'])
  ///   .get();
  /// ```
  Query<T> groupBy(List<String> columns) {
    final mapped = columns
        .map((field) => _ensureField(field).columnName)
        .toList();
    return _copyWith(groupBy: [..._groupBy, ...mapped]);
  }

  /// Adds a HAVING predicate over grouped rows.
  ///
  /// This method is similar to `where` but applies conditions to the results
  /// of aggregate functions after grouping.
  ///
  /// Example:
  /// ```dart
  /// final citiesWithManyUsers = await context.query<User>()
  ///   .select(['city'])
  ///   .countAggregate(alias: 'userCount')
  ///   .groupBy(['city'])
  ///   .having('userCount', PredicateOperator.greaterThan, 10)
  ///   .get();
  /// ```
  Query<T> having(String field, PredicateOperator operator, Object? value) {
    final column = _resolveHavingField(field);
    final predicate = FieldPredicate(
      field: column,
      operator: operator,
      value: value,
    );
    return _appendHavingPredicate(predicate, PredicateLogicalOperator.and);
  }

  /// Adds a raw HAVING fragment.
  ///
  /// This method allows you to inject raw SQL into the `HAVING` clause.
  /// Use `?` for parameter placeholders, and provide [bindings] for security.
  ///
  /// Example:
  /// ```dart
  /// final customHaving = await context.query<User>()
  ///   .select(['city'])
  ///   .countAggregate(alias: 'userCount')
  ///   .groupBy(['city'])
  ///   .havingRaw('SUM(age) > ?', [100])
  ///   .get();
  /// ```
  Query<T> havingRaw(String sql, [List<Object?> bindings = const []]) {
    final predicate = RawPredicate(sql: sql, bindings: bindings);
    return _appendHavingPredicate(predicate, PredicateLogicalOperator.and);
  }

  /// Adds a HAVING clause with a bitwise operator.
  ///
  /// This method allows you to apply bitwise operations in the `HAVING` clause.
  ///
  /// Example:
  /// ```dart
  /// final groupedByPermissions = await context.query<User>()
  ///   .select(['permissions'])
  ///   .countAggregate(alias: 'userCount')
  ///   .groupBy(['permissions'])
  ///   .havingBitwise('permissions', '&', 4)
  ///   .get();
  /// ```
  Query<T> havingBitwise(String field, String operator, Object value) {
    final predicate = _buildBitwisePredicate(field, operator, value);
    return _appendHavingPredicate(predicate, PredicateLogicalOperator.and);
  }

  /// Adds a HAVING clause with a bitwise operator using OR chaining.
  ///
  /// This method is similar to [havingBitwise] but applies `OR` logic when
  /// combining with previous `HAVING` clauses.
  ///
  /// Example:
  /// ```dart
  /// final groupedByPermissions = await context.query<User>()
  ///   .select(['permissions'])
  ///   .countAggregate(alias: 'userCount')
  ///   .groupBy(['permissions'])
  ///   .havingBitwise('permissions', '&', 1)
  ///   .orHavingBitwise('permissions', '&', 2)
  ///   .get();
  /// ```
  Query<T> orHavingBitwise(String field, String operator, Object value) {
    final predicate = _buildBitwisePredicate(field, operator, value);
    return _appendHavingPredicate(predicate, PredicateLogicalOperator.or);
  }

  /// Orders results randomly.
  ///
  /// This method adds a `ORDER BY RANDOM()` (or equivalent) clause to the query.
  /// An optional [seed] can be provided for reproducible random ordering in some databases.
  ///
  /// Example:
  /// ```dart
  /// final randomUsers = await context.query<User>()
  ///   .orderByRandom()
  ///   .limit(5)
  ///   .get();
  /// ```
  Query<T> orderByRandom([num? seed]) => _copyWith(
    orders: const <OrderClause>[],
    randomOrder: true,
    randomSeed: seed,
  );

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
  Query<T> lockForUpdate() => _copyWith(lockClause: _LockClauses.forUpdate);

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
  Query<T> sharedLock() => _copyWith(lockClause: _LockClauses.shared);

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

  /// Adds a full-text predicate.
  ///
  /// This method allows you to perform full-text searches on specified columns.
  /// The behavior depends on the underlying database driver's full-text capabilities.
  ///
  /// [columns] are the columns to search within.
  /// [value] is the search query.
  /// [language] is an optional language for the full-text search.
  /// [mode] specifies the full-text search mode (e.g., [FullTextMode.natural]).
  /// [expanded] indicates whether to expand the search query.
  ///
  /// Example:
  /// ```dart
  /// final relevantPosts = await context.query<Post>()
  ///   .whereFullText(['title', 'body'], 'Dart programming')
  ///   .get();
  /// ```
  Query<T> whereFullText(
    List<String> columns,
    Object value, {
    String? language,
    FullTextMode mode = FullTextMode.natural,
    bool expanded = false,
  }) {
    if (columns.isEmpty) {
      throw ArgumentError.value(columns, 'columns', 'must not be empty.');
    }
    final clause = FullTextWhere(
      columns: columns,
      value: value,
      language: language,
      mode: mode,
      expanded: expanded,
    );
    return _copyWith(fullTextWheres: [..._fullTextWheres, clause]);
  }

  /// Requests eager loading for the relation named [name].
  ///
  /// Eager loading fetches related models in the same query or a minimal number
  /// of subsequent queries, preventing N+1 query problems.
  ///
  /// [name] is the name of the relation as defined in the model.
  /// [constraint] is an optional callback to apply additional `WHERE` conditions
  /// to the eager-loaded relation.
  ///
  /// Example:
  /// ```dart
  /// // Eager load the 'posts' relation for each user
  /// final usersWithPosts = await context.query<User>()
  ///   .withRelation('posts')
  ///   .get();
  ///
  /// // Eager load 'posts' and filter them
  /// final usersWithPublishedPosts = await context.query<User>()
  ///   .withRelation('posts', (query) => query.where('isPublished', true))
  ///   .get();
  /// ```
  Query<T> withRelation(String name, [PredicateCallback<dynamic>? constraint]) {
    final relation = definition.relations.firstWhereOrNull(
      (r) => r.name == name,
    );
    if (relation == null) {
      throw ArgumentError.value(
        name,
        'name',
        'Relation not defined on ${definition.modelName}.',
      );
    }
    final predicate = _buildRelationLoadPredicate(relation, constraint);
    _relationPaths.putIfAbsent(name, () {
      final segment = _buildRelationSegment(definition, relation);
      return RelationPath(segments: [segment]);
    });
    return _copyWith(
      relations: [
        ..._relations,
        RelationLoad(relation: relation, predicate: predicate),
      ],
    );
  }

  /// Adds a `WHERE HAS` clause for a relation.
  ///
  /// This method filters the parent models based on the existence of related models
  /// that satisfy an optional constraint.
  ///
  /// [relation] is the name of the relation.
  /// [constraint] is an optional callback to apply conditions to the related models.
  ///
  /// Example:
  /// ```dart
  /// // Find users who have at least one post
  /// final usersWithPosts = await context.query<User>()
  ///   .whereHas('posts')
  ///   .get();
  ///
  /// // Find users who have at least one published post
  /// final usersWithPublishedPosts = await context.query<User>()
  ///   .whereHas('posts', (query) => query.where('isPublished', true))
  ///   .get();
  /// ```
  Query<T> whereHas(
    String relation, [
    PredicateCallback<dynamic>? constraint,
  ]) => _addRelationWhere(
    relation,
    constraint,
    logical: PredicateLogicalOperator.and,
  );

  /// Adds an `OR WHERE HAS` clause for a relation.
  ///
  /// This method is similar to [whereHas] but applies `OR` logic.
  ///
  /// [relation] is the name of the relation.
  /// [constraint] is an optional callback to apply conditions to the related models.
  ///
  /// Example:
  /// ```dart
  /// // Find users who are active OR have at least one post
  /// final activeOrPostedUsers = await context.query<User>()
  ///   .where('isActive', true)
  ///   .orWhereHas('posts')
  ///   .get();
  /// ```
  Query<T> orWhereHas(
    String relation, [
    PredicateCallback<dynamic>? constraint,
  ]) => _addRelationWhere(
    relation,
    constraint,
    logical: PredicateLogicalOperator.or,
  );

  /// Adds a `WITH COUNT` aggregate for a relation.
  ///
  /// This method counts the number of related models for each parent model
  /// and adds it as a new column to the result.
  ///
  /// [relation] is the name of the relation.
  /// [alias] is an optional alias for the count result (defaults to `relation_count`).
  /// [constraint] is an optional callback to apply conditions to the related models
  /// before counting.
  /// [distinct] whether to count distinct related models.
  ///
  /// Example:
  /// ```dart
  /// final usersWithPostCounts = await context.query<User>()
  ///   .withCount('posts', alias: 'totalPosts')
  ///   .get();
  ///
  /// // Count only published posts
  /// final usersWithPublishedPostCounts = await context.query<User>()
  ///   .withCount('posts', alias: 'publishedPosts', (query) => query.where('isPublished', true))
  ///   .get();
  /// ```
  Query<T> withCount(
    String relation, {
    String? alias,
    PredicateCallback<dynamic>? constraint,
    bool distinct = false,
  }) {
    final aggregate = _buildRelationAggregate(
      relation,
      RelationAggregateType.count,
      alias,
      constraint,
      distinct: distinct,
    );
    return _copyWith(relationAggregates: [..._relationAggregates, aggregate]);
  }

  /// Adds a `WITH EXISTS` aggregate for a relation.
  ///
  /// This method checks for the existence of related models for each parent model
  /// and adds a boolean flag as a new column to the result.
  ///
  /// [relation] is the name of the relation.
  /// [alias] is an optional alias for the existence flag (defaults to `relation_exists`).
  /// [constraint] is an optional callback to apply conditions to the related models.
  ///
  /// Example:
  /// ```dart
  /// final usersWithPostsFlag = await context.query<User>()
  ///   .withExists('posts', alias: 'hasPosts')
  ///   .get();
  /// ```
  Query<T> withExists(
    String relation, {
    String? alias,
    PredicateCallback<dynamic>? constraint,
  }) {
    final aggregate = _buildRelationAggregate(
      relation,
      RelationAggregateType.exists,
      alias,
      constraint,
    );
    return _copyWith(relationAggregates: [..._relationAggregates, aggregate]);
  }

  /// Orders results based on a relation aggregate.
  ///
  /// This method allows you to sort parent models based on an aggregate value
  /// (e.g., count) of their related models.
  ///
  /// [relation] is the name of the relation.
  /// [descending] (defaults to `false`) to sort in reverse.
  /// [aggregate] is the type of aggregate to use for ordering (defaults to [RelationAggregateType.count]).
  /// [constraint] is an optional callback to apply conditions to the related models.
  /// [distinct] whether to count distinct related models for the aggregate.
  ///
  /// Example:
  /// ```dart
  /// // Order users by the number of their posts (most posts first)
  /// final usersByPostCount = await context.query<User>()
  ///   .orderByRelation('posts', descending: true)
  ///   .get();
  /// ```
  Query<T> orderByRelation(
    String relation, {
    bool descending = false,
    RelationAggregateType aggregate = RelationAggregateType.count,
    PredicateCallback<dynamic>? constraint,
    bool distinct = false,
  }) {
    if (aggregate != RelationAggregateType.count && distinct) {
      throw ArgumentError(
        'distinct relation ordering is only supported for count aggregates.',
      );
    }
    final path = _resolveRelationPath(relation);
    final where = _buildRelationPredicateConstraint(path, constraint);
    final order = RelationOrder(
      path: path,
      aggregateType: aggregate,
      descending: descending,
      where: where,
      distinct: distinct,
    );
    return _copyWith(relationOrders: [..._relationOrders, order]);
  }

  /// Returns the SQL preview without executing the query.
  ///
  /// This method is useful for debugging and understanding the generated SQL.
  ///
  /// Example:
  /// ```dart
  /// final sql = context.query<User>()
  ///   .where('isActive', true)
  ///   .toSql();
  /// print(sql.sqlWithBindings);
  /// ```
  StatementPreview toSql() => context.describeQuery(_buildPlan());

  /// Executes the query and returns hydrated [QueryRow] objects.
  ///
  /// Each [QueryRow] contains the materialized model and its raw data.
  ///
  /// Example:
  /// ```dart
  /// final userRows = await context.query<User>().rows();
  /// for (final row in userRows) {
  ///   print('User ID: ${row.model.id}, Raw data: ${row.row}');
  /// }
  /// ```
  Future<List<QueryRow<T>>> rows() async {
    final plan = _buildPlan();
    final rows = await context.runSelect(plan);
    final queryRows = rows
        .map((row) => _hydrateRow(row, plan))
        .toList(growable: true);
    await _applyRelationHookBatch(plan, queryRows);
    return queryRows;
  }

  @Deprecated('Use rows()')
  Future<List<QueryRow<T>>> getRows() => rows();

  /// Returns only the models without the surrounding [QueryRow] metadata.
  ///
  /// Example:
  /// ```dart
  /// final users = await context.query<User>().get();
  /// for (final user in users) {
  ///   print('User name: ${user.name}');
  /// }
  /// ```
  Future<List<T>> get() async =>
      (await rows()).map((row) => row.model).toList(growable: false);

  /// Returns the first matching row or `null` if none exist.
  ///
  /// Example:
  /// ```dart
  /// final firstUserRow = await context.query<User>()
  ///   .orderBy('createdAt')
  ///   .firstRow();
  /// if (firstUserRow != null) {
  ///   print('First user: ${firstUserRow.model.name}');
  /// }
  /// ```
  Future<QueryRow<T>?> firstRow() async {
    final rows = await limit(1).rows();
    return rows.isEmpty ? null : rows.first;
  }

  /// Returns the first model instance or `null` when no rows exist.
  ///
  /// Example:
  /// ```dart
  /// final firstUser = await context.query<User>()
  ///   .orderBy('createdAt')
  ///   .first();
  /// if (firstUser != null) {
  ///   print('First user: ${firstUser.name}');
  /// }
  /// ```
  Future<T?> first() async => (await firstRow())?.model;

  /// Alias for [first] to match Laravel naming.
  Future<T?> firstOrNull() async => first();

  @Deprecated('Use firstOrNull() instead')
  Future<T?> firstModel() async => firstOrNull();

  /// Returns only the models without the surrounding [QueryRow] metadata.
  @Deprecated('Use get()')
  Future<List<T>> models() async => get();

  /// Returns the first model or throws when no records exist.
  ///
  /// Throws [ModelNotFoundException] if no record is found.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final user = await context.query<User>().where('id', 1).firstOrFail();
  ///   print('Found user: ${user.name}');
  /// } on ModelNotFoundException {
  ///   print('User with ID 1 not found.');
  /// }
  /// ```
  Future<T> firstOrFail({Object? key}) async {
    final model = await first();
    if (model != null) {
      return model;
    }
    throw ModelNotFoundException(definition.modelName, key: key);
  }

  /// Ensures there is exactly one record and returns it.
  ///
  /// Throws [ModelNotFoundException] if no record is found.
  /// Throws [MultipleRecordsFoundException] if more than one record is found.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final uniqueUser = await context.query<User>().where('email', 'unique@example.com').sole();
  ///   print('Found unique user: ${uniqueUser.name}');
  /// } on ModelNotFoundException {
  ///   print('No user found with that email.');
  /// } on MultipleRecordsFoundException {
  ///   print('Multiple users found with that email.');
  /// }
  /// ```
  Future<T> sole() async {
    final rows = await limit(2).rows();
    if (rows.isEmpty) {
      throw ModelNotFoundException(definition.modelName);
    }
    if (rows.length > 1) {
      throw MultipleRecordsFoundException(definition.modelName, rows.length);
    }
    return rows.first.model;
  }

  /// Finds a model by its primary key.
  ///
  /// Returns `null` if no model is found.
  /// Throws [StateError] if the model does not define a primary key.
  ///
  /// Example:
  /// ```dart
  /// final user = await context.query<User>().find(1);
  /// if (user != null) {
  ///   print('User found: ${user.name}');
  /// }
  /// ```
  Future<T?> find(Object key) async {
    final primaryKey = definition.primaryKeyField;
    if (primaryKey == null) {
      throw StateError(
        'Model ${definition.modelName} does not define a primary key.',
      );
    }
    return whereEquals(primaryKey.name, key).firstOrNull();
  }

  /// Finds multiple models by their primary keys.
  ///
  /// Returns an empty list if no models are found or [keys] is empty.
  /// Throws [StateError] if the model does not define a primary key.
  ///
  /// Example:
  /// ```dart
  /// final users = await context.query<User>().findMany([1, 2, 3]);
  /// print('Found ${users.length} users.');
  /// ```
  Future<List<T>> findMany(Iterable<Object> keys) async {
    final primaryKey = definition.primaryKeyField;
    if (primaryKey == null) {
      throw StateError(
        'Model ${definition.modelName} does not define a primary key.',
      );
    }
    final values = keys.toList(growable: false);
    if (values.isEmpty) return const [];
    return whereIn(primaryKey.name, values).get();
  }

  /// Finds a model by primary key or throws when missing.
  ///
  /// Throws [ModelNotFoundException] if no model is found.
  /// Throws [StateError] if the model does not define a primary key.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final user = await context.query<User>().findOrFail(1);
  ///   print('Found user: ${user.name}');
  /// } on ModelNotFoundException {
  ///   print('User with ID 1 not found.');
  /// }
  /// ```
  Future<T> findOrFail(Object key) async {
    final primaryKey = definition.primaryKeyField;
    if (primaryKey == null) {
      throw StateError(
        'Model ${definition.modelName} does not define a primary key.',
      );
    }
    return whereEquals(primaryKey.name, key).firstOrFail(key: key);
  }

  /// Returns the value of [field] from the first row, or `null` when missing.
  ///
  /// This is useful for retrieving a single scalar value from the database.
  ///
  /// Example:
  /// ```dart
  /// final userName = await context.query<User>()
  ///   .where('id', 1)
  ///   .value<String>('name');
  /// print('User name: $userName');
  /// ```
  Future<R?> value<R>(String field) async {
    final column = _ensureField(field).columnName;
    final result = await select(<String>[field]).firstRow();
    return result?.row[column] as R?;
  }

  /// Returns a list of values from [field].
  ///
  /// This is useful for retrieving a list of scalar values from a column.
  ///
  /// Example:
  /// ```dart
  /// final userNames = await context.query<User>()
  ///   .pluck<String>('name');
  /// print('All user names: $userNames');
  /// ```
  Future<List<R>> pluck<R>(String field) async {
    final column = _ensureField(field).columnName;
    final rows = await select(<String>[field]).rows();
    return rows.map((row) => row.row[column] as R).toList(growable: false);
  }

  /// Returns the number of rows that match the current query.
  ///
  /// [expression] is the column or expression to count (defaults to '*').
  ///
  /// Example:
  /// ```dart
  /// final activeUserCount = await context.query<User>()
  ///   .where('isActive', true)
  ///   .count();
  /// print('Active users: $activeUserCount');
  /// ```
  Future<int> count({String expression = '*'}) async {
    final alias = _aggregateAlias('count');
    final aggregateQuery = _copyForAggregation().withAggregate(
      AggregateFunction.count,
      expression,
      alias: alias,
    );
    final plan = aggregateQuery._buildPlan();
    final rows = await context.runSelect(plan);
    if (rows.isEmpty) return 0;
    final value = rows.first[alias];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return rows.length;
    return 0;
  }

  Future<num?> _aggregateScalar(
    AggregateFunction function,
    String expression, {
    String? alias,
  }) async {
    final resolved = _resolveExpression(expression);
    final referenceAlias = alias ?? _aggregateAlias(_aggregateLabel(function));
    final aggregateQuery = _copyForAggregation().withAggregate(
      function,
      resolved,
      alias: referenceAlias,
    );
    final plan = aggregateQuery._buildPlan();
    final rows = await context.runSelect(plan);
    if (rows.isEmpty) {
      return null;
    }
    final value = rows.first[referenceAlias];
    return _normalizeAggregateValue(value);
  }

  String _aggregateLabel(AggregateFunction function) {
    switch (function) {
      case AggregateFunction.count:
        return 'count';
      case AggregateFunction.sum:
        return 'sum';
      case AggregateFunction.avg:
        return 'avg';
      case AggregateFunction.min:
        return 'min';
      case AggregateFunction.max:
        return 'max';
    }
  }

  num? _normalizeAggregateValue(Object? value) {
    if (value is num) {
      return value;
    }
    if (value is String) {
      return num.tryParse(value);
    }
    return null;
  }

  /// Returns `true` if any rows match the current query.
  ///
  /// Example:
  /// ```dart
  /// final hasActiveUsers = await context.query<User>()
  ///   .where('isActive', true)
  ///   .exists();
  /// print('Are there active users? $hasActiveUsers');
  /// ```
  Future<bool> exists() async {
    final rows = await limit(1).rows();
    return rows.isNotEmpty;
  }

  /// Returns `true` if no rows match the current query.
  ///
  /// Example:
  /// ```dart
  /// final noInactiveUsers = await context.query<User>()
  ///   .where('isActive', false)
  ///   .doesntExist();
  /// print('Are there no inactive users? $noInactiveUsers');
  /// ```
  Future<bool> doesntExist() async => !(await exists());

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
    int eagerLoadBatchSize = _defaultStreamEagerBatchSize,
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

  /// Streams just the materialized models.
  ///
  /// This is a convenience method for [streamRows] that directly yields the
  /// model instances.
  ///
  /// Example:
  /// ```dart
  /// await for (final user in context.query<User>().streamModels()) {
  ///   print('Streaming user model: ${user.name}');
  /// }
  /// ```
  Stream<T> streamModels() => streamRows().map((row) => row.model);

  Future<void> _applyRelationHookBatch<R>(
    QueryPlan plan,
    List<QueryRow<R>> batch,
  ) async {
    if (batch.isEmpty || (_relations.isEmpty && _relationAggregates.isEmpty)) {
      return;
    }
    final relationHook = context.driver.metadata.relationHook;
    if (relationHook != null) {
      await relationHook.handleRelations(
        context,
        plan,
        definition,
        batch,
        _relations,
      );
      return;
    }
    if (_relations.isEmpty) {
      return;
    }
    final loader = RelationLoader(context);
    final joinMap = {for (final join in plan.relationJoins) join.pathKey: join};
    await loader.attach(definition, batch, _relations, joinMap: joinMap);
  }

  QueryRow<T> _hydrateRow(Map<String, Object?> row, QueryPlan plan) {
    final model = definition.fromMap(row, registry: context.codecRegistry);
    context.attachRuntimeMetadata(model);
    return QueryRow<T>(model: model, row: _projectionRow(row, plan));
  }

  Map<String, Object?> _projectionRow(
    Map<String, Object?> row,
    QueryPlan plan,
  ) {
    final hasCustomProjection =
        plan.selects.isNotEmpty ||
        plan.rawSelects.isNotEmpty ||
        plan.aggregates.isNotEmpty;
    if (!hasCustomProjection && plan.distinctOn.isEmpty) {
      return Map<String, Object?>.from(row);
    }
    final filtered = <String, Object?>{};
    for (final column in plan.selects) {
      if (row.containsKey(column)) {
        filtered[column] = row[column];
      }
    }
    for (final raw in plan.rawSelects) {
      final alias = raw.alias;
      if (alias != null && row.containsKey(alias)) {
        filtered[alias] = row[alias];
      }
    }
    for (final aggregate in plan.aggregates) {
      final alias = aggregate.alias;
      if (alias != null && row.containsKey(alias)) {
        filtered[alias] = row[alias];
      }
    }
    for (final clause in plan.distinctOn) {
      if (row.containsKey(clause.field)) {
        filtered[clause.field] = row[clause.field];
      }
    }
    if (filtered.isEmpty) {
      return Map<String, Object?>.from(row);
    }
    return filtered;
  }

  /// Exposes the built plan for tests.
  @visibleForTesting
  QueryPlan debugPlan() => _buildPlan();

  QueryPlan _buildPlan() {
    if (!_globalScopesApplied) {
      final scoped = context.scopeRegistry.applyGlobalScopes(this);
      if (!identical(scoped, this)) {
        return scoped._buildPlan();
      }
    }
    final relationJoinEntries = _relationPaths.entries
        .map((entry) {
          final edges = <RelationJoinEdge>[];
          var parentAlias = 'base';
          final aliasBase = entry.key.replaceAll('.', '_');
          final segments = entry.value.segments;
          for (var i = 0; i < segments.length; i++) {
            final segment = segments[i];
            final alias = 'rel_${aliasBase}_$i';
            final pivotAlias = segment.usesPivot
                ? 'pivot_${aliasBase}_$i'
                : null;
            edges.add(
              RelationJoinEdge(
                segment: segment,
                parentAlias: parentAlias,
                alias: alias,
                pivotAlias: pivotAlias,
              ),
            );
            parentAlias = alias;
          }
          return RelationJoin(pathKey: entry.key, edges: edges);
        })
        .toList(growable: false);
    final relationJoinClauses = _relationJoinRequests.isEmpty
        ? const <JoinDefinition>[]
        : _buildRelationJoinClauses(relationJoinEntries);

    return QueryPlan(
      definition: definition,
      driverName: context.driver.metadata.name,
      filters: _filters,
      orders: _orders,
      randomOrder: _randomOrder,
      randomSeed: _randomSeed,
      limit: _limit,
      offset: _offset,
      relations: _relations,
      indexHints: _indexHints,
      fullTextWheres: _fullTextWheres,
      jsonWheres: _jsonWheres,
      dateWheres: _dateWheres,
      predicate: _predicate,
      selects: _selects,
      rawSelects: _rawSelects,
      projectionOrder: _projectionOrder,
      aggregates: _aggregates,
      groupBy: _groupBy,
      having: _having,
      relationAggregates: _relationAggregates,
      relationOrders: _relationOrders,
      relationJoins: relationJoinEntries,
      joins: [..._joins, ...relationJoinClauses],
      tableAlias: _tableAlias,
      lockClause: _lockClause,
      groupLimit: _groupLimit,
      distinct: _distinct,
      distinctOn: _distinctOn,
      unions: _unions,
    );
  }

  List<JoinDefinition> _buildRelationJoinClauses(List<RelationJoin> joins) {
    if (_relationJoinRequests.isEmpty) {
      return const <JoinDefinition>[];
    }
    final lookup = <String, RelationJoin>{
      for (final join in joins) join.pathKey: join,
    };
    final definitions = <JoinDefinition>[];
    _relationJoinRequests.forEach((path, request) {
      final relation = lookup[path];
      if (relation == null) {
        return;
      }
      definitions.addAll(
        _joinDefinitionsForRelation(relation, request.joinType),
      );
    });
    return definitions;
  }

  List<JoinDefinition> _joinDefinitionsForRelation(
    RelationJoin relation,
    JoinType joinType,
  ) {
    final definitions = <JoinDefinition>[];
    for (final edge in relation.edges) {
      final segment = edge.segment;
      if (segment.usesPivot) {
        final pivotAlias = edge.pivotAlias;
        if (pivotAlias == null) {
          continue;
        }
        definitions.add(
          JoinDefinition(
            type: joinType,
            target: JoinTarget.table(segment.pivotTable!),
            alias: pivotAlias,
            conditions: [
              JoinCondition.column(
                left: '$pivotAlias.${segment.pivotParentKey!}',
                operator: '=',
                right: '${edge.parentAlias}.${segment.parentKey}',
              ),
            ],
          ),
        );
        final childConditions = <JoinCondition>[
          JoinCondition.column(
            left: '${edge.alias}.${segment.childKey}',
            operator: '=',
            right: '$pivotAlias.${segment.pivotRelatedKey!}',
          ),
        ];
        if (segment.usesMorph) {
          childConditions.add(
            JoinCondition.value(
              left: '${edge.alias}.${segment.morphTypeColumn!}',
              operator: '=',
              value: segment.morphClass,
            ),
          );
        }
        definitions.add(
          JoinDefinition(
            type: joinType,
            target: JoinTarget.table(
              _qualifiedRelationTableName(segment.targetDefinition),
            ),
            alias: edge.alias,
            conditions: childConditions,
          ),
        );
        continue;
      }

      final parentColumn = '${edge.parentAlias}.${segment.parentKey}';
      final childColumn = '${edge.alias}.${segment.childKey}';
      final comparison = segment.foreignKeyOnParent
          ? JoinCondition.column(
              left: parentColumn,
              operator: '=',
              right: childColumn,
            )
          : JoinCondition.column(
              left: childColumn,
              operator: '=',
              right: parentColumn,
            );
      final conditions = <JoinCondition>[comparison];
      if (segment.usesMorph) {
        conditions.add(
          JoinCondition.value(
            left: '${edge.alias}.${segment.morphTypeColumn!}',
            operator: '=',
            value: segment.morphClass,
          ),
        );
      }
      definitions.add(
        JoinDefinition(
          type: joinType,
          target: JoinTarget.table(
            _qualifiedRelationTableName(segment.targetDefinition),
          ),
          alias: edge.alias,
          conditions: conditions,
        ),
      );
    }
    return definitions;
  }

  String _qualifiedRelationTableName(ModelDefinition<dynamic> definition) {
    final schema = definition.schema;
    if (schema == null || schema.isEmpty) {
      return definition.tableName;
    }
    return '$schema.${definition.tableName}';
  }

  Query<T> _copyForAggregation() => _copyWith(
    limit: null,
    offset: null,
    orders: const <OrderClause>[],
    aggregates: const <AggregateExpression>[],
    selects: const <String>[],
    rawSelects: const <RawSelectExpression>[],
    projectionOrder: const <ProjectionOrderEntry>[],
    relationAggregates: const <RelationAggregate>[],
    relationOrders: const <RelationOrder>[],
  );

  static int _aggregateAliasCounter = 0;

  String _aggregateAlias(String base) =>
      '__orm_${base}_${_aggregateAliasCounter++}';

  Future<int> _countTotalRows() async {
    const alias = '_aggregate_count';
    final countQuery = _copyForAggregation().withAggregate(
      AggregateFunction.count,
      '*',
      alias: alias,
    );
    final plan = countQuery._buildPlan();
    final rows = await context.runSelect(plan);
    if (rows.isEmpty) {
      return 0;
    }
    final value = rows.first[alias];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value == null) {
      return rows.length;
    }
    return 0;
  }

  String _resolveCursorColumn(String? column) {
    if (column != null && column.isNotEmpty) {
      return _ensureField(column).columnName;
    }
    final pk = definition.primaryKeyField?.columnName;
    if (pk == null) {
      throw StateError(
        'Model ${definition.modelName} does not define a primary key.',
      );
    }
    return pk;
  }

  FieldDefinition? get _softDeleteField => definition.softDeleteField;

  FieldDefinition _requireSoftDeleteSupport(String method) {
    final field = _softDeleteField;
    if (field == null) {
      throw StateError(
        '$method requires ${definition.modelName} to enable soft deletes.',
      );
    }
    return field;
  }

  _UpdatePayload _normalizeUpdateValues(Map<String, Object?> input) {
    final mapped = <String, Object?>{};
    final jsonUpdates = <JsonUpdateClause>[];
    input.forEach((key, value) {
      final selector = json_path.parseJsonSelectorExpression(key);
      if (selector != null) {
        final field = _ensureField(selector.column);
        jsonUpdates.add(
          JsonUpdateClause(
            column: field.columnName,
            path: selector.path,
            value: value,
          ),
        );
        return;
      }
      final field = _ensureField(key);
      final encoded = context.codecRegistry.encodeField(field, value);
      mapped[field.columnName] = encoded;
    });
    return _UpdatePayload(mapped, jsonUpdates);
  }

  List<String> _normalizeInsertColumns(Iterable<String> columns) {
    final normalized = <String>[];
    for (final column in columns) {
      final field = _ensureField(column);
      normalized.add(field.columnName);
    }
    return normalized;
  }

  void _ensureSharedContext(Query<dynamic> source, String method) {
    if (!identical(source.context, context)) {
      throw StateError(
        '$method requires the source query to share the same QueryContext.',
      );
    }
  }

  Future<List<Map<String, Object?>>> _collectPrimaryKeyConditions(
    Query<T> target,
  ) async {
    final pkField = definition.primaryKeyField;
    if (pkField == null) {
      throw StateError(
        'Model ${definition.modelName} does not define a primary key.',
      );
    }
    final scoped = target.select([pkField.name]);
    final plan = scoped._buildPlan();
    final rawRows = await scoped.context.runSelect(plan);
    final keys = <Map<String, Object?>>[];
    for (final row in rawRows) {
      final value = row[pkField.columnName];
      if (value != null) {
        keys.add({pkField.columnName: value});
      }
    }
    return keys;
  }

  Query<T> _applySoftDeleteFilter(FieldDefinition field) {
    final predicate = FieldPredicate(
      field: field.columnName,
      operator: PredicateOperator.isNull,
    );
    final updated = _appendPredicate(predicate, PredicateLogicalOperator.and);
    return updated._withFilter(
      FilterClause(
        field: field.columnName,
        operator: FilterOperator.equals,
        value: null,
        compile: false,
      ),
    );
  }

  /// Removes a global scope by [identifier] from the query.
  ///
  /// This allows you to temporarily disable a global scope that would otherwise
  /// be applied to all queries of this model type.
  ///
  /// Example:
  /// ```dart
  /// // Get all users, including soft-deleted ones
  /// final allUsers = await context.query<User>()
  ///   .withoutGlobalScope(ScopeRegistry.softDeleteScopeIdentifier)
  ///   .get();
  /// ```
  Query<T> withoutGlobalScope(String identifier) {
    final updated = {..._ignoredGlobalScopes, identifier};
    return _copyWith(ignoredScopes: updated, globalScopesApplied: false);
  }

  /// Removes multiple global scopes or all global scopes from the query.
  ///
  /// If [identifiers] is `null`, all global scopes will be ignored.
  /// Otherwise, only the global scopes with the specified identifiers will be ignored.
  ///
  /// Example:
  /// ```dart
  /// // Get all users, ignoring all global scopes
  /// final allUsers = await context.query<User>()
  ///   .withoutGlobalScopes()
  ///   .get();
  ///
  /// // Ignore specific global scopes
  /// final users = await context.query<User>()
  ///   .withoutGlobalScopes(['scope1', 'scope2'])
  ///   .get();
  /// ```
  Query<T> withoutGlobalScopes([List<String>? identifiers]) {
    if (identifiers == null) {
      return _copyWith(ignoreAllGlobalScopes: true, globalScopesApplied: false);
    }
    final updated = {..._ignoredGlobalScopes, ...identifiers};
    return _copyWith(ignoredScopes: updated, globalScopesApplied: false);
  }

  /// Applies a named local scope to the query.
  ///
  /// Local scopes are reusable query constraints defined on the model.
  ///
  /// [name] is the name of the local scope.
  /// [args] are optional arguments to pass to the local scope.
  ///
  /// Example:
  /// ```dart
  /// // Assuming a local scope 'active' is defined on User model
  /// final activeUsers = await context.query<User>()
  ///   .scope('active')
  ///   .get();
  ///
  /// // With arguments
  /// final usersByRole = await context.query<User>()
  ///   .scope('byRole', ['admin'])
  ///   .get();
  /// ```
  Query<T> scope(String name, [List<Object?> args = const []]) => context
      .scopeRegistry
      .callLocalScope(definition.modelType, name, this, args);

  /// Calls a registered query macro.
  ///
  /// Macros provide a way to extend the query builder with custom, reusable logic.
  ///
  /// [name] is the name of the macro.
  /// [args] are optional arguments to pass to the macro.
  ///
  /// Example:
  /// ```dart
  /// // Assuming a macro 'recent' is defined
  /// final recentPosts = await context.query<Post>()
  ///   .macro('recent', [Duration(days: 7)])
  ///   .get();
  /// ```
  Query<T> macro(String name, [List<Object?> args = const []]) =>
      context.scopeRegistry.callMacro(name, this, args);

  /// Limits the number of rows returned per group.
  ///
  /// This is useful for "top N per group" queries.
  ///
  /// [limit] is the maximum number of rows to return for each group.
  /// [column] is the column used for grouping.
  /// [offset] is an optional offset within each group.
  ///
  /// Example:
  /// ```dart
  /// // Get the 3 latest posts for each user
  /// final latestPostsPerUser = await context.query<Post>()
  ///   .orderBy('createdAt', descending: true)
  ///   .limitPerGroup(3, 'userId')
  ///   .get();
  /// ```
  Query<T> limitPerGroup(int limit, String column, {int? offset}) {
    if (limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'Must be greater than zero');
    }
    if (offset != null && offset < 0) {
      throw ArgumentError.value(offset, 'offset', 'Must be non-negative');
    }
    final resolved = _resolveGroupLimitColumn(column);
    final next = GroupLimit(column: resolved, limit: limit, offset: offset);
    return _copyWith(groupLimit: next);
  }

  /// Applies ad-hoc table scopes to the query.
  ///
  /// This is typically used internally or for dynamic table-specific scopes.
  Query<T> withTableScopes(List<String> scopes) => _copyWith(
    adHocScopes: [..._adHocScopes, ...scopes],
    globalScopesApplied: false,
  );

  /// Sets an alias for the main table in the query.
  ///
  /// Example:
  /// ```dart
  /// final aliasedUsers = await context.query<User>()
  ///   .withAlias('u')
  ///   .where('u.isActive', true)
  ///   .get();
  /// ```
  Query<T> withAlias(String alias) => _copyWith(tableAlias: alias);

  /// Includes soft-deleted models in the query results.
  ///
  /// This method effectively disables the soft-delete global scope if it's applied.
  ///
  /// Example:
  /// ```dart
  /// final allUsers = await context.query<User>()
  ///   .withTrashed()
  ///   .get();
  /// ```
  Query<T> withTrashed() {
    if (_softDeleteField == null) {
      return this;
    }
    return withoutGlobalScope(_softDeleteScope);
  }

  /// Retrieves only soft-deleted models.
  ///
  /// This method applies a condition to only select models where the soft-delete
  /// field is not null.
  ///
  /// Example:
  /// ```dart
  /// final deletedUsers = await context.query<User>()
  ///   .onlyTrashed()
  ///   .get();
  /// ```
  Query<T> onlyTrashed() {
    final field = _softDeleteField;
    if (field == null) {
      return this;
    }
    return withTrashed().whereNotNull(field.name);
  }

  /// Restores soft-deleted models that match the current query constraints.
  ///
  /// This sets the soft-delete field back to null.
  /// Throws [StateError] if the model does not support soft deletes.
  ///
  /// Example:
  /// ```dart
  /// final restoredCount = await context.query<User>()
  ///   .where('id', 1)
  ///   .restore();
  /// print('Restored $restoredCount users.');
  /// ```
  Future<int> restore() async {
    final field = _requireSoftDeleteSupport('restore');
    final keys = await _collectPrimaryKeyConditions(onlyTrashed());
    if (keys.isEmpty) {
      return 0;
    }
    final rows = keys
        .map((key) => MutationRow(values: {field.columnName: null}, keys: key))
        .toList(growable: false);
    final plan = MutationPlan.update(
      definition: definition,
      rows: rows,
      driverName: context.driver.metadata.name,
    );
    final result = await context.runMutation(plan);
    return result.affectedRows;
  }

  /// Permanently deletes models that match the current query constraints,
  /// bypassing soft deletes.
  ///
  /// Throws [StateError] if the model does not define a primary key or
  /// the driver does not expose a row identifier for query updates.
  ///
  /// Example:
  /// ```dart
  /// final deletedCount = await context.query<User>()
  ///   .where('status', 'inactive')
  ///   .forceDelete();
  /// print('Force deleted $deletedCount inactive users.');
  /// ```
  Future<int> forceDelete() async {
    if (_supportsQueryDeletes) {
      final target = withTrashed();
      final driverMetadata = context.driver.metadata;
      final pk = definition.primaryKeyField;
      final fallbackIdentifier = driverMetadata.queryUpdateRowIdentifier;
      final identifier = pk?.columnName ?? fallbackIdentifier?.column;
      if (identifier == null) {
        throw StateError(
          'forceDelete requires ${definition.modelName} to declare a primary key or expose a driver row identifier.',
        );
      }
      final selection = pk != null ? target.select([pk.name]) : target;
      final plan = MutationPlan.queryDelete(
        definition: definition,
        plan: selection._buildPlan(),
        primaryKey: identifier,
        driverName: driverMetadata.name,
      );
      final result = await context.runMutation(plan);
      return result.affectedRows;
    }
    return _forceDeleteByKeys();
  }

  Future<int> _forceDeleteByKeys() async {
    final keys = await _collectPrimaryKeyConditions(withTrashed());
    if (keys.isEmpty) {
      return 0;
    }
    final rows = keys
        .map((key) => MutationRow(values: const {}, keys: key))
        .toList(growable: false);
    final plan = MutationPlan.delete(
      definition: definition,
      rows: rows,
      driverName: context.driver.metadata.name,
    );
    final result = await context.runMutation(plan);
    return result.affectedRows;
  }

  bool get _supportsQueryDeletes =>
      context.driver.metadata.supportsQueryDeletes;

  /// Adds a `UNION` clause combining the current query with [query].
  ///
  /// The `UNION` operator combines the result sets of two or more `SELECT` statements
  /// and removes duplicate rows.
  ///
  /// Example:
  /// ```dart
  /// final activeAndAdminUsers = await context.query<User>()
  ///   .where('isActive', true)
  ///   .union(context.query<User>().where('role', 'admin'))
  ///   .get();
  /// ```
  Query<T> union(Query<dynamic> query) => _addUnion(query, all: false);

  /// Adds a `UNION ALL` clause combining the current query with [query].
  ///
  /// The `UNION ALL` operator combines the result sets of two or more `SELECT` statements
  /// and includes duplicate rows.
  ///
  /// Example:
  /// ```dart
  /// final allUsersIncludingDuplicates = await context.query<User>()
  ///   .where('isActive', true)
  ///   .unionAll(context.query<User>().where('role', 'admin'))
  ///   .get();
  /// ```
  Query<T> unionAll(Query<dynamic> query) => _addUnion(query, all: true);

  /// Inserts rows into this query's table using the results of [source]. The
  /// [columns] list must contain one entry per value selected by [source].
  ///
  /// This method allows for efficient bulk insertion of data from another query.
  ///
  /// [columns] are the target columns for insertion.
  /// [source] is the query whose results will be inserted.
  /// [ignoreConflicts] (defaults to `false`) whether to ignore duplicate key errors.
  ///
  /// Example:
  /// ```dart
  /// // Insert archived posts into a new 'old_posts' table
  /// final insertedCount = await context.query<OldPost>()
  ///   .insertUsing(
  ///     ['title', 'body'],
  ///     context.query<Post>().where('isArchived', true).select(['title', 'body']),
  ///   );
  /// print('Inserted $insertedCount old posts.');
  /// ```
  Future<int> insertUsing(
    Iterable<String> columns,
    Query<dynamic> source, {
    bool ignoreConflicts = false,
  }) async {
    _ensureSupportsCapability(
      DriverCapability.insertUsing,
      context.driver.metadata.name,
      'insertUsing',
    );
    final resolved = _normalizeInsertColumns(columns);
    if (resolved.isEmpty) {
      throw ArgumentError.value(columns, 'columns', 'At least one column');
    }
    _ensureSharedContext(source, 'insertUsing');
    final selectPlan = source._buildPlan();
    final mutation = MutationPlan.insertUsing(
      definition: definition,
      columns: resolved,
      selectPlan: selectPlan,
      ignoreConflicts: ignoreConflicts,
      driverName: context.driver.metadata.name,
    );
    final result = await context.runMutation(mutation);
    return result.affectedRows;
  }

  /// Convenience wrapper that suppresses duplicate-key errors during
  /// [insertUsing] by adding dialect-specific conflict clauses.
  ///
  /// This is equivalent to calling [insertUsing] with `ignoreConflicts: true`.
  Future<int> insertOrIgnoreUsing(
    Iterable<String> columns,
    Query<dynamic> source,
  ) => insertUsing(columns, source, ignoreConflicts: true);

  /// Updates rows that match the current query constraints.
  ///
  /// [values] is a map where keys are column names and values are the new values.
  ///
  /// Example:
  /// ```dart
  /// final updatedCount = await context.query<User>()
  ///   .where('id', 1)
  ///   .update({'name': 'New Name', 'email': 'new@example.com'});
  /// print('Updated $updatedCount users.');
  /// ```
  Future<int> update(Map<String, Object?> values) async {
    if (values.isEmpty) {
      return 0;
    }
    final payload = _normalizeUpdateValues(values);
    if (payload.isEmpty) {
      return 0;
    }
    final mutation = _buildQueryUpdateMutation(
      values: payload.values,
      jsonUpdates: payload.jsonUpdates,
      feature: 'update',
    );
    final result = await context.runMutation(mutation);
    return result.affectedRows;
  }

  /// Increments the value of a numeric [column] by [amount].
  ///
  /// [amount] defaults to 1.
  /// Throws [StateError] if the driver does not support increment operations.
  ///
  /// Example:
  /// ```dart
  /// final updatedCount = await context.query<Product>()
  ///   .where('id', 1)
  ///   .increment('stock', 5);
  /// print('Incremented stock for $updatedCount products.');
  /// ```
  Future<int> increment(String column, [num amount = 1]) {
    return _applyIncrement(column, amount, 'increment');
  }

  /// Decrements the value of a numeric [column] by [amount].
  ///
  /// [amount] defaults to 1.
  /// Throws [StateError] if the driver does not support decrement operations.
  ///
  /// Example:
  /// ```dart
  /// final updatedCount = await context.query<Product>()
  ///   .where('id', 1)
  ///   .decrement('stock', 2);
  /// print('Decremented stock for $updatedCount products.');
  /// ```
  Future<int> decrement(String column, [num amount = 1]) {
    return _applyIncrement(column, -amount.abs(), 'decrement');
  }

  Future<int> _applyIncrement(String column, num amount, String feature) async {
    if (amount == 0) {
      return 0;
    }
    final metadata = context.driver.metadata;
    _ensureSupportsCapability(
      DriverCapability.increment,
      metadata.name,
      feature,
    );
    final field = _ensureField(column).columnName;
    final mutation = _buildQueryUpdateMutation(
      queryIncrementValues: {field: amount},
      feature: feature,
    );
    final result = await context.runMutation(mutation);
    return result.affectedRows;
  }

  MutationPlan _buildQueryUpdateMutation({
    Map<String, Object?> values = const {},
    List<JsonUpdateClause> jsonUpdates = const [],
    Map<String, num> queryIncrementValues = const {},
    String feature = 'update',
  }) {
    final pkField = definition.primaryKeyField;
    final metadata = context.driver.metadata;
    final fallbackIdentifier = metadata.queryUpdateRowIdentifier?.column;
    final requiresPk = metadata.requiresPrimaryKeyForQueryUpdate;
    final identifier = pkField?.columnName ?? fallbackIdentifier;
    if (identifier == null && requiresPk) {
      throw StateError(
        '$feature requires ${definition.modelName} to declare a primary key.',
      );
    }
    final plan = _buildPlan();
    final primarySelect = _buildPrimarySelectionPlan(plan, pkField);
    return MutationPlan.queryUpdate(
      definition: definition,
      plan: primarySelect,
      values: values,
      jsonUpdates: jsonUpdates,
      driverName: metadata.name,
      primaryKey: identifier,
      queryIncrementValues: queryIncrementValues,
    );
  }

  QueryPlan _buildPrimarySelectionPlan(
    QueryPlan plan,
    FieldDefinition? pkField,
  ) {
    if (pkField != null) {
      return plan.copyWith(
        selects: [pkField.columnName],
        rawSelects: const [],
        aggregates: const [],
        projectionOrder: const [ProjectionOrderEntry.column(0)],
      );
    }
    return plan.copyWith(
      selects: const <String>[],
      rawSelects: const <RawSelectExpression>[],
      aggregates: const [],
      projectionOrder: const <ProjectionOrderEntry>[],
    );
  }

  bool get globalScopesApplied => _globalScopesApplied;

  bool get ignoreAllGlobalScopes => _ignoreAllGlobalScopes;

  Set<String> get ignoredGlobalScopes => _ignoredGlobalScopes;

  List<String> get adHocScopes => _adHocScopes;

  Query<T> markGlobalScopesApplied() => _copyWith(globalScopesApplied: true);

  /// Applies DISTINCT (and optional DISTINCT ON) semantics to the select.
  ///
  /// [columns] are optional columns to apply `DISTINCT ON` to (PostgreSQL specific).
  /// If no columns are provided, a simple `SELECT DISTINCT` is used.
  ///
  /// Examples:
  /// ```dart
  /// // Select distinct user names
  /// final distinctNames = await context.query<User>()
  ///   .distinct()
  ///   .select(['name'])
  ///   .pluck<String>('name');
  ///
  /// // Select distinct on specific columns (PostgreSQL)
  /// final distinctUsers = await context.query<User>()
  ///   .distinct(['firstName', 'lastName'])
  ///   .get();
  /// ```
  Query<T> distinct([Iterable<String> columns = const []]) {
    final normalized = _normalizeDistinctColumns(columns);
    return _copyWith(distinct: true, distinctOn: normalized);
  }

  /// Removes any previously applied DISTINCT state.
  ///
  /// Example:
  /// ```dart
  /// final allUsers = await context.query<User>()
  ///   .distinct()
  ///   .withoutDistinct()
  ///   .get();
  /// ```
  Query<T> withoutDistinct() =>
      _copyWith(distinct: false, distinctOn: const <DistinctOnClause>[]);

  Query<T> _copyWith({
    List<FilterClause>? filters,
    List<OrderClause>? orders,
    List<RelationLoad>? relations,
    List<JoinDefinition>? joins,
    List<IndexHint>? indexHints,
    List<FullTextWhere>? fullTextWheres,
    List<JsonWhereClause>? jsonWheres,
    List<DateWhereClause>? dateWheres,
    bool? randomOrder,
    Object? randomSeed = _unset,
    String? lockClause,
    int? limit,
    int? offset,
    QueryPredicate? predicate,
    List<String>? selects,
    List<RawSelectExpression>? rawSelects,
    List<ProjectionOrderEntry>? projectionOrder,
    List<AggregateExpression>? aggregates,
    List<String>? groupBy,
    QueryPredicate? having,
    List<RelationAggregate>? relationAggregates,
    List<RelationOrder>? relationOrders,
    Map<String, RelationPath>? relationPaths,
    Map<String, _RelationJoinRequest>? relationJoinRequests,
    Set<String>? ignoredScopes,
    bool? globalScopesApplied,
    bool? ignoreAllGlobalScopes,
    String? tableAlias,
    List<String>? adHocScopes,
    GroupLimit? groupLimit,
    bool? distinct,
    List<DistinctOnClause>? distinctOn,
    List<QueryUnion>? unions,
  }) => Query._(
    definition: definition,
    context: context,
    filters: filters ?? _filters,
    orders: orders ?? _orders,
    relations: relations ?? _relations,
    joins: joins ?? _joins,
    indexHints: indexHints ?? _indexHints,
    fullTextWheres: fullTextWheres ?? _fullTextWheres,
    jsonWheres: jsonWheres ?? _jsonWheres,
    dateWheres: dateWheres ?? _dateWheres,
    randomOrder: randomOrder ?? _randomOrder,
    randomSeed: identical(randomSeed, _unset)
        ? _randomSeed
        : randomSeed as num?,
    lockClause: lockClause ?? _lockClause,
    limit: limit ?? _limit,
    offset: offset ?? _offset,
    predicate: predicate ?? _predicate,
    selects: selects ?? _selects,
    rawSelects: rawSelects ?? _rawSelects,
    projectionOrder: projectionOrder ?? _projectionOrder,
    aggregates: aggregates ?? _aggregates,
    groupBy: groupBy ?? _groupBy,
    having: having ?? _having,
    relationAggregates: relationAggregates ?? _relationAggregates,
    relationOrders: relationOrders ?? _relationOrders,
    relationPaths: relationPaths ?? _relationPaths,
    relationJoinRequests: relationJoinRequests ?? _relationJoinRequests,
    ignoredScopes: ignoredScopes ?? _ignoredGlobalScopes,
    globalScopesApplied: globalScopesApplied ?? _globalScopesApplied,
    ignoreAllGlobalScopes: ignoreAllGlobalScopes ?? _ignoreAllGlobalScopes,
    tableAlias: tableAlias ?? _tableAlias,
    adHocScopes: adHocScopes ?? _adHocScopes,
    groupLimit: groupLimit ?? _groupLimit,
    distinct: distinct ?? _distinct,
    distinctOn: distinctOn ?? _distinctOn,
    unions: unions ?? _unions,
  );

  Query<T> _join({
    required JoinTarget target,
    required JoinType type,
    Object? constraint,
    Object? operator,
    Object? second,
    bool whereComparison = false,
    bool lateral = false,
    String? alias,
  }) {
    _ensureSupportsCapability(
      DriverCapability.joins,
      '${context.driver.metadata.name} driver',
      'join operations',
    );
    var conditions = <JoinCondition>[];
    if (constraint != null) {
      conditions = _buildJoinConditions(
        constraint,
        operator,
        second,
        whereComparison: whereComparison,
      );
    }
    if (conditions.isEmpty && lateral) {
      conditions = const [JoinCondition.raw(rawSql: 'TRUE')];
    }
    if (conditions.isEmpty && type != JoinType.cross && !lateral) {
      throw ArgumentError(
        'Join clauses require a constraint unless using cross joins.',
      );
    }
    return _copyWith(
      joins: [
        ..._joins,
        JoinDefinition(
          type: type,
          target: target,
          alias: alias,
          conditions: conditions,
          isLateral: lateral,
        ),
      ],
    );
  }

  void _ensureSupportsCapability(
    DriverCapability capability,
    String driverName,
    String feature,
  ) {
    final metadata = context.driver.metadata;
    if (!metadata.supportsCapability(capability)) {
      throw UnsupportedError(
        '$driverName does not support $feature (${capability.name}).',
      );
    }
  }

  Query<T> _addIndexHint(IndexHint hint) =>
      _copyWith(indexHints: [..._indexHints, hint]);

  Query<T> _addUnion(Query<dynamic> query, {required bool all}) {
    _ensureSharedContext(query, 'union');
    final clause = QueryUnion(plan: query._buildPlan(), all: all);
    return _copyWith(unions: [..._unions, clause]);
  }

  List<JoinCondition> _buildJoinConditions(
    Object constraint,
    Object? operator,
    Object? second, {
    required bool whereComparison,
  }) {
    if (constraint is JoinConstraintBuilder) {
      final builder = JoinBuilder._();
      constraint(builder);
      final built = builder._conditions;
      if (built.isEmpty) {
        throw ArgumentError('Join callbacks must add at least one clause.');
      }
      return List<JoinCondition>.unmodifiable(built);
    }
    if (constraint is! String) {
      throw ArgumentError.value(
        constraint,
        'constraint',
        'Expected a column name or callback.',
      );
    }
    if (operator == null || second == null) {
      throw ArgumentError(
        'Join clauses require both an operator and comparison target.',
      );
    }
    final op = _normalizeJoinOperatorToken(operator);
    if (whereComparison) {
      return [
        JoinCondition.value(left: constraint, operator: op, value: second),
      ];
    }
    if (second is! String) {
      throw ArgumentError.value(
        second,
        'second',
        'Column joins require another column reference.',
      );
    }
    return [
      JoinCondition.column(left: constraint, operator: op, right: second),
    ];
  }

  JoinTarget _resolveJoinTarget(Object table) {
    if (table is JoinTarget) {
      return table;
    }
    if (table is String) {
      return JoinTarget.table(table);
    }
    throw ArgumentError.value(table, 'table', 'Unsupported join target.');
  }

  void _assertSubqueryAlias(String alias) {
    if (alias.isEmpty) {
      throw ArgumentError.value(alias, 'alias', 'Alias cannot be empty.');
    }
  }

  JoinTarget _subqueryTarget(Query<dynamic> query) {
    final baseDriver = context.driver.metadata.name;
    final otherDriver = query.context.driver.metadata.name;
    if (baseDriver != otherDriver) {
      throw ArgumentError(
        'Subquery joins require both builders to share the same driver. '
        'Expected $baseDriver but received $otherDriver.',
      );
    }
    final plan = query._buildPlan();
    final preview = query.context.describeQuery(plan);
    if (preview.sql == '<unavailable>' || preview.sql.isEmpty) {
      throw StateError('Unable to produce SQL for the provided subquery.');
    }
    return JoinTarget.subquery(preview.sql, bindings: preview.parameters);
  }

  FilterClause _buildFieldFilter(
    String field,
    FilterOperator op,
    Object? value,
  ) {
    final definition = _ensureField(field);
    return FilterClause(
      field: definition.columnName,
      operator: op,
      value: value,
      compile: false,
    );
  }

  _ResolvedField _resolvePredicateField(String field) {
    if (json_path.hasJsonSelector(field)) {
      final selector = json_path.parseJsonSelectorExpression(field);
      if (selector == null) {
        throw ArgumentError.value(field, 'field', 'Invalid JSON selector.');
      }
      final definition = _ensureField(selector.column);
      final column = definition.columnName;
      final normalized = json_path.JsonSelector(
        column,
        selector.path,
        selector.extractsText,
      );
      return _ResolvedField(column: column, jsonSelector: normalized);
    }
    final column = _ensureField(field).columnName;
    return _ResolvedField(column: column);
  }

  bool _shouldTreatAsJsonBoolean(
    json_path.JsonSelector? selector,
    PredicateOperator operator,
    Object? value,
  ) {
    if (selector == null || selector.extractsText || value is! bool) {
      return false;
    }
    return operator == PredicateOperator.equals ||
        operator == PredicateOperator.notEquals;
  }

  FieldDefinition _ensureField(String name) {
    final field = definition.fields.firstWhereOrNull(
      (f) => f.name == name || f.columnName == name,
    );
    if (field != null) {
      return field;
    }
    if (definition is AdHocModelDefinition) {
      return (definition as AdHocModelDefinition).fieldFor(name);
    }
    throw ArgumentError.value(
      name,
      'field',
      'Unknown field on ${definition.modelName}.',
    );
  }

  _JsonPathReference _resolveJsonReference(
    String input, {
    String? overridePath,
  }) {
    final trimmedOverride = overridePath?.trim();
    if (trimmedOverride != null && trimmedOverride.isNotEmpty) {
      final base = _baseJsonField(input);
      final column = _ensureField(base).columnName;
      final normalized = json_path.normalizeJsonPath(trimmedOverride);
      return _JsonPathReference(column: column, path: normalized);
    }
    final selector = json_path.parseJsonSelectorExpression(input);
    if (selector != null) {
      final column = _ensureField(selector.column).columnName;
      return _JsonPathReference(column: column, path: selector.path);
    }
    final base = _baseJsonField(input);
    final column = _ensureField(base).columnName;
    return _JsonPathReference(column: column, path: r'$');
  }

  String _baseJsonField(String input) {
    final index = input.indexOf('->');
    if (index == -1) {
      return input;
    }
    return input.substring(0, index);
  }

  String _resolveGroupLimitColumn(String input) {
    final field = definition.fields.firstWhereOrNull(
      (f) => f.name == input || f.columnName == input,
    );
    if (field != null) {
      return field.columnName;
    }
    return input;
  }

  String _normalizeLengthOperator(String operator) =>
      _normalizeComparisonOperator(operator, context: 'JSON length comparison');

  String _normalizeComparisonOperator(String operator, {String? context}) {
    final normalized = operator.trim();
    const allowed = {'=', '!=', '<>', '>', '>=', '<', '<='};
    if (!allowed.contains(normalized)) {
      final label = context ?? 'comparison';
      throw ArgumentError.value(
        operator,
        'operator',
        'Unsupported $label operator. Allowed: ${allowed.join(', ')}.',
      );
    }
    return normalized;
  }

  Query<T> _appendDatePredicate(
    String field,
    DateComponent component,
    Object operatorOrValue, [
    Object? comparisonValue,
  ]) {
    final parsed = _normalizeDatePredicateInput(
      operatorOrValue,
      comparisonValue,
    );
    final normalizedValue = _normalizeDatePredicateValue(
      component,
      parsed.value,
    );
    final reference = _resolveJsonReference(field);
    final clause = DateWhereClause(
      column: reference.column,
      path: reference.path,
      component: component,
      operator: parsed.operator,
      value: normalizedValue,
    );
    return _copyWith(dateWheres: [..._dateWheres, clause]);
  }

  _DatePredicateInput _normalizeDatePredicateInput(
    Object operatorOrValue,
    Object? comparisonValue,
  ) {
    if (comparisonValue == null) {
      return _DatePredicateInput(operator: '=', value: operatorOrValue);
    }
    if (operatorOrValue is! String) {
      throw ArgumentError(
        'Date predicates that specify two arguments must provide a string operator as the first argument.',
      );
    }
    final operator = _normalizeComparisonOperator(
      operatorOrValue,
      context: 'date predicate',
    );
    return _DatePredicateInput(operator: operator, value: comparisonValue);
  }

  Object _normalizeDatePredicateValue(DateComponent component, Object value) {
    if (value is DateTime) {
      switch (component) {
        case DateComponent.date:
          return _formatDate(value);
        case DateComponent.time:
          return _formatTime(value);
        case DateComponent.day:
          return value.day;
        case DateComponent.month:
          return value.month;
        case DateComponent.year:
          return value.year;
      }
    }
    switch (component) {
      case DateComponent.date:
        return _coerceDateString(value);
      case DateComponent.time:
        return _coerceTimeString(value);
      case DateComponent.day:
        return _coerceIntComponent(value, 'day', min: 1, max: 31);
      case DateComponent.month:
        return _coerceIntComponent(value, 'month', min: 1, max: 12);
      case DateComponent.year:
        return _coerceIntComponent(value, 'year');
    }
  }

  String _coerceDateString(Object value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    throw ArgumentError.value(
      value,
      'value',
      'Expected a DateTime or ISO 8601 date string.',
    );
  }

  String _coerceTimeString(Object value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    throw ArgumentError.value(
      value,
      'value',
      'Expected a DateTime or HH:mm:ss string.',
    );
  }

  int _coerceIntComponent(
    Object value,
    String component, {
    int? min,
    int? max,
  }) {
    final int? parsed;
    if (value is int) {
      parsed = value;
    } else if (value is num && value % 1 == 0) {
      parsed = value.toInt();
    } else if (value is String) {
      parsed = int.tryParse(value.trim());
    } else {
      parsed = null;
    }
    if (parsed == null) {
      throw ArgumentError.value(
        value,
        'value',
        '$component component must be numeric.',
      );
    }
    if (min != null && parsed < min) {
      throw ArgumentError.value(
        parsed,
        'value',
        '$component component must be >= $min.',
      );
    }
    if (max != null && parsed > max) {
      throw ArgumentError.value(
        parsed,
        'value',
        '$component component must be <= $max.',
      );
    }
    return parsed;
  }

  String _formatDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  String _formatTime(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:${value.second.toString().padLeft(2, '0')}';

  Query<T> _addWhere(
    Object fieldOrCallback,
    Object? value,
    PredicateOperator operator, {
    required PredicateLogicalOperator logical,
  }) {
    if (fieldOrCallback is String) {
      final resolved = _resolvePredicateField(fieldOrCallback);
      final jsonBooleanComparison = _shouldTreatAsJsonBoolean(
        resolved.jsonSelector,
        operator,
        value,
      );
      final normalizedValue = jsonBooleanComparison && value is bool
          ? jsonEncode(value)
          : value;
      final predicate = _buildFieldPredicate(
        resolved.column,
        operator,
        normalizedValue,
        jsonSelector: resolved.jsonSelector,
        jsonBooleanComparison: jsonBooleanComparison,
      );
      final updated = _appendPredicate(predicate, logical);
      final canMirrorFilter =
          _mirrorsFilter(operator) && resolved.jsonSelector == null;
      if (canMirrorFilter) {
        // Maintain backwards compatibility for the in-memory executor.
        return updated._withFilter(
          _buildFieldFilter(
            fieldOrCallback,
            _mapPredicateToFilter(operator),
            value,
          ),
        );
      }
      return updated;
    }

    if (fieldOrCallback is PredicateCallback<T>) {
      final builder = PredicateBuilder<T>(definition);
      fieldOrCallback(builder);
      final nested = builder.build();
      if (nested == null) {
        return this;
      }
      return _appendPredicate(nested, logical);
    }

    throw ArgumentError.value(
      fieldOrCallback,
      'fieldOrCallback',
      'Must be a column name or predicate callback.',
    );
  }

  Query<T> _addRelationWhere(
    String relation,
    PredicateCallback<dynamic>? constraint, {
    required PredicateLogicalOperator logical,
  }) {
    final path = _resolveRelationPath(relation);
    final where = _buildRelationPredicateConstraint(path, constraint);
    final predicate = RelationPredicate(path: path, where: where);
    return _appendPredicate(predicate, logical);
  }

  Query<T> _appendSimpleCondition(
    String field,
    FilterOperator operator,
    Object? value,
  ) {
    final resolved = _resolvePredicateField(field);
    final predicate = _buildFieldPredicateFromFilter(resolved, operator, value);
    final updated = _appendPredicate(predicate, PredicateLogicalOperator.and);
    if (resolved.jsonSelector != null) {
      return updated;
    }
    return updated._withFilter(_buildFieldFilter(field, operator, value));
  }

  FieldPredicate _buildFieldPredicateFromFilter(
    _ResolvedField resolved,
    FilterOperator filter,
    Object? value,
  ) {
    final operator = _mapFilterToPredicate(filter);
    final jsonBooleanComparison = _shouldTreatAsJsonBoolean(
      resolved.jsonSelector,
      operator,
      value,
    );
    final normalizedValue = jsonBooleanComparison && value is bool
        ? jsonEncode(value)
        : value;
    return _buildFieldPredicate(
      resolved.column,
      operator,
      normalizedValue,
      jsonSelector: resolved.jsonSelector,
      jsonBooleanComparison: jsonBooleanComparison,
    );
  }

  PredicateOperator _mapFilterToPredicate(FilterOperator operator) {
    switch (operator) {
      case FilterOperator.equals:
        return PredicateOperator.equals;
      case FilterOperator.greaterThan:
        return PredicateOperator.greaterThan;
      case FilterOperator.greaterThanOrEqual:
        return PredicateOperator.greaterThanOrEqual;
      case FilterOperator.lessThan:
        return PredicateOperator.lessThan;
      case FilterOperator.lessThanOrEqual:
        return PredicateOperator.lessThanOrEqual;
      case FilterOperator.contains:
        return PredicateOperator.like;
      case FilterOperator.inValues:
        return PredicateOperator.inValues;
      case FilterOperator.isNull:
        return PredicateOperator.isNull;
      case FilterOperator.isNotNull:
        return PredicateOperator.isNotNull;
    }
  }

  FilterOperator _mapPredicateToFilter(PredicateOperator operator) {
    switch (operator) {
      case PredicateOperator.equals:
        return FilterOperator.equals;
      case PredicateOperator.inValues:
        return FilterOperator.inValues;
      case PredicateOperator.greaterThan:
        return FilterOperator.greaterThan;
      case PredicateOperator.greaterThanOrEqual:
        return FilterOperator.greaterThanOrEqual;
      case PredicateOperator.lessThan:
        return FilterOperator.lessThan;
      case PredicateOperator.lessThanOrEqual:
        return FilterOperator.lessThanOrEqual;
      case PredicateOperator.isNull:
        return FilterOperator.isNull;
      case PredicateOperator.isNotNull:
        return FilterOperator.isNotNull;
      default:
        return FilterOperator.equals;
    }
  }

  bool _mirrorsFilter(PredicateOperator operator) {
    switch (operator) {
      case PredicateOperator.equals:
      case PredicateOperator.inValues:
      case PredicateOperator.greaterThan:
      case PredicateOperator.greaterThanOrEqual:
      case PredicateOperator.lessThan:
      case PredicateOperator.lessThanOrEqual:
      case PredicateOperator.isNull:
      case PredicateOperator.isNotNull:
        return true;
      default:
        return false;
    }
  }

  BitwisePredicate _buildBitwisePredicate(
    String field,
    String operator,
    Object value,
  ) {
    final column = _ensureField(field).columnName;
    final normalizedOperator = _normalizeBitwiseOperator(operator);
    return BitwisePredicate(
      field: column,
      operator: normalizedOperator,
      value: value,
    );
  }

  FieldPredicate _buildFieldPredicate(
    String column,
    PredicateOperator operator,
    Object? value, {
    json_path.JsonSelector? jsonSelector,
    bool jsonBooleanComparison = false,
  }) {
    if (operator == PredicateOperator.columnEquals ||
        operator == PredicateOperator.columnNotEquals) {
      if (value is! String) {
        throw ArgumentError.value(
          value,
          'value',
          'Column comparisons require another column name.',
        );
      }
      final compare = _ensureField(value).columnName;
      return FieldPredicate(
        field: column,
        operator: operator,
        compareField: compare,
        jsonSelector: jsonSelector,
      );
    }
    if (operator == PredicateOperator.inValues ||
        operator == PredicateOperator.notInValues) {
      if (value is! Iterable) {
        throw ArgumentError.value(
          value,
          'value',
          'Iterable required for $operator predicates.',
        );
      }
      final Iterable<Object?> iterable = value;
      return FieldPredicate(
        field: column,
        operator: operator,
        values: List<Object?>.from(iterable),
        jsonSelector: jsonSelector,
      );
    }
    return FieldPredicate(
      field: column,
      operator: operator,
      value: value,
      jsonSelector: jsonSelector,
      jsonBooleanComparison: jsonBooleanComparison,
    );
  }

  RelationAggregate _buildRelationAggregate(
    String relation,
    RelationAggregateType type,
    String? alias,
    PredicateCallback<dynamic>? constraint, {
    bool distinct = false,
  }) {
    final path = _resolveRelationPath(relation);
    final where = _buildRelationPredicateConstraint(path, constraint);
    final sanitized = relation.replaceAll('.', '_');
    final resolvedAlias =
        alias ??
        '${sanitized}_${type == RelationAggregateType.count ? 'count' : 'exists'}';
    return RelationAggregate(
      type: type,
      alias: resolvedAlias,
      path: path,
      where: where,
      distinct: distinct,
    );
  }

  RelationPath _resolveRelationPath(String relation) {
    final names = relation.split('.');
    final segments = <RelationSegment>[];
    ModelDefinition<dynamic> current = definition;
    for (final name in names) {
      final relationDef = current.relations.firstWhereOrNull(
        (r) => r.name == name,
      );
      if (relationDef == null) {
        throw ArgumentError.value(
          relation,
          'relation',
          'Unknown relation $name on ${current.modelName}.',
        );
      }
      final segment = _buildRelationSegment(current, relationDef);
      segments.add(segment);
      current = segment.targetDefinition;
    }
    final path = RelationPath(segments: segments);
    _relationPaths.putIfAbsent(relation, () => path);
    return path;
  }

  RelationSegment _buildRelationSegment(
    ModelDefinition<dynamic> parent,
    RelationDefinition relation,
  ) {
    final target = context.registry.expectByName(relation.targetModel);
    final parentKey = relation.localKey ?? parent.primaryKeyField?.columnName;
    if (parentKey == null) {
      throw StateError('Relation ${relation.name} requires a parent key.');
    }
    switch (relation.kind) {
      case RelationKind.hasOne:
      case RelationKind.hasMany:
        final childKey = relation.foreignKey ?? '${parent.tableName}_id';
        return RelationSegment(
          name: relation.name,
          relation: relation,
          parentDefinition: parent,
          targetDefinition: target,
          parentKey: parentKey,
          childKey: childKey,
          expectSingleResult: relation.kind == RelationKind.hasOne,
        );
      case RelationKind.belongsTo:
        final foreignKey = relation.foreignKey ?? '${relation.name}_id';
        final ownerKey =
            relation.localKey ?? target.primaryKeyField?.columnName;
        if (ownerKey == null) {
          throw StateError('Relation ${relation.name} requires a target key.');
        }
        return RelationSegment(
          name: relation.name,
          relation: relation,
          parentDefinition: parent,
          targetDefinition: target,
          parentKey: foreignKey,
          childKey: ownerKey,
          foreignKeyOnParent: true,
          expectSingleResult: true,
        );
      case RelationKind.manyToMany:
        final pivotTable =
            relation.through ?? '${parent.tableName}_${target.tableName}';
        final pivotParentKey =
            relation.pivotForeignKey ?? '${parent.tableName}_id';
        final pivotRelatedKey =
            relation.pivotRelatedKey ?? '${target.tableName}_id';
        final targetKey =
            relation.localKey ?? target.primaryKeyField?.columnName;
        if (targetKey == null) {
          throw StateError('Relation ${relation.name} requires a target key.');
        }
        return RelationSegment(
          name: relation.name,
          relation: relation,
          parentDefinition: parent,
          targetDefinition: target,
          parentKey: parentKey,
          childKey: targetKey,
          pivotTable: pivotTable,
          pivotParentKey: pivotParentKey,
          pivotRelatedKey: pivotRelatedKey,
        );
      case RelationKind.morphOne:
      case RelationKind.morphMany:
        final childKey =
            relation.foreignKey ??
            (throw StateError(
              'Relation ${relation.name} requires a foreign key.',
            ));
        final morphColumn =
            relation.morphType ??
            (throw StateError(
              'Relation ${relation.name} requires a morph type column.',
            ));
        final morphClass =
            relation.morphClass ??
            (throw StateError(
              'Relation ${relation.name} requires a morph class.',
            ));
        return RelationSegment(
          name: relation.name,
          relation: relation,
          parentDefinition: parent,
          targetDefinition: target,
          parentKey: parentKey,
          childKey: childKey,
          morphTypeColumn: morphColumn,
          morphClass: morphClass,
          expectSingleResult: relation.kind == RelationKind.morphOne,
        );
    }
  }

  QueryPredicate? _buildRelationPredicateConstraint(
    RelationPath path,
    PredicateCallback<dynamic>? constraint,
  ) {
    if (constraint == null) {
      return null;
    }
    final builder = PredicateBuilder<dynamic>(path.leaf.targetDefinition);
    constraint(builder);
    return builder.build();
  }

  QueryPredicate? _buildRelationLoadPredicate(
    RelationDefinition relation,
    PredicateCallback<dynamic>? constraint,
  ) {
    if (constraint == null) return null;
    final target = context.registry.expectByName(relation.targetModel);
    final builder = PredicateBuilder<dynamic>(target);
    constraint(builder);
    return builder.build();
  }

  String _resolveHavingField(String field) {
    final aggregate = _aggregates.firstWhereOrNull(
      (agg) => agg.alias != null && agg.alias == field,
    );
    if (aggregate != null) {
      return field;
    }
    return _ensureField(field).columnName;
  }

  Query<T> _appendPredicate(
    QueryPredicate predicate,
    PredicateLogicalOperator logical,
  ) {
    final combined = _combinePredicates(_predicate, predicate, logical);
    return _copyWith(predicate: combined);
  }

  Query<T> _appendHavingPredicate(
    QueryPredicate predicate,
    PredicateLogicalOperator logical,
  ) {
    final combined = _combinePredicates(_having, predicate, logical);
    return _copyWith(having: combined);
  }

  QueryPredicate _combinePredicates(
    QueryPredicate? existing,
    QueryPredicate addition,
    PredicateLogicalOperator logical,
  ) {
    if (existing == null) {
      return addition;
    }

    if (logical == PredicateLogicalOperator.and) {
      return _mergeGroups(existing, addition, PredicateLogicalOperator.and);
    } else {
      return _mergeGroups(existing, addition, PredicateLogicalOperator.or);
    }
  }

  QueryPredicate _mergeGroups(
    QueryPredicate left,
    QueryPredicate right,
    PredicateLogicalOperator logical,
  ) {
    if (left is PredicateGroup && left.logicalOperator == logical) {
      return PredicateGroup(
        logicalOperator: logical,
        predicates: [...left.predicates, right],
      );
    }
    if (right is PredicateGroup && right.logicalOperator == logical) {
      return PredicateGroup(
        logicalOperator: logical,
        predicates: [left, ...right.predicates],
      );
    }
    return PredicateGroup(logicalOperator: logical, predicates: [left, right]);
  }

  Query<T> _withFilter(FilterClause clause) =>
      _copyWith(filters: [..._filters, clause]);
}

class _UpdatePayload {
  _UpdatePayload(this.values, this.jsonUpdates);

  final Map<String, Object?> values;
  final List<JsonUpdateClause> jsonUpdates;

  bool get isEmpty => values.isEmpty && jsonUpdates.isEmpty;
}

class _RelationJoinRequest {
  const _RelationJoinRequest({required this.joinType});

  final JoinType joinType;
}

extension MapQueryExtensions on Query<Map<String, Object?>> {
  MappedAdHocQuery<R> mapRows<R>(R Function(Map<String, Object?> row) mapper) =>
      MappedAdHocQuery<R>(this, mapper);
}

typedef JoinConstraintBuilder = void Function(JoinBuilder join);

class JoinBuilder {
  JoinBuilder._();

  final List<JoinCondition> _conditions = <JoinCondition>[];

  JoinBuilder on(String first, [Object? operator, String? second]) {
    final op = _normalizeJoinOperatorToken(operator);
    if (second == null) {
      throw ArgumentError('Join on clauses require a second column.');
    }
    _conditions.add(
      JoinCondition.column(left: first, operator: op, right: second),
    );
    return this;
  }

  JoinBuilder orOn(String first, [Object? operator, String? second]) {
    final op = _normalizeJoinOperatorToken(operator);
    if (second == null) {
      throw ArgumentError('Join on clauses require a second column.');
    }
    _conditions.add(
      JoinCondition.column(
        left: first,
        operator: op,
        right: second,
        boolean: PredicateLogicalOperator.or,
      ),
    );
    return this;
  }

  JoinBuilder where(String column, Object? value, [Object? operator]) {
    final op = _normalizeJoinOperatorToken(operator);
    _conditions.add(
      JoinCondition.value(left: column, operator: op, value: value),
    );
    return this;
  }

  JoinBuilder orWhere(String column, Object? value, [Object? operator]) {
    final op = _normalizeJoinOperatorToken(operator);
    _conditions.add(
      JoinCondition.value(
        left: column,
        operator: op,
        value: value,
        boolean: PredicateLogicalOperator.or,
      ),
    );
    return this;
  }

  JoinBuilder whereRaw(String sql, [List<Object?> bindings = const []]) {
    _conditions.add(JoinCondition.raw(rawSql: sql, bindings: bindings));
    return this;
  }

  JoinBuilder orWhereRaw(String sql, [List<Object?> bindings = const []]) {
    _conditions.add(
      JoinCondition.raw(
        rawSql: sql,
        bindings: bindings,
        boolean: PredicateLogicalOperator.or,
      ),
    );
    return this;
  }
}

class _LockClauses {
  static const String forUpdate = 'update';
  static const String shared = 'shared';
}

String _normalizeJoinOperatorToken(Object? operator) {
  if (operator == null) {
    return '=';
  }
  if (operator is String && operator.isNotEmpty) {
    return operator;
  }
  throw ArgumentError.value(operator, 'operator', 'Invalid join operator.');
}

/// Lightweight builder used for nested predicate callbacks.
class PredicateBuilder<T> {
  PredicateBuilder(this.definition);

  final ModelDefinition<T> definition;
  QueryPredicate? _predicate;

  PredicateBuilder<T> where(
    Object fieldOrCallback, [
    Object? value,
    PredicateOperator operator = PredicateOperator.equals,
  ]) {
    _addWhere(
      fieldOrCallback,
      value,
      operator,
      logical: PredicateLogicalOperator.and,
    );
    return this;
  }

  PredicateBuilder<T> orWhere(
    Object fieldOrCallback, [
    Object? value,
    PredicateOperator operator = PredicateOperator.equals,
  ]) {
    _addWhere(
      fieldOrCallback,
      value,
      operator,
      logical: PredicateLogicalOperator.or,
    );
    return this;
  }

  PredicateBuilder<T> whereBetween(String field, Object lower, Object upper) {
    final column = _ensureField(field).columnName;
    return _appendPredicate(
      FieldPredicate(
        field: column,
        operator: PredicateOperator.between,
        lower: lower,
        upper: upper,
      ),
      PredicateLogicalOperator.and,
    );
  }

  PredicateBuilder<T> whereNotBetween(
    String field,
    Object lower,
    Object upper,
  ) {
    final column = _ensureField(field).columnName;
    return _appendPredicate(
      FieldPredicate(
        field: column,
        operator: PredicateOperator.notBetween,
        lower: lower,
        upper: upper,
      ),
      PredicateLogicalOperator.and,
    );
  }

  PredicateBuilder<T> whereIn(String field, Iterable<Object?> values) =>
      where(field, values.toList(), PredicateOperator.inValues);

  PredicateBuilder<T> whereNotIn(String field, Iterable<Object?> values) =>
      where(field, values.toList(), PredicateOperator.notInValues);

  PredicateBuilder<T> whereNull(String field) {
    final column = _ensureField(field).columnName;
    return _appendPredicate(
      FieldPredicate(field: column, operator: PredicateOperator.isNull),
      PredicateLogicalOperator.and,
    );
  }

  PredicateBuilder<T> whereNotNull(String field) {
    final column = _ensureField(field).columnName;
    return _appendPredicate(
      FieldPredicate(field: column, operator: PredicateOperator.isNotNull),
      PredicateLogicalOperator.and,
    );
  }

  PredicateBuilder<T> whereLike(
    String field,
    Object value, {
    bool caseInsensitive = false,
  }) {
    final column = _ensureField(field).columnName;
    return _appendPredicate(
      FieldPredicate(
        field: column,
        operator: caseInsensitive
            ? PredicateOperator.iLike
            : PredicateOperator.like,
        value: value,
        caseInsensitive: caseInsensitive,
      ),
      PredicateLogicalOperator.and,
    );
  }

  PredicateBuilder<T> whereILike(String field, Object value) =>
      whereLike(field, value, caseInsensitive: true);

  PredicateBuilder<T> whereNotILike(String field, Object value) =>
      whereNotLike(field, value, caseInsensitive: true);

  PredicateBuilder<T> whereNotLike(
    String field,
    Object value, {
    bool caseInsensitive = false,
  }) {
    final column = _ensureField(field).columnName;
    return _appendPredicate(
      FieldPredicate(
        field: column,
        operator: caseInsensitive
            ? PredicateOperator.notILike
            : PredicateOperator.notLike,
        value: value,
        caseInsensitive: caseInsensitive,
      ),
      PredicateLogicalOperator.and,
    );
  }

  PredicateBuilder<T> whereColumn(
    String left,
    String right, {
    PredicateOperator operator = PredicateOperator.columnEquals,
  }) {
    final leftColumn = _ensureField(left).columnName;
    final rightColumn = _ensureField(right).columnName;
    return _appendPredicate(
      FieldPredicate(
        field: leftColumn,
        compareField: rightColumn,
        operator: operator,
      ),
      PredicateLogicalOperator.and,
    );
  }

  PredicateBuilder<T> whereRaw(
    String sql, [
    List<Object?> bindings = const [],
  ]) => _appendPredicate(
    RawPredicate(sql: sql, bindings: bindings),
    PredicateLogicalOperator.and,
  );

  PredicateBuilder<T> whereBitwise(
    String field,
    String operator,
    Object value,
  ) => _appendPredicate(
    BitwisePredicate(
      field: _ensureField(field).columnName,
      operator: _normalizeBitwiseOperator(operator),
      value: value,
    ),
    PredicateLogicalOperator.and,
  );

  PredicateBuilder<T> orWhereBitwise(
    String field,
    String operator,
    Object value,
  ) => _appendPredicate(
    BitwisePredicate(
      field: _ensureField(field).columnName,
      operator: _normalizeBitwiseOperator(operator),
      value: value,
    ),
    PredicateLogicalOperator.or,
  );

  QueryPredicate? build() => _predicate;

  PredicateBuilder<T> _appendPredicate(
    QueryPredicate predicate,
    PredicateLogicalOperator logical,
  ) {
    _predicate = _combinePredicates(_predicate, predicate, logical);
    return this;
  }

  void _addWhere(
    Object fieldOrCallback,
    Object? value,
    PredicateOperator operator, {
    required PredicateLogicalOperator logical,
  }) {
    if (fieldOrCallback is String) {
      final column = _ensureField(fieldOrCallback).columnName;
      final predicate = _buildFieldPredicate(column, operator, value);
      _predicate = _combinePredicates(_predicate, predicate, logical);
      return;
    }

    if (fieldOrCallback is PredicateCallback<T>) {
      final nestedBuilder = PredicateBuilder<T>(definition);
      fieldOrCallback(nestedBuilder);
      final nested = nestedBuilder.build();
      if (nested != null) {
        _predicate = _combinePredicates(_predicate, nested, logical);
      }
      return;
    }

    throw ArgumentError.value(
      fieldOrCallback,
      'fieldOrCallback',
      'Must be a column name or predicate callback.',
    );
  }

  FieldDefinition _ensureField(String name) {
    final field = definition.fields.firstWhereOrNull(
      (f) => f.name == name || f.columnName == name,
    );
    if (field != null) {
      return field;
    }
    if (definition is AdHocModelDefinition) {
      return (definition as AdHocModelDefinition).fieldFor(name);
    }
    throw ArgumentError.value(
      name,
      'field',
      'Unknown field on ${definition.modelName}.',
    );
  }

  FieldPredicate _buildFieldPredicate(
    String column,
    PredicateOperator operator,
    Object? value,
  ) {
    if (operator == PredicateOperator.columnEquals ||
        operator == PredicateOperator.columnNotEquals) {
      if (value is! String) {
        throw ArgumentError.value(
          value,
          'value',
          'Column comparisons require another column name.',
        );
      }
      final compare = _ensureField(value).columnName;
      return FieldPredicate(
        field: column,
        operator: operator,
        compareField: compare,
      );
    }
    if (operator == PredicateOperator.inValues ||
        operator == PredicateOperator.notInValues) {
      if (value is! Iterable) {
        throw ArgumentError.value(
          value,
          'value',
          'Iterable required for $operator predicates.',
        );
      }
      final Iterable<Object?> iterable = value;
      return FieldPredicate(
        field: column,
        operator: operator,
        values: List<Object?>.from(iterable),
      );
    }
    return FieldPredicate(field: column, operator: operator, value: value);
  }

  QueryPredicate _combinePredicates(
    QueryPredicate? existing,
    QueryPredicate addition,
    PredicateLogicalOperator logical,
  ) {
    if (existing == null) {
      return addition;
    }
    return _mergeGroups(existing, addition, logical);
  }

  QueryPredicate _mergeGroups(
    QueryPredicate left,
    QueryPredicate right,
    PredicateLogicalOperator logical,
  ) {
    if (left is PredicateGroup && left.logicalOperator == logical) {
      return PredicateGroup(
        logicalOperator: logical,
        predicates: [...left.predicates, right],
      );
    }
    if (right is PredicateGroup && right.logicalOperator == logical) {
      return PredicateGroup(
        logicalOperator: logical,
        predicates: [left, ...right.predicates],
      );
    }
    return PredicateGroup(logicalOperator: logical, predicates: [left, right]);
  }
}

class _JsonPathReference {
  _JsonPathReference({required this.column, required this.path});

  final String column;
  final String path;
}

class _ResolvedField {
  const _ResolvedField({required this.column, this.jsonSelector});

  final String column;
  final json_path.JsonSelector? jsonSelector;
}

class _DatePredicateInput {
  _DatePredicateInput({required this.operator, required this.value});

  final String operator;
  final Object value;
}

const Set<String> _bitwiseOperators = {
  '&',
  '|',
  '^',
  '<<',
  '>>',
  '&~',
  '~',
  '#',
  '<<=',
  '>>=',
};

String _normalizeBitwiseOperator(String operator) {
  final normalized = operator.trim();
  if (!_bitwiseOperators.contains(normalized)) {
    throw ArgumentError.value(
      operator,
      'operator',
      'Unsupported bitwise operator. Allowed: '
          '${_bitwiseOperators.join(', ')}.',
    );
  }
  return normalized;
}
