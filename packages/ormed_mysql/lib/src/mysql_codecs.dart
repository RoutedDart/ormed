import 'dart:convert';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:ormed/ormed.dart';
import 'package:uuid/uuid_value.dart';

import 'mysql_value_types.dart';

/// Registers MySQL-specific codecs with the global codec registry.
/// Also registers for MariaDB since it uses the same codecs.
void registerMySqlCodecs() {
  const Map<String, ValueCodec<dynamic>> codecs = {
    'bool': MySqlBoolCodec(),
    'bool?': MySqlBoolCodec(),
    'DateTime': MySqlDateTimeCodec(),
    'DateTime?': MySqlDateTimeCodec(),
    'Carbon': MySqlCarbonCodec(),
    'Carbon?': MySqlCarbonCodec(),
    'CarbonInterface': MySqlCarbonInterfaceCodec(),
    'CarbonInterface?': MySqlCarbonInterfaceCodec(),
    'Duration': MySqlDurationCodec(),
    'Duration?': MySqlDurationCodec(),
    'Decimal': MySqlDecimalCodec(),
    'Decimal?': MySqlDecimalCodec(),
    'UuidValue': MySqlUuidValueCodec(),
    'UuidValue?': MySqlUuidValueCodec(),
    'Set<String>': MySqlStringSetCodec(),
    'Set<String>?': MySqlStringSetCodec(),
    'MySqlBitString': MySqlBitStringCodec(),
    'MySqlBitString?': MySqlBitStringCodec(),
    'MySqlGeometry': MySqlGeometryCodec(),
    'MySqlGeometry?': MySqlGeometryCodec(),
    'Map<String, Object?>': MySqlJsonMapCodec(),
    'Map<String, Object?>?': MySqlJsonMapCodec(),
    'Map<String, dynamic>': MySqlJsonDynamicMapCodec(),
    'Map<String, dynamic>?': MySqlJsonDynamicMapCodec(),
    'List<Object?>': MySqlJsonListCodec(),
    'List<Object?>?': MySqlJsonListCodec(),
    'List<dynamic>': MySqlJsonListCodec(),
    'List<dynamic>?': MySqlJsonListCodec(),
  };

  ValueCodecRegistry.instance.registerDriver('mysql', codecs);
  ValueCodecRegistry.instance.registerDriver('mariadb', codecs);
}

class MySqlBoolCodec extends ValueCodec<bool> {
  const MySqlBoolCodec();

  @override
  Object? encode(bool? value) => value == null ? null : (value ? 1 : 0);

  @override
  bool? decode(Object? value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
      final numeric = num.tryParse(value);
      if (numeric != null) return numeric != 0;
    }
    throw StateError('Unsupported boolean value "$value".');
  }
}

class MySqlDateTimeCodec extends ValueCodec<DateTime> {
  const MySqlDateTimeCodec();

  @override
  Object? encode(DateTime? value) {
    if (value == null) return null;
    return _formatDateTime(value);
  }

  @override
  DateTime? decode(Object? value) {
    if (value == null) return null;
    if (value is DateTime) {
      if (value.isUtc) return value;
      return DateTime.utc(
        value.year,
        value.month,
        value.day,
        value.hour,
        value.minute,
        value.second,
        value.millisecond,
        value.microsecond,
      );
    }
    final raw = value.toString().trim();
    final parsed = DateTime.parse(
      RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(raw) ? raw : '${raw}Z',
    );
    if (parsed.isUtc) return parsed;
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    );
  }
}

class MySqlDurationCodec extends ValueCodec<Duration> {
  const MySqlDurationCodec();

  @override
  Object? encode(Duration? value) => value == null
      ? null
      : _formatDurationAsTime(value);

  @override
  Duration? decode(Object? value) {
    if (value == null) return null;
    if (value is Duration) return value;
    if (value is num) return Duration(microseconds: value.toInt());
    if (value is String) {
      return _parseMySqlTime(value);
    }
    throw StateError('Unsupported duration value "$value".');
  }
}

class MySqlDecimalCodec extends ValueCodec<Decimal> {
  const MySqlDecimalCodec();

  @override
  Object? encode(Decimal? value) => value?.toString();

  @override
  Decimal? decode(Object? value) {
    if (value == null) return null;
    if (value is Decimal) return value;
    if (value is num) return Decimal.parse(value.toString());
    if (value is String) return Decimal.parse(value.trim());
    throw StateError('Unsupported Decimal value "$value".');
  }
}

class MySqlUuidValueCodec extends ValueCodec<UuidValue> {
  const MySqlUuidValueCodec();

  @override
  Object? encode(UuidValue? value) => value?.toString();

  @override
  UuidValue? decode(Object? value) {
    if (value == null) return null;
    if (value is UuidValue) return value;
    if (value is String) return UuidValue.fromString(value.trim());
    throw StateError('Unsupported UUID value "$value".');
  }
}

class MySqlStringSetCodec extends ValueCodec<Set<String>> {
  const MySqlStringSetCodec();

  @override
  Object? encode(Set<String>? value) =>
      value?.join(',');

