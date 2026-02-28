/// SQLite codecs and sqlite3 row helpers.
library;

import 'package:sqlite3/sqlite3.dart';

export 'package:ormed_sqlite_core/src/sqlite_codecs.dart';

Map<String, Object?> rowToMap(Row row, List<String> columnNames) {
  final map = <String, Object?>{};
  for (var i = 0; i < columnNames.length; i++) {
    map[columnNames[i]] = row.columnAt(i);
  }
  return map;
}
