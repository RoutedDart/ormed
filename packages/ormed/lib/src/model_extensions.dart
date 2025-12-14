import 'package:carbonized/carbonized.dart';

import 'driver/mutation_plan.dart';
import 'driver/mutation_row.dart';
import 'model.dart';
import 'model_definition.dart';
import 'model_mixins/model_attributes.dart';
import 'model_mixins/model_connection.dart';
import 'model_mixins/model_relations.dart';
import 'model_mixins/soft_deletes_impl.dart';
import 'model_mixins/timestamps_impl.dart';
import 'value_codec.dart';

/// Extensions on Model to provide convenient access to attribute and relation
/// tracking features when working with tracked model instances.
///
/// These extensions check if the model instance is a tracked model (returned
/// from queries/repositories) before accessing the attribute/relation systems.
/// This allows tests and user code to safely call these methods on any Model
/// instance, even though the functionality only works on tracked models.
extension ModelAttributeExtensions<T extends Model<T>> on Model<T> {
  /// Check if an attribute exists in the attribute store.
  ///
  /// Returns true only if this is a tracked model instance (from a query/repository)
  /// and the attribute has been set. Returns false for directly instantiated models.
  bool hasAttribute(String key) {
    if (this is ModelAttributes) {
      return (this as ModelAttributes).hasAttribute(key);
    }
    return false;
  }

  /// Get an attribute value from the attribute store.
  ///
  /// Returns the attribute value if this is a tracked model instance and the
  /// attribute exists. Returns null for directly instantiated models.
  TValue? getAttribute<TValue>(String key) {
    if (this is ModelAttributes) {
      return (this as ModelAttributes).getAttribute<TValue>(key);
    }
    return null;
  }

  /// Set an attribute value in the attribute store.
  ///
  /// Only works if this is a tracked model instance or if the model has
  /// ModelAttributes mixed in. Does nothing for plain user model instances.
  void setAttribute(String key, Object? value) {
    if (this is ModelAttributes) {
      (this as ModelAttributes).setAttribute(key, value);
    }
  }

  /// Get all attributes as a map.
  ///
  /// Returns an empty map for directly instantiated models.
  Map<String, Object?> getAttributes() {
    if (this is ModelAttributes) {
      return (this as ModelAttributes).getAttributes();
    }
    return {};
  }

  /// Set multiple attributes at once.
  ///
  /// Only works if this is a tracked model instance. Does nothing for plain
  /// user model instances.
  void setAttributes(Map<String, Object?> attributes) {
    if (this is ModelAttributes) {
      (this as ModelAttributes).setAttributes(attributes);
    }
  }

  /// Check if the model has been modified since it was loaded.
  ///
  /// Returns false for directly instantiated models.
  bool isDirty([String? key]) {
    if (this is ModelAttributes) {
      return (this as ModelAttributes).isDirty(key);
    }
    return false;
  }

  /// Get the original (unmodified) value of an attribute.
  ///
  /// Returns null for directly instantiated models.
  Object? getOriginal([String? key]) {
    if (this is ModelAttributes) {
      return (this as ModelAttributes).getOriginal(key);
    }
    return null;
  }

  /// Check if a specific attribute has been modified.
  ///
  /// Returns false for directly instantiated models.
  bool wasChanged(String key) {
    if (this is ModelAttributes) {
      return (this as ModelAttributes).wasChanged(key);
    }
    return false;
  }

  /// Get all changed attributes as a map.
  ///
  /// Returns an empty map for directly instantiated models.
  Map<String, Object?> getDirty() {
    if (this is ModelAttributes) {
      return (this as ModelAttributes).getDirty();
    }
    return {};
  }

  /// Sync the original state to match current attributes.
  ///
  /// Only works if this is a tracked model instance.
  void syncOriginal() {
    if (this is ModelAttributes) {
      (this as ModelAttributes).syncOriginal();
    }
  }

  /// Get the raw attributes map.
  ///
  /// Returns an empty map for directly instantiated models.
  Map<String, Object?> get attributes {
    if (this is ModelAttributes) {
      return (this as ModelAttributes).attributes;
    }
    return {};
  }

  /// Replace all attributes with new values.
  ///
  /// Only works if this is a tracked model instance.
  void replaceAttributes(Map<String, Object?> attributes) {
    if (this is ModelAttributes) {
      (this as ModelAttributes).replaceAttributes(attributes);
    }
  }

  /// Attach a model definition to this model instance.
  ///
  /// Only works if this is a tracked model instance.
  void attachModelDefinition(ModelDefinition<T> definition) {
    if (this is ModelAttributes) {
      (this as ModelAttributes).attachModelDefinition(definition);
    }
  }

  /// Get all changed attributes with their new values (alias for getDirty).
  ///
  /// Returns an empty map for directly instantiated models.
  Map<String, Object?> getChanges() {
    return getDirty();
  }

