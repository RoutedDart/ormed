/// Marker mixin for soft-delete functionality.
///
/// This mixin serves as a marker on user-defined model classes to indicate
/// that soft-delete functionality should be generated. The actual soft-delete
/// implementation (deletedAt getter/setter, trashed property) is generated
/// in the tracked model class (_$ModelName) by the code generator.
///
/// Usage on user-defined models:
/// ```dart
/// @OrmModel(table: 'posts')
/// class Post extends Model<Post> with SoftDeletes {
///   final int? id;
///   final String title;
///   // ...
///   const Post({this.id, required this.title});
/// }
/// ```
///
/// The generator will detect this mixin and:
/// 1. Add a virtual 'deletedAt' field if not explicitly defined
/// 2. Apply the SoftDeletes implementation to the generated tracked class
/// 3. Enable soft-delete query scopes automatically
///
/// **Do not implement methods in this mixin.** All soft-delete functionality
/// is provided by the generated tracked model class.
mixin SoftDeletes {
  /// Default column name used for soft delete tracking.
  static const String defaultColumn = 'deleted_at';
}
