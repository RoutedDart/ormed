# Type System Design: SQLite Example

## Overview

The type system needs a **tiered resolution strategy** that maps between:
1. **Dart types** (e.g., `String`, `int`, `DateTime`)
2. **SQL types** (e.g., `TEXT`, `INTEGER`, `REAL`)
3. **Database runtime types** (what comes back from queries)
4. **Codec transformations** (encoding/decoding)

## Current Problems

1. **No centralized type mapping** - Each component guesses independently
2. **Codec registry doesn't know about SQL types** - Only works with Dart types
3. **Schema inspector returns raw SQL types** - No normalization or Dart type inference
4. **Generator lacks type context** - Can't determine proper codec without SQL context
5. **Driver-specific quirks not handled** - SQLite TEXT can be datetime, bool, json, etc.

## Proposed Solution: SQLite Type Mapper

### 1. Core Type Mapper Interface

```dart
/// Maps between Dart types, SQL types, and runtime values for a specific driver
abstract class TypeMapper {
  /// Get SQL type for a Dart type (used during schema generation)
  String dartToSql(Type dartType, {TypeHints? hints});
  
  /// Get Dart type from SQL type (used by schema inspector)
  Type sqlToDart(String sqlType);
  
  /// Get codec for a given Dart type and optional SQL type context
  ValueCodec? getCodec(Type dartType, {String? sqlType});
  
  /// Normalize SQL type string (e.g., "VARCHAR(255)" -> "VARCHAR")
  String normalizeSqlType(String sqlType);
  
  /// Check if SQL type needs special codec handling
  bool requiresCustomCodec(String sqlType, Type dartType);
}

/// Hints for type resolution
class TypeHints {
  final int? maxLength;
  final int? precision;
  final int? scale;
  final bool autoIncrement;
  final bool unsigned;
  final String? customSqlType; // User override
  
  const TypeHints({
    this.maxLength,
    this.precision,
    this.scale,
    this.autoIncrement = false,
    this.unsigned = false,
    this.customSqlType,
  });
}
```

### 2. SQLite Type Mapper Implementation

```dart
class SqliteTypeMapper implements TypeMapper {
  // ============================================================================
  // DART -> SQL TYPE MAPPING (for schema generation)
  // ============================================================================
  
  static const Map<Type, String> _dartToSqlMap = {
    String: 'TEXT',
    int: 'INTEGER',
    double: 'REAL',
    bool: 'INTEGER',  // SQLite uses 0/1
    DateTime: 'TEXT',  // ISO8601 strings by default
    Uint8List: 'BLOB',
  };
  
  @override
  String dartToSql(Type dartType, {TypeHints? hints}) {
    // 1. Check for user override
    if (hints?.customSqlType != null) {
      return hints!.customSqlType!;
    }
    
    // 2. Check auto-increment (must be INTEGER)
    if (hints?.autoIncrement == true) {
      return 'INTEGER';
    }
    
    // 3. Look up in standard mapping
    final sqlType = _dartToSqlMap[dartType];
    if (sqlType != null) {
      return sqlType;
    }
    
    // 4. Check for nullable types
    if (dartType.toString().endsWith('?')) {
      final baseType = _extractBaseType(dartType);
      return dartToSql(baseType, hints: hints);
    }
    
    // 5. Default to TEXT for unknown types
    return 'TEXT';
  }
  
  // ============================================================================
  // SQL -> DART TYPE MAPPING (for schema inspector)
  // ============================================================================
  
  static const Map<String, Type> _sqlToDartMap = {
    'TEXT': String,
    'INTEGER': int,
    'REAL': double,
    'BLOB': Uint8List,
    'NUMERIC': num,
    'NULL': Object, // SQLite NULL affinity
  };
  
  @override
  Type sqlToDart(String sqlType) {
    final normalized = normalizeSqlType(sqlType);
    
    // Check exact match
    final dartType = _sqlToDartMap[normalized];
    if (dartType != null) {
      return dartType;
    }
    
    // SQLite type affinity rules
    // https://www.sqlite.org/datatype3.html
    
    if (_containsAny(normalized, ['INT'])) {
      return int;
    }
    
    if (_containsAny(normalized, ['CHAR', 'CLOB', 'TEXT'])) {
      return String;
    }
    
    if (_containsAny(normalized, ['BLOB'])) {
      return Uint8List;
    }
    
    if (_containsAny(normalized, ['REAL', 'FLOA', 'DOUB'])) {
      return double;
    }
    
    // Default to String (most permissive)
    return String;
  }
  
  // ============================================================================
  // CODEC RESOLUTION (for runtime encoding/decoding)
  // ============================================================================
  
  @override
  ValueCodec? getCodec(Type dartType, {String? sqlType}) {
    // Special cases where SQL type affects codec choice
    
    // 1. DateTime stored as INTEGER (unix timestamp)
    if (dartType == DateTime && sqlType != null) {
      final normalized = normalizeSqlType(sqlType);
      if (normalized == 'INTEGER') {
        return UnixTimestampCodec();
      }
      // Default: ISO8601 string (stored as TEXT)
      return Iso8601DateTimeCodec();
    }
    
    // 2. Boolean stored as INTEGER (0/1)
    if (dartType == bool) {
      return SqliteBooleanCodec(); // Converts 0/1 <-> bool
    }
    
    // 3. JSON stored as TEXT
    if (dartType.toString().startsWith('Map<') || 
        dartType.toString().startsWith('List<')) {
      return JsonCodec();
    }
    
    // 4. Standard types use identity codec
    if (_dartToSqlMap.containsKey(dartType)) {
      return IdentityCodec(dartType);
    }
    
    return null; // Let registry handle it
  }
  
  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  @override
  String normalizeSqlType(String sqlType) {
    // Remove size/precision: VARCHAR(255) -> VARCHAR
    final typeOnly = sqlType.toUpperCase().split('(').first.trim();
    
    // SQLite is case-insensitive and flexible
    // Map common aliases to canonical types
    const aliases = {
      'VARCHAR': 'TEXT',
      'CHARACTER': 'TEXT',
      'VARYING CHARACTER': 'TEXT',
      'NCHAR': 'TEXT',
      'NATIVE CHARACTER': 'TEXT',
      'NVARCHAR': 'TEXT',
      'CLOB': 'TEXT',
      'INT': 'INTEGER',
      'TINYINT': 'INTEGER',
      'SMALLINT': 'INTEGER',
      'MEDIUMINT': 'INTEGER',
      'BIGINT': 'INTEGER',
      'UNSIGNED BIG INT': 'INTEGER',
      'INT2': 'INTEGER',
      'INT8': 'INTEGER',
      'FLOAT': 'REAL',
      'DOUBLE': 'REAL',
      'DOUBLE PRECISION': 'REAL',
    };
    
    return aliases[typeOnly] ?? typeOnly;
  }
  
  @override
  bool requiresCustomCodec(String sqlType, Type dartType) {
    final normalized = normalizeSqlType(sqlType);
    
    // Cases where runtime type doesn't match Dart type
    return (dartType == DateTime) ||  // Stored as TEXT or INTEGER
           (dartType == bool) ||      // Stored as INTEGER
           (normalized == 'TEXT' && dartType != String);  // JSON, etc.
  }
  
  bool _containsAny(String str, List<String> substrings) {
    return substrings.any((s) => str.contains(s));
  }
  
  Type _extractBaseType(Type nullableType) {
    // Remove '?' from type string
    final typeStr = nullableType.toString().replaceAll('?', '');
    // This is simplified - real implementation needs proper type reflection
    return _dartToSqlMap.keys.firstWhere(
      (t) => t.toString() == typeStr,
      orElse: () => String,
    );
  }
}
```

