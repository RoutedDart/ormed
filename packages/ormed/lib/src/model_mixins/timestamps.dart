/// Marker mixin for timestamp functionality (non-timezone aware).
///
/// This mixin serves as a marker on user-defined model classes to indicate
/// that timestamp fields (createdAt, updatedAt) should be generated and
/// automatically managed. The actual timestamp implementation is generated
/// in the tracked model class (_$ModelName) by the code generator.
///
/// **Non-timezone aware**: Timestamps are stored as-is without timezone conversion.
/// Use [TimestampsTZ] if you need timezone-aware timestamps (UTC storage).
///
/// Usage on user-defined models:
/// ```dart
/// @OrmModel(table: 'posts')
/// class Post extends Model<Post> with Timestamps {
///   final int? id;
///   final String title;
///   // ...
///   const Post({this.id, required this.title});
/// }
/// ```
///
/// The generator will detect this mixin and:
/// 1. Add virtual 'createdAt' and 'updatedAt' fields if not explicitly defined
/// 2. Apply the Timestamps implementation to the generated tracked class
/// 3. Automatically set timestamps on insert/update operations
///
/// **Do not implement methods in this mixin.** All timestamp functionality
/// is provided by the generated tracked model class.
mixin Timestamps {
  /// Default column name for creation timestamp.
  static const String defaultCreatedAtColumn = 'created_at';
  
  /// Default column name for update timestamp.
  static const String defaultUpdatedAtColumn = 'updated_at';
}

/// Marker mixin for timezone-aware timestamp functionality.
///
/// This mixin serves as a marker on user-defined model classes to indicate
/// that timezone-aware timestamp fields (createdAt, updatedAt) should be
/// generated and automatically managed. Timestamps are stored in UTC.
///
/// **Timezone aware**: All timestamps are converted to UTC before storage
/// and remain in UTC when retrieved. The application should handle timezone
/// conversion for display purposes.
///
/// Usage on user-defined models:
/// ```dart
/// @OrmModel(table: 'posts')
/// class Post extends Model<Post> with TimestampsTZ {
///   final int? id;
///   final String title;
///   // ...
///   const Post({this.id, required this.title});
/// }
/// ```
///
/// The generator will detect this mixin and:
/// 1. Add virtual 'createdAt' and 'updatedAt' fields if not explicitly defined
/// 2. Apply the TimestampsTZ implementation to the generated tracked class
/// 3. Automatically set UTC timestamps on insert/update operations
///
/// **Do not implement methods in this mixin.** All timestamp functionality
/// is provided by the generated tracked model class.
mixin TimestampsTZ {
  /// Default column name for creation timestamp.
  static const String defaultCreatedAtColumn = 'created_at';
  
  /// Default column name for update timestamp.
  static const String defaultUpdatedAtColumn = 'updated_at';
}

/// Marker mixin for timezone-aware soft-delete functionality.
///
/// Similar to [SoftDeletes] but ensures the deletion timestamp is stored in UTC.
///
/// Usage on user-defined models:
/// ```dart
/// @OrmModel(table: 'posts')
/// class Post extends Model<Post> with SoftDeletesTZ {
///   final int? id;
///   final String title;
///   // ...
///   const Post({this.id, required this.title});
/// }
/// ```
///
/// The generator will detect this mixin and:
/// 1. Add a virtual 'deletedAt' field if not explicitly defined
/// 2. Apply the SoftDeletesTZ implementation to the generated tracked class
/// 3. Store deletion timestamps in UTC
/// 4. Enable soft-delete query scopes automatically
///
/// **Do not implement methods in this mixin.** All soft-delete functionality
/// is provided by the generated tracked model class.
mixin SoftDeletesTZ {
  /// Default column name used for soft delete tracking.
  static const String defaultColumn = 'deleted_at';
}
