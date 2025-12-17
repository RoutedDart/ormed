import 'package:carbonized/carbonized.dart';

import 'model_attributes.dart';
import 'timestamps.dart';

/// Implementation mixin for timestamp functionality (non-timezone aware).
///
/// This mixin is applied to generated tracked model classes (_$ModelName)
/// and provides the actual timestamp functionality backed by the attribute store.
///
/// **Do not use this mixin directly in user-defined model classes.**
/// Use the marker [Timestamps] mixin instead, and the code generator will
/// apply this implementation to the generated tracked model class.
mixin TimestampsImpl on ModelAttributes {
  String get _createdAtColumn => Timestamps.defaultCreatedAtColumn;

  String get _updatedAtColumn => Timestamps.defaultUpdatedAtColumn;

  /// Timestamp when the model was created.
  ///
  /// Returns a Carbon instance for fluent date manipulation.
  CarbonInterface? get createdAt {
    final value = getAttribute<DateTime?>(_createdAtColumn);
    if (value == null) return null;
    // Create Carbon with explicit UTC timezone since all timestamps are stored in UTC
    final utcDateTime = value.isUtc ? value : value.toUtc();
    return Carbon.fromDateTime(utcDateTime).tz('UTC');
  }

  set createdAt(DateTime? value) => setAttribute(_createdAtColumn, value);

  /// Timestamp when the model was last updated.
  ///
  /// Returns a Carbon instance for fluent date manipulation.
  CarbonInterface? get updatedAt {
    final value = getAttribute<DateTime?>(_updatedAtColumn);
    if (value == null) return null;
    // Create Carbon with explicit UTC timezone since all timestamps are stored in UTC
    final utcDateTime = value.isUtc ? value : value.toUtc();
    return Carbon.fromDateTime(utcDateTime).tz('UTC');
  }

  set updatedAt(DateTime? value) => setAttribute(_updatedAtColumn, value);

  /// Updates the updatedAt timestamp to the current time.
  void touch() {
    final now = Carbon.now().toDateTime();
    updatedAt = now;
    // Also update the attribute store so save() picks up the change
    setAttribute('updated_at', now);
  }
}

/// Implementation mixin for timezone-aware timestamp functionality.
///
/// This mixin is applied to generated tracked model classes (_$ModelName)
/// and provides timezone-aware timestamp functionality. All timestamps are
/// stored and retrieved in UTC using Carbon for fluent date manipulation.
///
/// **Do not use this mixin directly in user-defined model classes.**
/// Use the marker [TimestampsTZ] mixin instead, and the code generator will
/// apply this implementation to the generated tracked model class.
mixin TimestampsTZImpl on ModelAttributes {
  String get _createdAtColumn => TimestampsTZ.defaultCreatedAtColumn;

  String get _updatedAtColumn => TimestampsTZ.defaultUpdatedAtColumn;

  /// Timestamp when the model was created (UTC).
  ///
  /// Returns a Carbon instance in UTC timezone for fluent date manipulation.
  CarbonInterface? get createdAt {
    final value = getAttribute<DateTime?>(_createdAtColumn);
    if (value == null) return null;
    // Ensure the DateTime is UTC, then create Carbon with explicit UTC timezone
    final utcDateTime = value.isUtc ? value : value.toUtc();
    return Carbon.fromDateTime(utcDateTime).tz('UTC');
  }

  set createdAt(Object? value) {
    if (value == null) {
      setAttribute(_createdAtColumn, null);
    } else if (value is CarbonInterface) {
      setAttribute(_createdAtColumn, value.toUtc().toDateTime());
    } else if (value is DateTime) {
      setAttribute(_createdAtColumn, value.isUtc ? value : value.toUtc());
    } else {
      throw ArgumentError(
        'createdAt must be DateTime or CarbonInterface, got ${value.runtimeType}',
      );
    }
  }

  /// Timestamp when the model was last updated (UTC).
  ///
  /// Returns a Carbon instance in UTC timezone for fluent date manipulation.
  CarbonInterface? get updatedAt {
    final value = getAttribute<DateTime?>(_updatedAtColumn);
    if (value == null) return null;
    // Ensure the DateTime is UTC, then create Carbon with explicit UTC timezone
    final utcDateTime = value.isUtc ? value : value.toUtc();
    return Carbon.fromDateTime(utcDateTime).tz('UTC');
  }

  set updatedAt(Object? value) {
    if (value == null) {
      setAttribute(_updatedAtColumn, null);
    } else if (value is CarbonInterface) {
      setAttribute(_updatedAtColumn, value.toUtc().toDateTime());
    } else if (value is DateTime) {
      setAttribute(_updatedAtColumn, value.isUtc ? value : value.toUtc());
    } else {
      throw ArgumentError(
        'updatedAt must be DateTime or CarbonInterface, got ${value.runtimeType}',
      );
    }
  }

  /// Updates the updatedAt timestamp to the current time in UTC.
  void touch() {
    final now = Carbon.now().toUtc().toDateTime();
    updatedAt = now;
    // Also update the attribute store so save() picks up the change
    setAttribute('updated_at', now);
  }
}

/// Implementation mixin for timezone-aware soft-delete functionality.
///
/// This mixin is applied to generated tracked model classes (_$ModelName)
/// and provides timezone-aware soft-delete functionality. The deletion
/// timestamp is stored in UTC using Carbon for fluent date manipulation.
///
/// **Do not use this mixin directly in user-defined model classes.**
/// Use the marker [SoftDeletesTZ] mixin instead, and the code generator will
/// apply this implementation to the generated tracked model class.
mixin SoftDeletesTZImpl on ModelAttributes {
  String get _column => getSoftDeleteColumn() ?? SoftDeletesTZ.defaultColumn;

  /// Timestamp describing when the row was soft deleted (UTC).
  ///
  /// Returns a Carbon instance in UTC timezone for fluent date manipulation.
  CarbonInterface? get deletedAt {
    final value = getAttribute<DateTime?>(_column);
    return value != null ? Carbon.fromDateTime(value).toUtc() : null;
  }

  set deletedAt(DateTime? value) {
    setAttribute(
      _column,
      value != null ? Carbon.fromDateTime(value).toUtc().toDateTime() : null,
    );
  }

  /// Whether the model currently has a deletion timestamp.
  bool get trashed => getAttribute<DateTime?>(_column) != null;

  /// Soft deletes the model by setting deletedAt to the current UTC time.
  void trash() {
    deletedAt = Carbon.now().toUtc().toDateTime();
  }

  /// Restores a soft-deleted model by clearing the deletedAt timestamp.
  void untrash() {
    deletedAt = null;
  }
}
