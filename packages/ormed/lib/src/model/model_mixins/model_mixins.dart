/// Core model mixins and helpers used by Ormed.
///
/// These mixins are used by generated tracked models (prefixed with `$`) and
/// by user-defined model classes that opt into features like soft deletes,
/// timestamps, factories, and attribute tracking.
///
/// {@template ormed.model.tracked_instances}
/// Ormed distinguishes between:
/// - User-defined models (`class User extends Model<User>`) which are typically
///   immutable value objects.
/// - Generated tracked models (`$User`) which Ormed hydrates from queries and
///   uses for change tracking, relation caching, and persistence helpers.
///
/// Many APIs in the model layer only behave correctly on tracked instances.
/// Prefer using repositories (`DataSource.repo<T>()`) or queries
/// (`DataSource.query<T>()`) to obtain tracked models.
/// {@endtemplate}
///
/// {@template ormed.model.connection_setup}
/// Before using model helpers that hit the database, a connection must be
/// configured.
///
/// In most apps, calling `DataSource.init()` is sufficient because it registers
/// a default data source on `ConnectionManager`. For custom wiring, call
/// `Model.bindConnectionResolver(...)`.
/// {@endtemplate}
///
/// {@template ormed.model.tracked_only}
/// This API requires a tracked instance (a generated `$Model`) hydrated by the
/// ORM. Calling it on a manually instantiated user model may throw or behave as
/// a no-op.
/// {@endtemplate}
///
/// {@template ormed.model.mass_assignment}
/// Ormed supports Laravel-style mass assignment controls.
///
/// Use `@OrmModel(fillable: [...])` / `@OrmModel(guarded: [...])` (and per-field
/// overrides on `@OrmField(...)`) to decide which attributes are allowed when
/// filling from untrusted payloads.
///
/// You typically apply these rules via:
/// - `ModelAttributes.fillAttributes(...)`, when working with tracked models.
/// - `filteredByAttributes(...)`, when filtering a raw map.
///
/// When `strict` is `true`, guarded fields throw `MassAssignmentException`.
/// To temporarily bypass guards (for internal code), use
/// `ModelAttributes.unguarded(...)`.
/// {@endtemplate}
///
/// {@template ormed.model.json_attribute_updates}
/// Ormed can emit partial JSON column updates without replacing the entire
/// JSON value.
///
/// On tracked models, queue updates with:
/// - `ModelAttributes.setJsonAttributeValue(...)` for path-based assignments.
/// - `ModelAttributes.setJsonAttributePatch(...)` for JSON merge operations.
///
/// Pending JSON updates are consumed the next time the model participates in a
/// mutation plan (for example, via `Model.save(...)` or repository mutations).
/// {@endtemplate}
library;

export 'model_attribute_extensions.dart';
export 'model_attribute_inspector.dart';
export 'model_attributes.dart';
export 'model_connection.dart';
export 'model_factory.dart';
export 'model_mixins.dart';
export 'model_relations.dart';
export 'model_with_tracked.dart';
export 'soft_deletes.dart';
export 'soft_deletes_impl.dart';
export 'timestamps.dart';
export 'timestamps_impl.dart';
