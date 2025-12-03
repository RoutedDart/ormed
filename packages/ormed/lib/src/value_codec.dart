import 'dart:convert';

import 'exceptions.dart';
import 'model_definition.dart';

/// Converts between backend driver payloads and Dart values.
abstract class ValueCodec<TDart> {
  const ValueCodec();

  Object? encode(TDart? value);
  TDart? decode(Object? value);
}

/// No-op codec used for primitives.
class IdentityCodec<TDart> extends ValueCodec<TDart> {
  const IdentityCodec();

  @override
  Object? encode(TDart? value) => value;

  @override
  TDart? decode(Object? value) => value as TDart?;
}

/// Codec for JSON encoding/decoding `Map<String, Object?>` fields.
/// Encodes to JSON string for storage, decodes from JSON string to Map.
class JsonCodec extends ValueCodec<Map<String, Object?>> {
  const JsonCodec();

  @override
  Object? encode(Map<String, Object?>? value) {
    if (value == null) return null;
    return jsonEncode(value);
  }

  @override
  Map<String, Object?>? decode(Object? value) {
    if (value == null) return null;
    if (value is Map<String, Object?>) return value;
    if (value is String) {
      final decoded = jsonDecode(value) as Map<String, dynamic>;
      return decoded.map((key, dynamic entry) => MapEntry(key, entry));
    }
    throw FormatException('Cannot decode $value to Map<String, Object?>');
  }
}

/// Codec for JSON array encoding/decoding List fields.
/// Encodes to JSON string for storage, decodes from JSON string to List.
class JsonArrayCodec extends ValueCodec<List<Object?>> {
  const JsonArrayCodec();

  @override
  Object? encode(List<Object?>? value) {
    if (value == null) return null;
    return jsonEncode(value);
  }

  @override
  List<Object?>? decode(Object? value) {
    if (value == null) return null;
    if (value is List<Object?>) return value;
    if (value is String) {
      return jsonDecode(value) as List<Object?>;
    }
    throw FormatException('Cannot decode $value to List<Object?>');
  }
}

/// Registry that resolves codecs per field/type, with driver-specific overlays.
class ValueCodecRegistry {
  ValueCodecRegistry._(this._codecs, this._driverCodecs, {String? activeDriver})
    : _activeDriver = activeDriver;

  factory ValueCodecRegistry({
    Map<String, ValueCodec<dynamic>> codecs = const {},
  }) => ValueCodecRegistry._({
    ..._defaultCodecs,
    ...codecs,
  }, <String, Map<String, ValueCodec<dynamic>>>{});

  final Map<String, ValueCodec<dynamic>> _codecs;
  final Map<String, Map<String, ValueCodec<dynamic>>> _driverCodecs;
  final String? _activeDriver;

  /// Clone the registry with additional codecs. Driver overlays are copied.
  ValueCodecRegistry fork({
    Map<String, ValueCodec<dynamic>> codecs = const {},
  }) => ValueCodecRegistry._(
    {..._codecs, ...codecs},
    _cloneDriverCodecs(_driverCodecs),
    activeDriver: _activeDriver,
  );

  /// Returns a view scoped to [driver]. Registrations become driver-specific.
  ValueCodecRegistry forDriver(String driver) {
    final normalized = _normalizeDriver(driver);
    return ValueCodecRegistry._(
      _codecs,
      _driverCodecs,
      activeDriver: normalized,
    );
  }

  /// Register or override a codec for a given type key.
  void registerCodec({
    required String key,
    required ValueCodec<dynamic> codec,
  }) {
    final driver = _activeDriver;
    if (driver != null) {
      final overlay = _driverCodecs.putIfAbsent(
        driver,
        () => <String, ValueCodec<dynamic>>{},
      );
      overlay[key] = codec;
      return;
    }
    _codecs[key] = codec;
  }

