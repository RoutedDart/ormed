// ignore_for_file: unused_local_variable

import 'package:ormed/ormed.dart';

/// This example demonstrates automatic Carbon configuration via DataSource.
///
/// Carbon is automatically configured when you call `DataSource.init()`.
/// No manual configuration is required unless you want to override the defaults.
void main() async {
  // Example 1: Basic setup (UTC, no named timezones)
  await example1BasicSetup();

  // Example 2: Named timezone support
  await example2NamedTimezones();

  // Example 3: Custom locale
  await example3CustomLocale();

  // Example 4: Manual configuration override
  await example4ManualOverride();
}

/// Example 1: Basic automatic configuration
///
/// Carbon is automatically configured with UTC timezone.
/// Named timezones are not available, but UTC and fixed offsets work.
Future<void> example1BasicSetup() async {
  print('\n=== Example 1: Basic Setup ===');

  final ds = DataSource(
    DataSourceOptions(
      driver: SqliteDriverAdapter.inMemory(),
      entities: [], // Add your model definitions here
      // Carbon uses defaults: UTC, en_US, no named timezones
    ),
  );

  await ds.init(); // Carbon automatically configured here

  // Create a Carbon instance
  final now = CarbonConfig.createCarbon();
  print('Current time (UTC): ${now.format('yyyy-MM-dd HH:mm:ss z')}');
  print('Is UTC: ${now.isUtc}');

  await ds.dispose();
}

/// Example 2: Named timezone support
///
/// Enable named timezones like 'America/New_York', 'Europe/London', etc.
Future<void> example2NamedTimezones() async {
  print('\n=== Example 2: Named Timezone Support ===');

  // Reset Carbon to demonstrate fresh configuration
  CarbonConfig.reset();

  final ds = DataSource(
    DataSourceOptions(
      driver: SqliteDriverAdapter.inMemory(),
      entities: [],
      carbonTimezone: 'America/New_York',
      enableNamedTimezones: true, // Enable TimeMachine
    ),
  );

  await ds.init(); // Carbon + TimeMachine automatically configured

  // Now named timezones work
  final utcTime = CarbonConfig.createCarbon(timezone: 'UTC');
  final nyTime = utcTime.tz('America/New_York');
  final londonTime = utcTime.tz('Europe/London');

  print('UTC:        ${utcTime.format('yyyy-MM-dd HH:mm z')}');
  print('New York:   ${nyTime.format('yyyy-MM-dd HH:mm z')}');
  print('London:     ${londonTime.format('yyyy-MM-dd HH:mm z')}');

  await ds.dispose();
}

/// Example 3: Custom locale
///
/// Configure Carbon with a different locale for date formatting.
Future<void> example3CustomLocale() async {
  print('\n=== Example 3: Custom Locale ===');

  CarbonConfig.reset();

  final ds = DataSource(
    DataSourceOptions(
      driver: SqliteDriverAdapter.inMemory(),
      entities: [],
      carbonTimezone: 'UTC',
      carbonLocale: 'fr_FR', // French locale
    ),
  );

  await ds.init();

  final date = CarbonConfig.createCarbon(
    dateTime: DateTime(2024, 12, 25, 10, 30),
  );

  print('English:  ${date.locale('en_US').format('LLLL')}');
  print('French:   ${date.locale('fr_FR').format('LLLL')}');
  print('Spanish:  ${date.locale('es_ES').format('LLLL')}');
  print('Japanese: ${date.locale('ja_JP').format('LLLL')}');

  await ds.dispose();
}

/// Example 4: Manual configuration override
///
/// You can manually configure Carbon before initializing DataSource.
/// Manual configuration takes precedence.
Future<void> example4ManualOverride() async {
  print('\n=== Example 4: Manual Override ===');

  CarbonConfig.reset();

  // Manual configuration BEFORE DataSource.init()
  await CarbonConfig.configureWithTimeMachine(
    defaultTimezone: 'Asia/Tokyo',
    defaultLocale: 'ja_JP',
  );

  final ds = DataSource(
    DataSourceOptions(
      driver: SqliteDriverAdapter.inMemory(),
      entities: [],
      carbonTimezone: 'America/New_York', // This will be ignored
      carbonLocale: 'en_US', // This will be ignored
      enableNamedTimezones: true,
    ),
  );

  await ds.init(); // Uses manual configuration, not DataSourceOptions

  // Verify manual configuration was used
  print('Default timezone: ${CarbonConfig.defaultTimezone}'); // Asia/Tokyo
  print('Default locale:   ${CarbonConfig.defaultLocale}'); // ja_JP

  final now = CarbonConfig.createCarbon();
  print('Current time: ${now.format('yyyy-MM-dd HH:mm z')}'); // In Tokyo

  await ds.dispose();
}

/// Example DataSource adapter (in-memory for examples)
extension SqliteDriverAdapter on Object {
  static DriverAdapter inMemory() {
    // This is a placeholder - in real code you'd use the actual adapter
    throw UnimplementedError('Use actual SqliteDriverAdapter.inMemory()');
  }
}
