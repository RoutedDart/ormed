/// Model lifecycle events for ormed.
///
/// These events are emitted during model CRUD operations.
library;

import '../events/event_bus.dart';

/// Base class for model lifecycle events.
abstract class ModelEvent extends Event {
  ModelEvent({
    required this.modelType,
    required this.tableName,
    super.timestamp,
  });

  /// The runtime type of the model.
  final Type modelType;

  /// The database table name.
  final String tableName;
}

/// Event emitted before a model is created in the database.
///
/// This event is cancellable - calling [cancel] will prevent the insert.
class ModelCreatingEvent extends ModelEvent with CancellableEvent {
  ModelCreatingEvent({
    required super.modelType,
    required super.tableName,
    required this.attributes,
    super.timestamp,
  });

  /// The attributes being inserted.
  final Map<String, dynamic> attributes;
}

/// Event emitted after a model is created in the database.
class ModelCreatedEvent extends ModelEvent {
  ModelCreatedEvent({
    required super.modelType,
    required super.tableName,
    required this.model,
    required this.attributes,
    super.timestamp,
  });

  /// The created model instance.
  final dynamic model;

  /// The attributes that were inserted.
  final Map<String, dynamic> attributes;
}

/// Event emitted before a model is saved (create or update).
///
/// This event is cancellable - calling [cancel] will prevent the operation.
class ModelSavingEvent extends ModelEvent with CancellableEvent {
  ModelSavingEvent({
    required super.modelType,
    required super.tableName,
    this.model,
    required this.attributes,
    super.timestamp,
  });

  /// The model being saved (may be null for inserts created from maps/DTOs).
  final dynamic model;

  /// Attributes that will be persisted.
  final Map<String, dynamic> attributes;
}

/// Event emitted after a model is saved (create or update).
class ModelSavedEvent extends ModelEvent {
  ModelSavedEvent({
    required super.modelType,
    required super.tableName,
    required this.model,
    required this.attributes,
    super.timestamp,
  });

  /// The saved model instance.
  final dynamic model;

  /// Attributes persisted in the save.
  final Map<String, dynamic> attributes;
}

/// Event emitted before a model is updated in the database.
///
/// This event is cancellable - calling [cancel] will prevent the update.
class ModelUpdatingEvent extends ModelEvent with CancellableEvent {
  ModelUpdatingEvent({
    required super.modelType,
    required super.tableName,
    required this.model,
    required this.originalAttributes,
    required this.dirtyAttributes,
    super.timestamp,
  });

  /// The model being updated.
  final dynamic model;

  /// The original attributes before changes.
  final Map<String, dynamic> originalAttributes;

  /// Only the attributes that have changed.
  final Map<String, dynamic> dirtyAttributes;
}

/// Event emitted after a model is updated in the database.
class ModelUpdatedEvent extends ModelEvent {
  ModelUpdatedEvent({
    required super.modelType,
    required super.tableName,
    required this.model,
    required this.originalAttributes,
    required this.changedAttributes,
    super.timestamp,
  });

  /// The updated model instance.
  final dynamic model;

  /// The original attributes before the update.
  final Map<String, dynamic> originalAttributes;

  /// The attributes that were changed.
  final Map<String, dynamic> changedAttributes;
}

/// Event emitted before a model is deleted from the database.
///
/// This event is cancellable - calling [cancel] will prevent the delete.
class ModelDeletingEvent extends ModelEvent with CancellableEvent {
  ModelDeletingEvent({
    required super.modelType,
    required super.tableName,
    required this.model,
    required this.forceDelete,
    super.timestamp,
  });

  /// The model being deleted.
  final dynamic model;

  /// Whether this is a force delete (bypassing soft delete).
  final bool forceDelete;
}

/// Event emitted when a soft-deleted model is trashed.
class ModelTrashedEvent extends ModelEvent {
  ModelTrashedEvent({
    required super.modelType,
    required super.tableName,
    required this.model,
    super.timestamp,
  });

  /// The trashed model instance.
  final dynamic model;
}

