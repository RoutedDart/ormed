/// Events library for ormed.
///
/// This library exports all event types and the EventBus infrastructure.
///
/// ## Usage
///
/// ```dart
/// import 'package:ormed/events.dart';
///
/// // Subscribe to events
/// EventBus.instance.on<ModelCreatedEvent>((event) {
///   print('Created: ${event.model}');
/// });
///
/// // Emit events
/// EventBus.instance.emit(MigrationStartedEvent(...));
/// ```
library;

// Connection events (these are co-located with connection logic)
export 'src/connection/connection_events.dart';
// Core event bus infrastructure
export 'src/events/event_bus.dart';
// Migration events
export 'src/migrations/migration_events.dart';
// Model events
export 'src/model/model_events.dart';
// Seeder events
export 'src/seeding/seeder_events.dart';
