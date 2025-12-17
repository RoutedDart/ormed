import 'package:meta/meta.dart';

@immutable
class PgInet {
  const PgInet(this.value);

  factory PgInet.parse(String value) => PgInet(value);

  final String value;

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) => other is PgInet && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

@immutable
class PgCidr {
  const PgCidr(this.value);

  factory PgCidr.parse(String value) => PgCidr(value);

  final String value;

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) => other is PgCidr && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

@immutable
class PgMacAddress {
  const PgMacAddress(this.value);

  factory PgMacAddress.parse(String value) => PgMacAddress(value);

  final String value;

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      other is PgMacAddress && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

@immutable
class PgVector {
  PgVector(this.values);

  factory PgVector.parse(String value) {
    final trimmed = value.trim();
    final content = trimmed.startsWith('[') && trimmed.endsWith(']')
        ? trimmed.substring(1, trimmed.length - 1)
        : trimmed;
    if (content.isEmpty) return PgVector(const []);

    final parts = content.split(',');
    final parsed = <double>[];
    for (final raw in parts) {
      final token = raw.trim();
      if (token.isEmpty) continue;
      parsed.add(double.parse(token));
    }
    return PgVector(List<double>.unmodifiable(parsed));
  }

  final List<double> values;

  int get dimensions => values.length;

  @override
  String toString() => '[${values.join(',')}]';

  @override
  bool operator ==(Object other) =>
      other is PgVector && _listEquals(other.values, values);

  @override
  int get hashCode => Object.hashAll(values);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
