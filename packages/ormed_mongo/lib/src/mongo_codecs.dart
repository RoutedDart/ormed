import 'package:mongo_dart/mongo_dart.dart';
import 'package:ormed/ormed.dart';

/// Codec that converts between MongoDB's ObjectId and Dart int values.
/// MongoDB uses ObjectId as the primary key (_id), but models may expect int.
/// This codec handles the conversion by using the ObjectId's timestamp as an int.
class MongoObjectIdToIntCodec extends ValueCodec<int> {
  MongoObjectIdToIntCodec();

  @override
  Object? encode(int? value) {
    if (value == null) return null;
    // If value is 0 or negative, generate a new ObjectId
    // Otherwise, try to convert the int to ObjectId hex
    if (value <= 0) {
      return ObjectId();
    }
    // Convert int to hex string (padded to 24 chars)
    final hex = value.toRadixString(16).padLeft(24, '0');
    if (hex.length > 24) {
      // Int too large, generate new ObjectId
      return ObjectId();
    }
    return ObjectId.fromHexString(hex);
  }

  @override
  int? decode(Object? value) {
    if (value == null) return null;
    // If it's already an int, return it as-is
    if (value is int) return value;

    // If it's an ObjectId, convert the full hex to int
    // This ensures consistent round-trip conversion
    if (value is ObjectId) {
      final hex = value.oid;
      try {
        // Parse full 24-char hex as int
        // Note: This may produce very large ints
        return int.parse(hex, radix: 16);
      } catch (_) {
        // If it overflows, use a hash
        return hex.hashCode;
      }
    }
    
    if (value is String) {
      // Try to parse as int first
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
      
      // If it's a hex string (ObjectId), convert it
      if (ObjectId.isValidHexId(value)) {
        try {
          return int.parse(value, radix: 16);
        } catch (_) {
          return value.hashCode;
        }
      }
    }

    return null;
  }
}

/// Codec that converts between MongoDB's ObjectId and Dart String values.
/// This is useful when the model's id field is a String.
class MongoObjectIdToStringCodec extends ValueCodec<String> {
  MongoObjectIdToStringCodec();

  @override
  Object? encode(String? value) {
    if (value == null) return null;
    // Convert string to ObjectId
    try {
      return ObjectId.fromHexString(value);
    } catch (_) {
      // If it's not a valid hex string, create a new ObjectId
      return ObjectId();
    }
  }

  @override
  String? decode(Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is ObjectId) {
      return value.oid;
    }
    return value.toString();
  }
}
