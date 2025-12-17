import 'dart:convert';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:ormed/ormed.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid_value.dart';

import 'postgres_value_types.dart';

/// PostgreSQL-specific type mapper
///
/// PostgreSQL has a rich type system with strict typing.
/// This mapper handles conversions between Dart types and PostgreSQL column types.
class PostgresTypeMapper extends DriverTypeMapper {
  @override
  String get driverName => 'postgres';

  @override
  List<TypeMapping> get typeMappings => [
    // INTEGER types
    TypeMapping(
      dartType: int,
      defaultSqlType: 'INTEGER',
      acceptedSqlTypes: [
        'SMALLINT',
        'INT',
        'INT2',
        'INT4',
        'BIGINT',
        'INT8',
        'SERIAL',
        'SERIAL4',
        'BIGSERIAL',
        'SERIAL8',
      ],
    ),

    // BOOLEAN (native boolean type)
    TypeMapping(
      dartType: bool,
      defaultSqlType: 'BOOLEAN',
      acceptedSqlTypes: ['BOOL'],
    ),

    // FLOAT types
    TypeMapping(
      dartType: double,
      defaultSqlType: 'DOUBLE PRECISION',
      acceptedSqlTypes: ['REAL', 'FLOAT4', 'FLOAT8', 'DOUBLE'],
    ),

    // NUMERIC/DECIMAL
    TypeMapping(
      dartType: Decimal,
      defaultSqlType: 'NUMERIC',
      acceptedSqlTypes: ['DECIMAL'],
    ),

    // TEXT types
    TypeMapping(
      dartType: String,
      defaultSqlType: 'TEXT',
      acceptedSqlTypes: [
        'VARCHAR',
        'CHARACTER VARYING',
        'CHAR',
        'CHARACTER',
        'NAME',
      ],
    ),

    // UUID
    TypeMapping(dartType: UuidValue, defaultSqlType: 'UUID'),

    // UUID arrays
    TypeMapping(dartType: List<UuidValue>, defaultSqlType: 'UUID[]'),

    // TEXT arrays
    TypeMapping(dartType: List<String>, defaultSqlType: 'TEXT[]'),

    // INTEGER arrays
    TypeMapping(dartType: List<int>, defaultSqlType: 'INTEGER[]'),

    // BOOLEAN arrays
    TypeMapping(dartType: List<bool>, defaultSqlType: 'BOOLEAN[]'),

    // DOUBLE arrays
    TypeMapping(dartType: List<double>, defaultSqlType: 'DOUBLE PRECISION[]'),

    // TIMESTAMP types
    TypeMapping(
      dartType: DateTime,
      defaultSqlType: 'TIMESTAMP',
      acceptedSqlTypes: [
        'TIMESTAMPTZ',
        'TIMESTAMP WITH TIME ZONE',
        'TIMESTAMP WITHOUT TIME ZONE',
        'DATE',
      ],
    ),

    // TIME (without time zone)
    TypeMapping(
      dartType: Time,
      defaultSqlType: 'TIME',
      acceptedSqlTypes: ['TIME WITHOUT TIME ZONE'],
    ),

    // TIME WITH TIME ZONE (timetz)
    TypeMapping(
      dartType: PgTimeTz,
      defaultSqlType: 'TIMETZ',
      acceptedSqlTypes: ['TIME WITH TIME ZONE'],
    ),

    // TIMESTAMP arrays
    TypeMapping(
      dartType: List<DateTime>,
      defaultSqlType: 'TIMESTAMPTZ[]',
      acceptedSqlTypes: ['TIMESTAMP[]'],
    ),

    // INTERVAL
    TypeMapping(dartType: Interval, defaultSqlType: 'INTERVAL'),

    // Full text search
    TypeMapping(dartType: TsVector, defaultSqlType: 'TSVECTOR'),
    TypeMapping(dartType: TsQuery, defaultSqlType: 'TSQUERY'),

    // Range types
    TypeMapping(
      dartType: IntRange,
      defaultSqlType: 'INT4RANGE',
      acceptedSqlTypes: ['INT8RANGE'],
    ),
    TypeMapping(dartType: DateRange, defaultSqlType: 'DATERANGE'),
    TypeMapping(
      dartType: DateTimeRange,
      defaultSqlType: 'TSRANGE',
      acceptedSqlTypes: ['TSTZRANGE'],
    ),

    // Network types
    TypeMapping(dartType: PgInet, defaultSqlType: 'INET'),
    TypeMapping(dartType: PgCidr, defaultSqlType: 'CIDR'),
    TypeMapping(
      dartType: PgMacAddress,
      defaultSqlType: 'MACADDR',
      acceptedSqlTypes: ['MACADDR8'],
    ),

    // BIT/VARBIT
    TypeMapping(
      dartType: PgBitString,
      defaultSqlType: 'VARBIT',
      acceptedSqlTypes: ['BIT', 'BIT VARYING'],
    ),

    // MONEY
    TypeMapping(dartType: PgMoney, defaultSqlType: 'MONEY'),

    // pg_lsn
    TypeMapping(dartType: LSN, defaultSqlType: 'PG_LSN'),

    // pg_snapshot / txid_snapshot
    TypeMapping(
      dartType: PgSnapshot,
      defaultSqlType: 'PG_SNAPSHOT',
      acceptedSqlTypes: ['TXID_SNAPSHOT'],
    ),

    // Geometric types
    TypeMapping(dartType: Point, defaultSqlType: 'POINT'),
    TypeMapping(dartType: Line, defaultSqlType: 'LINE'),
    TypeMapping(dartType: LineSegment, defaultSqlType: 'LSEG'),
    TypeMapping(dartType: Box, defaultSqlType: 'BOX'),
    TypeMapping(dartType: Path, defaultSqlType: 'PATH'),
    TypeMapping(dartType: Polygon, defaultSqlType: 'POLYGON'),
    TypeMapping(dartType: Circle, defaultSqlType: 'CIRCLE'),

    // pgvector (extension-backed)
    TypeMapping(dartType: PgVector, defaultSqlType: 'VECTOR'),

    // BYTEA (binary data)
    TypeMapping(dartType: Uint8List, defaultSqlType: 'BYTEA'),

    // JSON types
    TypeMapping(
      dartType: Map,
      defaultSqlType: 'JSONB',
      acceptedSqlTypes: ['JSON'],
      codec: _JsonCodec(),
    ),
  ];

