// Model lifecycle event examples for documentation
// ignore_for_file: unused_import, unused_local_variable

import 'package:ormed/ormed.dart';

import '../models/user.dart';
import '../models/user.orm.dart';
import '../orm_registry.g.dart';

final List<String> modelEventLog = [];

bool _forUser(Type modelType) => modelType == User || modelType == $User;

// #region model-event-listeners
void registerModelEventListeners(EventBus bus) {
  bus.on<ModelSavingEvent>((event) {
    if (!_forUser(event.modelType)) return;
    modelEventLog.add('saving ${event.attributes['email']}');
  });

  bus.on<ModelCreatedEvent>((event) {
    if (!_forUser(event.modelType)) return;
    modelEventLog.add('created ${event.model.id}');
  });

  bus.on<ModelUpdatedEvent>((event) {
    if (!_forUser(event.modelType)) return;
    modelEventLog.add('updated ${event.model.id}');
  });

  bus.on<ModelDeletedEvent>((event) {
    if (!_forUser(event.modelType)) return;
    final mode = event.forceDelete ? 'forceDelete' : 'trash';
    modelEventLog.add('$mode ${event.model.id}');
  });

  bus.on<ModelRetrievedEvent>((event) {
    if (!_forUser(event.modelType)) return;
    modelEventLog.add('retrieved ${event.model.id}');
  });
}
// #endregion model-event-listeners

// #region model-delete-guard
void enforceActiveUserDeletes(EventBus bus) {
  bus.on<ModelDeletingEvent>((event) {
    if (!_forUser(event.modelType)) return;
    final user = event.model as $User;
    if (!user.active) {
      event.cancel(); // block delete/forceDelete
      modelEventLog.add('blocked delete for inactive user ${user.id}');
    }
  });
}
// #endregion model-delete-guard

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
  final bus = EventBus.instance;
  registerModelEventListeners(bus);
  enforceActiveUserDeletes(bus);

  final dataSource = DataSource(
    DataSourceOptions(
      name: 'events-demo',
      driver: InMemoryQueryExecutor(),
      entities: generatedOrmModelDefinitions,
    ),
  );
  await dataSource.init();

  final alice = await dataSource.repo<$User>().insert(
        $User(id: 0, name: 'Alice', email: 'alice@example.com'),
      );

  await dataSource
      .query<$User>()
      .whereEquals('id', alice.id)
      .update({'name': 'Alice Updated'});

  await dataSource
      .query<$User>()
      .whereEquals('id', alice.id)
      .deleteReturning();

  print(modelEventLog);
}
// #endregion model-events-usage

