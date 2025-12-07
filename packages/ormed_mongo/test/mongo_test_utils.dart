/// MongoDB-specific test utilities to handle ObjectId conversions
library;

import 'package:mongo_dart/mongo_dart.dart';

/// Converts various ID types to ObjectId for MongoDB operations
ObjectId toObjectId(dynamic id) {
  if (id is ObjectId) return id;
  if (id is String) return ObjectId.fromHexString(id);
  if (id is int) {
    // For int IDs in tests, we generate a deterministic ObjectId
    // This allows tests to work but isn't production-ready
    final hex = id.toRadixString(16).padLeft(24, '0');
    return ObjectId.fromHexString(hex);
  }
  throw ArgumentError('Cannot convert $id (${id.runtimeType}) to ObjectId');
}

/// Extracts an int ID from an ObjectId for test assertions
/// This is a lossy conversion only suitable for testing
int objectIdToInt(ObjectId oid) {
  // Use the timestamp portion as an int
  return oid.milliseconds;
}
