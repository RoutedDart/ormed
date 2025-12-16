/// Model used to exercise all lifecycle events in tests.
library;

import 'package:ormed/ormed.dart';

part 'event_model.orm.dart';

@OrmModel(table: 'event_models', softDeletes: true)
class EventModel extends Model<EventModel>
    with ModelFactoryCapable, SoftDeletes {
  const EventModel({required this.id, required this.name, required this.score});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String name;

  final int score;

  /// Simple in-memory log for test assertions.
  static final List<String> lifecycleLog = <String>[];

  static void resetLog() => lifecycleLog.clear();

  static void _log(String phase, ModelEvent event) {
    lifecycleLog.add(phase);
  }

  @OrmEvent(ModelSavingEvent)
  static void onSaving(ModelSavingEvent event) => _log('saving', event);

  @OrmEvent(ModelCreatingEvent)
  static void onCreating(ModelCreatingEvent event) => _log('creating', event);

  @OrmEvent(ModelCreatedEvent)
  static void onCreated(ModelCreatedEvent event) => _log('created', event);

  @OrmEvent(ModelSavedEvent)
  static void onSaved(ModelSavedEvent event) => _log('saved', event);

  @OrmEvent(ModelUpdatingEvent)
  static void onUpdating(ModelUpdatingEvent event) => _log('updating', event);

  @OrmEvent(ModelUpdatedEvent)
  static void onUpdated(ModelUpdatedEvent event) => _log('updated', event);

  @OrmEvent(ModelDeletingEvent)
  static void onDeleting(ModelDeletingEvent event) => _log('deleting', event);

  @OrmEvent(ModelDeletedEvent)
  static void onDeleted(ModelDeletedEvent event) => _log('deleted', event);

  @OrmEvent(ModelRestoringEvent)
  static void onRestoring(ModelRestoringEvent event) =>
      _log('restoring', event);

  @OrmEvent(ModelRestoredEvent)
  static void onRestored(ModelRestoredEvent event) => _log('restored', event);

  @OrmEvent(ModelTrashedEvent)
  static void onTrashed(ModelTrashedEvent event) => _log('trashed', event);

  @OrmEvent(ModelForceDeletedEvent)
  static void onForceDeleted(ModelForceDeletedEvent event) =>
      _log('forceDeleted', event);

  @OrmEvent(ModelReplicatingEvent)
  static void onReplicating(ModelReplicatingEvent event) =>
      _log('replicating', event);

  @OrmEvent(ModelRetrievedEvent)
  static void onRetrieved(ModelRetrievedEvent event) =>
      _log('retrieved', event);
}
