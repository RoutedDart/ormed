/// Provides per-instance attribute storage for ORM models.
///
/// Attributes are guarded/encoded through the decorators defined on the
/// attached [ModelDefinition].
library;

import 'dart:collection';

import '../exceptions.dart';
import '../model_definition.dart';
import '../query/json_path.dart' as json_path;
import '../value_codec.dart';
import 'model_attribute_inspector.dart';

mixin ModelAttributes {
  static int _unguardedCount = 0;

  /// Runs [callback] while temporarily bypassing mass assignment guards.
  static T unguarded<T>(T Function() callback) {
    _unguardedCount++;
    try {
      return callback();
    } finally {
      _unguardedCount--;
    }
  }

  static final Expando<Map<String, Object?>> _store =
      Expando<Map<String, Object?>>('_ormAttributes');
  static final Expando<ModelDefinition<dynamic>> _definitions =
      Expando<ModelDefinition<dynamic>>('_ormModelDefinition');
  static final Expando<String> _softDeleteColumns = Expando<String>(
    '_ormSoftDeleteColumn',
  );
  static final Expando<List<JsonAttributeUpdate>> _jsonUpdates =
      Expando<List<JsonAttributeUpdate>>('_ormJsonUpdates');

  Map<String, Object?> _ensureAttributes() =>
      _store[this] ??= <String, Object?>{};

  List<JsonAttributeUpdate> _ensureJsonUpdates() =>
      _jsonUpdates[this] ??= <JsonAttributeUpdate>[];

  /// Snapshot of the current attribute map.
  Map<String, Object?> get attributes =>
      UnmodifiableMapView(_ensureAttributes());

  /// Reads an attribute by column name.
  T? getAttribute<T>(String column) => _ensureAttributes()[column] as T?;

  /// Upserts an attribute value.
  void setAttribute(String column, Object? value) {
    _ensureAttributes()[column] = value;
  }

  /// Replaces the entire attribute map.
  void replaceAttributes(Map<String, Object?> values) {
    _store[this] = Map<String, Object?>.from(values);
  }

  /// Associates the generated model definition with this instance.
  void attachModelDefinition(ModelDefinition<dynamic> definition) {
    _definitions[this] = definition;
  }

  /// Definition metadata attached to this model, when available.
  ModelDefinition<dynamic>? get modelDefinition => _definitions[this];

  /// Stores the effective soft delete column for this instance.
  void attachSoftDeleteColumn(String column) {
    _softDeleteColumns[this] = column;
  }

  /// Returns the soft delete column name if the model supports it.
  String? getSoftDeleteColumn() {
    return _softDeleteColumns[this] ?? modelDefinition?.softDeleteColumn;
  }

  /// Queues a JSON update for [columnOrSelector].
  ///
  /// When [pathOverride] is null, [columnOrSelector] may include `->`/`->>`
  /// syntax.
  void setJsonAttributeValue(
    String columnOrSelector,
    Object? value, {
    String? pathOverride,
    bool patch = false,
  }) {
    final parsed = _parseJsonSelector(columnOrSelector, pathOverride);
    _ensureJsonUpdates().add(
      JsonAttributeUpdate(
        fieldOrColumn: parsed.column,
        path: parsed.path,
        value: value,
        patch: patch,
      ),
    );
  }

  /// Queues a JSON patch merge for [column] with the provided delta map.
  void setJsonAttributePatch(String column, Map<String, Object?> delta) {
    setJsonAttributeValue(column, delta, pathOverride: r'$', patch: true);
  }

  /// Returns and clears any pending JSON attribute updates.
  List<JsonAttributeUpdate> takeJsonAttributeUpdates() {
    final pending = _jsonUpdates[this];
    if (pending == null || pending.isEmpty) {
      return const <JsonAttributeUpdate>[];
    }
    _jsonUpdates[this] = <JsonAttributeUpdate>[];
    return List<JsonAttributeUpdate>.from(pending);
  }

  /// Clears any pending JSON attribute updates without applying them.
  void clearJsonAttributeUpdates() {
    _jsonUpdates[this]?.clear();
  }

  _ParsedJsonSelector _parseJsonSelector(
    String columnOrSelector,
    String? overridePath,
  ) {
    final trimmed = columnOrSelector.trim();
    if (overridePath != null && overridePath.trim().isNotEmpty) {
      return _ParsedJsonSelector(
        column: trimmed,
        path: json_path.normalizeJsonPath(overridePath),
      );
    }
    final selector = json_path.parseJsonSelectorExpression(trimmed);
    if (selector != null) {
      return _ParsedJsonSelector(column: selector.column, path: selector.path);
    }
    return _ParsedJsonSelector(column: trimmed, path: r'$');
  }

  bool get _isUngarded => _unguardedCount > 0;

  AttributeInspector _attributeInspector() => AttributeInspector(
    metadata: _metadata,
    fields: modelDefinition?.fields ?? const <FieldDefinition>[],
  );

  ModelAttributesMetadata get _metadata =>
      modelDefinition?.metadata ?? const ModelAttributesMetadata();

  ModelDefinition<dynamic>? get _definition => modelDefinition;

  /// Fills attributes from [payload], respecting fillable/guarded metadata.
  ///
  /// Returns a map containing the values that were accepted. When [strict]
  /// is `true`, guarded properties produce a [MassAssignmentException].
  Map<String, Object?> fillAttributes(
    Map<String, Object?> payload, {
    bool strict = true,
    ValueCodecRegistry? registry,
  }) {
    final inspector = _attributeInspector();
    final codecs = registry ?? ValueCodecRegistry.standard();
    final filled = <String, Object?>{};
    final discarded = <String>[];
    for (final entry in payload.entries) {
      if (_isUngarded || inspector.isFillable(entry.key)) {
        final decoded = _decodeAttribute(
          column: entry.key,
          value: entry.value,
          registry: codecs,
          definition: _definition,
          inspector: inspector,
        );
        setAttribute(entry.key, decoded);
        filled[entry.key] = decoded;
      } else {
        discarded.add(entry.key);
      }
    }
    if (strict && discarded.isNotEmpty) {
      throw MassAssignmentException(
        'Mass assignment rejected for attributes: ${discarded.join(', ')}',
      );
    }
    return filled;
  }

  /// Serializes the attribute map, applying casts and filtering hidden fields.
  Map<String, Object?> serializableAttributes({
    bool includeHidden = false,
    ValueCodecRegistry? registry,
  }) {
    final inspector = _attributeInspector();
    final codecs = registry ?? ValueCodecRegistry.standard();
    final result = <String, Object?>{};
    final definition = _definition;
    for (final entry in _ensureAttributes().entries) {
      if (!_shouldSerializeColumn(entry.key, includeHidden, inspector)) {
        continue;
      }
      final encoded = _encodeAttribute(
        column: entry.key,
        value: entry.value,
        registry: codecs,
        definition: definition,
        inspector: inspector,
      );
      result[entry.key] = encoded;
    }
    return result;
  }

  bool _shouldSerializeColumn(
    String column,
    bool includeHidden,
    AttributeInspector inspector,
  ) {
    if (!inspector.isHidden(column)) return true;
    if (!includeHidden) return false;
    return inspector.isVisible(column);
  }

  Object? _decodeAttribute({
    required String column,
    required Object? value,
    required ValueCodecRegistry registry,
    required ModelDefinition<dynamic>? definition,
    required AttributeInspector inspector,
  }) {
    final cast = inspector.castFor(column);
    if (cast != null) {
      return registry.decodeByKey(cast, value);
    }
    if (definition == null) {
      return value;
    }
    final field = definition.fieldByColumn(column);
    if (field == null) {
      return value;
    }
    return registry.decodeField(field, value);
  }

  Object? _encodeAttribute({
    required String column,
    required Object? value,
    required ValueCodecRegistry registry,
    required ModelDefinition<dynamic>? definition,
    required AttributeInspector inspector,
  }) {
    final cast = inspector.castFor(column);
    if (cast != null) {
      return registry.encodeByKey(cast, value);
    }
    if (definition == null) {
      return value;
    }
    final field = definition.fieldByColumn(column);
    if (field == null) {
      return value;
    }
    return registry.encodeField(field, value);
  }
}

/// Represents a queued JSON attribute operation.
class JsonAttributeUpdate {
  const JsonAttributeUpdate({
    required this.fieldOrColumn,
    required this.path,
    required this.value,
    this.patch = false,
  });

  /// The column or field being patched.
  final String fieldOrColumn;

  /// JSON path describing where within the structure to apply the update.
  final String path;

  /// Value to assign or merge into the JSON column.
  final Object? value;

  /// Whether the update should merge the existing JSON value.
  final bool patch;
}

class _ParsedJsonSelector {
  _ParsedJsonSelector({required this.column, required this.path});

  final String column;
  final String path;
}
