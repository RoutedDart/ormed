part of '../query_builder.dart';

class UpdatePayload {
  UpdatePayload(this.values, this.jsonUpdates);

  final Map<String, Object?> values;
  final List<JsonUpdateClause> jsonUpdates;

  bool get isEmpty => values.isEmpty && jsonUpdates.isEmpty;
}

class RelationJoinRequest {
  const RelationJoinRequest({required this.joinType});

  final JoinType joinType;
}

extension MapQueryExtensions on Query<AdHocRow> {
  MappedAdHocQuery<R> mapRows<R extends OrmEntity>(R Function(AdHocRow row) mapper) =>
      MappedAdHocQuery<R>(this, mapper);
}

typedef JoinConstraintBuilder = void Function(JoinBuilder join);

class LockClauses {
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

class JsonPathReference {
  JsonPathReference({required this.column, required this.path});

  final String column;
  final String path;
}

class ResolvedField {
  const ResolvedField({required this.column, this.jsonSelector});

  final String column;
  final json_path.JsonSelector? jsonSelector;
}

class DatePredicateInput {
  DatePredicateInput({required this.operator, required this.value});

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
