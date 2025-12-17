import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

import '../../models.dart';

void runModelEventCancelTests() {
  ormedGroup('model event cancellation', (dataSource) {
    test(
      'ModelDeletingEvent.cancel blocks deletes for matching models',
      () async {
        final repo = dataSource.context.repository<$User>();
        final deletingEvents = <ModelDeletingEvent>[];

        final unsubscribe = EventBus.instance.on<ModelDeletingEvent>((event) {
          if (event.modelType != $User) return;
          final user = event.model as $User;
          if (!user.active) {
            deletingEvents.add(event);
            event.cancel();
          }
        });
        addTearDown(unsubscribe);

        final inserted = await repo.insert(
          $User(id: 0, email: 'inactive-delete@test.dev', active: false),
        );

        // Cancellation for deleting events requires a model instance. Passing the
        // tracked model ensures ModelDeletingEvent has access to model fields.
        final deleted = await repo.delete(inserted);
        expect(deleted, equals(0));

        final stillThere = await repo.findOrFail(inserted.id);
        expect(stillThere.id, inserted.id);

        expect(deletingEvents, isNotEmpty);
        expect(deletingEvents.every((e) => e.isCancelled), isTrue);
      },
    );

    test(
      'cancel blocks soft delete and forceDelete (forceDelete flag differs)',
      () async {
        final repo = dataSource.context.repository<$Comment>();
        final deleting = <ModelDeletingEvent>[];

        final unsubscribe = EventBus.instance.on<ModelDeletingEvent>((event) {
          if (event.modelType != $Comment) return;
          deleting.add(event);
          event.cancel();
        });
        addTearDown(unsubscribe);

        final inserted = await repo.insert($Comment(id: 0, body: 'hello'));

        final trashed = await repo.trash(inserted);
        expect(trashed, equals(0));
        expect(await repo.find(inserted.id), isNotNull);

        final forceDeleted = await repo.forceDelete(inserted);
        expect(forceDeleted, equals(0));
        expect(await repo.find(inserted.id), isNotNull);

        expect(deleting, hasLength(greaterThanOrEqualTo(2)));
        expect(deleting.first.forceDelete, isFalse); // soft delete attempt
        expect(deleting.last.forceDelete, isTrue); // force delete attempt
      },
    );
  });
}
