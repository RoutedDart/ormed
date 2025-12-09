import 'dart:convert';

import 'package:ormed/ormed.dart';
import 'package:postgres/postgres.dart';

/// Registers PostgreSQL-specific codecs with the global codec registry.
void registerPostgresCodecs() {
  const timestampCodec = _PostgresTimestampCodec();
  const intervalCodec = _PostgresIntervalCodec();
  const jsonMapCodec = _PostgresJsonMapCodec();
  const jsonDynamicMapCodec = _PostgresJsonDynamicMapCodec();
  const jsonListCodec = _PostgresJsonListCodec();
  const carbonCodec = PostgresCarbonCodec();
  const carbonInterfaceCodec = PostgresCarbonInterfaceCodec();
  
  ValueCodecRegistry.instance.registerDriver('postgres', {
    'DateTime': timestampCodec,
    'DateTime?': timestampCodec,
    'Duration': intervalCodec,
    'Duration?': intervalCodec,
    'Carbon': carbonCodec,
    'Carbon?': carbonCodec,
    'CarbonInterface': carbonInterfaceCodec,
    'CarbonInterface?': carbonInterfaceCodec,
    'Map<String, Object?>': jsonMapCodec,
    'Map<String, Object?>?': jsonMapCodec,
    'Map<String, dynamic>': jsonDynamicMapCodec,
    'Map<String, dynamic>?': jsonDynamicMapCodec,
    'List<Object?>': jsonListCodec,
    'List<Object?>?': jsonListCodec,
    'List<dynamic>': jsonListCodec,
    'List<dynamic>?': jsonListCodec,
    'List<String>': const _PostgresArrayCodec<String>(Type.textArray),
    'List<int>': const _PostgresArrayCodec<int>(Type.integerArray),
    'List<double>': const _PostgresArrayCodec<double>(Type.doubleArray),
    'List<bool>': const _PostgresArrayCodec<bool>(Type.booleanArray),
    'List<DateTime>': const _PostgresArrayCodec<DateTime>(
      Type.timestampTzArray,
    ),
  });
}

class _PostgresTimestampCodec extends ValueCodec<DateTime> {
  const _PostgresTimestampCodec();

  @override
  Object? encode(DateTime? value) {
    if (value == null) {
      return TypedValue<DateTime>(Type.timestampTz, null, isSqlNull: true);
    }
    return TypedValue<DateTime>(Type.timestampTz, value.toUtc());
  }

  @override
  DateTime? decode(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value);
    }
    throw StateError('Unsupported timestamp value "$value".');
  }
}

class _PostgresIntervalCodec extends ValueCodec<Duration> {
  const _PostgresIntervalCodec();

  @override
  Object? encode(Duration? value) {
    if (value == null) {
      return TypedValue<Interval>(Type.interval, null, isSqlNull: true);
    }
    return TypedValue<Interval>(Type.interval, Interval.duration(value));
  }

  @override
  Duration? decode(Object? value) {
    if (value == null) return null;
    if (value is Duration) return value;
    if (value is Interval) {
      final fromMonths = Duration(days: value.months * 30);
      final fromDays = Duration(days: value.days);
      final fromMicros = Duration(microseconds: value.microseconds);
      return fromMonths + fromDays + fromMicros;
    }
    throw StateError('Unsupported interval value "$value".');
  }
}

class _PostgresJsonMapCodec extends ValueCodec<Map<String, Object?>> {
  const _PostgresJsonMapCodec();

  @override
  Object? encode(Map<String, Object?>? value) {
    if (value == null) {
      return TypedValue<Object>(Type.jsonb, null, isSqlNull: true);
    }
    return TypedValue<Object>(Type.jsonb, value);
  }

  @override
  Map<String, Object?>? decode(Object? value) {
    if (value == null) return null;
    if (value is Map<String, Object?>) {
      return Map<String, Object?>.from(value);
    }
    if (value is Map) {
      return value.map((key, dynamic v) => MapEntry(key.toString(), v));
    }
    if (value is String && value.isNotEmpty) {
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        return decoded.map((key, dynamic v) => MapEntry(key.toString(), v));
      }
    }
    throw StateError('Expected JSON map but received "$value".');
  }
}

class _PostgresJsonDynamicMapCodec extends ValueCodec<Map<String, dynamic>> {
  const _PostgresJsonDynamicMapCodec();

