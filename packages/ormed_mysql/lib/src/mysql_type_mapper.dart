import 'dart:convert';

import 'package:ormed/ormed.dart';

/// MySQL/MariaDB-specific type mapper
///
/// MySQL has a comprehensive type system with various integer, string, and temporal types.
/// Booleans are stored as TINYINT(1), and DateTimes may be returned as strings.
class MysqlTypeMapper extends DriverTypeMapper {
  @override
  String get driverName => 'mysql';

  @override
  List<TypeMapping> get typeMappings => [
    // INTEGER types
    TypeMapping(
      dartType: int,
      defaultSqlType: 'INT',
      acceptedSqlTypes: [
        'TINYINT',
        'SMALLINT',
        'MEDIUMINT',
        'INTEGER',
        'BIGINT',
      ],
    ),

    // BOOLEAN (stored as TINYINT(1) in MySQL)
    TypeMapping(
      dartType: bool,
      defaultSqlType: 'TINYINT',
      acceptedSqlTypes: ['BOOLEAN', 'BOOL'],
      codec: _BoolCodec(),
    ),

    // FLOAT types
    TypeMapping(
      dartType: double,
      defaultSqlType: 'DOUBLE',
      acceptedSqlTypes: ['FLOAT', 'DECIMAL', 'NUMERIC'],
    ),

    // TEXT types
    TypeMapping(
      dartType: String,
      defaultSqlType: 'VARCHAR',
      acceptedSqlTypes: ['CHAR', 'TEXT', 'TINYTEXT', 'MEDIUMTEXT', 'LONGTEXT'],
    ),

    // DATETIME types (may be returned as String from MySQL)
    TypeMapping(
      dartType: DateTime,
      defaultSqlType: 'DATETIME',
      acceptedSqlTypes: ['TIMESTAMP', 'DATE', 'TIME'],
      codec: _DateTimeCodec(),
    ),

    // BINARY types
    TypeMapping(
      dartType: List<int>,
      defaultSqlType: 'BLOB',
      acceptedSqlTypes: [
        'BINARY',
        'VARBINARY',
        'TINYBLOB',
        'MEDIUMBLOB',
        'LONGBLOB',
      ],
    ),

    // JSON type
    TypeMapping(dartType: Map, defaultSqlType: 'JSON', codec: _JsonCodec()),
  ];

  @override
  String normalizeSqlType(String sqlType) {
    final cleaned = sqlType.trim().toUpperCase();

    // Special case: TINYINT(1) is treated as BOOLEAN
    if (cleaned.contains('TINYINT(1)') ||
        cleaned == 'BOOLEAN' ||
        cleaned == 'BOOL') {
      return 'TINYINT'; // Will map to bool via codec
    }

    final baseType = cleaned.split(RegExp(r'[\s(]'))[0];

    // Map MySQL type aliases
    if (_integerTypes.contains(baseType)) return 'INT';
    if (_floatTypes.contains(baseType)) return 'DOUBLE';
    if (_textTypes.contains(baseType)) return 'VARCHAR';
    if (_dateTimeTypes.contains(baseType)) return 'DATETIME';
    if (_binaryTypes.contains(baseType)) return 'BLOB';
    if (_jsonTypes.contains(baseType)) return 'JSON';

    return baseType;
  }

  static const _integerTypes = {
    'TINYINT',
    'SMALLINT',
    'MEDIUMINT',
    'INT',
    'INTEGER',
    'BIGINT',
  };

  static const _floatTypes = {'FLOAT', 'DOUBLE', 'DECIMAL', 'NUMERIC'};

  static const _textTypes = {
    'CHAR',
    'VARCHAR',
    'TEXT',
    'TINYTEXT',
    'MEDIUMTEXT',
    'LONGTEXT',
  };

  static const _dateTimeTypes = {
    'DATE',
    'DATETIME',
    'TIMESTAMP',
    'TIME',
    'YEAR',
  };

  static const _binaryTypes = {
    'BINARY',
    'VARBINARY',
    'BLOB',
    'TINYBLOB',
    'MEDIUMBLOB',
    'LONGBLOB',
  };

  static const _jsonTypes = {'JSON'};

  @override
  bool supportsUnsigned(String sqlType) => true; // MySQL supports UNSIGNED

  @override
  String applySqlTypeModifiers(
    String baseType, {
    int? maxLength,
    int? precision,
    int? scale,
    bool unsigned = false,
    bool autoIncrement = false,
  }) {
    var result = super.applySqlTypeModifiers(
      baseType,
      maxLength: maxLength,
      precision: precision,
      scale: scale,
      unsigned: false, // Handle separately
      autoIncrement: autoIncrement,
    );

    if (unsigned && supportsUnsigned(baseType)) {
      result = '$result UNSIGNED';
    }

    return result;
  }
}

// MySQL-specific codecs

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

class _DateTimeCodec extends ValueCodec<DateTime> {
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
  dynamic encode(DateTime? value) => value?.toIso8601String();
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
