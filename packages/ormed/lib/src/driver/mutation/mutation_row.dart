import 'package:ormed/src/driver/json_update_clause.dart';

class MutationRow {
  MutationRow({
    required this.values,
    required this.keys,
    List<JsonUpdateClause>? jsonUpdates,
  }) : jsonUpdates = List.unmodifiable(
         jsonUpdates ?? const <JsonUpdateClause>[],
       );

  final Map<String, Object?> values;
  final Map<String, Object?> keys;
  final List<JsonUpdateClause> jsonUpdates;
}