  @override
  Object? encode(Map<String, dynamic>? value) {
    if (value == null) {
      return TypedValue<Object>(Type.jsonb, null, isSqlNull: true);
    }
    return TypedValue<Object>(Type.jsonb, value);
  }

  @override
  Map<String, dynamic>? decode(Object? value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    if (value is Map) {
      return value.map((key, dynamic v) => MapEntry(key.toString(), v));
    }
    if (value is String && value.isNotEmpty) {
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        return decoded.map((key, dynamic v) => MapEntry(key.toString(), v));
      }
    }
    throw StateError('Expected JSON map but received "$value".');
  }
}

class _PostgresJsonListCodec extends ValueCodec<List<Object?>> {
  const _PostgresJsonListCodec();

  @override
  Object? encode(List<Object?>? value) {
    if (value == null) {
      return TypedValue<Object>(Type.jsonb, null, isSqlNull: true);
    }
    return TypedValue<Object>(Type.jsonb, value);
  }

  @override
  List<Object?>? decode(Object? value) {
    if (value == null) return null;
    if (value is List<Object?>) {
      return List<Object?>.from(value);
    }
    if (value is List) {
      return value.cast<Object?>();
    }
    if (value is String && value.isNotEmpty) {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded.cast<Object?>();
      }
    }
    throw StateError('Expected JSON array but received "$value".');
  }
}

class _PostgresArrayCodec<T> extends ValueCodec<List<T>> {
  const _PostgresArrayCodec(this._type);

  final Type<List<T>> _type;

  @override
  Object? encode(List<T>? value) {
    if (value == null) return null;
    return TypedValue<List<T>>(_type, value);
  }

  @override
  List<T>? decode(Object? value) {
    if (value == null) return null;
    if (value is List<T>) {
      return List<T>.from(value);
    }
    if (value is List) {
      return value.cast<T>();
    }
    throw StateError('Expected Postgres array but received "$value".');
  }
}

/// Codec for Carbon instances with timezone-aware decoding.
/// Encodes to UTC TIMESTAMP WITH TIME ZONE, decodes to configured timezone.
class PostgresCarbonCodec extends ValueCodec<Carbon> {
  const PostgresCarbonCodec();

  @override
  Object? encode(Carbon? value) {
    if (value == null) {
      return TypedValue<DateTime>(Type.timestampTz, null, isSqlNull: true);
    }
    // Convert to DateTime then to UTC
    final dateTime = value.toDateTime();
    return TypedValue<DateTime>(Type.timestampTz, dateTime.toUtc());
  }

  @override
  Carbon? decode(Object? value) {
    if (value == null) return null;
    
    // Handle DateTime from postgres package
    if (value is DateTime) {
      final utcDateTime = value.isUtc ? value : value.toUtc();
      return Carbon.fromDateTime(utcDateTime).tz(CarbonConfig.defaultTimezone) as Carbon;
    }
    
    // Handle string parsing (fallback)
    if (value is String && value.isNotEmpty) {
      final utcDateTime = DateTime.parse(value).toUtc();
      return Carbon.fromDateTime(utcDateTime).tz(CarbonConfig.defaultTimezone) as Carbon;
    }
    
    throw StateError('Unsupported Carbon value "$value".');
  }
}

/// Codec for CarbonInterface instances with timezone-aware decoding.
/// Encodes to UTC TIMESTAMP WITH TIME ZONE, decodes to configured timezone.
class PostgresCarbonInterfaceCodec extends ValueCodec<CarbonInterface> {
  const PostgresCarbonInterfaceCodec();

  @override
  Object? encode(CarbonInterface? value) {
    if (value == null) {
      return TypedValue<DateTime>(Type.timestampTz, null, isSqlNull: true);
    }
    // CarbonInterface implements DateTime
    final dt = value as DateTime;
    return TypedValue<DateTime>(Type.timestampTz, dt.toUtc());
  }

  @override
  CarbonInterface? decode(Object? value) {
    if (value == null) return null;
    
    // Handle DateTime from postgres package
    if (value is DateTime) {
      final utcDateTime = value.isUtc ? value : value.toUtc();
      return Carbon.fromDateTime(utcDateTime).tz(CarbonConfig.defaultTimezone);
    }
    
    // Handle string parsing (fallback)
    if (value is String && value.isNotEmpty) {
      final utcDateTime = DateTime.parse(value).toUtc();
      return Carbon.fromDateTime(utcDateTime).tz(CarbonConfig.defaultTimezone);
    }
    
    throw StateError('Unsupported CarbonInterface value "$value".');
  }
}
