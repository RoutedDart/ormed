import 'dart:convert';

import 'package:ormed/ormed.dart';

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
      acceptedSqlTypes: ['REAL', 'FLOAT4', 'FLOAT8', 'NUMERIC', 'DECIMAL'],
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

    // TIMESTAMP types
    TypeMapping(
      dartType: DateTime,
      defaultSqlType: 'TIMESTAMP',
      acceptedSqlTypes: [
        'TIMESTAMPTZ',
        'TIMESTAMP WITH TIME ZONE',
        'TIMESTAMP WITHOUT TIME ZONE',
        'DATE',
        'TIME',
        'TIMETZ',
        'TIME WITH TIME ZONE',
        'TIME WITHOUT TIME ZONE',
      ],
    ),

    // BYTEA (binary data)
    TypeMapping(dartType: List<int>, defaultSqlType: 'BYTEA'),

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
    final baseType = cleaned.split(RegExp(r'[\s(]'))[0];

    // Map PostgreSQL type aliases
    if (_integerTypes.contains(baseType)) return 'INTEGER';
    if (_floatTypes.contains(baseType)) return 'DOUBLE PRECISION';
    if (_textTypes.contains(baseType)) return 'TEXT';
    if (_timestampTypes.contains(baseType)) return 'TIMESTAMP';
    if (_binaryTypes.contains(baseType)) return 'BYTEA';
    if (_jsonTypes.contains(baseType)) return 'JSONB';
    if (_boolTypes.contains(baseType)) return 'BOOLEAN';

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
    'DOUBLE PRECISION',
    'NUMERIC',
    'DECIMAL',
  };

  static const _textTypes = {
    'TEXT',
    'VARCHAR',
    'CHARACTER VARYING',
    'CHAR',
    'CHARACTER',
    'NAME',
  };

  static const _timestampTypes = {
    'TIMESTAMP',
    'TIMESTAMPTZ',
    'TIMESTAMP WITH TIME ZONE',
    'TIMESTAMP WITHOUT TIME ZONE',
    'DATE',
    'TIME',
    'TIMETZ',
    'TIME WITH TIME ZONE',
    'TIME WITHOUT TIME ZONE',
  };

  static const _binaryTypes = {'BYTEA'};

  static const _jsonTypes = {'JSON', 'JSONB'};

  static const _boolTypes = {'BOOLEAN', 'BOOL'};

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
