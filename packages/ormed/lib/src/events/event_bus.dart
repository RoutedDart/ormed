/// Core event system for ormed.
///
/// Provides a type-safe pub/sub event bus for:
/// - Model lifecycle events (creating, created, updating, updated, deleting, deleted)
/// - Migration events (started, completed, failed)
/// - Seeding events (started, completed, failed)
/// - Connection events (connected, disconnected, failed)
/// - Custom application events
///
/// ## Usage
///
/// ```dart
/// // Subscribe to all events
/// final unsubscribe = EventBus.instance.on<ModelCreatedEvent>((event) {
///   print('Created ${event.model.runtimeType} with id ${event.model.primaryKey}');
/// });
///
/// // Subscribe with a stream
/// EventBus.instance.stream<MigrationStartedEvent>().listen((event) {
///   print('Migrating ${event.migrationName}...');
/// });
///
/// // Emit an event
/// EventBus.instance.emit(ModelCreatedEvent(user));
///
/// // Cleanup
/// unsubscribe();
/// ```
library;

import 'dart:async';

import 'package:meta/meta.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Core Event Bus
// ─────────────────────────────────────────────────────────────────────────────

/// Base class for all events in the system.
///
/// All event types should extend this class.
abstract class Event {
  Event({DateTime? timestamp}) : timestamp = timestamp ?? DateTime.now().toUtc();

  /// When the event occurred.
  final DateTime timestamp;
}

/// Callback type for event listeners.
typedef EventListener<T extends Event> = void Function(T event);

/// A type-safe event bus implementing the publish/subscribe pattern.
///
/// The EventBus allows decoupled communication between components using
/// strongly-typed events.
///
/// ## Example
///
/// ```dart
/// // Get the default instance
/// final bus = EventBus.instance;
///
/// // Subscribe to a specific event type
/// final unsubscribe = bus.on<UserCreatedEvent>((event) {
///   print('User ${event.user.name} was created');
/// });
///
/// // Emit an event
/// bus.emit(UserCreatedEvent(user));
///
/// // Subscribe using streams
/// bus.stream<OrderPlacedEvent>().listen((event) {
///   sendEmailConfirmation(event.order);
/// });
///
/// // Cleanup when done
/// unsubscribe();
/// ```
class EventBus {
  /// Creates a new event bus instance.
  ///
  /// For most use cases, prefer [EventBus.instance] for the global singleton.
  EventBus();

  /// The global event bus instance.
  ///
  /// This is the recommended way to access the event bus in most applications.
  static final EventBus instance = EventBus();

  final StreamController<Event> _controller = StreamController<Event>.broadcast(
    sync: true,
  );

  final Map<Type, List<Function>> _listeners = {};

  /// Whether the event bus has been disposed.
  bool _disposed = false;

  /// Stream of all events.
  ///
  /// Use [stream<T>()] to filter by event type.
  Stream<Event> get allEvents => _controller.stream;

  /// Returns a stream of events of type [T].
  ///
  /// ```dart
  /// eventBus.stream<UserCreatedEvent>().listen((event) {
  ///   print('User created: ${event.user}');
  /// });
  /// ```
  Stream<T> stream<T extends Event>() =>
      _controller.stream.where((event) => event is T).cast<T>();

  /// Subscribe to events of type [T].
  ///
  /// Returns an unsubscribe function that should be called to stop listening.
  ///
  /// ```dart
  /// final unsubscribe = eventBus.on<UserCreatedEvent>((event) {
  ///   print('User created: ${event.user}');
  /// });
  ///
  /// // Later, when done:
  /// unsubscribe();
  /// ```
  void Function() on<T extends Event>(EventListener<T> listener) {
    _listeners.putIfAbsent(T, () => []).add(listener);
    return () => _listeners[T]?.remove(listener);
  }

  /// Subscribe to events of type [T] and automatically unsubscribe after
  /// receiving [count] events.
  ///
  /// ```dart
  /// eventBus.once<AppReadyEvent>((event) {
  ///   initializeApp();
  /// });
  /// ```
  void once<T extends Event>(EventListener<T> listener, {int count = 1}) {
    var remaining = count;
    late void Function() unsubscribe;
    unsubscribe = on<T>((event) {
      listener(event);
      remaining--;
      if (remaining <= 0) {
        unsubscribe();
      }
    });
  }

  /// Emit an event to all subscribers.
  ///
  /// ```dart
  /// eventBus.emit(UserCreatedEvent(user));
  /// ```
  void emit(Event event) {
    if (_disposed) {
      throw StateError('Cannot emit events after EventBus is disposed');
    }

    // Notify stream listeners
    _controller.add(event);

    // Notify direct listeners (walk up the type hierarchy)
    _notifyListeners(event);
  }

  void _notifyListeners(Event event) {
    final eventType = event.runtimeType;

    // Direct type match
    final listeners = _listeners[eventType];
    if (listeners != null) {
      for (final listener in List.of(listeners)) {
        Function.apply(listener, [event]);
      }
    }

    // Also check for parent type listeners
    // This allows subscribing to base event types
    for (final entry in _listeners.entries) {
      if (entry.key != eventType && _isSubtype(event, entry.key)) {
        for (final listener in List.of(entry.value)) {
          Function.apply(listener, [event]);
        }
      }
    }
  }

  bool _isSubtype(Event event, Type targetType) {
    // This is a simplified check - in practice we'd use mirrors or
    // maintain a type hierarchy
    return false; // Disable parent matching for now
  }

  /// Remove all listeners for a specific event type.
  void off<T extends Event>() {
    _listeners.remove(T);
  }

  /// Remove all listeners for all event types.
  void clear() {
    _listeners.clear();
  }

  /// Dispose the event bus and release resources.
  ///
  /// After calling this, no more events can be emitted.
  Future<void> dispose() async {
    _disposed = true;
    _listeners.clear();
    await _controller.close();
  }

  /// Reset the event bus (for testing).
  @visibleForTesting
  void reset() {
    _listeners.clear();
    // Don't close the controller, just clear listeners
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Event Mixins
// ─────────────────────────────────────────────────────────────────────────────

/// Mixin for events that can be cancelled.
mixin CancellableEvent on Event {
  bool _cancelled = false;

  /// Whether this event has been cancelled.
  bool get isCancelled => _cancelled;

  /// Cancel this event, preventing further processing.
  void cancel() => _cancelled = true;
}

/// Mixin for events that carry a result/response.
mixin ResultEvent<T> on Event {
  T? _result;

  /// The result of this event.
  T? get result => _result;

  /// Set the result of this event.
  set result(T? value) => _result = value;

  /// Whether a result has been set.
  bool get hasResult => _result != null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Event Annotations (for code generation)
// ─────────────────────────────────────────────────────────────────────────────

/// Annotation to mark a method as an event handler.
///
/// Used by code generation to automatically register event handlers.
///
/// ```dart
/// class User extends Model<User> {
///   @OnEvent(ModelCreatingEvent)
///   static void beforeCreate(ModelCreatingEvent event) {
///     event.attributes['created_at'] = DateTime.now();
///   }
///
///   @OnEvent(ModelCreatedEvent)
///   void afterCreate(ModelCreatedEvent event) {
///     sendWelcomeEmail(this);
///   }
/// }
/// ```
class OnEvent {
  const OnEvent(this.eventType);

  /// The event type this handler responds to.
  final Type eventType;
}

