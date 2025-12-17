import 'package:meta/meta.dart';
import 'package:postgres/postgres.dart' show Time;

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

@immutable
class PgBitString {
  const PgBitString(this.bits);

  factory PgBitString.parse(String value) => PgBitString(_sanitizeBits(value));

  final String bits;

  int get length => bits.length;

  @override
  String toString() => bits;

  @override
  bool operator ==(Object other) => other is PgBitString && other.bits == bits;

  @override
  int get hashCode => bits.hashCode;
}

String _sanitizeBits(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return '';
  for (final codeUnit in trimmed.codeUnits) {
    if (codeUnit != 0x30 && codeUnit != 0x31) {
      throw FormatException('Invalid bit string "$input".');
    }
  }
  return trimmed;
}

@immutable
class PgMoney {
  const PgMoney.fromCents(this.cents);

  factory PgMoney.parse(String value) {
    var trimmed = value.trim();
    if (trimmed.isEmpty) return const PgMoney.fromCents(0);

    var negative = false;
    if (trimmed.startsWith('-')) {
      negative = true;
      trimmed = trimmed.substring(1).trimLeft();
    } else if (trimmed.startsWith('(') && trimmed.endsWith(')')) {
      negative = true;
      trimmed = trimmed.substring(1, trimmed.length - 1).trim();
    }

    // Strip common currency symbols and grouping separators.
    trimmed = trimmed.replaceAll(RegExp(r'[^0-9.,]'), '');
    trimmed = trimmed.replaceAll(',', '');
    if (trimmed.isEmpty) return const PgMoney.fromCents(0);

    final parts = trimmed.split('.');
    final major = int.parse(parts.first.isEmpty ? '0' : parts.first);
    final minorRaw = parts.length > 1 ? parts[1] : '';
    final minorNormalized = minorRaw.padRight(2, '0');
    final minor = int.parse(
      minorNormalized.isEmpty
          ? '0'
          : minorNormalized.substring(0, minorNormalized.length.clamp(0, 2)),
    );

    final cents = major * 100 + minor;
    return PgMoney.fromCents(negative ? -cents : cents);
  }

  final int cents;

  String toDecimalString() {
    final abs = cents.abs();
    final major = abs ~/ 100;
    final minor = abs % 100;
    final sign = cents.isNegative ? '-' : '';
    return '$sign$major.${minor.toString().padLeft(2, '0')}';
  }

  @override
  String toString() => toDecimalString();

  @override
  bool operator ==(Object other) => other is PgMoney && other.cents == cents;

  @override
  int get hashCode => cents.hashCode;
}

@immutable
class PgTimeTz {
  const PgTimeTz({required this.time, required this.offset});

  factory PgTimeTz.parse(String value) {
    final trimmed = value.trim();
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})(?::(\d{2})(?:\.(\d{1,6}))?)?([+-])(\d{2})(?::?(\d{2}))?$',
    ).firstMatch(trimmed);
    if (match == null) {
      throw FormatException('Invalid timetz "$value".');
    }

    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final second = int.parse(match.group(3) ?? '0');
    final fraction = match.group(4);
    final micros = fraction == null
        ? 0
        : int.parse(fraction.padRight(6, '0').substring(0, 6));
    final sign = match.group(5) == '-' ? -1 : 1;
    final offsetHours = int.parse(match.group(6)!);
    final offsetMinutes = int.parse(match.group(7) ?? '0');
    final offset = Duration(
      seconds: sign * (offsetHours * 3600 + offsetMinutes * 60),
    );

    return PgTimeTz(
      time: Time(hour, minute, second, 0, micros),
      offset: offset,
    );
  }

  final Time time;
  final Duration offset;

  String toPgString() {
    final micros = time.microseconds % Duration.microsecondsPerSecond;
    final totalSeconds = time.microseconds ~/ Duration.microsecondsPerSecond;
    final hour = totalSeconds ~/ 3600;
    final minute = (totalSeconds % 3600) ~/ 60;
    final second = totalSeconds % 60;
    final base =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
    final fraction = micros == 0
        ? ''
        : '.${micros.toString().padLeft(6, '0').replaceFirst(RegExp(r'0+$'), '')}';
    final offsetSeconds = offset.inSeconds;
    final sign = offsetSeconds.isNegative ? '-' : '+';
    final absOffset = offsetSeconds.abs();
    final offHours = absOffset ~/ 3600;
    final offMinutes = (absOffset % 3600) ~/ 60;
    return '$base$fraction$sign${offHours.toString().padLeft(2, '0')}:${offMinutes.toString().padLeft(2, '0')}';
  }

  @override
  String toString() => toPgString();

  @override
  bool operator ==(Object other) =>
      other is PgTimeTz && other.time == time && other.offset == offset;

  @override
  int get hashCode => Object.hash(time, offset);
}

@immutable
class PgSnapshot {
  const PgSnapshot({required this.xmin, required this.xmax, required this.xip});

  factory PgSnapshot.parse(String value) {
    final trimmed = value.trim();
    final parts = trimmed.split(':');
    if (parts.length < 3) {
      throw FormatException('Invalid snapshot "$value".');
    }
    final xmin = int.parse(parts[0]);
    final xmax = int.parse(parts[1]);
    final xipPart = parts.sublist(2).join(':');
    final xip = xipPart.isEmpty
        ? const <int>[]
        : xipPart
              .split(',')
              .where((e) => e.trim().isNotEmpty)
              .map((e) => int.parse(e.trim()))
              .toList(growable: false);
    return PgSnapshot(xmin: xmin, xmax: xmax, xip: xip);
  }

  final int xmin;
  final int xmax;
  final List<int> xip;

  @override
  String toString() {
    final list = xip.isEmpty ? '' : xip.join(',');
    return '$xmin:$xmax:$list';
  }

  @override
  bool operator ==(Object other) =>
      other is PgSnapshot &&
      other.xmin == xmin &&
      other.xmax == xmax &&
      _listEquals(other.xip, xip);

  @override
  int get hashCode => Object.hash(xmin, xmax, Object.hashAll(xip));
}
