import 'package:ormed/src/model/model.dart';

import '../contracts.dart';
import '../driver/json_update_clause.dart';
import '../query/json_path.dart' as json_path;

typedef JsonUpdateBuilder<T extends OrmEntity> =
    List<JsonUpdateDefinition> Function(T model);

/// Defines a JSON update operation.
class JsonUpdateDefinition {
  JsonUpdateDefinition({
    required this.fieldOrColumn,
    required this.path,
    required this.value,
    this.patch = false,
  });

  factory JsonUpdateDefinition.selector(String selector, Object? value) {
    final parsed = json_path.parseJsonSelectorExpression(selector);
    if (parsed == null) {
      return JsonUpdateDefinition(
        fieldOrColumn: selector,
        path: r'$',
        value: value,
      );
    }
    return JsonUpdateDefinition(
      fieldOrColumn: parsed.column,
      path: parsed.path,
      value: value,
    );
  }

  factory JsonUpdateDefinition.path(
    String fieldOrColumn,
    String path,
    Object? value,
  ) => JsonUpdateDefinition(
    fieldOrColumn: fieldOrColumn,
    path: json_path.normalizeJsonPath(path),
    value: value,
  );

  factory JsonUpdateDefinition.patch(
    String fieldOrColumn,
    Map<String, Object?> delta,
  ) => JsonUpdateDefinition(
    fieldOrColumn: fieldOrColumn,
    path: r'$',
    value: delta,
    patch: true,
  );

  final String fieldOrColumn;
  final String path;
  final Object? value;
  final bool patch;
}

class JsonUpdateSupport<T extends OrmEntity> {
  JsonUpdateSupport(this.definition);

  final ModelDefinition<T> definition;

  List<JsonUpdateClause> buildJsonUpdates(
    T model,
    JsonUpdateBuilder<T>? builder,
  ) {
    final clauses = <JsonUpdateClause>[];
    if (builder != null) {
      for (final def in builder(model)) {
        clauses.add(_toClause(def));
      }
    }

    if (model is ModelAttributes) {
      final attrs = model as ModelAttributes;
      final pending = attrs.takeJsonAttributeUpdates();
      for (final update in pending) {
        clauses.add(
          JsonUpdateClause(
            column: _resolveColumn(update.fieldOrColumn),
            path: update.path,
            value: update.value,
            patch: update.patch,
          ),
        );
      }
    }

    return clauses;
  }

  JsonUpdateClause _toClause(JsonUpdateDefinition definition) =>
      JsonUpdateClause(
        column: _resolveColumn(definition.fieldOrColumn),
        path: definition.path,
        value: definition.value,
        patch: definition.patch,
      );

  String _resolveColumn(String input) {
    for (final field in definition.fields) {
      if (field.name == input || field.columnName == input) {
        return field.columnName;
      }
    }
    return input;
  }
}
