import 'package:meta/meta.dart';

/// Representation of a default value. Literal values and SQL expressions are both supported.
@immutable
class ColumnDefault {
  const ColumnDefault.literal(this.value)
    : expression = null,
      useCurrentTimestamp = false;

  const ColumnDefault.expression(this.expression)
    : value = null,
      useCurrentTimestamp = false;

  const ColumnDefault.currentTimestamp()
    : value = null,
      expression = null,
      useCurrentTimestamp = true;

  /// Literal value to use as default.
  final Object? value;

  /// SQL expression evaluated when inserting the column.
  final String? expression;

  /// Whether to use the database current timestamp helper.
  final bool useCurrentTimestamp;

  Map<String, Object?> toJson() => {
    if (value != null) 'value': value,
    if (expression != null) 'expression': expression,
    if (useCurrentTimestamp) 'current': true,
  };

  factory ColumnDefault.fromJson(Map<String, Object?> json) {
    if (json['current'] == true) {
      return const ColumnDefault.currentTimestamp();
    }
    if (json.containsKey('expression')) {
      return ColumnDefault.expression(json['expression'] as String);
    }
    return ColumnDefault.literal(json['value']);
  }
}
