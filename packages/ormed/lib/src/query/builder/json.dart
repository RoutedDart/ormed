part of '../query_builder.dart';

extension JsonExtension<T extends OrmEntity> on Query<T> {
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

  /// Adds an OR JSON containment predicate.
  ///
  /// Checks if a JSON column contains a specific value (OR variant).
  ///
  /// Example:
  /// ```dart
  /// final users = await context.query<User>()
  ///   .where('name', 'John')
  ///   .orWhereJsonContains('skills', 'Dart')
  ///   .get();
  /// ```
  Query<T> orWhereJsonContains(String field, Object? value) {
    final resolved = _resolvePredicateField(field);
    return _appendPredicate(
      FieldPredicate(
        field: resolved.column,
        operator: PredicateOperator.like,
        value: value,
        jsonSelector: resolved.jsonSelector,
      ),
      PredicateLogicalOperator.or,
    );
  }

  /// Adds an OR JSON length predicate.
  ///
  /// Checks the length of a JSON array or object (OR variant).
  ///
  /// Example:
  /// ```dart
  /// final users = await context.query<User>()
  ///   .whereJsonLength('tags', 1)
  ///   .orWhereJsonLength('categories', 2)
  ///   .get();
  /// ```
  Query<T> orWhereJsonLength(
    String field,
    int length, {
    PredicateOperator operator = PredicateOperator.equals,
  }) {
    final resolved = _resolvePredicateField(field);
    return _appendPredicate(
      FieldPredicate(
        field: resolved.column,
        operator: operator,
        value: length,
        jsonSelector: resolved.jsonSelector,
      ),
      PredicateLogicalOperator.or,
    );
  }

  /// Adds an OR JSON containsKey predicate.
  ///
  /// Checks if a JSON object contains a specific key (OR variant).
  ///
  /// Example:
  /// ```dart
  /// final users = await context.query<User>()
  ///   .whereJsonContainsKey('profile')
  ///   .orWhereJsonContainsKey('settings')
  ///   .get();
  /// ```
  Query<T> orWhereJsonContainsKey(String field) {
    final resolved = _resolvePredicateField(field);
    return _appendPredicate(
      FieldPredicate(
        field: resolved.column,
        operator: PredicateOperator.isNotNull,
        jsonSelector: resolved.jsonSelector,
      ),
      PredicateLogicalOperator.or,
    );
  }

  /// Adds an OR JSON overlaps predicate.
  ///
  /// Checks if two JSON arrays have at least one element in common (OR variant).
  ///
  /// Example:
  /// ```dart
  /// final users = await context.query<User>()
  ///   .whereJsonOverlaps('skills', ['Dart'])
  ///   .orWhereJsonOverlaps('languages', ['English'])
  ///   .get();
  /// ```
  Query<T> orWhereJsonOverlaps(String field, Object value) {
    final resolved = _resolvePredicateField(field);
    return _appendPredicate(
      FieldPredicate(
        field: resolved.column,
        operator: PredicateOperator.inValues,
        values: value is List ? value : [value],
        jsonSelector: resolved.jsonSelector,
      ),
      PredicateLogicalOperator.or,
    );
  }
}
