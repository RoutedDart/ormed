import 'dart:convert';

import 'package:carbonized/carbonized.dart';
import 'package:ormed/ormed.dart';

import 'sqlite_codecs.dart';

/// SQLite-specific type mapper
///
/// SQLite has a flexible type system with type affinity:
/// - NULL, INTEGER, REAL, TEXT, BLOB
///
/// This mapper handles the conversion between Dart types and SQLite column types,
/// including common type aliases like VARCHAR, CHAR, etc.
class SqliteTypeMapper extends DriverTypeMapper {
  @override
  String get driverName => 'sqlite';

  @override
  List<TypeMapping> get typeMappings => [
        // INTEGER affinity
        TypeMapping(
          dartType: int,
          defaultSqlType: 'INTEGER',
          acceptedSqlTypes: [
            'INT',
            'TINYINT',
            'SMALLINT',
            'MEDIUMINT',
            'BIGINT',
            'INT2',
            'INT8',
          ],
          codec: _IntCodec(),
        ),

        // BOOLEAN (stored as INTEGER in SQLite: 0 or 1)
        TypeMapping(
          dartType: bool,
          defaultSqlType: 'INTEGER',
          acceptedSqlTypes: ['BOOLEAN', 'BOOL'],
          codec: _BoolCodec(),
        ),

        // REAL affinity
        TypeMapping(
          dartType: double,
          defaultSqlType: 'REAL',
          acceptedSqlTypes: [
            'DOUBLE',
            'FLOAT',
            'NUMERIC',
            'DECIMAL',
          ],
          codec: _DoubleCodec(),
        ),

        // TEXT affinity
        TypeMapping(
          dartType: String,
          defaultSqlType: 'TEXT',
          acceptedSqlTypes: [
            'VARCHAR',
            'CHAR',
            'CLOB',
            'CHARACTER',
            'VARYING CHARACTER',
            'NCHAR',
            'NATIVE CHARACTER',
            'NVARCHAR',
          ],
        ),

        // DATETIME (stored as TEXT in ISO8601 format)
        TypeMapping(
          dartType: DateTime,
          defaultSqlType: 'TEXT',
          acceptedSqlTypes: ['DATETIME', 'TIMESTAMP', 'DATE', 'TIME'],
          codec: _DateTimeCodec(),
        ),

        // Carbon (stored as TEXT in ISO8601 format)
        TypeMapping(
          dartType: Carbon,
          defaultSqlType: 'TEXT',
          acceptedSqlTypes: ['DATETIME', 'TIMESTAMP', 'DATE', 'TIME'],
          codec: SqliteCarbonCodec(),
        ),

        // CarbonInterface (stored as TEXT in ISO8601 format)
        TypeMapping(
          dartType: CarbonInterface,
          defaultSqlType: 'TEXT',
          acceptedSqlTypes: ['DATETIME', 'TIMESTAMP', 'DATE', 'TIME'],
          codec: SqliteCarbonInterfaceCodec(),
        ),

        // BLOB affinity
        TypeMapping(
          dartType: List<int>,
          defaultSqlType: 'BLOB',
          acceptedSqlTypes: ['BYTEA'],
        ),

        // JSON (stored as TEXT)
        TypeMapping(
          dartType: Map,
          defaultSqlType: 'TEXT',
          acceptedSqlTypes: ['JSON', 'JSONB'],
          codec: _JsonCodec(),
        ),
      ];

  @override
  String normalizeSqlType(String sqlType) {
    // SQLite is case-insensitive and ignores most type decorations
    final cleaned = sqlType.trim().toUpperCase();

    // Extract base type
    final baseType = cleaned.split(RegExp(r'[\s(]'))[0];

    // Map common aliases to SQLite affinities
    if (_integerTypes.contains(baseType)) return 'INTEGER';
    if (_realTypes.contains(baseType)) return 'REAL';
    if (_textTypes.contains(baseType)) return 'TEXT';
    if (_blobTypes.contains(baseType)) return 'BLOB';
    if (_dateTimeTypes.contains(baseType)) return 'TEXT'; // DATETIME stored as TEXT
    if (_jsonTypes.contains(baseType)) return 'TEXT'; // JSON stored as TEXT

    return baseType;
  }

  static const _integerTypes = {
    'INTEGER',
    'INT',
    'TINYINT',
    'SMALLINT',
    'MEDIUMINT',
    'BIGINT',
    'INT2',
    'INT8',
    'BOOLEAN',
    'BOOL',
  };

  static const _realTypes = {
    'REAL',
    'DOUBLE',
    'FLOAT',
    'NUMERIC',
    'DECIMAL',
  };

  static const _textTypes = {
    'TEXT',
    'VARCHAR',
    'CHAR',
    'CLOB',
    'CHARACTER',
    'NCHAR',
    'NVARCHAR',
  };

  static const _blobTypes = {
    'BLOB',
    'BYTEA',
  };

  static const _dateTimeTypes = {
    'DATETIME',
    'TIMESTAMP',
    'DATE',
    'TIME',
  };

  static const _jsonTypes = {
    'JSON',
    'JSONB',
  };

  @override
  bool supportsUnsigned(String sqlType) => false; // SQLite doesn't have UNSIGNED

  @override
  String applySqlTypeModifiers(
    String baseType, {
    int? maxLength,
    int? precision,
    int? scale,
    bool unsigned = false,
    bool autoIncrement = false,
  }) {
    // SQLite ignores most type modifiers but we can include them for documentation
    var result = baseType;

    if (maxLength != null && supportsLength(baseType)) {
      result = '$result($maxLength)';
    } else if (precision != null && supportsDecimal(baseType)) {
      if (scale != null) {
        result = '$result($precision, $scale)';
      } else {
        result = '$result($precision)';
      }
    }

    // Note: SQLite doesn't enforce UNSIGNED, but we document it
    // Note: AUTOINCREMENT is a constraint, not a type modifier in SQLite

    return result;
  }
}

// SQLite-specific codecs

class _IntCodec extends ValueCodec<int> {
  @override
  int? decode(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }

  @override
  dynamic encode(int? value) => value;
}

class _BoolCodec extends ValueCodec<bool> {
  @override
  bool? decode(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return null;
  }

  @override
  dynamic encode(bool? value) => value == null ? null : (value ? 1 : 0);
}

class _DoubleCodec extends ValueCodec<double> {
  @override
  double? decode(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  @override
  dynamic encode(double? value) => value;
}

class _DateTimeCodec extends ValueCodec<dynamic> {
  @override
  DateTime? decode(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) {
      // Unix timestamp in milliseconds
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }

  @override
  dynamic encode(dynamic value) {
    if (value == null) return null;
    // Handle any object with toIso8601String method (DateTime, Carbon, etc.)
    if (value is DateTime) {
      return value.toIso8601String();
    }
    // Try to call toIso8601String if it exists (for Carbon/CarbonInterface)
    try {
      return (value as dynamic).toIso8601String();
    } catch (_) {
      // Fallback: return the value as-is
      return value;
    }
  }
}

class _JsonCodec extends ValueCodec<Map> {
  @override
  Map? decode(dynamic value) {
    if (value == null) return null;
    if (value is Map) return value;
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        return decoded is Map ? decoded : null;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  dynamic encode(Map? value) => value == null ? null : jsonEncode(value);
}
