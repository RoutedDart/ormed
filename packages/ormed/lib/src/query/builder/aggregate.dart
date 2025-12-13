part of '../query_builder.dart';

/// Extension providing aggregate functions for query results.
extension AggregateExtension<T extends OrmEntity> on Query<T> {
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
}
