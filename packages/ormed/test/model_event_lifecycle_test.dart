import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  late ModelRegistry registry;
  late InMemoryQueryExecutor executor;
  late QueryContext context;

  setUp(() {
    final bus = EventBus.instance..reset();
    registry = bootstrapOrm(
      registerFactories: false,
      registerEventHandlers: true,
      bus: bus,
    );
    executor = InMemoryQueryExecutor();
    executor.register(
      EventModelOrmDefinition.definition,
      const <$EventModel>[],
    );
    context = QueryContext(registry: registry, driver: executor, events: bus);
    Model.bindConnectionResolver(resolveConnection: (_) => context);
    EventModel.resetLog();
  });

  test('emits creating/created on insert', () async {
    await context.query<EventModel>().create({'name': 'alpha', 'score': 1});
    expect(
      EventModel.lifecycleLog,
      containsAllInOrder(['saving', 'creating', 'created', 'saved']),
    );
  });

  test(
    'repository insert emits creating/created for tracked $EventModel',
    () async {
      final repo = Model.repository<$EventModel>(connection: null);
      final created = await repo.insert(
        $EventModel(id: 0, name: 'alpha', score: 1),
      );
      expect(created.name, 'alpha');
      expect(
        EventModel.lifecycleLog,
        containsAllInOrder(['saving', 'creating', 'created', 'saved']),
      );
    },
  );

  test('emits retrieved on select', () async {
    await context.query<EventModel>().create({'name': 'alpha', 'score': 1});
    EventModel.resetLog();

    final row = await context.query<EventModel>().first();
    expect(row, isNotNull);
    expect(EventModel.lifecycleLog, contains('retrieved'));
  });

  test('emits updating/updated on tracked update', () async {
    final created = await context.query<EventModel>().create({
      'name': 'alpha',
      'score': 1,
    });
    final id = created.id;

    // Load tracked instance, then clear log to capture only update lifecycle.
    var model = (await context
        .query<EventModel>()
        .whereEquals('id', id)
        .first())!;
    EventModel.resetLog();

    (model as ModelAttributes).setAttribute('name', 'bravo');
    model = await context
        .query<EventModel>()
        .whereEquals('id', id)
        .updateInputs([model])
        .then((list) => list.single);

    expect(
      EventModel.lifecycleLog,
      containsAllInOrder(['saving', 'updating', 'updated', 'saved']),
    );
    expect(model.name, 'bravo');
  });

  test('emits deleting/deleted/trashed and restoring/restored', () async {
    final created = await context.query<EventModel>().create({
      'name': 'alpha',
      'score': 1,
    });
    final id = created.id;

    EventModel.resetLog();
    final deleted = await context
        .query<EventModel>()
        .whereEquals('id', id)
        .deleteReturning();
    expect(deleted, isNotEmpty);
    expect(
      EventModel.lifecycleLog,
      containsAllInOrder(['deleting', 'deleted', 'trashed']),
    );

    EventModel.resetLog();
    final restored = await context
        .query<EventModel>()
        .withTrashed()
        .whereEquals('id', id)
        .restore();
    expect(restored, equals(1));
    expect(
      EventModel.lifecycleLog,
      containsAllInOrder(['restoring', 'restored']),
    );
  });

  test('emits deleting/forceDeleted on force delete', () async {
    final created = await context.query<EventModel>().create({
      'name': 'alpha',
      'score': 1,
    });
    final id = created.id;

    EventModel.resetLog();
    final deletedCount = await context
        .query<EventModel>()
        .withTrashed()
        .whereEquals('id', id)
        .forceDelete();

    expect(deletedCount, equals(1));
    expect(
      EventModel.lifecycleLog,
      containsAllInOrder(['deleting', 'deleted', 'forceDeleted']),
    );
  });

  test(
    'repository update/delete/restore emits events for tracked $EventModel',
    () async {
      final repo = Model.repository<$EventModel>(connection: null);

      final created = await repo.insert(
        $EventModel(id: 0, name: 'alpha', score: 1),
      );
      final id = created.id;

      EventModel.resetLog();
      final updated = await repo.updateMany([created.copyWith(name: 'bravo')]);
      expect(updated.single.name, 'bravo');
      expect(
        EventModel.lifecycleLog,
        containsAllInOrder(['saving', 'updating', 'updated', 'saved']),
      );

      EventModel.resetLog();
      final deletedCount = await repo.deleteMany([created]);
      expect(deletedCount, equals(1));
      expect(
        EventModel.lifecycleLog,
        containsAllInOrder(['deleting', 'deleted', 'trashed']),
      );

      EventModel.resetLog();
      final restored = await repo.restore(
        (Query<$EventModel> q) => q.withTrashed().whereEquals('id', id),
      );
      expect(restored, equals(1));
      expect(
        EventModel.lifecycleLog,
        containsAllInOrder(['restoring', 'restored']),
      );
    },
  );

  test('repository replicate emits replicating', () {
    final repo = Model.repository<$EventModel>(connection: null);
    final model = $EventModel(id: 0, name: 'alpha', score: 1);

    EventModel.resetLog();
    final copy = repo.replicate(model);

    expect(copy.id, 0);
    expect(EventModel.lifecycleLog, contains('replicating'));
  });
}
