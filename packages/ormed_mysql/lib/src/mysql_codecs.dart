import 'dart:convert';

import 'package:ormed/ormed.dart';

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
      return Carbon.fromDateTime(value) as Carbon;
    }
    
    // Handle string parsing as fallback
    if (value is String && value.isNotEmpty) {
      // Parse using Carbon.parse WITHOUT timezone conversion for DATETIME
      return Carbon.parse(value) as Carbon;
    }
    
    throw StateError('Unsupported Carbon value "$value" of type ${value.runtimeType}.');
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
      final dateTime = DateTime.parse(value);
      // MySQL DATETIME is stored in local time (not UTC)
      // IMPORTANT: Do NOT shift timezone for DATETIME columns - they store local time as-is
      return Carbon.fromDateTime(dateTime);
    }
    
    // Handle DateTime from mysql package (fallback)
    if (value is DateTime) {
      // Note: DateTime from mysql package might have truncated fractional seconds
      // IMPORTANT: Do NOT shift timezone for DATETIME columns
      return Carbon.fromDateTime(value);
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
