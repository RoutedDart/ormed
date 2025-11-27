/// Helpers for encoding/decoding SQLite-friendly values.
library;

import 'dart:convert';

import 'package:ormed/ormed.dart';
import 'package:sqlite3/sqlite3.dart';

ValueCodecRegistry augmentSqliteCodecs(ValueCodecRegistry registry) {
  registry.registerCodecFor(bool, const SqliteBoolCodec());
  registry.registerCodec(key: 'bool?', codec: const SqliteBoolCodec());
  registry.registerCodecFor(DateTime, const SqliteDateTimeCodec());
  registry.registerCodec(key: 'DateTime?', codec: const SqliteDateTimeCodec());
  registry.registerCodecFor(double, const SqliteDoubleCodec());
  registry.registerCodec(key: 'double?', codec: const SqliteDoubleCodec());
  registry.registerCodec(key: 'json', codec: const SqliteJsonCodec());
  return registry;
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
  Object? encode(DateTime? value) => value?.toUtc().toIso8601String();

  @override
  DateTime? decode(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.parse(value as String);
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
