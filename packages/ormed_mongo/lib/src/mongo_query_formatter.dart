import 'dart:convert';

import 'package:ormed/ormed.dart';

/// Formats MongoDB commands from DocumentStatementPayload for logging.
class MongoQueryFormatter {
  const MongoQueryFormatter();

  /// Formats a DocumentStatementPayload into a MongoDB shell command string.
  /// Examples:
  ///   - `db.users.find({age: {$gt: 18}})`
  ///   - `db.posts.aggregate([{$match: {published: true}}])`
  String format(DocumentStatementPayload payload) {
    final metadata = payload.metadata ?? {};
    final tableName = metadata['table'] as String? ?? 'collection';

    switch (payload.command) {
      case 'find':
        return _formatFind(tableName, payload.arguments);
      case 'aggregate':
        return _formatAggregate(tableName, payload.arguments);
      case 'insertMany':
        return _formatInsertMany(tableName, payload.arguments);
      case 'updateMany':
        return _formatUpdateMany(tableName, payload.arguments);
      case 'deleteMany':
        return _formatDeleteMany(tableName, payload.arguments);
      case 'bulkWrite':
        return _formatBulkWrite(tableName, payload.arguments);
      default:
        return 'db.$tableName.${payload.command}(${_formatArgs(payload.arguments)})';
    }
  }

  String _formatFind(String collection, Map<String, Object?> args) {
    final filter = args['filter'] ?? {};
    final projection = args['projection'];
    final sort = args['sort'];
    final limit = args['limit'];
    final skip = args['skip'];

    final parts = <String>[];
    parts.add(_toJson(filter));
    if (projection != null) {
      parts.add(_toJson(projection));
    }

    var command = 'db.$collection.find(${parts.join(', ')})';

    if (sort != null) {
      command += '.sort(${_toJson(sort)})';
    }
    if (skip != null) {
      command += '.skip($skip)';
    }
    if (limit != null) {
      command += '.limit($limit)';
    }

    return command;
  }

  String _formatAggregate(String collection, Map<String, Object?> args) {
    final pipeline = args['pipeline'] ?? [];
    return 'db.$collection.aggregate(${_toJson(pipeline)})';
  }

  String _formatInsertMany(String collection, Map<String, Object?> args) {
    final documents = args['documents'] ?? [];
    return 'db.$collection.insertMany(${_toJson(documents)})';
  }

  String _formatUpdateMany(String collection, Map<String, Object?> args) {
    if (args.containsKey('updates')) {
      // Bulk update format
      final updates = args['updates'] ?? [];
      return 'db.$collection.bulkWrite(${_toJson(updates)})';
    } else {
      // Single update format
      final filter = args['filter'] ?? {};
      final update = args['update'] ?? {};
      return 'db.$collection.updateMany(${_toJson(filter)}, ${_toJson(update)})';
    }
  }

  String _formatDeleteMany(String collection, Map<String, Object?> args) {
    if (args.containsKey('deletes')) {
      // Bulk delete format
      final deletes = args['deletes'] ?? [];
      return 'db.$collection.bulkWrite(${_toJson(deletes)})';
    } else {
      // Single delete format
      final filter = args['filter'] ?? {};
      return 'db.$collection.deleteMany(${_toJson(filter)})';
    }
  }

  String _formatBulkWrite(String collection, Map<String, Object?> args) {
    final operations = args['operations'] ?? [];
    return 'db.$collection.bulkWrite(${_toJson(operations)})';
  }

  String _formatArgs(Map<String, Object?> args) {
    if (args.isEmpty) return '';
    return _toJson(args);
  }

  String _toJson(Object? value) {
    try {
      // Use compact JSON for readability
      return const JsonEncoder().convert(value);
    } catch (_) {
      return value.toString();
    }
  }
}