/// Event emitted when a model is permanently deleted (force delete).
class ModelForceDeletedEvent extends ModelEvent {
  ModelForceDeletedEvent({
    required super.modelType,
    required super.tableName,
    required this.model,
    super.timestamp,
  });

  /// The force-deleted model instance.
  final dynamic model;
}

/// Event emitted after a model is deleted from the database.
class ModelDeletedEvent extends ModelEvent {
  ModelDeletedEvent({
    required super.modelType,
    required super.tableName,
    required this.model,
    required this.forceDelete,
    super.timestamp,
  });

  /// The deleted model instance.
  final dynamic model;

  /// Whether this was a force delete.
  final bool forceDelete;
}

/// Event emitted before a model is restored from soft delete.
class ModelRestoringEvent extends ModelEvent with CancellableEvent {
  ModelRestoringEvent({
    required super.modelType,
    required super.tableName,
    required this.model,
    super.timestamp,
  });

  /// The model being restored.
  final dynamic model;
}

/// Event emitted after a model is restored from soft delete.
class ModelRestoredEvent extends ModelEvent {
  ModelRestoredEvent({
    required super.modelType,
    required super.tableName,
    required this.model,
    super.timestamp,
  });

  /// The restored model instance.
  final dynamic model;
}

/// Event emitted when a model is being replicated.
class ModelReplicatingEvent extends ModelEvent with CancellableEvent {
  ModelReplicatingEvent({
    required super.modelType,
    required super.tableName,
    required this.model,
    super.timestamp,
  });

  /// The model being replicated.
  final dynamic model;
}

/// Event emitted when a model is retrieved from the database.
class ModelRetrievedEvent extends ModelEvent {
  ModelRetrievedEvent({
    required super.modelType,
    required super.tableName,
    required this.model,
    super.timestamp,
  });

  /// The retrieved model instance.
  final dynamic model;
}

// ─────────────────────────────────────────────────────────────────────────────
// Convenience Annotations
// ─────────────────────────────────────────────────────────────────────────────

/// Convenience annotation for model creating events.
class OnCreating extends OnEvent {
  const OnCreating() : super(ModelCreatingEvent);
}

/// Convenience annotation for model created events.
class OnCreated extends OnEvent {
  const OnCreated() : super(ModelCreatedEvent);
}

/// Convenience annotation for model saving events.
class OnSaving extends OnEvent {
  const OnSaving() : super(ModelSavingEvent);
}

/// Convenience annotation for model saved events.
class OnSaved extends OnEvent {
  const OnSaved() : super(ModelSavedEvent);
}

/// Convenience annotation for model updating events.
class OnUpdating extends OnEvent {
  const OnUpdating() : super(ModelUpdatingEvent);
}

/// Convenience annotation for model updated events.
class OnUpdated extends OnEvent {
  const OnUpdated() : super(ModelUpdatedEvent);
}

/// Convenience annotation for model deleting events.
class OnDeleting extends OnEvent {
  const OnDeleting() : super(ModelDeletingEvent);
}

/// Convenience annotation for model deleted events.
class OnDeleted extends OnEvent {
  const OnDeleted() : super(ModelDeletedEvent);
}

/// Convenience annotation for model restoring events.
class OnRestoring extends OnEvent {
  const OnRestoring() : super(ModelRestoringEvent);
}

/// Convenience annotation for model restored events.
class OnRestored extends OnEvent {
  const OnRestored() : super(ModelRestoredEvent);
}

/// Convenience annotation for model trashed events.
class OnTrashed extends OnEvent {
  const OnTrashed() : super(ModelTrashedEvent);
}

/// Convenience annotation for model force-deleted events.
class OnForceDeleted extends OnEvent {
  const OnForceDeleted() : super(ModelForceDeletedEvent);
}

/// Convenience annotation for model replicating events.
class OnReplicating extends OnEvent {
  const OnReplicating() : super(ModelReplicatingEvent);
}

/// Convenience annotation for model retrieved events.
class OnRetrieved extends OnEvent {
  const OnRetrieved() : super(ModelRetrievedEvent);
}
