import 'package:ormed/src/seeding/seeder_events.dart';
import 'package:ormed/src/events/event_bus.dart';
import 'package:test/test.dart';

void main() {
  group('SeederEvent', () {
    test('creates with timestamp', () {
      final before = DateTime.now().toUtc();
      final event = SeedingStartedEvent(seederNames: ['UserSeeder']);
      final after = DateTime.now().toUtc();

      expect(
        event.timestamp.isAfter(before.subtract(Duration(seconds: 1))),
        isTrue,
      );
      expect(event.timestamp.isBefore(after.add(Duration(seconds: 1))), isTrue);
    });
  });

  group('SeedingStartedEvent', () {
    test('stores seeder names', () {
      final event = SeedingStartedEvent(
        seederNames: ['UserSeeder', 'PostSeeder', 'CommentSeeder'],
      );

      expect(event.seederNames, hasLength(3));
      expect(event.seederNames, contains('UserSeeder'));
      expect(event.seederNames, contains('PostSeeder'));
    });
  });

  group('SeedingCompletedEvent', () {
    test('stores count and duration', () {
      final event = SeedingCompletedEvent(
        count: 5,
        duration: Duration(seconds: 30),
      );

      expect(event.count, equals(5));
      expect(event.duration, equals(Duration(seconds: 30)));
    });
  });

  group('SeederStartedEvent', () {
    test('stores seeder details', () {
      final event = SeederStartedEvent(
        seederName: 'UserSeeder',
        index: 1,
        total: 3,
      );

      expect(event.seederName, equals('UserSeeder'));
      expect(event.index, equals(1));
      expect(event.total, equals(3));
    });
  });

  group('SeederCompletedEvent', () {
    test('stores seeder details with duration', () {
      final event = SeederCompletedEvent(
        seederName: 'UserSeeder',
        duration: Duration(milliseconds: 500),
        recordsCreated: 100,
      );

      expect(event.seederName, equals('UserSeeder'));
      expect(event.duration, equals(Duration(milliseconds: 500)));
      expect(event.recordsCreated, equals(100));
    });

    test('recordsCreated can be null', () {
      final event = SeederCompletedEvent(
        seederName: 'UserSeeder',
        duration: Duration(milliseconds: 500),
      );

      expect(event.recordsCreated, isNull);
    });
  });

  group('SeederFailedEvent', () {
    test('stores seeder details with error', () {
      final error = Exception('Seeding error');
      final stackTrace = StackTrace.current;
      final event = SeederFailedEvent(
        seederName: 'UserSeeder',
        error: error,
        stackTrace: stackTrace,
      );

      expect(event.seederName, equals('UserSeeder'));
      expect(event.error, equals(error));
      expect(event.stackTrace, equals(stackTrace));
    });

    test('stackTrace can be null', () {
      final event = SeederFailedEvent(
        seederName: 'UserSeeder',
        error: 'some error',
      );

      expect(event.stackTrace, isNull);
    });
  });

  group('Seeder events integrate with EventBus', () {
    late EventBus bus;

    setUp(() {
      bus = EventBus();
    });

    tearDown(() async {
      await bus.dispose();
    });

    test('can subscribe to seeding started events', () {
      final received = <SeedingStartedEvent>[];

      bus.on<SeedingStartedEvent>((event) {
        received.add(event);
      });

      bus.emit(SeedingStartedEvent(seederNames: ['UserSeeder']));

      expect(received, hasLength(1));
      expect(received.first.seederNames, contains('UserSeeder'));
    });

    test('can subscribe to seeder completed events', () {
      final received = <SeederCompletedEvent>[];

      bus.on<SeederCompletedEvent>((event) {
        received.add(event);
      });

      bus.emit(
        SeederCompletedEvent(
          seederName: 'UserSeeder',
          duration: Duration(seconds: 1),
          recordsCreated: 50,
        ),
      );

      expect(received, hasLength(1));
      expect(received.first.seederName, equals('UserSeeder'));
      expect(received.first.recordsCreated, equals(50));
    });

    test('can subscribe to seeder failed events', () {
      final received = <SeederFailedEvent>[];

      bus.on<SeederFailedEvent>((event) {
        received.add(event);
      });

      bus.emit(
        SeederFailedEvent(
          seederName: 'UserSeeder',
          error: 'Constraint violation',
        ),
      );

      expect(received, hasLength(1));
      expect(received.first.error, equals('Constraint violation'));
    });
  });
}
