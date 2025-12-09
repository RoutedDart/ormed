/// Provides helpers to filter raw payloads through model metadata.
library;

import 'package:collection/collection.dart';

import '../exceptions.dart';
import '../model_definition.dart';
import '../value_codec.dart';
import 'model_attribute_inspector.dart';

extension ModelAttributeMapExtensions on Map<String, Object?> {
  /// Returns inputs filtered to what the model would accept via fillable/guarded.
  Map<String, Object?> filteredByAttributes(
    ModelAttributesMetadata metadata,
    Iterable<FieldDefinition> fields, {
    bool strict = true,
    bool unguarded = false,
    ValueCodecRegistry? registry,
  }) {
    final inspector = AttributeInspector(metadata: metadata, fields: fields);
    final codecs = registry ?? ValueCodecRegistry.instance;
    final filtered = <String, Object?>{};
    final discarded = <String>[];

    for (final entry in entries) {
      if (unguarded || inspector.isFillable(entry.key)) {
        filtered[entry.key] = _decodeEntry(
          column: entry.key,
          value: entry.value,
          inspector: inspector,
          fields: fields,
          codecs: codecs,
        );
      } else {
        discarded.add(entry.key);
      }
    }

    if (strict && discarded.isNotEmpty) {
      throw MassAssignmentException(
        'Mass assignment rejected for attributes: ${discarded.join(', ')}',
      );
    }

    return filtered;
  }

  Object? _decodeEntry({
    required String column,
    required Object? value,
    required AttributeInspector inspector,
    required Iterable<FieldDefinition> fields,
    required ValueCodecRegistry codecs,
  }) {
    final cast = inspector.castFor(column);
    if (cast != null) {
      return codecs.decodeByKey(cast, value);
    }
    final field = fields.firstWhereOrNull(
      (entry) => entry.columnName == column,
    );
    if (field != null) {
      return codecs.decodeField(field, value);
    }
    return value;
  }
}
