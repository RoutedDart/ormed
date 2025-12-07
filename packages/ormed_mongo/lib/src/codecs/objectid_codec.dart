import 'package:mongo_dart/mongo_dart.dart';
import 'package:ormed/ormed.dart';

/// Codec that handles conversion between ObjectId and various ID types.
///
/// This codec is automatically applied to primary key fields in MongoDB
/// to handle the conversion between MongoDB's ObjectId format and the
/// user's declared ID type (int, String, etc.).
class ObjectIdCodec<T> extends ValueCodec<T, ObjectId> {
  const ObjectIdCodec();

  @override
  ObjectId encode(T value) {
    if (value == null) {
      throw ArgumentError('Cannot encode null value to ObjectId');
    }

    if (value is ObjectId) {
      return value;
    }

    if (value is String) {
      // Try to parse as ObjectId hex string
      if (ObjectId.isValidHexId(value)) {
        return ObjectId.fromHexString(value);
      }
      // Otherwise generate a new ObjectId
      return ObjectId();
    }

    if (value is int) {
      // For int IDs, we generate a deterministic ObjectId based on the int
      // This allows roundtrip conversion
      final hexString = value.toRadixString(16).padLeft(24, '0');
      if (hexString.length > 24) {
        throw ArgumentError('Int value $value is too large to convert to ObjectId');
      }
      return ObjectId.fromHexString(hexString);
    }

    throw ArgumentError('Cannot encode type ${value.runtimeType} to ObjectId');
  }

  @override
  @override
  T? decode(Object? value) {
    if (value == null) return null;
    
    if (value is! ObjectId) {
      throw ArgumentError('Expected ObjectId but got ${value.runtimeType}');
    }
    
    if (T == ObjectId) {
      return value as T;
    }

    if (T == String) {
      return value.toHexString() as T;
    }

    if (T == int) {
      // Convert ObjectId to int by parsing hex string
      final hexString = value.toHexString();
      return int.parse(hexString, radix: 16) as T;
    }

    throw ArgumentError('Cannot decode ObjectId to type $T');
  }
}

/// Special codec for nullable ObjectId conversions
class NullableObjectIdCodec<T> extends ValueCodec<T?, ObjectId?> {
  const NullableObjectIdCodec();

  @override
  ObjectId? encode(T? value) {
    if (value == null) {
      return null;
    }

    if (value is ObjectId) {
      return value;
    }

    if (value is String) {
      if (ObjectId.isValidHexId(value)) {
        return ObjectId.fromHexString(value);
      }
      return ObjectId();
    }

    if (value is int) {
      final hexString = value.toRadixString(16).padLeft(24, '0');
      if (hexString.length > 24) {
        throw ArgumentError('Int value $value is too large to convert to ObjectId');
      }
      return ObjectId.fromHexString(hexString);
    }

    throw ArgumentError('Cannot encode type ${value.runtimeType} to ObjectId');
  }

  @override
  T? decode(ObjectId? value) {
    if (value == null) {
      return null;
    }

    if (T == ObjectId) {
      return value as T;
    }

    if (T == String) {
      return value.toHexString() as T;
    }

    if (T == int) {
      final hexString = value.toHexString();
      return int.parse(hexString, radix: 16) as T;
    }

    throw ArgumentError('Cannot decode ObjectId to type $T');
  }
}