  @override
  Set<String>? decode(Object? value) {
    if (value == null) return null;
    if (value is Set<String>) return Set<String>.from(value);
    if (value is Iterable) {
      return value.map((e) => e.toString()).toSet();
    }
    final raw = value.toString();
    if (raw.isEmpty) return <String>{};
    return raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
  }
}

class MySqlBitStringCodec extends ValueCodec<MySqlBitString> {
  const MySqlBitStringCodec();

  @override
  Object? encode(MySqlBitString? value) => value?.bytes;

  @override
  MySqlBitString? decode(Object? value) {
    if (value == null) return null;
    if (value is MySqlBitString) return value;
    if (value is Uint8List) return MySqlBitString(value);
    if (value is List<int>) return MySqlBitString(Uint8List.fromList(value));
    if (value is String) {
      final trimmed = value.trim();
      final isBitString =
          trimmed.isNotEmpty && RegExp(r'^[01]+$').hasMatch(trimmed);
      if (isBitString) {
        return MySqlBitString.parse(trimmed);
      }

      // mysql_client_plus may decode BIT columns through utf8, producing control
      // characters for small integers (e.g. '\n' == 0x0A). Preserve raw bytes
      // by using the string's code units.
      return MySqlBitString(Uint8List.fromList(value.codeUnits));
    }
    throw StateError('Unsupported BIT value "$value".');
  }
}

class MySqlGeometryCodec extends ValueCodec<MySqlGeometry> {
  const MySqlGeometryCodec();

  @override
  Object? encode(MySqlGeometry? value) => value?.bytes;

  @override
  MySqlGeometry? decode(Object? value) {
    if (value == null) return null;
    if (value is MySqlGeometry) return value;
    if (value is Uint8List) return MySqlGeometry(value);
    if (value is List<int>) return MySqlGeometry(Uint8List.fromList(value));
    if (value is String) return MySqlGeometry.fromHex(value);
    throw StateError('Unsupported geometry value "$value".');
  }
}

class MySqlJsonMapCodec extends ValueCodec<Map<String, Object?>> {
  const MySqlJsonMapCodec();

  @override
  Object? encode(Map<String, Object?>? value) =>
      value == null ? null : jsonEncode(value);

  @override
  Map<String, Object?>? decode(Object? value) {
    if (value == null) return null;
    if (value is Map<String, Object?>) return Map<String, Object?>.from(value);
    if (value is Map) {
      return value.map((key, dynamic v) => MapEntry(key.toString(), v));
    }
    final decoded = jsonDecode(value.toString());
    if (decoded is Map) {
      return decoded.map((key, dynamic v) => MapEntry(key.toString(), v));
    }
    throw StateError('Expected JSON object but received "$value".');
  }
}

class MySqlJsonDynamicMapCodec extends ValueCodec<Map<String, dynamic>> {
  const MySqlJsonDynamicMapCodec();

  @override
  Object? encode(Map<String, dynamic>? value) =>
      value == null ? null : jsonEncode(value);

  @override
  Map<String, dynamic>? decode(Object? value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    if (value is Map) {
      return value.map((key, dynamic v) => MapEntry(key.toString(), v));
    }
    final decoded = jsonDecode(value.toString());
    if (decoded is Map) {
      return decoded.map((key, dynamic v) => MapEntry(key.toString(), v));
    }
    throw StateError('Expected JSON object but received "$value".');
  }
}

class MySqlJsonListCodec extends ValueCodec<List<Object?>> {
  const MySqlJsonListCodec();

  @override
  Object? encode(List<Object?>? value) =>
      value == null ? null : jsonEncode(value);

  @override
  List<Object?>? decode(Object? value) {
    if (value == null) return null;
    if (value is List<Object?>) {
      return List<Object?>.from(value);
    }
    if (value is List) {
      return value.cast<Object?>();
    }
    final decoded = jsonDecode(value.toString());
    if (decoded is List) {
      return decoded.cast<Object?>();
    }
    throw StateError('Expected JSON array but received "$value".');
  }
}

/// Codec for Carbon instances with timezone-aware decoding.
/// Encodes to UTC DATETIME, decodes to configured timezone.
class MySqlCarbonCodec extends ValueCodec<Carbon> {
  const MySqlCarbonCodec();

  @override
  Object? encode(Carbon? value) {
    if (value == null) return null;
    // Convert to DateTime then format as UTC
    final dateTime = value.toDateTime();
    return _formatDateTime(dateTime);
  }

  @override
  Carbon? decode(Object? value) {
    if (value == null) return null;

    // Handle DateTime from mysql package - check this FIRST
    // The mysql1 package returns DateTime objects directly
    if (value is DateTime) {
      // MySQL stores DATETIME with microsecond precision (6 digits)
      // The mysql1 package preserves this when returning DateTime
      // IMPORTANT: Do NOT shift timezone for DATETIME columns - they store local time as-is
      final utcValue = value.isUtc
          ? value
          : DateTime.utc(
              value.year,
              value.month,
              value.day,
              value.hour,
              value.minute,
              value.second,
              value.millisecond,
              value.microsecond,
            );
      return Carbon.fromDateTime(utcValue);
    }

    // Handle string parsing as fallback
    if (value is String && value.isNotEmpty) {
      // Parse using Carbon.parse WITHOUT timezone conversion for DATETIME
      final raw = value.trim();
      final parsed = DateTime.parse(
        RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(raw) ? raw : '${raw}Z',
      );
      final utcValue = parsed.isUtc
          ? parsed
          : DateTime.utc(
              parsed.year,
              parsed.month,
              parsed.day,
              parsed.hour,
              parsed.minute,
              parsed.second,
              parsed.millisecond,
              parsed.microsecond,
            );
      return Carbon.fromDateTime(utcValue);
    }

    throw StateError(
      'Unsupported Carbon value "$value" of type ${value.runtimeType}.',
    );
  }
}