  @override
  String normalizeSqlType(String sqlType) {
    final cleaned = sqlType.trim().toUpperCase();
    if (cleaned.isEmpty) return cleaned;

    if (cleaned.endsWith('[]')) {
      final element = cleaned.substring(0, cleaned.length - 2).trim();
      final normalizedElement = normalizeSqlType(element);
      return '$normalizedElement[]';
    }

    if (cleaned.startsWith('TIMESTAMPTZ') ||
        cleaned.startsWith('TIMESTAMP WITH TIME ZONE') ||
        cleaned.startsWith('TIMESTAMP WITHOUT TIME ZONE') ||
        cleaned.startsWith('TIMESTAMP')) {
      return 'TIMESTAMP';
    }
    if (cleaned.startsWith('TIME WITH TIME ZONE') ||
        cleaned.startsWith('TIMETZ')) {
      return 'TIMETZ';
    }
    if (cleaned.startsWith('TIME')) {
      return 'TIME';
    }

    final baseType = cleaned.split(RegExp(r'[\s(]'))[0];

    // Map PostgreSQL type aliases
    if (_integerTypes.contains(baseType)) return 'INTEGER';
    if (_floatTypes.contains(baseType)) return 'DOUBLE PRECISION';
    if (_textTypes.contains(baseType)) return 'TEXT';
    if (_dateTypes.contains(baseType)) return 'DATE';
    if (_binaryTypes.contains(baseType)) return 'BYTEA';
    if (_jsonTypes.contains(baseType)) return 'JSONB';
    if (_boolTypes.contains(baseType)) return 'BOOLEAN';
    if (_numericTypes.contains(baseType)) return 'NUMERIC';
    if (_uuidTypes.contains(baseType)) return 'UUID';
    if (_intervalTypes.contains(baseType)) return 'INTERVAL';
    if (_fullTextTypes.contains(baseType)) return baseType;
    if (_rangeTypes.contains(baseType)) return baseType;
    if (_networkTypes.contains(baseType)) return baseType;
    if (_bitTypes.contains(baseType)) {
      if (cleaned.startsWith('BIT VARYING') || baseType == 'VARBIT') {
        return 'VARBIT';
      }
      return 'BIT';
    }
    if (_moneyTypes.contains(baseType)) return 'MONEY';
    if (_pgLsnTypes.contains(baseType)) return 'PG_LSN';
    if (_snapshotTypes.contains(baseType)) return baseType;
    if (_vectorTypes.contains(baseType)) return 'VECTOR';

    return baseType;
  }

  static const _integerTypes = {
    'INTEGER',
    'INT',
    'INT2',
    'INT4',
    'INT8',
    'SMALLINT',
    'BIGINT',
    'SERIAL',
    'SERIAL4',
    'BIGSERIAL',
    'SERIAL8',
  };

  static const _floatTypes = {
    'REAL',
    'FLOAT4',
    'FLOAT8',
    'DOUBLE',
    'DOUBLE PRECISION',
  };

  static const _numericTypes = {'NUMERIC', 'DECIMAL'};

  static const _textTypes = {
    'TEXT',
    'VARCHAR',
    'CHARACTER VARYING',
    'CHAR',
    'CHARACTER',
    'NAME',
  };

  static const _dateTypes = {'DATE'};

  static const _binaryTypes = {'BYTEA'};

  static const _jsonTypes = {'JSON', 'JSONB'};

  static const _boolTypes = {'BOOLEAN', 'BOOL'};

  static const _uuidTypes = {'UUID'};

  static const _intervalTypes = {'INTERVAL'};

  static const _fullTextTypes = {'TSVECTOR', 'TSQUERY'};

  static const _rangeTypes = {
    'INT4RANGE',
    'INT8RANGE',
    'DATERANGE',
    'TSRANGE',
    'TSTZRANGE',
    'NUMRANGE',
  };

  static const _networkTypes = {'INET', 'CIDR', 'MACADDR', 'MACADDR8'};

  static const _bitTypes = {'BIT', 'VARBIT'};

  static const _moneyTypes = {'MONEY', 'CASH'};

  static const _pgLsnTypes = {'PG_LSN'};

  static const _snapshotTypes = {'PG_SNAPSHOT', 'TXID_SNAPSHOT'};

  static const _vectorTypes = {'VECTOR'};

  @override
  bool supportsUnsigned(String sqlType) => false; // PostgreSQL doesn't have UNSIGNED
}

// PostgreSQL-specific codecs

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
