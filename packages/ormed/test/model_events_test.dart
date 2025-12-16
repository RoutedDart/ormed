import 'package:ormed/src/model/model_events.dart';
import 'package:ormed/src/events/event_bus.dart';
import 'package:test/test.dart';

void main() {
  group('ModelEvent', () {
    test('stores modelType and tableName', () {
      final event = ModelCreatedEvent(
        modelType: String,
        tableName: 'users',
        model: 'test',
        attributes: {'name': 'John'},
      );

      expect(event.modelType, equals(String));
      expect(event.tableName, equals('users'));
    });
  });

  group('ModelCreatingEvent', () {
    test('stores attributes and can be cancelled', () {
      final event = ModelCreatingEvent(
        modelType: String,
        tableName: 'users',
        attributes: {'name': 'John', 'email': 'john@example.com'},
      );

      expect(event.attributes, containsPair('name', 'John'));
      expect(event.isCancelled, isFalse);

      event.cancel();
      expect(event.isCancelled, isTrue);
    });
  });

  group('ModelCreatedEvent', () {
    test('stores model and attributes', () {
      final event = ModelCreatedEvent(
        modelType: String,
        tableName: 'users',
        model: {'id': 1, 'name': 'John'},
        attributes: {'name': 'John'},
      );

      expect(event.model, equals({'id': 1, 'name': 'John'}));
      expect(event.attributes, containsPair('name', 'John'));
    });
  });

  group('ModelUpdatingEvent', () {
    test('stores model, original and dirty attributes, can be cancelled', () {
      final event = ModelUpdatingEvent(
        modelType: String,
        tableName: 'users',
        model: {'id': 1, 'name': 'Jane'},
        originalAttributes: {'id': 1, 'name': 'John'},
        dirtyAttributes: {'name': 'Jane'},
      );

      expect(event.originalAttributes, containsPair('name', 'John'));
      expect(event.dirtyAttributes, containsPair('name', 'Jane'));
      expect(event.isCancelled, isFalse);

      event.cancel();
      expect(event.isCancelled, isTrue);
    });
  });

  group('ModelUpdatedEvent', () {
    test('stores model, original and changed attributes', () {
      final event = ModelUpdatedEvent(
        modelType: String,
        tableName: 'users',
        model: {'id': 1, 'name': 'Jane'},
        originalAttributes: {'id': 1, 'name': 'John'},
        changedAttributes: {'name': 'Jane'},
      );

      expect(event.originalAttributes, containsPair('name', 'John'));
      expect(event.changedAttributes, containsPair('name', 'Jane'));
    });
  });

  group('ModelDeletingEvent', () {
    test('stores model, forceDelete flag, and can be cancelled', () {
      final event = ModelDeletingEvent(
        modelType: String,
        tableName: 'users',
        model: {'id': 1},
        forceDelete: false,
      );

      expect(event.model, equals({'id': 1}));
      expect(event.forceDelete, isFalse);
      expect(event.isCancelled, isFalse);

      event.cancel();
      expect(event.isCancelled, isTrue);
    });

    test('can be force delete', () {
      final event = ModelDeletingEvent(
        modelType: String,
        tableName: 'users',
        model: {'id': 1},
        forceDelete: true,
      );

      expect(event.forceDelete, isTrue);
    });
  });

  group('ModelDeletedEvent', () {
    test('stores model and forceDelete flag', () {
      final event = ModelDeletedEvent(
        modelType: String,
        tableName: 'users',
        model: {'id': 1},
        forceDelete: true,
      );

      expect(event.model, equals({'id': 1}));
      expect(event.forceDelete, isTrue);
    });
  });

  group('ModelRestoringEvent', () {
    test('stores model and can be cancelled', () {
      final event = ModelRestoringEvent(
        modelType: String,
        tableName: 'users',
        model: {'id': 1},
      );

      expect(event.model, equals({'id': 1}));
      expect(event.isCancelled, isFalse);

      event.cancel();
      expect(event.isCancelled, isTrue);
    });
  });

  group('ModelRestoredEvent', () {
    test('stores model', () {
      final event = ModelRestoredEvent(
        modelType: String,
        tableName: 'users',
        model: {'id': 1},
      );

      expect(event.model, equals({'id': 1}));
    });
  });

  group('ModelRetrievedEvent', () {
    test('stores model', () {
      final event = ModelRetrievedEvent(
        modelType: String,
        tableName: 'users',
        model: {'id': 1, 'name': 'John'},
      );

      expect(event.model, equals({'id': 1, 'name': 'John'}));
    });
  });

  group('Model event annotations', () {
    test('OnCreating stores ModelCreatingEvent type', () {
      const annotation = OnCreating();
      expect(annotation.eventType, equals(ModelCreatingEvent));
    });

    test('OnCreated stores ModelCreatedEvent type', () {
      const annotation = OnCreated();
      expect(annotation.eventType, equals(ModelCreatedEvent));
    });

    test('OnUpdating stores ModelUpdatingEvent type', () {
      const annotation = OnUpdating();
      expect(annotation.eventType, equals(ModelUpdatingEvent));
    });

    test('OnUpdated stores ModelUpdatedEvent type', () {
      const annotation = OnUpdated();
      expect(annotation.eventType, equals(ModelUpdatedEvent));
    });

    test('OnDeleting stores ModelDeletingEvent type', () {
      const annotation = OnDeleting();
      expect(annotation.eventType, equals(ModelDeletingEvent));
    });

    test('OnDeleted stores ModelDeletedEvent type', () {
      const annotation = OnDeleted();
      expect(annotation.eventType, equals(ModelDeletedEvent));
    });

    test('OnRestoring stores ModelRestoringEvent type', () {
      const annotation = OnRestoring();
      expect(annotation.eventType, equals(ModelRestoringEvent));
    });

    test('OnRestored stores ModelRestoredEvent type', () {
      const annotation = OnRestored();
      expect(annotation.eventType, equals(ModelRestoredEvent));
    });

    test('OnRetrieved stores ModelRetrievedEvent type', () {
      const annotation = OnRetrieved();
      expect(annotation.eventType, equals(ModelRetrievedEvent));
    });
  });

  group('Model events integrate with EventBus', () {
    late EventBus bus;

    setUp(() {
      bus = EventBus();
    });

    tearDown(() async {
      await bus.dispose();
    });

    test('can subscribe and receive model events', () {
      final received = <ModelCreatedEvent>[];

      bus.on<ModelCreatedEvent>((event) {
        received.add(event);
      });

      bus.emit(
        ModelCreatedEvent(
          modelType: String,
          tableName: 'users',
          model: {'id': 1},
          attributes: {},
        ),
      );

      expect(received, hasLength(1));
      expect(received.first.tableName, equals('users'));
    });
  });
}
