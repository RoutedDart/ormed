// Model lifecycle event examples for documentation
// ignore_for_file: unused_import, unused_local_variable

import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

import 'package:ormed_examples/src/database/orm_registry.g.dart';

part 'model_events.orm.dart';

final List<String> modelEventLog = [];

bool _forUser(Type modelType) =>
    modelType == EventUser || modelType == $EventUser;

@OrmModel(table: 'event_users')
class EventUser extends Model<EventUser> with SoftDeletes {
  const EventUser({
    required this.id,
    required this.email,
    required this.active,
    this.name,
  });

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String email;
  final bool active;
  final String? name;
}

// #region model-event-listeners
void registerModelEventListeners(EventBus bus) {
  // #region model-event-listeners-saving-created
  bus.on<ModelSavingEvent>((event) {
    if (!_forUser(event.modelType)) return;
    modelEventLog.add('saving ${event.attributes['email']}');
  });

  bus.on<ModelCreatedEvent>((event) {
    if (!_forUser(event.modelType)) return;
    modelEventLog.add('created ${event.model.id}');
  });
  // #endregion model-event-listeners-saving-created

  // #region model-event-listeners-updated-deleted
  bus.on<ModelUpdatedEvent>((event) {
    if (!_forUser(event.modelType)) return;
    modelEventLog.add('updated ${event.model.id}');
  });

  bus.on<ModelDeletedEvent>((event) {
    if (!_forUser(event.modelType)) return;
    final mode = event.forceDelete ? 'forceDelete' : 'trash';
    modelEventLog.add('$mode ${event.model.id}');
  });
  // #endregion model-event-listeners-updated-deleted

  // #region model-event-listeners-retrieved
  bus.on<ModelRetrievedEvent>((event) {
    if (!_forUser(event.modelType)) return;
    modelEventLog.add('retrieved ${event.model.id}');
  });
  // #endregion model-event-listeners-retrieved
}
// #endregion model-event-listeners

// #region model-delete-guard
void enforceActiveUserDeletes(EventBus bus) {
  bus.on<ModelDeletingEvent>((event) {
    if (!_forUser(event.modelType)) return;
    final user = event.model as EventUser;
    if (!user.active) {
      event.cancel(); // block delete/forceDelete
      modelEventLog.add('blocked delete for inactive user ${user.id}');
    }
  });
}
// #endregion model-delete-guard

// #region model-delete-guard-usage
Future<void> guardedDeleteExample(DataSource dataSource) async {
  final inactive = await dataSource.repo<$EventUser>().insert(
    $EventUser(id: 0, email: 'inactive@example.com', active: false),
  );

  final affected = await dataSource
      .query<$EventUser>()
      .whereEquals('id', inactive.id)
      .delete();

  // => 0 (delete is cancelled)
  print(affected);
}
// #endregion model-delete-guard-usage

// #region model-event-annotation
@OrmModel(table: 'audited_users')
class AuditedUser extends Model<AuditedUser> {
  const AuditedUser({required this.id, required this.email});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  final String email;

  @OrmEvent(ModelSavingEvent)
  static void onSaving(ModelSavingEvent event) =>
      modelEventLog.add('saving ${event.attributes['email']}');

  @OrmEvent(ModelCreatedEvent)
  static void onCreated(ModelCreatedEvent event) =>
      modelEventLog.add('created ${event.model.id}');

  @OrmEvent(ModelForceDeletedEvent)
  static void onForceDeleted(ModelForceDeletedEvent event) =>
      modelEventLog.add('forceDeleted ${event.model.id}');
}
// #endregion model-event-annotation

// #region model-events-usage
Future<void> modelEventsUsageExample() async {
  // #region model-events-setup
  final bus = EventBus.instance;
  registerModelEventListeners(bus);
  enforceActiveUserDeletes(bus);

  final dataSource = DataSource(
    DataSourceOptions(
      name: 'events-demo',
      driver: SqliteDriverAdapter.inMemory(),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await dataSource.init();
  // #endregion model-events-setup

  // #region model-events-mutations
  final alice = await dataSource.repo<$EventUser>().insert(
    $EventUser(id: 0, name: 'Alice', email: 'alice@example.com', active: true),
  );

  await dataSource.query<$EventUser>().whereEquals('id', alice.id).update({
    'name': 'Alice Updated',
  });

  await dataSource
      .query<$EventUser>()
      .whereEquals('id', alice.id)
      .deleteReturning();

  await dataSource
      .query<$EventUser>()
      .withTrashed()
      .whereEquals('id', alice.id)
      .restore();

  print(modelEventLog);
  // #endregion model-events-mutations
}

// #endregion model-events-usage
