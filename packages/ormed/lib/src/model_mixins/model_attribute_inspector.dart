import '../model_definition.dart';

/// Mirrors Laravel-style attribute guards, hidden lists, and casts.
///
/// Inspectors are used when filling or serializing model attributes so that
/// driver-specific overrides are respected.
class AttributeInspector {
  AttributeInspector({
    required this.metadata,
    required Iterable<FieldDefinition> fields,
  }) : _guardableColumns = fields.map((field) => field.columnName).toSet(),
       _fieldOverrides = metadata.fieldOverrides;

  final ModelAttributesMetadata metadata;
  final Set<String> _guardableColumns;
  final Map<String, FieldAttributeMetadata> _fieldOverrides;

  Set<String> get _effectiveFillable {
    final result = Set<String>.of(metadata.fillable);
    for (final entry in _fieldOverrides.entries) {
      final override = entry.value;
      if (override.fillable == true) {
        result.add(entry.key);
      } else if (override.fillable == false) {
        result.remove(entry.key);
      }
    }
    return result;
  }

  Set<String> get _effectiveGuarded {
    final result = Set<String>.of(metadata.guarded);
    for (final entry in _fieldOverrides.entries) {
      final override = entry.value;
      if (override.guarded == true) {
        result.add(entry.key);
      } else if (override.guarded == false) {
        result.remove(entry.key);
      }
    }
    return result;
  }

  bool isFillable(String column) {
    final override = _fieldOverrides[column];
    if (override?.fillable != null) {
      return override!.fillable!;
    }
    if (override?.guarded == true) {
      return false;
    }
    final fillable = _effectiveFillable;
    if (fillable.isNotEmpty) {
      return fillable.contains(column);
    }
    if (isGuarded(column)) {
      return false;
    }
    return _isGuardableCandidate(column);
  }

  bool isGuarded(String column) {
    final override = _fieldOverrides[column];
    if (override?.guarded != null) {
      return override!.guarded!;
    }
    final guarded = _effectiveGuarded;
    if (guarded.isEmpty) {
      return false;
    }
    if (guarded.length == 1 && guarded.first == '*') {
      return _isGuardableColumn(column);
    }
    if (guarded.contains(column)) {
      return true;
    }
    return !_isGuardableColumn(column);
  }

  bool isHidden(String column) {
    final override = _fieldOverrides[column];
    if (override?.hidden != null) {
      return override!.hidden!;
    }
    if (metadata.hidden.isEmpty) return false;
    return metadata.hidden.contains(column);
  }

  bool isVisible(String column) {
    final override = _fieldOverrides[column];
    if (override?.visible != null) {
      return override!.visible!;
    }
    return metadata.visible.contains(column);
  }

  String? castFor(String column) =>
      _fieldOverrides[column]?.cast ?? metadata.casts[column];

  bool _isGuardableColumn(String column) => _guardableColumns.contains(column);

  bool _isGuardableCandidate(String column) =>
      !column.contains('.') && !column.startsWith('_');
}