### 3. Integration with Schema Inspector

```dart
class EnhancedSchemaInspector extends SchemaInspector {
  EnhancedSchemaInspector(super.driver, this.typeMapper);
  
  final TypeMapper typeMapper;
  
  /// Get Dart type for a column by inspecting the database
  Future<Type?> columnDartType(
    String table,
    String column, {
    String? schema,
  }) async {
    final sqlType = await columnType(table, column, schema: schema);
    if (sqlType == null) return null;
    
    return typeMapper.sqlToDart(sqlType);
  }
  
  /// Get suggested codec for a column
  Future<ValueCodec?> columnCodec(
    String table,
    String column,
    Type dartType, {
    String? schema,
  }) async {
    final sqlType = await columnType(table, column, schema: schema);
    return typeMapper.getCodec(dartType, sqlType: sqlType);
  }
}
```

### 4. Integration with Code Generator

```dart
// In the code generator when processing @OrmField annotations

class FieldCodecResolver {
  final TypeMapper typeMapper;
  
  FieldCodecResolver(this.typeMapper);
  
  String resolveCodec(FieldElement field, OrmField annotation) {
    final dartType = field.type.element?.name ?? 'dynamic';
    final sqlType = annotation.sqlType;  // User-specified SQL type
    
    // Get codec from type mapper
    final codec = typeMapper.getCodec(
      _stringToType(dartType),
      sqlType: sqlType,
    );
    
    if (codec != null) {
      return _codecToCode(codec);
    }
    
    // Fallback to registry lookup
    return 'ValueCodecRegistry.instance.getCodec<$dartType>()';
  }
}
```

### 5. Example Usage Scenarios

#### Scenario A: Simple String Field
```dart
@OrmField()
String name;  // No SQL type specified

// Resolution:
// 1. Generator: dartToSql(String) -> "TEXT"
// 2. Schema: CREATE TABLE ... name TEXT
// 3. Runtime: sqlToDart("TEXT") -> String
// 4. Codec: getCodec(String, "TEXT") -> IdentityCodec<String>
```

