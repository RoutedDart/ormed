part of '../query_builder.dart';

extension QueryHelpers<T> on Query<T> {
  /// Resolves a JSON reference from a field expression.
  ///
  /// Handles both simple column references and JSON path expressions.
  ({String column, String path}) _resolveJsonReference(
    String field, {
    String? overridePath,
  }) {
    final selector = json_path.parseJsonSelectorExpression(field);
    if (selector != null) {
      return (column: selector.column, path: overridePath ?? selector.path);
    }

    // Simple field reference
    final fieldDef = _ensureField(field);
    return (column: fieldDef.columnName, path: overridePath ?? r'$');
  }

  /// Normalizes a length comparison operator to a standard form.
  String _normalizeLengthOperator(String operator) {
    switch (operator.trim()) {
      case '=':
      case '==':
        return '=';
      case '>':
        return '>';
      case '>=':
      case '=>':
        return '>=';
      case '<':
        return '<';
      case '<=':
      case '=<':
        return '<=';
      case '!=':
      case '<>':
        return '!=';
      default:
        throw ArgumentError('Invalid length operator: $operator');
    }
  }
}
