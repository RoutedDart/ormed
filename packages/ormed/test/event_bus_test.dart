import 'dart:async';

import 'package:ormed/src/events/event_bus.dart';
import 'package:test/test.dart';

// Test event classes
class TestEvent extends Event {
  TestEvent({required this.message, super.timestamp});
  final String message;
}

class AnotherTestEvent extends Event {
  AnotherTestEvent({required this.value, super.timestamp});
  final int value;
}

class CancellableTestEvent extends Event with CancellableEvent {
  CancellableTestEvent({required this.data, super.timestamp});
  final String data;
}

class ResultTestEvent extends Event with ResultEvent<String> {
  ResultTestEvent({required this.query, super.timestamp});
  final String query;
}

void main() {
  group('Event', () {
    test('creates with current timestamp when none provided', () {
      final before = DateTime.now().toUtc();
      final event = TestEvent(message: 'test');
      final after = DateTime.now().toUtc();

      expect(event.timestamp.isUtc, isTrue);
      expect(
        event.timestamp.isAfter(before.subtract(Duration(seconds: 1))),
        isTrue,
      );
      expect(
        event.timestamp.isBefore(after.add(Duration(seconds: 1))),
        isTrue,
      );
    });

    test('uses provided timestamp', () {
      final customTime = DateTime.utc(2024, 1, 15, 10, 30);
      final event = TestEvent(message: 'test', timestamp: customTime);

      expect(event.timestamp, equals(customTime));
    });
  });

  group('EventBus', () {
    late EventBus bus;

    setUp(() {
      bus = EventBus();
    });

    tearDown(() async {
      await bus.dispose();
    });

    group('on()', () {
      test('subscribes to events of specific type', () async {
        final received = <TestEvent>[];

        bus.on<TestEvent>((event) {
          received.add(event);
        });

        bus.emit(TestEvent(message: 'hello'));
        bus.emit(TestEvent(message: 'world'));

        expect(received, hasLength(2));
        expect(received[0].message, equals('hello'));
        expect(received[1].message, equals('world'));
      });

      test('does not receive events of different type', () async {
        final testEvents = <TestEvent>[];
        final anotherEvents = <AnotherTestEvent>[];

        bus.on<TestEvent>((event) => testEvents.add(event));
        bus.on<AnotherTestEvent>((event) => anotherEvents.add(event));

        bus.emit(TestEvent(message: 'test'));
        bus.emit(AnotherTestEvent(value: 42));

        expect(testEvents, hasLength(1));
        expect(anotherEvents, hasLength(1));
        expect(testEvents[0].message, equals('test'));
        expect(anotherEvents[0].value, equals(42));
      });

      test('returns unsubscribe function', () async {
        final received = <TestEvent>[];

        final unsubscribe = bus.on<TestEvent>((event) {
          received.add(event);
        });

        bus.emit(TestEvent(message: 'first'));
        expect(received, hasLength(1));

        unsubscribe();

        bus.emit(TestEvent(message: 'second'));
        expect(received, hasLength(1)); // No new event received
      });

      test('supports multiple listeners for same event type', () async {
        var listener1Called = false;
        var listener2Called = false;

        bus.on<TestEvent>((_) => listener1Called = true);
        bus.on<TestEvent>((_) => listener2Called = true);

        bus.emit(TestEvent(message: 'test'));

        expect(listener1Called, isTrue);
        expect(listener2Called, isTrue);
      });
    });

    group('once()', () {
      test('unsubscribes after receiving one event by default', () async {
        final received = <TestEvent>[];

        bus.once<TestEvent>((event) {
          received.add(event);
        });

        bus.emit(TestEvent(message: 'first'));
        bus.emit(TestEvent(message: 'second'));

        expect(received, hasLength(1));
        expect(received[0].message, equals('first'));
      });

      test('unsubscribes after receiving specified count', () async {
        final received = <TestEvent>[];

        bus.once<TestEvent>((event) {
          received.add(event);
        }, count: 3);

        bus.emit(TestEvent(message: '1'));
        bus.emit(TestEvent(message: '2'));
        bus.emit(TestEvent(message: '3'));
        bus.emit(TestEvent(message: '4'));

        expect(received, hasLength(3));
        expect(received.map((e) => e.message).toList(), equals(['1', '2', '3']));
      });
    });

    group('stream()', () {
      test('returns filtered stream for event type', () async {
        final testEvents = <TestEvent>[];
        final subscription = bus.stream<TestEvent>().listen((event) {
          testEvents.add(event);
        });

        bus.emit(TestEvent(message: 'test'));
        bus.emit(AnotherTestEvent(value: 42));
        bus.emit(TestEvent(message: 'test2'));

        // Give time for stream events to be processed
        await Future.delayed(Duration(milliseconds: 10));

        expect(testEvents, hasLength(2));
        expect(testEvents[0].message, equals('test'));
        expect(testEvents[1].message, equals('test2'));

        await subscription.cancel();
      });
    });

    group('allEvents', () {
      test('returns stream of all events', () async {
        final allEvents = <Event>[];
        final subscription = bus.allEvents.listen((event) {
          allEvents.add(event);
        });

        bus.emit(TestEvent(message: 'test'));
        bus.emit(AnotherTestEvent(value: 42));

        await Future.delayed(Duration(milliseconds: 10));

        expect(allEvents, hasLength(2));
        expect(allEvents[0], isA<TestEvent>());
        expect(allEvents[1], isA<AnotherTestEvent>());

        await subscription.cancel();
      });
    });

    group('off()', () {
      test('removes all listeners for specific event type', () async {
        final received = <TestEvent>[];

        bus.on<TestEvent>((event) => received.add(event));
        bus.on<TestEvent>((event) => received.add(event));

        bus.emit(TestEvent(message: 'before'));
        expect(received, hasLength(2));

        bus.off<TestEvent>();

        bus.emit(TestEvent(message: 'after'));
        expect(received, hasLength(2)); // No new events
      });
    });

    group('clear()', () {
      test('removes all listeners for all event types', () async {
        final testEvents = <TestEvent>[];
        final anotherEvents = <AnotherTestEvent>[];

        bus.on<TestEvent>((event) => testEvents.add(event));
        bus.on<AnotherTestEvent>((event) => anotherEvents.add(event));

        bus.emit(TestEvent(message: 'test'));
        bus.emit(AnotherTestEvent(value: 42));

        expect(testEvents, hasLength(1));
        expect(anotherEvents, hasLength(1));

        bus.clear();

        bus.emit(TestEvent(message: 'test2'));
        bus.emit(AnotherTestEvent(value: 43));

        expect(testEvents, hasLength(1)); // No change
        expect(anotherEvents, hasLength(1)); // No change
      });
    });

    group('dispose()', () {
      test('throws StateError when emitting after dispose', () async {
        await bus.dispose();

        expect(
          () => bus.emit(TestEvent(message: 'test')),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('reset()', () {
      test('clears listeners but allows new subscriptions', () async {
        final received = <TestEvent>[];

        bus.on<TestEvent>((event) => received.add(event));
        bus.emit(TestEvent(message: 'before'));

        expect(received, hasLength(1));

        bus.reset();

        bus.emit(TestEvent(message: 'after reset'));
        expect(received, hasLength(1)); // Old listener cleared

        // Can still subscribe
        bus.on<TestEvent>((event) => received.add(event));
        bus.emit(TestEvent(message: 'new subscription'));
        expect(received, hasLength(2));
      });
    });
  });

  group('EventBus.instance', () {
    test('returns singleton instance', () {
      final instance1 = EventBus.instance;
      final instance2 = EventBus.instance;

      expect(identical(instance1, instance2), isTrue);
    });
  });

  group('CancellableEvent', () {
    test('is not cancelled by default', () {
      final event = CancellableTestEvent(data: 'test');
      expect(event.isCancelled, isFalse);
    });

    test('can be cancelled', () {
      final event = CancellableTestEvent(data: 'test');
      event.cancel();
      expect(event.isCancelled, isTrue);
    });

    test('cancel can be called multiple times', () {
      final event = CancellableTestEvent(data: 'test');
      event.cancel();
      event.cancel();
      expect(event.isCancelled, isTrue);
    });
  });

  group('ResultEvent', () {
    test('has no result by default', () {
      final event = ResultTestEvent(query: 'test');
      expect(event.hasResult, isFalse);
      expect(event.result, isNull);
    });

    test('can set and get result', () {
      final event = ResultTestEvent(query: 'test');
      event.result = 'the answer';

      expect(event.hasResult, isTrue);
      expect(event.result, equals('the answer'));
    });

    test('can set result to null after having a value', () {
      final event = ResultTestEvent(query: 'test');
      event.result = 'the answer';
      event.result = null;

      expect(event.hasResult, isFalse);
      expect(event.result, isNull);
    });
  });

  group('OnEvent annotation', () {
    test('stores event type', () {
      const annotation = OnEvent(TestEvent);
      expect(annotation.eventType, equals(TestEvent));
    });

    test('can be used as const', () {
      // This compiles, so the test passes
      const annotation = OnEvent(TestEvent);
      expect(annotation, isNotNull);
    });
  });
}