  /// Convenience helper to register by using a [Type] token (e.g., `JsonCodec`).
  void registerCodecFor(Type codecType, ValueCodec<dynamic> codec) {
    registerCodec(key: codecType.toString(), codec: codec);
  }

  /// Returns a standard registry with built-in primitives.
  factory ValueCodecRegistry.standard() => ValueCodecRegistry();

  Object? encodeField(FieldDefinition field, Object? value) =>
      _codecFor(field).encode(value);

  T? decodeField<T>(FieldDefinition field, Object? value) =>
      _codecFor(field).decode(value) as T?;

  /// Encodes [value] using the codec registered under [key].
  Object? encodeByKey(String key, Object? value) {
    final codec = _codecForKey(key);
    if (codec == null) {
      return value;
    }
    return codec.encode(value);
  }

  /// Decodes [value] using the codec registered under [key].
  T? decodeByKey<T>(String key, Object? value) {
    final codec = _codecForKey(key);
    if (codec == null) {
      return value as T?;
    }
    return codec.decode(value) as T?;
  }

  ValueCodec<dynamic>? _driverCodecForKey(String key) {
    final driver = _activeDriver;
    if (driver == null) return null;
    return _driverCodecs[driver]?[key];
  }

  ValueCodec<dynamic>? _codecForKey(String key) {
    final driverCodec = _driverCodecForKey(key);
    if (driverCodec != null) {
      return driverCodec;
    }
    return _codecs[key];
  }

  Object? encodeValue(Object? value) {
    if (value == null) {
      return null;
    }
    final codec = _codecForKey(value.runtimeType.toString());
    if (codec == null) {
      return value;
    }
    return codec.encode(value);
  }

  ValueCodec<dynamic> _codecFor(FieldDefinition field) {
    final driver = _activeDriver;
    final key = field.codecTypeForDriver(driver) ?? field.dartType;
    ValueCodec<dynamic>? codec = _codecForKey(key);
    if (codec == null) {
      throw CodecNotFound(key, field);
    }
    return codec;
  }
}

Map<String, Map<String, ValueCodec<dynamic>>> _cloneDriverCodecs(
  Map<String, Map<String, ValueCodec<dynamic>>> source,
) {
  if (source.isEmpty) return <String, Map<String, ValueCodec<dynamic>>>{};
  final copy = <String, Map<String, ValueCodec<dynamic>>>{};
  source.forEach((driver, codecs) {
    copy[driver] = Map<String, ValueCodec<dynamic>>.from(codecs);
  });
  return copy;
}

String _normalizeDriver(String driver) {
  final normalized = driver.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(driver, 'driver', 'must not be empty');
  }
  return normalized.toLowerCase();
}

/// Default codecs available in all registries.
/// 
/// Basic types use IdentityCodec (no conversion).
/// Cast keys support Laravel-style @OrmField(cast: 'json') syntax:
/// - 'json' / 'object': Encodes Map to JSON string, decodes JSON string to Map
/// - 'array': Encodes List to JSON string, decodes JSON string to List
Map<String, ValueCodec<dynamic>> get _defaultCodecs => const {
  // Basic types
  'Object': IdentityCodec<Object?>(),
  'Object?': IdentityCodec<Object?>(),
  'String': IdentityCodec<String>(),
  'int': IdentityCodec<int>(),
  'double': IdentityCodec<double>(),
  'num': IdentityCodec<num>(),
  'bool': IdentityCodec<bool>(),
  'DateTime': IdentityCodec<DateTime>(),
  'Map<String, Object?>': IdentityCodec<Map<String, Object?>>(),
  'Map<String, dynamic>': IdentityCodec<Map<String, dynamic>>(),
  'List<Object?>': IdentityCodec<List<Object?>>(),
  'List<dynamic>': IdentityCodec<List<dynamic>>(),
  
  // Common cast keys (Laravel-style)
  'json': JsonCodec(),
  'array': JsonArrayCodec(),
  'object': JsonCodec(), // Alias for json
};
