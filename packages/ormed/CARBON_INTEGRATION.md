# Carbon Integration Summary

This document provides a complete overview of Carbon (date/time library) integration in Ormed.

## Overview

Ormed integrates the [carbonized](https://pub.dev/packages/carbonized) package to provide powerful, Laravel-inspired date/time handling. Carbon is automatically configured when you initialize a DataSource, with full support for timezones, locales, and fluent date manipulation.

## Key Features

✅ **Automatic Configuration** - Carbon is configured automatically via `DataSource.init()`  
✅ **Timezone Support** - Full support for UTC, fixed offsets, and 170+ named timezones  
✅ **Locale Support** - 170+ locales for internationalized date formatting  
✅ **Timestamp Mixins** - `Timestamps` and `TimestampsTZ` for automatic created_at/updated_at  
✅ **Query Integration** - Timestamps automatically updated on insert/update operations  
✅ **Type Safety** - Full TypeScript-style type safety with Dart's strong typing  
✅ **Fluent API** - Laravel-style fluent date manipulation methods  

## Quick Examples

### Basic Usage (UTC Only)

```dart
// No configuration needed for UTC
final ds = DataSource(DataSourceOptions(
  driver: SqliteDriverAdapter.file('app.sqlite'),
  entities: [UserOrmDefinition.definition],
));

await ds.init(); // Carbon automatically configured

final user = await User.query().first();
print(user.createdAt!.format('yyyy-MM-dd')); // "2024-12-08"
print(user.createdAt!.diffForHumans());      // "5 minutes ago"
```

### Named Timezones

```dart
final ds = DataSource(DataSourceOptions(
  driver: SqliteDriverAdapter.file('app.sqlite'),
  entities: [UserOrmDefinition.definition],
  enableNamedTimezones: true, // Enable TimeMachine
));

await ds.init();

final user = await User.query().first();
final eastern = user.createdAt!.tz('America/New_York');
final tokyo = user.createdAt!.tz('Asia/Tokyo');

print('NY:    ${eastern.format('HH:mm z')}');
print('Tokyo: ${tokyo.format('HH:mm z')}');
```

### Custom Timezone and Locale

```dart
final ds = DataSource(DataSourceOptions(
  driver: SqliteDriverAdapter.file('app.sqlite'),
  entities: [UserOrmDefinition.definition],
  carbonTimezone: 'Europe/Paris',
  carbonLocale: 'fr_FR',
  enableNamedTimezones: true,
));

await ds.init();

final date = CarbonConfig.createCarbon();
print(date.format('LLLL')); // "8 décembre 2024"
```

## Configuration Options

### DataSourceOptions Parameters

```dart
DataSourceOptions(
  // ... standard options
  
  /// Default timezone for Carbon instances
  /// Examples: 'UTC', 'America/New_York', '+05:30'
  carbonTimezone: 'UTC',
  
  /// Default locale for Carbon formatting
  /// Examples: 'en_US', 'fr_FR', 'ja_JP'
  carbonLocale: 'en_US',
  
  /// Enable named timezone support (requires async initialization)
  /// Set to true for timezones like 'America/New_York'
  enableNamedTimezones: false,
)
```

### Configuration Methods

```dart
// Automatic (via DataSource - recommended)
final ds = DataSource(DataSourceOptions(
  driver: adapter,
  entities: entities,
  carbonTimezone: 'UTC',
  enableNamedTimezones: true,
));
await ds.init(); // Configures Carbon automatically

// Manual (advanced use cases)
await CarbonConfig.configureWithTimeMachine(
  defaultTimezone: 'America/New_York',
  defaultLocale: 'en_US',
);

// Query configuration state
print(CarbonConfig.defaultTimezone);        // 'UTC'
print(CarbonConfig.defaultLocale);          // 'en_US'
print(CarbonConfig.isTimeMachineConfigured); // true/false
```

## Timestamp Mixins

### Basic Timestamps (Non-Timezone Aware)

```dart
@OrmModel(table: 'users')
class User extends Model<User> with Timestamps {
  final int? id;
  final String name;
  
  const User({this.id, required this.name});
}

// Usage
final user = await User.query().first();
print(user.createdAt!.format('yyyy-MM-dd')); // Returns CarbonInterface
print(user.updatedAt!.diffForHumans());      // "2 hours ago"
```

### Timezone-Aware Timestamps

```dart
@OrmModel(table: 'posts')
class Post extends Model<Post> with TimestampsTZ {
  final int? id;
  final String title;
  
  const Post({this.id, required this.title});
}

// Both Timestamps and TimestampsTZ return Carbon instances in UTC
// The difference is semantic: TZ explicitly indicates timezone awareness
```

### Automatic Timestamp Management

Timestamps are **automatically managed** by the ORM:

```dart
// INSERT - created_at and updated_at set automatically
final user = User(name: 'Alice');
await user.save(); // created_at = now(), updated_at = now()

// UPDATE - updated_at set automatically
user.name = 'Alice Updated';
await user.save(); // updated_at = now()

// Query Builder - updated_at injected automatically
await User.query()
    .where('active', true)
    .update({'name': 'Bob'}); // updated_at automatically added
```

## Carbon API

### Available on Timestamp Fields

All timestamp fields (createdAt, updatedAt, deletedAt) return `CarbonInterface`:

```dart
final user = await User.query().first();
final created = user.createdAt!; // CarbonInterface

// Formatting
created.format('yyyy-MM-dd HH:mm:ss');     // Dart DateFormat patterns
created.toIso8601String();                  // ISO8601 string
created.toRfc2822String();                  // RFC2822 format

// Timezone conversion
created.tz('America/New_York');             // Convert to timezone
created.toUtc();                            // Convert to UTC

// Locale formatting
created.locale('fr_FR').format('LLLL');     // Localized format

// Comparisons
created.isToday();                          // Is today?
created.isFuture();                         // Is in the future?
created.isPast();                           // Is in the past?
created.isBetween(start, end);              // Between two dates?

// Arithmetic
created.addDays(7);                         // Add 7 days
created.subHours(2);                        // Subtract 2 hours
created.startOfDay();                       // Start of day
created.endOfMonth();                       // End of month

// Differences
created.diffForHumans();                    // "5 minutes ago"
created.diffInDays(other);                  // Days between
created.diffInHours(other);                 // Hours between

// Properties
created.year;                               // Year
created.month;                              // Month
created.day;                                // Day
created.hour;                               // Hour
created.isUtc;                              // Is UTC?
```

## Codec System

### Automatic Codec Registration

Ormed automatically registers codecs for DateTime and Carbon types:

```dart
// These codecs are registered automatically:
- SqliteDateTimeCodec       // DateTime ↔ ISO8601 TEXT
- SqliteCarbonCodec         // Carbon ↔ ISO8601 TEXT (timezone-aware)
- SqliteCarbonInterfaceCodec // CarbonInterface ↔ ISO8601 TEXT (timezone-aware)
```

### Timezone-Aware Decoding

**Important**: Carbon codecs now respect the configured default timezone when decoding from the database:

- **Encoding**: Always stores as UTC (ISO8601 with 'Z' suffix) for database consistency
- **Decoding**: Returns Carbon instances in the configured default timezone

```dart
// Configure timezone
await CarbonConfig.configureWithTimeMachine(
  defaultTimezone: 'America/New_York',
);

// Database stores: '2024-12-08T20:30:00.000Z' (UTC)
final user = await User.query().first();

// Carbon is decoded in NY timezone
print(user.createdAt!.format('HH:mm z')); // "15:30 EST"
print(user.createdAt!.hour);               // 15

// Convert to other timezones as needed
print(user.createdAt!.tz('UTC').format('HH:mm z'));     // "20:30 UTC"
print(user.createdAt!.tz('Asia/Tokyo').format('HH:mm z')); // "05:30 JST"
```

This makes it easy to work with timestamps in the user's timezone without manual conversion.

### Using @Casts Annotation

```dart
class User extends Model<User> {
  @Casts({'createdAt': 'datetime'})
  final DateTime? createdAt;
  
  const User({this.createdAt});
}

// The codec is automatically applied during serialization/deserialization
```

### Type Mapping

The ORM automatically handles these type mappings:

| Dart Type        | Database Type (SQLite) | Codec                        |
|------------------|------------------------|------------------------------|
| DateTime         | TEXT (ISO8601)         | SqliteDateTimeCodec          |
| DateTime?        | TEXT (ISO8601)         | SqliteDateTimeCodec          |
| Carbon           | TEXT (ISO8601)         | SqliteCarbonCodec            |
| CarbonInterface  | TEXT (ISO8601)         | SqliteCarbonInterfaceCodec   |

## Common Patterns

### Display User's Timezone

```dart
extension CarbonUserDisplay on CarbonInterface {
  String formatForUser(User user) {
    return tz(user.timezone).format('yyyy-MM-dd HH:mm z');
  }
}

// Usage
final post = await Post.query().first();
print(post.createdAt!.formatForUser(currentUser));
```

### Time-Based Queries

```dart
// Posts created today
final today = Carbon.now().startOfDay();
final tomorrow = today.addDays(1);

final posts = await Post.query()
    .whereBetween('created_at', [today.toUtc(), tomorrow.toUtc()])
    .get();

// Posts updated in last hour
final oneHourAgo = Carbon.now().subHours(1);
final recentPosts = await Post.query()
    .where('updated_at', '>', oneHourAgo.toUtc())
    .get();
```

### Multi-Timezone Application

```dart
// Store everything in UTC (automatic)
await CarbonConfig.configureWithTimeMachine(defaultTimezone: 'UTC');

// Display per user
String formatForUserTimezone(CarbonInterface timestamp, String userTz) {
  return timestamp.tz(userTz).format('yyyy-MM-dd HH:mm z');
}

final user = await User.query().first();
final userTz = user.timezone; // e.g., 'America/New_York'

print(formatForUserTimezone(user.createdAt!, userTz));
```

## Important Notes

### Format Patterns

Carbon uses **Dart DateFormat patterns**, not PHP-style:

```dart
// ❌ Wrong (PHP-style)
carbon.format('Y-m-d H:i:s');

// ✅ Correct (Dart DateFormat)
carbon.format('yyyy-MM-dd HH:mm:ss');
```

Common patterns:
- `yyyy` - 4-digit year (2024)
- `MM` - 2-digit month (01-12)
- `dd` - 2-digit day (01-31)
- `HH` - 2-digit hour 24h (00-23)
- `mm` - 2-digit minute (00-59)
- `ss` - 2-digit second (00-59)
- `z` - Timezone abbreviation (UTC, EST, etc.)

### Database Storage

All timestamps are stored in **UTC** as ISO8601 strings:

```sql
-- SQLite example
CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  name TEXT,
  created_at TEXT, -- '2024-12-08T20:30:00.000Z'
  updated_at TEXT  -- '2024-12-08T20:30:00.000Z'
);
```

This is handled automatically by the codecs - you don't need to do anything.

### TimeMachine Initialization

Named timezones require async initialization:

```dart
// ❌ Will throw error without TimeMachine
CarbonConfig.configure(defaultTimezone: 'UTC');
final eastern = CarbonConfig.createCarbon(timezone: 'America/New_York'); // Error!

// ✅ Correct - enable named timezones
await CarbonConfig.configureWithTimeMachine();
final eastern = CarbonConfig.createCarbon(timezone: 'America/New_York'); // Works!
```

Or use DataSourceOptions:

```dart
final ds = DataSource(DataSourceOptions(
  // ...
  enableNamedTimezones: true, // Automatically configures TimeMachine
));
```

## Testing

### Reset Configuration in Tests

```dart
group('Timestamp tests', () {
  setUp(() {
    CarbonConfig.reset(); // Reset to defaults
  });
  
  test('timezone handling', () async {
    await CarbonConfig.configureWithTimeMachine(
      defaultTimezone: 'America/New_York',
    );
    // ... test code
  });
});
```

### Use enableNamedTimezones in Test Setup

```dart
final testDataSource = DataSource(
  DataSourceOptions(
    driver: SqliteDriverAdapter.inMemory(),
    entities: entities,
    enableNamedTimezones: true, // For timezone conversion tests
  ),
);

await testDataSource.init();
```

## Performance Considerations

### TimeMachine Overhead

- **Without TimeMachine**: Very lightweight, no additional data loaded
- **With TimeMachine**: ~1-2 MB of timezone data loaded at initialization
- **Recommendation**: Only enable if you need named timezones

### Carbon vs DateTime

- Carbon wraps DateTime with convenience methods
- Minimal overhead for most operations
- If you only need storage/retrieval, plain DateTime is fine
- If you need formatting/manipulation, Carbon is worth it

## Migration Guide

### From Plain DateTime

```dart
// Before
class User extends Model<User> {
  final DateTime? createdAt;
  
  const User({this.createdAt});
}

// Usage
final user = await User.query().first();
print(user.createdAt!.toIso8601String());

// After - no changes needed! DateTime still works
// But you can also use Carbon for richer functionality
final user = await User.query().first();
final carbon = Carbon.fromDateTime(user.createdAt!);
print(carbon.format('yyyy-MM-dd'));
print(carbon.diffForHumans());
```

### Adding Timestamps Mixin

```dart
// Before
class User extends Model<User> {
  final int? id;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  const User({this.id, required this.name, this.createdAt, this.updatedAt});
}

// After
@OrmModel(table: 'users')
class User extends Model<User> with Timestamps {
  final int? id;
  final String name;
  // createdAt and updatedAt provided by Timestamps mixin
  
  const User({this.id, required this.name});
}

// Benefits:
// - Automatic timestamp management
// - Returns CarbonInterface (richer API)
// - Less boilerplate
```

## Troubleshooting

### Error: Named timezone requires configureWithTimeMachine

```dart
// Problem
CarbonConfig.configure(defaultTimezone: 'UTC');
final ny = Carbon.now().tz('America/New_York'); // Error!

// Solution 1: Use DataSourceOptions
final ds = DataSource(DataSourceOptions(
  driver: adapter,
  entities: entities,
  enableNamedTimezones: true, // ✅
));
await ds.init();

// Solution 2: Manual configuration
await CarbonConfig.configureWithTimeMachine(); // ✅
```

### Format returns unexpected output

```dart
// Problem: Using PHP format codes
carbon.format('Y-m-d'); // Returns "Y-46-8" ❌

// Solution: Use Dart DateFormat patterns
carbon.format('yyyy-MM-dd'); // Returns "2024-12-08" ✅
```

### Timestamps not in user's timezone

```dart
// Problem: Forgetting to convert timezone
final created = user.createdAt!;
print(created.format('HH:mm')); // Shows UTC time

// Solution: Convert to user's timezone explicitly
final created = user.createdAt!.tz(userTimezone);
print(created.format('HH:mm z')); // Shows user's time
```

## Documentation

- [CARBON_CONFIGURATION.md](./CARBON_CONFIGURATION.md) - Complete configuration guide
- [DATETIME_CODECS.md](./DATETIME_CODECS.md) - DateTime codec system details
- [TIMESTAMPS_USAGE.md](./TIMESTAMPS_USAGE.md) - Automatic timestamp management
- [Carbonized Package](https://pub.dev/packages/carbonized) - Official Carbon docs

## Support

For issues, questions, or contributions related to Carbon integration in Ormed:
1. Check the documentation files listed above
2. Search existing issues on GitHub
3. Create a new issue with detailed reproduction steps

## Changelog

### v1.0.0 (2024-12-08)
- ✅ Automatic Carbon configuration via DataSource
- ✅ Named timezone support via TimeMachine
- ✅ 170+ locale support
- ✅ Automatic timestamp management (insert/update)
- ✅ Complete codec system for DateTime/Carbon types
- ✅ Timestamps and TimestampsTZ mixins
- ✅ Query builder update timestamp injection
- ✅ Full test coverage (530/530 tests passing)
