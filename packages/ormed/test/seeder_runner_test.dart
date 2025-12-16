import 'package:driver_tests/driver_tests.dart';
import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  group('SeederRunner', () {
    late OrmConnection connection;

    setUp(() {
      connection = OrmConnection(
        config: ConnectionConfig(name: 'test'),
        driver: InMemoryQueryExecutor(),
        registry: ModelRegistry(),
      );
    });

    test('emits lifecycle events for seeder runs', () async {
      final bus = EventBus();
      final events = <Event>[];
      final subscription = bus.allEvents.listen(events.add);
      var runCount = 0;

      final runner = SeederRunner(events: bus);

      final report = await runner.run(
        connection: connection,
        seeders: [
          SeederRegistration(
            name: 'AlphaSeeder',
            factory: (conn) => _RecordingSeeder(conn, onRun: () => runCount++),
          ),
          SeederRegistration(
            name: 'BetaSeeder',
            factory: (conn) => _RecordingSeeder(conn, onRun: () => runCount++),
          ),
        ],
        names: const ['AlphaSeeder', 'BetaSeeder'],
      );

      await subscription.cancel();
      await bus.dispose();

      expect(runCount, equals(2));
      expect(report.actions, hasLength(2));
      expect(
        events.whereType<SeedingStartedEvent>().single.seederNames,
        equals(['AlphaSeeder', 'BetaSeeder']),
      );
      expect(events.whereType<SeederStartedEvent>(), hasLength(2));
      expect(events.whereType<SeederCompletedEvent>(), hasLength(2));
      final completed = events.whereType<SeedingCompletedEvent>().single;
      expect(completed.count, equals(2));
    });

    test('counts nested seeders executed via call()', () async {
      final bus = EventBus();
      final events = <Event>[];
      final subscription = bus.allEvents.listen(events.add);

      final runner = SeederRunner(events: bus);

      await runner.run(
        connection: connection,
        seeders: [
          SeederRegistration(
            name: 'AggregatorSeeder',
            factory: (conn) => _AggregatingSeeder(conn),
          ),
        ],
      );

      await subscription.cancel();
      await bus.dispose();

      expect(events.whereType<SeederCompletedEvent>(), hasLength(2));
      final seedingCompleted = events.whereType<SeedingCompletedEvent>().single;
      expect(seedingCompleted.count, equals(2));
    });

    test('emits failed event and rethrows errors', () async {
      final bus = EventBus();
      final events = <Event>[];
      final subscription = bus.allEvents.listen(events.add);

      final runner = SeederRunner(events: bus);

      await expectLater(
        () => runner.run(
          connection: connection,
          seeders: [
            SeederRegistration(
              name: 'BrokenSeeder',
              factory: (conn) => _FailingSeeder(conn),
            ),
          ],
        ),
        throwsStateError,
      );

      await subscription.cancel();
      await bus.dispose();

      expect(events.whereType<SeederFailedEvent>(), hasLength(1));
      expect(events.whereType<SeedingCompletedEvent>(), isEmpty);
    });
  });
}

class _RecordingSeeder extends DatabaseSeeder {
  _RecordingSeeder(super.connection, {this.onRun});

  final void Function()? onRun;

  @override
  Future<void> run() async {
    onRun?.call();
  }
}

class _AggregatingSeeder extends DatabaseSeeder {
  _AggregatingSeeder(super.connection);

  @override
  Future<void> run() async {
    await call([_RecordingSeeder.new]);
  }
}

class _FailingSeeder extends DatabaseSeeder {
  _FailingSeeder(super.connection);

  @override
  Future<void> run() async {
    throw StateError('boom');
  }
}