#### Scenario B: DateTime with Custom Storage
```dart
@OrmField(sqlType: 'INTEGER')  // Store as unix timestamp
DateTime createdAt;

// Resolution:
// 1. Generator: Uses user override -> "INTEGER"
// 2. Schema: CREATE TABLE ... created_at INTEGER
// 3. Runtime: sqlToDart("INTEGER") -> int (wrong!)
// 4. Codec: getCodec(DateTime, "INTEGER") -> UnixTimestampCodec()
// 5. Decode: UnixTimestampCodec converts int -> DateTime
```

#### Scenario C: Boolean Field
```dart
@OrmField()
bool isActive;

// Resolution:
// 1. Generator: dartToSql(bool) -> "INTEGER"
// 2. Schema: CREATE TABLE ... is_active INTEGER
// 3. Runtime: Query returns 0 or 1 (int)
// 4. Codec: getCodec(bool, "INTEGER") -> SqliteBooleanCodec()
// 5. Decode: SqliteBooleanCodec converts 0/1 -> bool
```

#### Scenario D: JSON Field
```dart
@OrmField()
Map<String, dynamic> metadata;

// Resolution:
// 1. Generator: dartToSql(Map) -> "TEXT"
// 2. Schema: CREATE TABLE ... metadata TEXT
// 3. Runtime: Query returns String (JSON)
// 4. Codec: getCodec(Map, "TEXT") -> JsonCodec()
// 5. Decode: JsonCodec converts String -> Map
```

#### Scenario E: Schema Inspector Discovers Type
```dart
// Database has: CREATE TABLE users (age INTEGER)
final inspector = EnhancedSchemaInspector(driver, SqliteTypeMapper());

// Inspect existing column
final sqlType = await inspector.columnType('users', 'age');
// Returns: "INTEGER"

final dartType = await inspector.columnDartType('users', 'age');
// Returns: int

final codec = await inspector.columnCodec('users', 'age', int);
// Returns: IdentityCodec<int>
```

## Driver-Specific Codecs

### SQLite Codecs
```dart
/// Converts SQLite INTEGER (0/1) <-> Dart bool
class SqliteBooleanCodec extends ValueCodec<bool, int> {
  const SqliteBooleanCodec();
  
  @override
  int encode(bool value) => value ? 1 : 0;
  
  @override
  bool decode(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }
}

/// Converts unix timestamp <-> DateTime
class UnixTimestampCodec extends ValueCodec<DateTime, int> {
  const UnixTimestampCodec();
  
  @override
  int encode(DateTime value) => value.millisecondsSinceEpoch ~/ 1000;
  
  @override
  DateTime decode(dynamic value) {
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    if (value is String) return DateTime.parse(value);
    throw ArgumentError('Cannot decode $value to DateTime');
  }
}

/// Converts ISO8601 string <-> DateTime (default for SQLite TEXT)
class Iso8601DateTimeCodec extends ValueCodec<DateTime, String> {
  const Iso8601DateTimeCodec();
  
  @override
  String encode(DateTime value) => value.toIso8601String();
  
  @override
  DateTime decode(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    throw ArgumentError('Cannot decode $value to DateTime');
  }
}
```

## Registration and Discovery

### Driver Registration
```dart
class SqliteAdapter extends OrmAdapter {
  @override
  void registerTypes(ValueCodecRegistry registry) {
    final mapper = SqliteTypeMapper();
    
    // Register driver-specific codecs
    registry.registerCodec(SqliteBooleanCodec(), driver: 'sqlite');
    registry.registerCodec(UnixTimestampCodec(), driver: 'sqlite');
    registry.registerCodec(Iso8601DateTimeCodec(), driver: 'sqlite');
    
    // Store type mapper for schema operations
    registry.setTypeMapper('sqlite', mapper);
  }
  
  @override
  TypeMapper get typeMapper => SqliteTypeMapper();
}
```

### Generator Integration
```dart
// In build.yaml or generator config
generators:
  ormed_generator:
    options:
      drivers:
        sqlite:
          type_mapper: SqliteTypeMapper
          default_datetime_storage: text  # or integer
          default_bool_storage: integer
```

## Benefits

1. **Centralized Type Logic** - All type decisions in one place per driver
2. **Schema Inspector Integration** - Can infer Dart types from database
3. **Generator Support** - Generator knows which codec to use
4. **User Overrides** - `sqlType` parameter works correctly
5. **Runtime Safety** - Proper codec selection based on actual SQL type
6. **Driver Flexibility** - Each driver can handle its quirks
7. **Extensibility** - Easy to add new type mappings

## Migration Path

1. ✅ Implement `TypeMapper` interface
2. ✅ Create `SqliteTypeMapper` 
3. ✅ Create driver-specific codecs
4. ✅ Update `ValueCodecRegistry` to store type mappers
5. ✅ Update generator to use type mapper
6. ✅ Update schema inspector to use type mapper
7. ✅ Test with existing models
8. ✅ Repeat for MySQL and PostgreSQL
