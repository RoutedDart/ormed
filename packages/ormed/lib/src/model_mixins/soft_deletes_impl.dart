import 'package:carbonized/carbonized.dart';

import 'model_attributes.dart';
import 'model_connection.dart';
import 'soft_deletes.dart';

/// Implementation mixin for soft-delete functionality.
///
/// This mixin is applied to generated tracked model classes (_$ModelName)
/// and provides the actual soft-delete functionality backed by the attribute store.
///
/// **Do not use this mixin directly in user-defined model classes.**
/// Use the marker [SoftDeletes] mixin instead, and the code generator will
/// apply this implementation to the generated tracked model class.
mixin SoftDeletesImpl on ModelAttributes, ModelConnection {
  String get _column => getSoftDeleteColumn() ?? SoftDeletes.defaultColumn;

  /// Timestamp describing when the row was soft deleted.
  /// Handles both DateTime and Carbon types that may be stored.
  DateTime? get deletedAt {
    final value = getAttribute<Object?>(_column);
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Carbon) return value.toDateTime();
    return null;
  }

  set deletedAt(DateTime? value) => setAttribute(_column, value);

  /// Whether the model currently has a deletion timestamp.
  bool get trashed => deletedAt != null;
}

