import 'dart:convert';

import '../src/value_codec.dart';

/// SQLite-specific codec that stores JSON scalars directly as strings.
class SqlitePayloadCodec extends ValueCodec<Map<String, Object?>> {
  const SqlitePayloadCodec();

  @override
  Object? encode(Map<String, Object?>? value) {
    if (value == null) return null;
    return jsonEncode(value);
  }

  @override
  Map<String, Object?>? decode(Object? value) {
    if (value == null) return null;
    final input = value as String;
    final decoded = jsonDecode(input) as Map<String, dynamic>;
    return Map<String, Object?>.from(decoded);
  }
}

/// Postgres-specific codec that stores JSON bodies directly as JSONB.
class PostgresPayloadCodec extends ValueCodec<Map<String, Object?>> {
  const PostgresPayloadCodec();

  @override
  Object? encode(Map<String, Object?>? value) {
    if (value == null) return null;
    return {
      ...value,
      'encoded_by': 'postgres',
    };
  }

  @override
  Map<String, Object?>? decode(Object? value) {
    if (value == null) return null;
    if (value is Map) {
      final map = Map<String, Object?>.from(value);
      map.remove('encoded_by');
      return map;
    }
    throw FormatException('Invalid payload format: $value');
  }
}

/// MariaDB-specific codec that piggybacks on the Postgres payload structure.
class MariaDbPayloadCodec extends ValueCodec<Map<String, Object?>> {
  const MariaDbPayloadCodec();

  @override
  Object? encode(Map<String, Object?>? value) {
    if (value == null) return null;
    return jsonEncode(value);
  }

  @override
  Map<String, Object?>? decode(Object? value) {
    if (value == null) return null;
    final String input;
    if (value is String) {
      input = value;
    } else if (value is List<int>) {
      input = utf8.decode(value);
    } else if (value is Map) {
      return Map<String, Object?>.from(value.cast<String, Object?>());
    } else {
      input = value.toString();
    }
    final decoded = jsonDecode(input) as Map<String, dynamic>;
    return Map<String, Object?>.from(decoded);
  }
}
