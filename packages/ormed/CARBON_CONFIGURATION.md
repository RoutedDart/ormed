# Carbon Configuration Guide

This guide explains how to configure Carbon (the date/time library) in Ormed, including timezone settings, locale preferences, and TimeMachine initialization for named timezone support.

## Table of Contents

- [Quick Start](#quick-start)
- [Basic Configuration](#basic-configuration)
- [Named Timezone Support](#named-timezone-support)
- [Default Settings](#default-settings)
- [Creating Carbon Instances](#creating-carbon-instances)
- [Usage with Timestamps](#usage-with-timestamps)
- [Advanced Usage](#advanced-usage)
- [API Reference](#api-reference)

## Quick Start

### Automatic Configuration (Recommended)

Carbon is automatically configured when you initialize your DataSource:

```dart
import 'package:ormed/ormed.dart';

Future<void> main() async {
  // Carbon is automatically configured with these settings
  final ds = DataSource(DataSourceOptions(
    driver: SqliteDriverAdapter.file('app.sqlite'),
    entities: [UserOrmDefinition.definition],
    carbonTimezone: 'UTC',           // Default timezone (optional)
    carbonLocale: 'en_US',            // Default locale (optional)
    enableNamedTimezones: false,      // Set true for 'America/New_York' etc.
  ));
  
  await ds.init(); // Carbon is automatically configured here
  
  // Use timestamps immediately
  final user = await User.query().first();
  print(user.createdAt!.format('yyyy-MM-dd')); // Works!
}
```

### With Named Timezones (America/New_York, Europe/London, etc.)

```dart
import 'package:ormed/ormed.dart';

Future<void> main() async {
  final ds = DataSource(DataSourceOptions(
    driver: SqliteDriverAdapter.file('app.sqlite'),
    entities: [UserOrmDefinition.definition],
    carbonTimezone: 'America/New_York',
    carbonLocale: 'en_US',
    enableNamedTimezones: true,  // Enable named timezone support
  ));
  
  await ds.init(); // Carbon + TimeMachine automatically configured
  
  // Now you can use named timezones
  final user = await User.query().first();
  final eastern = user.createdAt!.tz('America/New_York');
  print(eastern.format('yyyy-MM-dd HH:mm z')); // Works!
}
```

### Manual Configuration (Advanced)

You can still manually configure Carbon before initializing DataSource:

```dart
import 'package:ormed/ormed.dart';

Future<void> main() async {
  // Manual configuration takes precedence
  await CarbonConfig.configureWithTimeMachine(
    defaultTimezone: 'Asia/Tokyo',
    defaultLocale: 'ja_JP',
  );
  
  // DataSource won't override manual configuration
  final ds = DataSource(DataSourceOptions(
    driver: SqliteDriverAdapter.file('app.sqlite'),
    entities: [UserOrmDefinition.definition],
  ));
  
  await ds.init();
  
  // Uses manually configured settings
  final user = await User.query().first();
  print(user.createdAt!.format('yyyy-MM-dd')); // In Tokyo timezone
}
```

## Automatic Configuration

Carbon is automatically configured when you call `DataSource.init()`. The configuration is based on the `DataSourceOptions` you provide:

```dart
final ds = DataSource(DataSourceOptions(
  driver: SqliteDriverAdapter.file('app.sqlite'),
  entities: [UserOrmDefinition.definition],
  
  // Carbon configuration (all optional)
  carbonTimezone: 'UTC',           // Default: 'UTC'
  carbonLocale: 'en_US',            // Default: 'en_US'
  enableNamedTimezones: false,      // Default: false
));

await ds.init(); // Carbon automatically configured here
```

### Configuration Behavior

When `DataSource.init()` is called, it checks the following in order:

1. **Manual configuration takes precedence**: If you already called `CarbonConfig.configure()` or `CarbonConfig.configureWithTimeMachine()` before `DataSource.init()`, your manual configuration is preserved and DataSource won't override it.

2. **Named timezone check**: If `enableNamedTimezones` is `true` and TimeMachine is not yet configured, it calls `CarbonConfig.configureWithTimeMachine()`.

3. **Basic configuration**: If Carbon is still at default values (UTC, en_US), it calls `CarbonConfig.configure()` with your specified timezone and locale.

### Configuration Precedence

```
Manual Configuration > DataSource Options > Built-in Defaults
```

**Example:**
```dart
// Step 1: Manual configuration
await CarbonConfig.configureWithTimeMachine(
  defaultTimezone: 'Asia/Tokyo',
  defaultLocale: 'ja_JP',
);

// Step 2: Create DataSource with different settings
final ds = DataSource(DataSourceOptions(
  driver: adapter,
  entities: entities,
  carbonTimezone: 'America/New_York', // ⚠️ Ignored - manual config wins
  carbonLocale: 'en_US',               // ⚠️ Ignored - manual config wins
));

await ds.init();

// Result: Uses Tokyo timezone and Japanese locale (from manual config)
```

### Default Values

If you don't specify Carbon settings in DataSourceOptions, these defaults are used:
- **carbonTimezone**: `'UTC'`
- **carbonLocale**: `'en_US'`
- **enableNamedTimezones**: `false`

## Basic Configuration

### Configure Without TimeMachine

For applications that only need UTC or fixed offset timezones:

```dart
CarbonConfig.configure(
  defaultTimezone: 'UTC',      // or '+05:30', '-08:00', etc.
  defaultLocale: 'en_US',
);
```

**Supported timezones without TimeMachine:**
- `'UTC'` - Coordinated Universal Time
- Fixed offsets: `'+05:30'`, `'-08:00'`, `'+00:00'`, etc.

**Not supported without TimeMachine:**
- Named timezones: `'America/New_York'`, `'Europe/London'`, `'Asia/Tokyo'`, etc.

## Named Timezone Support

### Configure With TimeMachine

For applications that need named timezone support:

```dart
await CarbonConfig.configureWithTimeMachine(
  defaultTimezone: 'America/New_York',
  defaultLocale: 'en_US',
);
```

**This enables:**
- All IANA timezone names (170+ timezones)
- Daylight Saving Time (DST) awareness
- Historical timezone rule changes
- Timezone conversions

### Example Named Timezones

```dart
await CarbonConfig.configureWithTimeMachine(
  defaultTimezone: 'America/New_York',  // US Eastern Time
  defaultLocale: 'en_US',
);

// Now you can convert between timezones
final user = await User.query().first();
final created = user.createdAt!; // UTC by default from DB

final eastern = created.tz('America/New_York');
final london = created.tz('Europe/London');
final tokyo = created.tz('Asia/Tokyo');
final sydney = created.tz('Australia/Sydney');

print('NY:     ${eastern.format('HH:mm z')}');
print('London: ${london.format('HH:mm z')}');
print('Tokyo:  ${tokyo.format('HH:mm z')}');
print('Sydney: ${sydney.format('HH:mm z')}');
```

## Default Settings

### Default Timezone

The default timezone is applied to Carbon instances created via `CarbonConfig.createCarbon()`:

```dart
CarbonConfig.configure(defaultTimezone: 'UTC');

final now = CarbonConfig.createCarbon(); // Uses UTC
```

**Note:** Timestamps from the database are always UTC regardless of this setting. The default timezone only affects newly created Carbon instances.

### Default Locale

The default locale affects date formatting and human-readable strings:

```dart
CarbonConfig.configure(defaultLocale: 'fr_FR');

final date = CarbonConfig.createCarbon();
print(date.format('MMMM')); // "décembre" (French)
```

**Supported locales:** 170+ locales including:
- `'en_US'` - English (United States)
- `'fr_FR'` - French (France)
- `'es_ES'` - Spanish (Spain)
- `'de_DE'` - German (Germany)
- `'ja_JP'` - Japanese (Japan)
- `'zh_CN'` - Chinese (China)
- And many more...

## Creating Carbon Instances

### Using CarbonConfig Helper Methods

```dart
// Create from current time
final now = CarbonConfig.createCarbon();

// Create from specific DateTime
final custom = CarbonConfig.createCarbon(
  dateTime: DateTime(2024, 12, 25, 10, 30),
);

// Create with specific timezone
final eastern = CarbonConfig.createCarbon(
  timezone: 'America/New_York',
);

// Create with specific locale
final french = CarbonConfig.createCarbon(
  locale: 'fr_FR',
);

// Parse from string
final date = CarbonConfig.parseCarbon('2024-12-25T10:30:00Z');

// Parse with timezone
final customDate = CarbonConfig.parseCarbon(
  '2024-12-25',
  timezone: 'America/New_York',
);
```

### Error Handling

Attempting to use named timezones without TimeMachine throws an error:

```dart
CarbonConfig.configure(defaultTimezone: 'UTC'); // No TimeMachine

try {
  final eastern = CarbonConfig.createCarbon(
    timezone: 'America/New_York', // ❌ Will throw
  );
} catch (e) {
  print(e); // StateError: Named timezone requires configureWithTimeMachine()
}
```

## Usage with Timestamps

### Model Timestamps

Timestamps retrieved from the database automatically use Carbon:

```dart
@OrmModel(table: 'users')
class User extends Model<User> with Timestamps {
  final int? id;
  final String name;
  
  const User({this.id, required this.name});
}

// Usage
final user = await User.query().first();

// Returns CarbonInterface (always UTC from database)
final created = user.createdAt!;
print(created.isUtc); // true
print(created.format('yyyy-MM-dd HH:mm z')); // "2024-12-08 20:00 UTC"

// Convert to different timezone (requires TimeMachine)
final eastern = created.tz('America/New_York');
print(eastern.format('yyyy-MM-dd HH:mm z')); // "2024-12-08 15:00 EST"

// Human-readable difference
print(created.diffForHumans()); // "5 minutes ago"
```

### Timezone-Aware Timestamps

Use `TimestampsTZ` for explicit UTC timezone awareness:

```dart
@OrmModel(table: 'posts')
class Post extends Model<Post> with TimestampsTZ {
  final int? id;
  final String title;
  
  const Post({this.id, required this.title});
}

// Usage (same as Timestamps, both return Carbon instances in UTC)
final post = await Post.query().first();
print(post.createdAt!.isUtc); // true
```

## Advanced Usage

### Check Configuration State

```dart
// Check if TimeMachine is configured
if (CarbonConfig.isTimeMachineConfigured) {
  print('Named timezones are available');
}

// Get current defaults
print('Default timezone: ${CarbonConfig.defaultTimezone}');
print('Default locale: ${CarbonConfig.defaultLocale}');
```

### Reset Configuration

Useful for testing:

```dart
setUp(() {
  CarbonConfig.reset(); // Reset to defaults (UTC, en_US, no TimeMachine)
});

test('timezone handling', () async {
  await CarbonConfig.configureWithTimeMachine(
    defaultTimezone: 'America/New_York',
  );
  // ... test code
});
```

### Multiple Timezones in Same App

```dart
await CarbonConfig.configureWithTimeMachine(
  defaultTimezone: 'UTC', // Store everything in UTC
);

// Display times in user's timezone
String formatForUser(CarbonInterface timestamp, String userTimezone) {
  return timestamp.tz(userTimezone).format('yyyy-MM-dd HH:mm z');
}

final user = await User.query().first();
print(formatForUser(user.createdAt!, 'America/New_York'));
print(formatForUser(user.createdAt!, 'Europe/London'));
print(formatForUser(user.createdAt!, 'Asia/Tokyo'));
```

### Locale-Specific Formatting

```dart
await CarbonConfig.configureWithTimeMachine(
  defaultTimezone: 'UTC',
  defaultLocale: 'en_US',
);

final date = CarbonConfig.createCarbon(
  dateTime: DateTime(2024, 12, 25),
);

// Change locale on the fly
print(date.locale('fr_FR').format('LLLL')); // "25 décembre 2024"
print(date.locale('es_ES').format('LLLL')); // "25 de diciembre de 2024"
print(date.locale('ja_JP').format('LLLL')); // "2024年12月25日"
```

## API Reference

### CarbonConfig Class

#### Static Properties

- **`defaultTimezone`** (`String`) - Get the default timezone
- **`defaultLocale`** (`String`) - Get the default locale
- **`isTimeMachineConfigured`** (`bool`) - Check if TimeMachine is configured

#### Static Methods

##### `configure({String? defaultTimezone, String? defaultLocale})`

Configure Carbon settings (synchronous, no TimeMachine support).

**Parameters:**
- `defaultTimezone` - Default timezone (default: 'UTC')
- `defaultLocale` - Default locale (default: 'en_US')

**Example:**
```dart
CarbonConfig.configure(
  defaultTimezone: 'UTC',
  defaultLocale: 'en_US',
);
```

##### `configureWithTimeMachine({String? defaultTimezone, String? defaultLocale})`

Configure Carbon with TimeMachine for named timezone support (async).

**Parameters:**
- `defaultTimezone` - Default timezone (default: 'UTC')
- `defaultLocale` - Default locale (default: 'en_US')

**Returns:** `Future<void>`

**Example:**
```dart
await CarbonConfig.configureWithTimeMachine(
  defaultTimezone: 'America/New_York',
  defaultLocale: 'en_US',
);
```

##### `createCarbon({DateTime? dateTime, String? timezone, String? locale})`

Create a Carbon instance with configured defaults.

**Parameters:**
- `dateTime` - DateTime to wrap (default: now)
- `timezone` - Override default timezone
- `locale` - Override default locale

**Returns:** `Carbon`

**Throws:** `StateError` if named timezone is used without TimeMachine

**Example:**
```dart
final now = CarbonConfig.createCarbon();
final custom = CarbonConfig.createCarbon(
  dateTime: DateTime(2024, 12, 25),
  timezone: 'America/New_York',
  locale: 'fr_FR',
);
```

##### `parseCarbon(String dateString, {String? timezone, String? locale})`

Parse a date string into a Carbon instance with configured defaults.

**Parameters:**
- `dateString` - Date string to parse (ISO8601 recommended)
- `timezone` - Override default timezone
- `locale` - Override default locale

**Returns:** `Carbon`

**Throws:** `StateError` if named timezone is used without TimeMachine

**Example:**
```dart
final date = CarbonConfig.parseCarbon('2024-12-25T10:30:00Z');
final custom = CarbonConfig.parseCarbon(
  '2024-12-25',
  timezone: 'America/New_York',
);
```

##### `reset()`

Reset configuration to defaults (for testing).

**Example:**
```dart
CarbonConfig.reset(); // UTC, en_US, no TimeMachine
```

## Best Practices

### 1. Configure Early

Configure Carbon at application startup, before any ORM operations:

```dart
Future<void> main() async {
  // Configure first
  await CarbonConfig.configureWithTimeMachine(
    defaultTimezone: 'UTC',
    defaultLocale: 'en_US',
  );
  
  // Then run your app
  runApp(MyApp());
}
```

### 2. Store Everything in UTC

Always store timestamps in UTC in the database (Ormed does this automatically):

```dart
// ✅ Good: Database stores UTC
final user = User(name: 'John');
await user.save(); // created_at stored as UTC

// ✅ Good: Display in user's timezone
final displayTime = user.createdAt!.tz(userTimezone);
```

### 3. Use Named Timezones for User Display

Configure TimeMachine if your app displays times in user-specific timezones:

```dart
// For global apps with timezone support
await CarbonConfig.configureWithTimeMachine(
  defaultTimezone: 'UTC', // Store in UTC
);

// Display per user
String formatForUser(CarbonInterface time, User user) {
  return time.tz(user.timezone).format('yyyy-MM-dd HH:mm z');
}
```

### 4. UTC-Only Apps Can Skip TimeMachine

If your app only uses UTC, skip the async configuration:

```dart
// Simpler for UTC-only apps
void main() {
  CarbonConfig.configure(defaultTimezone: 'UTC');
  runApp(MyApp());
}
```

### 5. Test Configuration

Reset configuration in tests:

```dart
group('Timestamp tests', () {
  setUp(() async {
    CarbonConfig.reset();
    await CarbonConfig.configureWithTimeMachine();
  });
  
  test('timezone conversion', () {
    // ... test code
  });
});
```

## Common Patterns

### Multi-Tenant with Different Timezones

```dart
class TenantConfig {
  static Future<void> configureTenant(Tenant tenant) async {
    await CarbonConfig.configureWithTimeMachine(
      defaultTimezone: tenant.timezone,
      defaultLocale: tenant.locale,
    );
  }
}

// Usage
await TenantConfig.configureTenant(currentTenant);
final orders = await Order.query().where('tenant_id', tenant.id).get();
```

### Global App with User Preferences

```dart
extension CarbonUserDisplay on CarbonInterface {
  String formatForUser(User user) {
    return tz(user.timezone)
        .locale(user.locale)
        .format('yyyy-MM-dd HH:mm z');
  }
}

// Usage
final post = await Post.query().first();
print(post.createdAt!.formatForUser(currentUser));
```

### Time-Based Queries in User Timezone

```dart
// Find posts created today in user's timezone
Future<List<Post>> getPostsCreatedToday(String userTimezone) async {
  final now = CarbonConfig.createCarbon(timezone: userTimezone);
  final startOfDay = now.startOfDay().toUtc(); // Convert back to UTC for query
  final endOfDay = now.endOfDay().toUtc();
  
  return await Post.query()
      .whereBetween('created_at', [startOfDay, endOfDay])
      .get();
}
```

## Troubleshooting

### Error: Named timezone requires configureWithTimeMachine

```dart
// ❌ Problem
CarbonConfig.configure(defaultTimezone: 'UTC');
final eastern = CarbonConfig.createCarbon(timezone: 'America/New_York'); // Error!

// ✅ Solution
await CarbonConfig.configureWithTimeMachine();
final eastern = CarbonConfig.createCarbon(timezone: 'America/New_York');
```

### Timestamps Not Converting to User Timezone

```dart
// ❌ Problem: Forgot to call .tz()
final created = user.createdAt!;
print(created.format('HH:mm')); // Still in UTC

// ✅ Solution: Convert timezone explicitly
final created = user.createdAt!.tz('America/New_York');
print(created.format('HH:mm z')); // Now in Eastern Time
```

### Format Codes Not Working

```dart
// ❌ Problem: Using PHP format codes
final formatted = carbon.format('Y-m-d'); // Returns "Y-46-8"

// ✅ Solution: Use Dart DateFormat patterns
final formatted = carbon.format('yyyy-MM-dd'); // Returns "2024-12-08"
```

## See Also

- [DATETIME_CODECS.md](./DATETIME_CODECS.md) - DateTime codec system
- [TIMESTAMPS_USAGE.md](./TIMESTAMPS_USAGE.md) - Automatic timestamp management
- [Carbonized Package Documentation](https://pub.dev/packages/carbonized)
- [IANA Time Zone Database](https://www.iana.org/time-zones)