  /// Fill attributes from payload, respecting fillable/guarded metadata.
  ///
  /// Returns a map of filled attributes. Only works if this is a tracked model instance.
  Map<String, Object?> fillAttributes(
    Map<String, Object?> payload, {
    bool strict = true,
    ValueCodecRegistry? registry,
  }) {
    if (this is ModelAttributes) {
      return (this as ModelAttributes).fillAttributes(
        payload,
        strict: strict,
        registry: registry,
      );
    }
    return {};
  }

  /// Check if a relation has been loaded.
  ///
  /// Returns false for directly instantiated models.
  bool relationLoaded(String relation) {
    return (this as ModelRelations).relationLoaded(relation);
  }

  /// Get a loaded relation value.
  ///
  /// Returns null for directly instantiated models or if the relation
  /// hasn't been loaded.
  TRelation? getRelation<TRelation>(String relation) {
    return (this as ModelRelations).getRelation<TRelation>(relation);
  }

  /// Get a loaded relation list.
  ///
  /// Returns an empty list for directly instantiated models or if the
  /// relation hasn't been loaded.
  List<TRelation> getRelationList<TRelation>(String relation) {
    return (this as ModelRelations).getRelationList<TRelation>(relation);
  }

  /// Set a relation value.
  ///
  /// Only works if this is a tracked model instance.
  void setRelation(String relation, dynamic value) {
    (this as ModelRelations).setRelation(relation, value);
  }

  /// Unload a relation.
  ///
  /// Only works if this is a tracked model instance.
  void unsetRelation(String relation) {
    (this as ModelRelations).unsetRelation(relation);
  }

  /// Get all loaded relations as a map.
  ///
  /// Returns an empty map for directly instantiated models.
  Map<String, dynamic> getLoadedRelations() {
    return (this as ModelRelations).loadedRelations;
  }

  /// Get all loaded relations as a map (shorthand for getLoadedRelations).
  ///
  /// Returns an empty map for directly instantiated models.
  Map<String, dynamic> get relations {
    return (this as ModelRelations).loadedRelations;
  }

  /// Get names of all loaded relations.
  ///
  /// Returns an empty set for directly instantiated models.
  Set<String> get loadedRelationNames {
    return (this as ModelRelations).loadedRelationNames;
  }

  /// Get all loaded relations as a map (property alias).
  ///
  /// Returns an empty map for directly instantiated models.
  Map<String, dynamic> get loadedRelations {
    return (this as ModelRelations).loadedRelations;
  }

  /// Set multiple relations at once.
  ///
  /// Only works if this is a tracked model instance.
  void setRelations(Map<String, dynamic> relations) {
    (this as ModelRelations).setRelations(relations);
  }

  /// Clear all loaded relations.
  ///
  /// Only works if this is a tracked model instance.
  void clearRelations() {
    (this as ModelRelations).clearRelations();
  }

  /// Sync relations from a query row map.
  ///
  /// Only works if this is a tracked model instance.
  void syncRelationsFromQueryRow(Map<String, dynamic> row) {
    (this as ModelRelations).syncRelationsFromQueryRow(row);
  }
}

/// Extensions for timestamp functionality on models.
///
/// These extensions provide safe access to timestamp methods when working
/// with models that may or may not have timestamp support.
///
/// All timestamp getters return Carbon instances for fluent date manipulation.
extension ModelTimestampExtensions<T extends Model<T>> on Model<T> {
  /// Get the creation timestamp as a Carbon instance.
  ///
  /// Returns null for directly instantiated models without timestamp tracking.
  /// For fluent date manipulation:
  /// ```dart
  /// final post = await Post.query().find(1);
  /// print(post.createdAt?.diffForHumans()); // "2 hours ago"
  /// print(post.createdAt?.format('Y-m-d H:i:s'));
  /// ```
  CarbonInterface? get createdAt {
    if (this is TimestampsImpl) {
      return (this as TimestampsImpl).createdAt;
    }
    if (this is TimestampsTZImpl) {
      return (this as TimestampsTZImpl).createdAt;
    }
    return null;
  }

  /// Set the creation timestamp.
  ///
  /// Accepts DateTime or Carbon instance. Only works if this is a tracked
  /// model instance with timestamp support.
  set createdAt(DateTime? value) {
    if (this is TimestampsImpl) {
      (this as TimestampsImpl).createdAt = value;
    } else if (this is TimestampsTZImpl) {
      (this as TimestampsTZImpl).createdAt = value;
    }
  }

  /// Get the last update timestamp as a Carbon instance.
  ///
  /// Returns null for directly instantiated models without timestamp tracking.
  /// For fluent date manipulation:
  /// ```dart
  /// final post = await Post.query().find(1);
  /// print(post.updatedAt?.isToday()); // true/false
  /// print(post.updatedAt?.addDays(5).format('Y-m-d'));
  /// ```
  CarbonInterface? get updatedAt {
    if (this is TimestampsImpl) {
      return (this as TimestampsImpl).updatedAt;
    }
    if (this is TimestampsTZImpl) {
      return (this as TimestampsTZImpl).updatedAt;
    }
    return null;
  }

