import 'dart:convert';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:ormed/ormed.dart';
import 'package:uuid/uuid_value.dart';

import 'mysql_codecs.dart';
import 'mysql_value_types.dart';

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
        'INT',
        'INTEGER',
        'BIGINT',
        'YEAR',
      ],
    ),

    // BOOLEAN (stored as TINYINT(1) in MySQL)
    TypeMapping(
      dartType: bool,
      defaultSqlType: 'TINYINT',
      acceptedSqlTypes: ['BOOLEAN', 'BOOL'],
      codec: MySqlBoolCodec(),
    ),

    // FLOAT types
    TypeMapping(
      dartType: double,
      defaultSqlType: 'DOUBLE',
      acceptedSqlTypes: ['FLOAT', 'REAL'],
    ),

    // NUMERIC/DECIMAL (exact)
    TypeMapping(
      dartType: Decimal,
      defaultSqlType: 'DECIMAL',
      acceptedSqlTypes: ['DECIMAL', 'NUMERIC', 'FIXED'],
      codec: MySqlDecimalCodec(),
    ),

    // TEXT types
    TypeMapping(
      dartType: String,
      defaultSqlType: 'VARCHAR',
      acceptedSqlTypes: [
        'CHAR',
        'VARCHAR',
        'TEXT',
        'TINYTEXT',
        'MEDIUMTEXT',
        'LONGTEXT',
        'ENUM',
      ],
    ),

    // DATETIME/DATE types
    TypeMapping(
      dartType: DateTime,
      defaultSqlType: 'DATETIME',
      acceptedSqlTypes: ['TIMESTAMP', 'DATE'],
      codec: MySqlDateTimeCodec(),
    ),

    // TIME (duration)
    TypeMapping(
      dartType: Duration,
      defaultSqlType: 'TIME',
      acceptedSqlTypes: ['TIME'],
      codec: MySqlDurationCodec(),
    ),

    // UUID (MariaDB supports UUID; migrations default to CHAR(36) on MySQL)
    TypeMapping(
      dartType: UuidValue,
      defaultSqlType: 'CHAR(36)',
      acceptedSqlTypes: ['UUID'],
      codec: MySqlUuidValueCodec(),
    ),

    // SET (stored as comma-separated values)
    TypeMapping(
      dartType: Set<String>,
      defaultSqlType: 'SET',
      acceptedSqlTypes: ['SET'],
      codec: MySqlStringSetCodec(),
    ),

    // BIT
    TypeMapping(
      dartType: MySqlBitString,
      defaultSqlType: 'BIT',
      acceptedSqlTypes: ['BIT'],
      codec: MySqlBitStringCodec(),
    ),

    // GEOMETRY + common spatial aliases
    TypeMapping(
      dartType: MySqlGeometry,
      defaultSqlType: 'GEOMETRY',
      acceptedSqlTypes: [
        'GEOMETRY',
        'POINT',
        'LINESTRING',
        'POLYGON',
        'MULTIPOINT',
        'MULTILINESTRING',
        'MULTIPOLYGON',
        'GEOMETRYCOLLECTION',
      ],
      codec: MySqlGeometryCodec(),
    ),

    // BINARY types
    TypeMapping(
      dartType: List<int>,
      defaultSqlType: 'BLOB',
      acceptedSqlTypes: [
        'BINARY',
        'VARBINARY',
        'BLOB',
        'TINYBLOB',
        'MEDIUMBLOB',
        'LONGBLOB',
        'GEOMETRY',
        'BIT',
      ],
    ),

    // BINARY types (mysql_client_plus returns Uint8List)
    TypeMapping(
      dartType: Uint8List,
      defaultSqlType: 'BLOB',
      acceptedSqlTypes: ['BLOB', 'TINYBLOB', 'MEDIUMBLOB', 'LONGBLOB'],
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
    if (_decimalTypes.contains(baseType)) return 'DECIMAL';
    if (_textTypes.contains(baseType)) return 'VARCHAR';
    if (_dateTimeTypes.contains(baseType)) return baseType;
    if (_binaryTypes.contains(baseType)) return 'BLOB';
    if (_bitTypes.contains(baseType)) return 'BIT';
    if (_geometryTypes.contains(baseType)) return 'GEOMETRY';
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
    'YEAR',
  };

  static const _floatTypes = {'FLOAT', 'DOUBLE', 'REAL'};

  static const _decimalTypes = {'DECIMAL', 'NUMERIC', 'FIXED'};

  static const _textTypes = {
    'CHAR',
    'VARCHAR',
    'TEXT',
    'TINYTEXT',
    'MEDIUMTEXT',
    'LONGTEXT',
  };

  static const _dateTimeTypes = {'DATE', 'DATETIME', 'TIMESTAMP', 'TIME'};

  static const _binaryTypes = {
    'BINARY',
    'VARBINARY',
    'BLOB',
    'TINYBLOB',
    'MEDIUMBLOB',
    'LONGBLOB',
  };

  static const _bitTypes = {'BIT'};

  static const _geometryTypes = {
    'GEOMETRY',
    'POINT',
    'LINESTRING',
    'POLYGON',
    'MULTIPOINT',
    'MULTILINESTRING',
    'MULTIPOLYGON',
    'GEOMETRYCOLLECTION',
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
