import 'package:ormed/src/migrations/migration_events.dart';
import 'package:ormed/src/events/event_bus.dart';
import 'package:test/test.dart';

void main() {
  group('MigrationEvent', () {
    test('creates with timestamp', () {
      final before = DateTime.now().toUtc();
      final event = MigrationBatchStartedEvent(
        direction: MigrationDirection.up,
        count: 5,
      );
      final after = DateTime.now().toUtc();

      expect(
        event.timestamp.isAfter(before.subtract(Duration(seconds: 1))),
        isTrue,
      );
      expect(event.timestamp.isBefore(after.add(Duration(seconds: 1))), isTrue);
    });
  });

  group('MigrationBatchStartedEvent', () {
    test('stores direction, count, and optional batch', () {
      final event = MigrationBatchStartedEvent(
        direction: MigrationDirection.up,
        count: 5,
        batch: 3,
      );

      expect(event.direction, equals(MigrationDirection.up));
      expect(event.count, equals(5));
      expect(event.batch, equals(3));
    });

    test('batch can be null', () {
      final event = MigrationBatchStartedEvent(
        direction: MigrationDirection.down,
        count: 2,
      );

      expect(event.batch, isNull);
    });
  });

  group('MigrationBatchCompletedEvent', () {
    test('stores direction, count, and duration', () {
      final event = MigrationBatchCompletedEvent(
        direction: MigrationDirection.up,
        count: 5,
        duration: Duration(seconds: 10),
      );

      expect(event.direction, equals(MigrationDirection.up));
      expect(event.count, equals(5));
      expect(event.duration, equals(Duration(seconds: 10)));
    });
  });

  group('MigrationStartedEvent', () {
    test('stores migration details', () {
      final event = MigrationStartedEvent(
        migrationId: '2024_01_15_120000_create_users',
        migrationName: 'create_users',
        direction: MigrationDirection.up,
        index: 1,
        total: 5,
      );

      expect(event.migrationId, equals('2024_01_15_120000_create_users'));
      expect(event.migrationName, equals('create_users'));
      expect(event.direction, equals(MigrationDirection.up));
      expect(event.index, equals(1));
      expect(event.total, equals(5));
    });
  });

  group('MigrationCompletedEvent', () {
    test('stores migration details with duration', () {
      final event = MigrationCompletedEvent(
        migrationId: '2024_01_15_120000_create_users',
        migrationName: 'create_users',
        direction: MigrationDirection.up,
        duration: Duration(milliseconds: 150),
      );

      expect(event.migrationId, equals('2024_01_15_120000_create_users'));
      expect(event.migrationName, equals('create_users'));
      expect(event.direction, equals(MigrationDirection.up));
      expect(event.duration, equals(Duration(milliseconds: 150)));
    });
  });

  group('MigrationFailedEvent', () {
    test('stores migration details with error', () {
      final error = Exception('Database error');
      final stackTrace = StackTrace.current;
      final event = MigrationFailedEvent(
        migrationId: '2024_01_15_120000_create_users',
        migrationName: 'create_users',
        direction: MigrationDirection.up,
        error: error,
        stackTrace: stackTrace,
      );

      expect(event.migrationId, equals('2024_01_15_120000_create_users'));
      expect(event.migrationName, equals('create_users'));
      expect(event.direction, equals(MigrationDirection.up));
      expect(event.error, equals(error));
      expect(event.stackTrace, equals(stackTrace));
    });

    test('stackTrace can be null', () {
      final event = MigrationFailedEvent(
        migrationId: 'test',
        migrationName: 'test',
        direction: MigrationDirection.down,
        error: 'some error',
      );

      expect(event.stackTrace, isNull);
    });
  });

  group('MigrationDirection', () {
    test('has up and down values', () {
      expect(MigrationDirection.values, contains(MigrationDirection.up));
      expect(MigrationDirection.values, contains(MigrationDirection.down));
      expect(MigrationDirection.values, hasLength(2));
    });
  });

  group('Migration events integrate with EventBus', () {
    late EventBus bus;

    setUp(() {
      bus = EventBus();
    });

    tearDown(() async {
      await bus.dispose();
    });

    test('can subscribe to migration started events', () {
      final received = <MigrationStartedEvent>[];

      bus.on<MigrationStartedEvent>((event) {
        received.add(event);
      });

      bus.emit(
        MigrationStartedEvent(
          migrationId: 'test',
          migrationName: 'test_migration',
          direction: MigrationDirection.up,
          index: 1,
          total: 1,
        ),
      );

      expect(received, hasLength(1));
      expect(received.first.migrationName, equals('test_migration'));
    });

    test('can subscribe to migration failed events', () {
      final received = <MigrationFailedEvent>[];

      bus.on<MigrationFailedEvent>((event) {
        received.add(event);
      });

      bus.emit(
        MigrationFailedEvent(
          migrationId: 'test',
          migrationName: 'test_migration',
          direction: MigrationDirection.up,
          error: 'Failed!',
        ),
      );

      expect(received, hasLength(1));
      expect(received.first.error, equals('Failed!'));
    });
  });
}