  /// Set the last update timestamp.
  ///
  /// Accepts DateTime or Carbon instance. Only works if this is a tracked
  /// model instance with timestamp support.
  set updatedAt(DateTime? value) {
    if (this is TimestampsImpl) {
      (this as TimestampsImpl).updatedAt = value;
    } else if (this is TimestampsTZImpl) {
      (this as TimestampsTZImpl).updatedAt = value;
    }
  }

  /// Updates the updatedAt timestamp to the current time.
  ///
  /// For TimestampsTZ models, uses UTC time.
  /// Only works if this is a tracked model instance with timestamp support.
  void touch() {
    if (this is TimestampsImpl) {
      (this as TimestampsImpl).touch();
    } else if (this is TimestampsTZImpl) {
      (this as TimestampsTZImpl).touch();
    }
  }

  /// Saves the current model instance to the database.
  ///
  /// This method persists any changes made to the model attributes back to
  /// the database. It requires that the model was hydrated via a QueryContext
  /// or Repository (i.e., it has a connection resolver attached).
  ///
  /// Returns a Future that completes when the save operation is done.
  ///
  /// Throws [StateError] if the model doesn't have a connection resolver attached.
  Future<void> save() async {
    final conn = this as ModelConnection;
    if (!conn.hasConnection) {
      throw StateError(
        'Cannot save: No connection resolver attached to $runtimeType. '
        'Ensure the model was hydrated via a QueryContext or Repository.',
      );
    }

    if (this is! ModelAttributes) {
      throw StateError(
        'Cannot save: $runtimeType does not have ModelAttributes mixin.',
      );
    }

    final attrs = this as ModelAttributes;
    final dirty = attrs.getDirty();

    if (dirty.isEmpty) {
      return; // Nothing to save
    }

    // Get the model definition from the registry
    final resolver = conn.connectionResolver!;
    final definition = resolver.registry.expect<T>();

    // Get the primary key field
    final pkField = definition.primaryKeyField;
    if (pkField == null) {
      throw StateError(
        'Cannot save: Model $runtimeType does not have a primary key defined.',
      );
    }

    // Get the primary key value
    final pkValue = getAttribute(pkField.name);
    if (pkValue == null) {
      throw StateError('Cannot save: Model does not have a primary key value.');
    }

    // Build and execute update mutation
    final plan = MutationPlan.update(
      definition: definition,
      rows: [
        MutationRow(values: dirty, keys: {pkField.columnName: pkValue}),
      ],
      driverName: resolver.driver.metadata.name,
    );

    await conn.runMutation(plan);

    // Sync original attributes with current state
    attrs.syncOriginal();
  }
}

/// Extensions for soft delete functionality on models.
///
/// These extensions provide safe access to soft delete methods when working
/// with models that may or may not have soft delete support.
extension ModelSoftDeleteExtensions<T extends Model<T>> on Model<T> {
  /// Check if the model has been soft deleted.
  ///
  /// Returns true only if this is a tracked model instance with soft delete
  /// support and the model has been soft deleted. Returns false otherwise.
  bool get trashed {
    if (this is SoftDeletesImpl) {
      return (this as SoftDeletesImpl).trashed;
    }
    if (this is SoftDeletesTZImpl) {
      return (this as SoftDeletesTZImpl).trashed;
    }
    return false;
  }

  /// Get the soft delete timestamp as a Carbon instance.
  ///
  /// Returns the deletion timestamp if this is a tracked model instance with
  /// soft delete support and has been deleted. Returns null otherwise.
  /// For fluent date manipulation:
  /// ```dart
  /// final user = await User.query().withTrashed().find(1);
  /// print(user.deletedAt?.diffForHumans()); // "3 days ago"
  /// ```
  CarbonInterface? get deletedAt {
    if (this is SoftDeletesImpl) {
      final dt = (this as SoftDeletesImpl).deletedAt;
      return dt != null ? Carbon.fromDateTime(dt) : null;
    }
    if (this is SoftDeletesTZImpl) {
      return (this as SoftDeletesTZImpl).deletedAt;
    }
    return null;
  }

  /// Set the soft delete timestamp.
  ///
  /// Only works if this is a tracked model instance with soft delete support.
  /// For SoftDeletesTZ models, the timestamp is automatically converted to UTC.
  set deletedAt(DateTime? value) {
    if (this is SoftDeletesImpl) {
      (this as SoftDeletesImpl).deletedAt = value;
    } else if (this is SoftDeletesTZImpl) {
      (this as SoftDeletesTZImpl).deletedAt = value;
    }
  }
}
