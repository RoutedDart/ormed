/// Write-side helpers for inserting models via driver adapters.
library;

import 'package:carbonized/carbonized.dart';

import '../driver/driver.dart';
import '../model_definition.dart';
import '../model_mixins/model_attributes.dart';
import '../query/json_path.dart' as json_path;
import '../value_codec.dart';

// Part files for repository mixins
part 'repository_insert_mixin.dart';
part 'repository_update_mixin.dart';
part 'repository_upsert_mixin.dart';
part 'repository_delete_mixin.dart';
part 'repository_preview_mixin.dart';
part 'repository_helpers_mixin.dart';

typedef JsonUpdateBuilder<T> = List<JsonUpdateDefinition> Function(T model);

/// Base class for repositories.
///
/// This abstract class provides the core dependencies and accessors that all
/// repository mixins require.
abstract class RepositoryBase<T> {
  ModelDefinition<T> get definition;
  String get driverName;
  ValueCodecRegistry get codecs;
  Future<MutationResult> Function(MutationPlan plan) get runMutation;
  StatementPreview Function(MutationPlan plan) get describeMutation;
  void Function(Object? model) get attachRuntimeMetadata;
}

/// A repository for a model of type [T].
///
/// Provides methods for inserting, updating, upserting and deleting models.
/// The repository is composed of several mixins, each providing a specific
/// set of operations:
///
/// - [RepositoryInsertMixin] - Insert operations
/// - [RepositoryUpdateMixin] - Update operations
/// - [RepositoryUpsertMixin] - Upsert operations
/// - [RepositoryDeleteMixin] - Delete operations
/// - [RepositoryPreviewMixin] - Preview methods for all operations
/// - [RepositoryHelpersMixin] - Internal helper methods
class Repository<T> extends RepositoryBase<T>
    with
        RepositoryHelpersMixin<T>,
        RepositoryInsertMixin<T>,
        RepositoryUpdateMixin<T>,
        RepositoryUpsertMixin<T>,
        RepositoryDeleteMixin<T>,
        RepositoryPreviewMixin<T> {
  Repository({
    required ModelDefinition<T> definition,
    required String driverName,
    required Future<MutationResult> Function(MutationPlan plan) runMutation,
    required StatementPreview Function(MutationPlan plan) describeMutation,
    required void Function(Object? model) attachRuntimeMetadata,
  }) : _definition = definition,
       _driverName = driverName,
       _runMutation = runMutation,
       _describeMutation = describeMutation,
       _attachRuntimeMetadata = attachRuntimeMetadata;

  final ModelDefinition<T> _definition;
  final String _driverName;
  final Future<MutationResult> Function(MutationPlan plan) _runMutation;
  final StatementPreview Function(MutationPlan plan) _describeMutation;
  final void Function(Object? model) _attachRuntimeMetadata;

  @override
  ModelDefinition<T> get definition => _definition;

  @override
  String get driverName => _driverName;

  @override
  ValueCodecRegistry get codecs =>
      ValueCodecRegistry.instance.forDriver(_driverName);

  @override
  Future<MutationResult> Function(MutationPlan plan) get runMutation =>
      _runMutation;

  @override
  StatementPreview Function(MutationPlan plan) get describeMutation =>
      _describeMutation;

  @override
  void Function(Object? model) get attachRuntimeMetadata =>
      _attachRuntimeMetadata;
}

/// Defines a JSON update operation.
class JsonUpdateDefinition {
  /// Creates a new [JsonUpdateDefinition].
  ///
  /// The [fieldOrColumn] is the name of the field or column to update.
  /// The [path] is the JSON path to the value to update.
  /// The [value] is the new value.
  /// If [patch] is `true`, the [value] is merged with the existing value.
  JsonUpdateDefinition({
    required this.fieldOrColumn,
    required this.path,
    required this.value,
    this.patch = false,
  });

  /// Creates a new [JsonUpdateDefinition] from a [selector] and [value].
  ///
  /// The [selector] is a string that contains the field/column name and the
  /// JSON path, e.g. `meta.tags`.
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

  /// Creates a new [JsonUpdateDefinition] from a [fieldOrColumn], [path] and
  /// [value].
  factory JsonUpdateDefinition.path(
    String fieldOrColumn,
    String path,
    Object? value,
  ) => JsonUpdateDefinition(
    fieldOrColumn: fieldOrColumn,
    path: json_path.normalizeJsonPath(path),
    value: value,
  );

  /// Creates a new [JsonUpdateDefinition] for a patch operation.
  ///
  /// The [fieldOrColumn] is the name of the field or column to update.
  /// The [delta] is a map of key-value pairs to merge with the existing value.
  factory JsonUpdateDefinition.patch(
    String fieldOrColumn,
    Map<String, Object?> delta,
  ) => JsonUpdateDefinition(
    fieldOrColumn: fieldOrColumn,
    path: r'$',
    value: delta,
    patch: true,
  );

  /// The name of the field or column to update.
  final String fieldOrColumn;

  /// The JSON path to the value to update.
  final String path;

  /// The new value.
  final Object? value;

  /// Whether to merge the [value] with the existing value.
  final bool patch;
}
