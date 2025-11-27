import 'dart:convert';

import 'package:ormed/ormed.dart';

/// Extends the base codec registry with MySQL-friendly codecs.
ValueCodecRegistry augmentMySqlCodecs(ValueCodecRegistry registry) =>
    registry.fork(
      codecs: const {
        'bool': MySqlBoolCodec(),
        'bool?': MySqlBoolCodec(),
        'DateTime': MySqlDateTimeCodec(),
        'DateTime?': MySqlDateTimeCodec(),
        'Duration': MySqlDurationCodec(),
        'Duration?': MySqlDurationCodec(),
        'Map<String, Object?>': MySqlJsonMapCodec(),
        'Map<String, Object?>?': MySqlJsonMapCodec(),
        'Map<String, dynamic>': MySqlJsonDynamicMapCodec(),
        'Map<String, dynamic>?': MySqlJsonDynamicMapCodec(),
        'List<Object?>': MySqlJsonListCodec(),
        'List<Object?>?': MySqlJsonListCodec(),
        'List<dynamic>': MySqlJsonListCodec(),
        'List<dynamic>?': MySqlJsonListCodec(),
      },
    );

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
  Object? encode(DateTime? value) =>
      value == null ? null : _formatDateTime(value);

  @override
  DateTime? decode(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.parse(value.toString());
  }
}

class MySqlDurationCodec extends ValueCodec<Duration> {
  const MySqlDurationCodec();

  @override
  Object? encode(Duration? value) => value?.inMicroseconds;

  @override
  Duration? decode(Object? value) {
    if (value == null) return null;
    if (value is Duration) return value;
    if (value is num) return Duration(microseconds: value.toInt());
    if (value is String) {
      final parsed = num.tryParse(value);
      if (parsed != null) {
        return Duration(microseconds: parsed.toInt());
      }
    }
    throw StateError('Unsupported duration value "$value".');
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

String _formatDateTime(DateTime value) {
  final utc = value.toUtc();
  final buffer = StringBuffer()
    ..write(_padNumber(utc.year, 4))
    ..write('-')
    ..write(_padNumber(utc.month, 2))
    ..write('-')
    ..write(_padNumber(utc.day, 2))
    ..write(' ')
    ..write(_padNumber(utc.hour, 2))
    ..write(':')
    ..write(_padNumber(utc.minute, 2))
    ..write(':')
    ..write(_padNumber(utc.second, 2))
    ..write('.')
    ..write(_padNumber(utc.microsecond, 6));
  return buffer.toString();
}

String _padNumber(int value, int width) => value.toString().padLeft(width, '0');
