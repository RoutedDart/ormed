/// Core type mapping system for database drivers.
///
/// This defines the contract for how drivers map between:
/// 1. Dart types (Type) -> SQL column types (String)
/// 2. SQL column types (String) -> Dart types (Type)
/// 3. Driver-specific codecs for encoding/decoding values
library;

import '../value_codec.dart';

/// Represents a mapping between Dart and SQL types with codec support
class TypeMapping {
  /// The Dart type this mapping represents
  final Type dartType;

  /// The default SQL column type for this Dart type
  final String defaultSqlType;

  /// Alternative SQL types that map to this Dart type
  final List<String> acceptedSqlTypes;

  /// Whether this type is nullable by default
  final bool nullable;

  /// Optional codec for encoding/decoding values
  final ValueCodec? codec;

  const TypeMapping({
    required this.dartType,
    required this.defaultSqlType,
    this.acceptedSqlTypes = const [],
    this.nullable = false,
    this.codec,
  });

  /// Get all SQL types that map to this Dart type
  List<String> get allSqlTypes => [defaultSqlType, ...acceptedSqlTypes];
}

/// Abstract base class for driver-specific type mappings
abstract class DriverTypeMapper {
  /// The name of this driver (e.g., 'sqlite', 'postgres', 'mysql')
  String get driverName;

  /// Get all type mappings for this driver
  List<TypeMapping> get typeMappings;

  /// Map a Dart type to its default SQL column type
  String? dartTypeToSql(Type dartType, {bool nullable = false}) {
    final mapping = _findMappingByDartType(dartType);
    return mapping?.defaultSqlType;
  }

  /// Map a SQL column type to its corresponding Dart type
  Type? sqlTypeToDart(String sqlType) {
    final normalized = normalizeSqlType(sqlType);
    final mapping = _findMappingBySqlType(normalized);
    return mapping?.dartType;
  }

  /// Get the codec for a specific Dart type
  ValueCodec? getCodecForDartType(Type dartType) {
    final mapping = _findMappingByDartType(dartType);
    return mapping?.codec;
  }

  /// Get the codec for a specific SQL type
  ValueCodec? getCodecForSqlType(String sqlType) {
    final normalized = normalizeSqlType(sqlType);
    final mapping = _findMappingBySqlType(normalized);
    return mapping?.codec;
  }

  /// Normalize a SQL type string (remove size, unsigned, etc.)
  String normalizeSqlType(String sqlType) {
    // Remove everything after first space or parenthesis
    final normalized = sqlType.trim().toUpperCase().split(RegExp(r'[\s(]'))[0];
    return normalized;
  }

  /// Validate if a SQL type is supported by this driver
  bool isSqlTypeSupported(String sqlType) {
    final normalized = normalizeSqlType(sqlType);
    return typeMappings.any((m) => m.allSqlTypes.contains(normalized));
  }

  /// Get the default SQL type for a specific Dart type name string.
  /// This is useful for schema generation when you have type name strings.
  String? dartTypeNameToSql(String dartTypeName) {
    // Remove nullable suffix
    final cleanTypeName = dartTypeName.replaceAll('?', '').trim();
    
    // Try to find matching type mapping
    for (final mapping in typeMappings) {
      if (mapping.dartType.toString() == cleanTypeName) {
        return mapping.defaultSqlType;
      }
    }
    return null;
  }

  /// Suggest a SQL type based on Dart type and constraints
  String suggestSqlType(Type dartType, {
    int? maxLength,
    int? precision,
    int? scale,
    bool unsigned = false,
    bool autoIncrement = false,
  }) {
    final baseType = dartTypeToSql(dartType);
    if (baseType == null) return 'TEXT';

    return applySqlTypeModifiers(
      baseType,
      maxLength: maxLength,
      precision: precision,
      scale: scale,
      unsigned: unsigned,
      autoIncrement: autoIncrement,
    );
  }

  /// Apply modifiers to a base SQL type
  String applySqlTypeModifiers(
    String baseType, {
    int? maxLength,
    int? precision,
    int? scale,
    bool unsigned = false,
    bool autoIncrement = false,
  }) {
    // Default implementation - drivers can override
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

    if (unsigned && supportsUnsigned(baseType)) {
      result = '$result UNSIGNED';
    }

    return result;
  }

  /// Check if a SQL type supports length specification
  bool supportsLength(String sqlType) {
    final normalized = normalizeSqlType(sqlType);
    return ['VARCHAR', 'CHAR', 'VARBINARY', 'BINARY'].contains(normalized);
  }

  /// Check if a SQL type supports decimal precision/scale
  bool supportsDecimal(String sqlType) {
    final normalized = normalizeSqlType(sqlType);
    return ['DECIMAL', 'NUMERIC'].contains(normalized);
  }

  /// Check if a SQL type supports UNSIGNED modifier
  bool supportsUnsigned(String sqlType) {
    // Override in MySQL/MariaDB drivers
    return false;
  }

  TypeMapping? _findMappingByDartType(Type dartType) {
    return typeMappings.firstWhere(
      (m) => m.dartType == dartType,
      orElse: () => typeMappings.firstWhere(
        (m) => m.dartType.toString() == dartType.toString(),
        orElse: () => throw UnsupportedError(
          'No type mapping found for Dart type: $dartType',
        ),
      ),
    );
  }

  TypeMapping? _findMappingBySqlType(String sqlType) {
    return typeMappings.firstWhere(
      (m) => m.allSqlTypes.contains(sqlType),
      orElse: () => throw UnsupportedError(
        'No type mapping found for SQL type: $sqlType in driver $driverName',
      ),
    );
  }
}

/// Registry for driver type mappers
class TypeMapperRegistry {
  static final Map<String, DriverTypeMapper> _mappers = {};

  /// Register a type mapper for a driver
  static void register(String driverName, DriverTypeMapper mapper) {
    _mappers[driverName] = mapper;
  }

  /// Get a type mapper for a driver
  static DriverTypeMapper? get(String driverName) {
    return _mappers[driverName];
  }

  /// Get a type mapper for a driver, throwing if not found
  static DriverTypeMapper getOrThrow(String driverName) {
    final mapper = _mappers[driverName];
    if (mapper == null) {
      throw ArgumentError(
        'No TypeMapper registered for driver: $driverName. '
        'Available drivers: ${_mappers.keys.join(", ")}',
      );
    }
    return mapper;
  }

  /// Check if a driver has a registered mapper
  static bool has(String driverName) {
    return _mappers.containsKey(driverName);
  }

  /// Clear all registered mappers (useful for testing)
  static void clear() {
    _mappers.clear();
  }
}
