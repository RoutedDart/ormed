// Carbon usage examples for documentation
// ignore_for_file: unused_local_variable

import 'package:ormed/ormed.dart';

// #region carbon-mutable-warning
// ⚠️ WARNING: Carbon (mutable) mutates in-place!
void mutableCarbonPitfall() {
  final date = Carbon.parse('2024-12-21');
  print(date.toDateString()); // 2024-12-21

  final yesterday = date.subDay(); // Mutates `date` in-place!
  print(date.toDateString()); // 2024-12-20 (unexpected!)
  print(identical(date, yesterday)); // true - same object!
}
// #endregion carbon-mutable-warning

// #region carbon-immutable-safe
// ✅ CarbonImmutable is safe - methods return new instances
void immutableCarbonSafe() {
  final date = CarbonImmutable.parse('2024-12-21');
  print(date.toDateString()); // 2024-12-21

  final yesterday = date.subDay(); // Returns NEW instance
  print(date.toDateString()); // 2024-12-21 (unchanged!)
  print(yesterday.toDateString()); // 2024-12-20
}
// #endregion carbon-immutable-safe

// #region ormed-timestamps-immutable
// Ormed timestamp getters return immutable Carbon instances
void ormedTimestampsAreImmutable() {
  // When you access createdAt/updatedAt/deletedAt from a model,
  // Ormed returns immutable instances so you can safely chain methods:

  // final user = await repo.find(1);
  // final createdAt = user.createdAt;  // CarbonImmutable
  //
  // // Safe to chain - original is never mutated
  // final yesterday = createdAt.subDay();
  // final isRecent = createdAt.isAfter(Carbon.now().subDays(7));
  //
  // print(createdAt);  // Still the original value ✓
}
// #endregion ormed-timestamps-immutable

// #region convert-to-immutable
// Converting between mutable and immutable
void convertingCarbon() {
  // Mutable → Immutable
  final mutable = Carbon.now();
  final immutable = mutable.toImmutable();

  // Immutable → Mutable (creates a copy)
  final backToMutable = immutable.toMutable();

  // Create a copy of mutable Carbon
  final copy = mutable.copy();
  copy.subDay(); // Only affects the copy
}
// #endregion convert-to-immutable

// #region timestamp-manipulation
// Common timestamp operations
void timestampOperations() {
  // Assuming `user` is a model with Timestamps mixin
  // final user = await repo.find(1);

  // Date comparisons
  // final wasCreatedToday = user.createdAt?.isToday ?? false;
  // final wasCreatedThisWeek = user.createdAt?.isCurrentWeek ?? false;

  // Human-readable differences
  // print(user.createdAt?.diffForHumans()); // "2 hours ago"

  // Date arithmetic (safe - returns new instance)
  // final weekAgo = user.createdAt?.subWeek();
  // final nextMonth = user.updatedAt?.addMonth();

  // Formatting
  // print(user.createdAt?.format('yyyy-MM-dd HH:mm:ss'));
  // print(user.createdAt?.toDateTimeString());
}
// #endregion timestamp-manipulation

// #region carbon-config-datasource
// Carbon is auto-configured by DataSource
Future<void> carbonAutoConfiguration() async {
  final ds = DataSource(
    DataSourceOptions(
      driver: throw UnimplementedError(), // Your driver
      entities: [],
      // Optional Carbon configuration:
      carbonTimezone: 'UTC', // Default timezone
      carbonLocale: 'en_US', // Default locale
      enableNamedTimezones: true, // Enable 'America/New_York', etc.
    ),
  );

  await ds.init(); // Carbon is configured here
}
// #endregion carbon-config-datasource

// #region carbon-best-practices
// Best practices for Carbon in Ormed
void carbonBestPractices() {
  // 1. Prefer CarbonImmutable for local variables
  final date = CarbonImmutable.now();

  // 2. Use toImmutable() when you need to store a reference
  final stored = Carbon.now().toImmutable();

  // 3. Model timestamps are already immutable - just use them
  // final yesterday = user.createdAt?.subDay(); // Safe!

  // 4. Use copy() if you need to mutate a mutable Carbon
  final mutable = Carbon.now();
  final safeCopy = mutable.copy();
  safeCopy.addDays(5); // Only copy is affected
}

// #endregion carbon-best-practices
