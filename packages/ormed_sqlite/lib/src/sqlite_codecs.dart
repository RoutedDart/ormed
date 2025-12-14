/// Helpers for encoding/decoding SQLite-friendly values.
library;

import 'dart:convert';

import 'package:ormed/ormed.dart';
import 'package:sqlite3/sqlite3.dart';

/// Registers SQLite-specific codecs with the global codec registry.
void registerSqliteCodecs() {
  ValueCodecRegistry.instance.registerDriver('sqlite', {
    // Boolean codecs
    'bool': const SqliteBoolCodec(),
    'bool?': const SqliteBoolCodec(),
    'boolean': const SqliteBoolCodec(),

    // DateTime codecs
    'DateTime': const SqliteDateTimeCodec(),
    'DateTime?': const SqliteDateTimeCodec(),
    'datetime': const SqliteDateTimeCodec(),

    // Carbon codecs
    'Carbon': const SqliteCarbonCodec(),
    'Carbon?': const SqliteCarbonCodec(),
    'CarbonInterface': const SqliteCarbonInterfaceCodec(),
    'CarbonInterface?': const SqliteCarbonInterfaceCodec(),
    'carbon': const SqliteCarbonCodec(),

    // Numeric codecs
    'double': const SqliteDoubleCodec(),
    'double?': const SqliteDoubleCodec(),

    // JSON codec
    'json': const SqliteJsonCodec(),
  });
}

class SqliteBoolCodec extends ValueCodec<bool> {
  const SqliteBoolCodec();

  @override
  Object? encode(bool? value) => value == null ? null : (value ? 1 : 0);

  @override
  bool? decode(Object? value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    return value == '1' || value == 'true';
  }
}

class SqliteDateTimeCodec extends ValueCodec<DateTime> {
  const SqliteDateTimeCodec();

  @override
  Object? encode(DateTime? value) {
    if (value == null) return null;
    return value.toUtc().toIso8601String();
  }

  @override
  DateTime? decode(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    throw ArgumentError(
      'SqliteDateTimeCodec.decode expects String or DateTime, got ${value.runtimeType}',
    );
  }
}

/// Codec for Carbon instances that stores as ISO8601 strings in SQLite.
///
/// This codec handles both encoding Carbon to text and decoding text back to Carbon.
/// All times are stored in UTC to ensure consistency across timezones.
/// When decoding, Carbon instances are created with the configured default timezone.
class SqliteCarbonCodec extends ValueCodec<Carbon> {
  const SqliteCarbonCodec();

  @override
  Object? encode(Carbon? value) {
    if (value == null) return null;
    // Convert to UTC and store as ISO8601 string
    return value.toUtc().toIso8601String();
  }

  @override
  Carbon? decode(Object? value) {
    if (value == null) return null;
    // If already Carbon, return as-is
    if (value is Carbon) return value;
    // If CarbonInterface but not Carbon, convert to Carbon
    if (value is CarbonInterface) {
      return Carbon.fromDateTime(
            value.toDateTime(),
          ).tz(CarbonConfig.defaultTimezone)
          as Carbon;
    }
    // If DateTime, wrap in Carbon with configured timezone
    if (value is DateTime) {
      final utcDateTime = value.isUtc ? value : value.toUtc();
      return Carbon.fromDateTime(utcDateTime).tz(CarbonConfig.defaultTimezone)
          as Carbon;
    }
    // Parse ISO8601 string using CarbonConfig for proper timezone handling
    if (value is String) {
      final parsed = CarbonConfig.parseCarbon(value);
      return parsed.tz(CarbonConfig.defaultTimezone) as Carbon;
    }
    throw ArgumentError(
      'SqliteCarbonCodec.decode expects String, DateTime, or Carbon, got ${value.runtimeType}',
    );
  }
}

/// Codec for CarbonInterface instances that stores as ISO8601 strings in SQLite.
///
/// This codec handles the CarbonInterface type, which includes both Carbon and
/// CarbonImmutable implementations. Decodes to Carbon (mutable) by default.
/// When decoding, Carbon instances are created with the configured default timezone.
class SqliteCarbonInterfaceCodec extends ValueCodec<CarbonInterface> {
  const SqliteCarbonInterfaceCodec();

  @override
  Object? encode(CarbonInterface? value) {
    if (value == null) return null;
    // Convert to UTC and store as ISO8601 string
    return value.toUtc().toIso8601String();
  }

  @override
  CarbonInterface? decode(Object? value) {
    if (value == null) return null;
    // If already CarbonInterface, return as-is
    if (value is CarbonInterface) return value;
    // If DateTime, wrap in Carbon with configured timezone
    if (value is DateTime) {
      final utcDateTime = value.isUtc ? value : value.toUtc();
      return Carbon.fromDateTime(utcDateTime).tz(CarbonConfig.defaultTimezone);
    }
    // Parse ISO8601 string using CarbonConfig for proper timezone handling
    if (value is String) {
      final parsed = CarbonConfig.parseCarbon(value);
      return parsed.tz(CarbonConfig.defaultTimezone);
    }
    throw ArgumentError(
      'SqliteCarbonInterfaceCodec.decode expects String, DateTime, or CarbonInterface, got ${value.runtimeType}',
    );
  }
}

class SqliteDoubleCodec extends ValueCodec<double> {
  const SqliteDoubleCodec();

  @override
  Object? encode(double? value) => value; // No special encoding needed

  @override
  double? decode(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble(); // Convert any num to double
    throw FormatException('Invalid double value: $value');
  }
}

class SqliteJsonCodec extends ValueCodec<Map<String, Object?>> {
  const SqliteJsonCodec();

  @override
  Object? encode(Map<String, Object?>? value) =>
      value == null ? null : jsonEncode(value);

  @override
  Map<String, Object?>? decode(Object? value) {
    if (value == null) return null;
    if (value is Map<String, Object?>) return value;
    if (value is String) {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, Object?>) {
        return decoded;
      }
    }
    throw FormatException('Invalid JSON value: $value');
  }
}

List<Object?> normalizeSqliteParameters(List<Object?> values) =>
    values.map(_normalizeValue).toList(growable: false);

Object? _normalizeValue(Object? value) {
  if (value is bool) return value ? 1 : 0;
  if (value is DateTime) return value.toUtc().toIso8601String();
  if (value is CarbonInterface) return value.toUtc().toIso8601String();
  if (value is List) {
    return value.map<Object?>(_normalizeValue).toList();
  }
  if (value is BigInt) return value.toInt();
  return value;
}

Map<String, Object?> rowToMap(Row row, List<String> columnNames) {
  final map = <String, Object?>{};
  for (var i = 0; i < columnNames.length; i++) {
    map[columnNames[i]] = row.columnAt(i);
  }
  return map;
}