/// Codec for CarbonInterface instances with timezone-aware decoding.
/// Encodes to UTC DATETIME, decodes to configured timezone.
class MySqlCarbonInterfaceCodec extends ValueCodec<CarbonInterface> {
  const MySqlCarbonInterfaceCodec();

  @override
  Object? encode(CarbonInterface? value) {
    if (value == null) return null;
    // CarbonInterface implements DateTime
    return _formatDateTime(value as DateTime);
  }

  @override
  CarbonInterface? decode(Object? value) {
    if (value == null) return null;

    // Handle string parsing FIRST to preserve fractional seconds
    // MySQL client might truncate DateTime milliseconds
    if (value is String && value.isNotEmpty) {
      // Parse the datetime string directly to preserve fractional seconds
      final raw = value.trim();
      final dateTime = DateTime.parse(
        RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(raw) ? raw : '${raw}Z',
      );
      final utcValue = dateTime.isUtc
          ? dateTime
          : DateTime.utc(
              dateTime.year,
              dateTime.month,
              dateTime.day,
              dateTime.hour,
              dateTime.minute,
              dateTime.second,
              dateTime.millisecond,
              dateTime.microsecond,
            );
      return Carbon.fromDateTime(utcValue);
    }

    // Handle DateTime from mysql package (fallback)
    if (value is DateTime) {
      // Note: DateTime from mysql package might have truncated fractional seconds
      final utcValue = value.isUtc ? value : value.toUtc();
      return Carbon.fromDateTime(utcValue);
    }

    throw StateError('Unsupported CarbonInterface value "$value".');
  }
}

String _formatDateTime(DateTime value) {
  // MySQL DATETIME stores local time as-is (not converted to UTC)
  // Only TIMESTAMP converts to/from UTC automatically
  // Calculate full microseconds: milliseconds * 1000 + microseconds
  final totalMicroseconds = (value.millisecond * 1000) + value.microsecond;
  final buffer = StringBuffer()
    ..write(_padNumber(value.year, 4))
    ..write('-')
    ..write(_padNumber(value.month, 2))
    ..write('-')
    ..write(_padNumber(value.day, 2))
    ..write(' ')
    ..write(_padNumber(value.hour, 2))
    ..write(':')
    ..write(_padNumber(value.minute, 2))
    ..write(':')
    ..write(_padNumber(value.second, 2))
    ..write('.')
    ..write(_padNumber(totalMicroseconds, 6));
  return buffer.toString();
}

String _padNumber(int value, int width) => value.toString().padLeft(width, '0');

Duration _parseMySqlTime(String raw) {
  final trimmed = raw.trim();
  final match = RegExp(
    r'^([+-])?(\d+):(\d{2}):(\d{2})(?:\.(\d{1,6}))?$',
  ).firstMatch(trimmed);
  if (match == null) {
    // Some connectors send TIME as an integer microsecond count.
    final numeric = num.tryParse(trimmed);
    if (numeric != null) return Duration(microseconds: numeric.toInt());
    throw FormatException('Invalid MySQL TIME "$raw".');
  }

  final sign = match.group(1) == '-' ? -1 : 1;
  final hours = int.parse(match.group(2)!);
  final minutes = int.parse(match.group(3)!);
  final seconds = int.parse(match.group(4)!);
  final fraction = match.group(5);
  final micros = fraction == null
      ? 0
      : int.parse(fraction.padRight(6, '0').substring(0, 6));

  final totalMicros =
      ((hours * 3600 + minutes * 60 + seconds) * 1000000) + micros;
  return Duration(microseconds: sign * totalMicros);
}

String _formatDurationAsTime(Duration value) {
  final negative = value.isNegative;
  final microsTotal = value.inMicroseconds.abs();
  final secondsTotal = microsTotal ~/ 1000000;
  final micros = microsTotal % 1000000;

  final hours = secondsTotal ~/ 3600;
  final minutes = (secondsTotal % 3600) ~/ 60;
  final seconds = secondsTotal % 60;

  final buffer = StringBuffer();
  if (negative) buffer.write('-');
  buffer
    ..write(hours.toString().padLeft(2, '0'))
    ..write(':')
    ..write(minutes.toString().padLeft(2, '0'))
    ..write(':')
    ..write(seconds.toString().padLeft(2, '0'));
  if (micros != 0) {
    buffer..write('.')..write(micros.toString().padLeft(6, '0'));
  }
  return buffer.toString();
}
