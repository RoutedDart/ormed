import 'package:ormed/ormed.dart';

Map<String, Object?> mutationRowFilter(MutationRow row) =>
    Map<String, Object?>.from(row.keys);

Map<String, Object?> mutationRowValues(MutationRow row) {
  final values = Map<String, Object?>.from(row.values);
  for (final key in row.keys.keys) {
    values.remove(key);
  }
  return values;
}

Map<String, Object?> buildSetDocument(
  Map<String, Object?> values,
  List<JsonUpdateClause> jsonUpdates,
) {
  final merged = <String, Object?>{};
  merged.addAll(values);
  merged.addAll(_jsonUpdateMap(jsonUpdates));
  if (merged.isEmpty) {
    return const {};
  }
  return {'\$set': merged};
}

Map<String, Object?> buildUpdateDocument(
  Map<String, Object?> values,
  List<JsonUpdateClause> jsonUpdates,
  Map<String, num> increments,
) {
  final document = <String, Object?>{};
  final setDocument = buildSetDocument(values, jsonUpdates);
  if (setDocument.isNotEmpty) {
    document.addAll(setDocument);
  }
  if (increments.isNotEmpty) {
    document['\$inc'] = Map<String, num>.from(increments);
  }
  return document;
}

Map<String, Object?> _jsonUpdateMap(List<JsonUpdateClause> clauses) {
  final map = <String, Object?>{};
  for (final clause in clauses) {
    final key = _jsonUpdateKey(clause);
    map[key] = clause.value;
  }
  return map;
}

String _jsonUpdateKey(JsonUpdateClause clause) {
  final segments = _segmentsFromNormalizedPath(clause.path);
  final parts = <String>[clause.column, ...segments];
  return parts.where((segment) => segment.isNotEmpty).join('.');
}

List<String> _segmentsFromNormalizedPath(String path) {
  if (path.isEmpty) {
    return const [];
  }
  final segments = <String>[];
  var index = 0;

  while (index < path.length) {
    final char = path[index];
    if (char == r'$') {
      index += 1;
      continue;
    }
    if (char == '.') {
      index += 1;
      final buffer = StringBuffer();
      while (index < path.length && path[index] != '.' && path[index] != '[') {
        buffer.write(path[index]);
        index += 1;
      }
      final value = buffer.toString();
      if (value.isNotEmpty) {
        segments.add(value);
      }
      continue;
    }
    if (char == '[') {
      index += 1;
      if (index < path.length && path[index] == '"') {
        index += 1;
        final buffer = StringBuffer();
        while (index < path.length) {
          final current = path[index];
          if (current == '\\' && index + 1 < path.length) {
            buffer.write(path[index + 1]);
            index += 2;
            continue;
          }
          if (current == '"') {
            index += 1;
            break;
          }
          buffer.write(current);
          index += 1;
        }
        while (index < path.length && path[index] != ']') {
          index += 1;
        }
        if (index < path.length && path[index] == ']') {
          index += 1;
        }
        final value = buffer.toString();
        if (value.isNotEmpty) {
          segments.add(value);
        }
      } else {
        final buffer = StringBuffer();
        while (index < path.length && path[index] != ']') {
          buffer.write(path[index]);
          index += 1;
        }
        if (index < path.length && path[index] == ']') {
          index += 1;
        }
        final value = buffer.toString().trim();
        if (value.isEmpty) {
          continue;
        }
        segments.add(value);
      }
      continue;
    }
    final buffer = StringBuffer();
    while (index < path.length && path[index] != '.' && path[index] != '[') {
      buffer.write(path[index]);
      index += 1;
    }
    final value = buffer.toString();
    if (value.isNotEmpty) {
      segments.add(value);
    }
  }

  return segments;
}

Map<String, Object?> upsertFilter(
  MutationRow row,
  Iterable<String> uniqueColumns,
) {
  final filter = <String, Object?>{};
  for (final column in uniqueColumns) {
    final value = row.values[column];
    if (value != null) {
      filter[column] = value;
    }
  }
  if (filter.isNotEmpty) {
    return filter;
  }
  return mutationRowFilter(row);
}

Map<String, Object?> upsertValues(
  Map<String, Object?> values,
  Iterable<String> uniqueColumns,
  Iterable<String>? updateColumns,
) {
  final uniqueSet = uniqueColumns.toSet();
  final updateSet = updateColumns?.toSet();
  final filtered = <String, Object?>{};
  for (final entry in values.entries) {
    final column = entry.key;
    if (uniqueSet.contains(column)) {
      continue;
    }
    if (updateSet != null && !updateSet.contains(column)) {
      continue;
    }
    filtered[column] = entry.value;
  }
  return filtered;
}

Map<String, Object?>? buildUpsertOperation(
  MutationRow row,
  Iterable<String> uniqueColumns,
  Iterable<String> updateColumns,
) {
  final filter = upsertFilter(row, uniqueColumns);
  final updates = upsertValues(row.values, uniqueColumns, updateColumns);
  final updateDoc = buildSetDocument(updates, row.jsonUpdates);
  if (updateDoc.isEmpty) {
    return null;
  }
  return {
    'updateOne': [
      filter,
      updateDoc,
      {'upsert': true},
    ],
  };
}
