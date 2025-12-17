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
/// final unsubscribe = EventBus.instance.on<ModelCreatedEvent>((event) {
///   print('Created: ${event.model}');
/// });
///
/// // Emit events
/// EventBus.instance.emit(
///   MigrationStartedEvent(
///     migrationId: 'm_20250101000000_create_users_table',
///     migrationName: 'create_users_table',
///     direction: MigrationDirection.up,
///     index: 1,
///     total: 1,
///   ),
/// );
///
/// // Cleanup
/// unsubscribe();
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
