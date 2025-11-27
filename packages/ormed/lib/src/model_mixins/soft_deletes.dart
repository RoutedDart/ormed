import 'model_attributes.dart';
import 'model_connection.dart';

/// Adds soft-delete helpers backed by the attribute store.
///
/// ```dart
/// class Post extends Model with ModelAttributes, SoftDeletes {
///   // ...
/// }
/// ```
mixin SoftDeletes on ModelAttributes, ModelConnection {
  /// Default column name used for soft delete tracking.
  static const String defaultColumn = 'deleted_at';

  String get _column => getSoftDeleteColumn() ?? defaultColumn;

  /// Timestamp describing when the row was soft deleted.
  DateTime? get deletedAt => getAttribute<DateTime?>(_column);

  set deletedAt(DateTime? value) => setAttribute(_column, value);

  /// Whether the model currently has a deletion timestamp.
  bool get trashed => deletedAt != null;
}
