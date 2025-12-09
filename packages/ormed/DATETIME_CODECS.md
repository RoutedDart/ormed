# DateTime and Carbon Codec System

This document explains how DateTime and Carbon values are encoded/decoded for different database drivers, with a focus on SQLite's implementation.

## Overview

Ormed provides a flexible codec system that handles conversion between Dart types and database-specific storage formats. For date/time values, we support three main types:

1. **DateTime** - Dart's built-in date/time class
2. **Carbon** - Mutable Carbon instance from the carbonized package  
3. **CarbonInterface** - Interface implemented by both Carbon and CarbonImmutable

## SQLite DateTime Storage

Following SQLite best practices, date/time values are stored as **TEXT** in ISO8601 format:

```
"YYYY-MM-DD HH:MM:SS.SSSZ"
```

The 'Z' suffix indicates UTC timezone, ensuring consistency across different timezones.

### Storage Format Comparison

SQLite supports three formats for dates:
- **TEXT** (ISO8601) - `"2024-12-08T20:33:46.781Z"` ✅ **We use this**
- **REAL** (Julian day) - `2460288.356257176`
- **INTEGER** (Unix time) - `1733692426`

We chose ISO8601 TEXT because:
- Human-readable in database browsers
- Preserves millisecond precision
- Clearly indicates UTC with 'Z' suffix
- Compatible with DateTime.parse()

## Available Codecs

### 1. SqliteDateTimeCodec

Handles Dart `DateTime` <-> SQLite TEXT conversion.

```dart
// Encoding (Dart → Database)
DateTime.now()  →  "2024-12-08T20:33:46.781Z"

// Decoding (Database → Dart)
"2024-12-08T20:33:46.781Z"  →  DateTime (UTC)
```

**Registered Keys:**
- `'DateTime'`
- `'DateTime?'`
- `'datetime'` (for `casts` annotation)

### 2. SqliteCarbonCodec

Handles `Carbon` <-> SQLite TEXT conversion.

```dart
// Encoding
Carbon.now()  →  "2024-12-08T20:33:46.781Z"

// Decoding
"2024-12-08T20:33:46.781Z"  →  Carbon (UTC)
```

**Registered Keys:**
- `'Carbon'`
- `'Carbon?'`
- `'carbon'` (for `casts` annotation)

### 3. SqliteCarbonInterfaceCodec

Handles `CarbonInterface` <-> SQLite TEXT conversion.

```dart
// Encoding
carbon.toUtc()  →  "2024-12-08T20:33:46.781Z"

// Decoding (returns Carbon, not CarbonImmutable)
"2024-12-08T20:33:46.781Z"  →  Carbon (UTC)
```

**Registered Keys:**
- `'CarbonInterface'`
- `'CarbonInterface?'`

**Note:** Decodes to `Carbon` (mutable) by default, not `CarbonImmutable`.

## Usage Examples

### Using DateTime Fields

```dart
@OrmModel(table: 'events')
class Event extends Model<Event> {
  final int? id;
  final String name;
  
  // Option 1: Explicit DateTime field
  final DateTime? eventDate;
  
  // Option 2: Use casts annotation
  @OrmField(cast: 'datetime')
  final DateTime? scheduledAt;
  
  const Event({this.id, required this.name, this.eventDate, this.scheduledAt});
}

// Usage
final event = Event(
  name: 'Conference',
  eventDate: DateTime.now(),
  scheduledAt: DateTime.parse('2024-12-25T10:00:00Z'),
);
```

### Using Carbon Fields

```dart
@OrmModel(table: 'posts')
class Post extends Model<Post> {
  final int? id;
  final String title;
  
  // Option 1: Carbon field (mutable)
  @OrmField(codec: Carbon)
  final Carbon? publishedAt;
  
  // Option 2: CarbonInterface field (accepts both Carbon and CarbonImmutable)
  @OrmField(codec: CarbonInterface)
  final CarbonInterface? archivedAt;
  
  const Post({this.id, required this.title, this.publishedAt, this.archivedAt});
}

// Usage
final post = Post(
  title: 'Hello World',
  publishedAt: Carbon.now(),
  archivedAt: Carbon.parse('2024-12-31 23:59:59'),
);

// Carbon provides fluent methods
print(post.publishedAt?.diffForHumans()); // "5 minutes ago"
print(post.publishedAt?.addDays(7).format('Y-m-d')); // "2024-12-15"
```

### Using Timestamp Mixins (Automatic Management)

```dart
@OrmModel(table: 'authors')
class Author extends Model<Author> with TimestampsTZ {
  final int? id;
  final String name;
  
  const Author({this.id, required this.name});
}

// The generated tracked model (_$AuthorModel) will have:
// - CarbonInterface? get createdAt
// - CarbonInterface? get updatedAt
// Both automatically managed and stored in UTC

final author = const Author(name: 'John Doe');
await repo<Author>().insert(author); // created_at & updated_at set automatically

final fetched = await query<Author>().where('id', 1).first();
print(fetched!.createdAt!.isUtc); // true
print(fetched.createdAt!.format('Y-m-d H:i:s')); // "2024-12-08 20:33:46"
```

## Codec Resolution

The codec system resolves in this order:

1. **Field-specific codec** (via `@OrmField(codec: ...)`)
2. **Cast type** (via `@OrmField(cast: 'datetime')` or model-level `casts: {'field': 'datetime'}`)
3. **Driver-specific codec** (registered via `registerDriver('sqlite', {...})`)
4. **Global codec** (registered via `register({...})`)
5. **Dart type fallback** (uses field's Dart type)

### Example Resolution

```dart
// Model definition
@OrmModel(table: 'logs', casts: {'timestamp': 'datetime'})
class Log extends Model<Log> {
  @OrmField(cast: 'datetime')  // Field-level cast
  final DateTime? timestamp;
  
  final DateTime? createdAt;  // Falls back to model-level casts
}
```

Resolution:
- `timestamp` → `'datetime'` cast → `SqliteDateTimeCodec`
- `createdAt` → `'DateTime'` type → `SqliteDateTimeCodec`

## UTC Handling

All codecs ensure UTC consistency:

### Encoding (Storage)
```dart
// DateTime
value.toUtc().toIso8601String()

// Carbon
value.toUtc().toIso8601String()
```

### Decoding (Retrieval)
```dart
// DateTime
final parsed = DateTime.parse(value);  // Already UTC if 'Z' suffix
return parsed.isUtc ? parsed : parsed.toUtc();

// Carbon
final dateTime = DateTime.parse(value);
final utcDateTime = dateTime.isUtc ? dateTime : dateTime.toUtc();
return Carbon.fromDateTime(utcDateTime).tz('UTC');
```

## Parameter Normalization

Before passing values to SQLite, the `normalizeSqliteParameters()` function converts Dart types:

```dart
Object? _normalizeValue(Object? value) {
  if (value is bool) return value ? 1 : 0;
  if (value is DateTime) return value.toUtc().toIso8601String();
  if (value is CarbonInterface) return value.toUtc().toIso8601String();
  if (value is BigInt) return value.toInt();
  return value;
}
```

This ensures that:
- Booleans become 0/1
- DateTimes and Carbons become ISO8601 strings in UTC
- BigInts become regular ints

## Timestamp Setters (TimestampsTZ)

The `TimestampsTZImpl` mixin provides setters that accept both DateTime and CarbonInterface:

```dart
set createdAt(value) {
  if (value == null) {
    setAttribute(_createdAtColumn, null);
  } else if (value is CarbonInterface) {
    setAttribute(_createdAtColumn, value.toUtc().toDateTime());
  } else if (value is DateTime) {
    setAttribute(_createdAtColumn, value.isUtc ? value : value.toUtc());
  } else {
    throw ArgumentError('createdAt must be DateTime or CarbonInterface');
  }
}
```

This allows flexible usage:

```dart
model.createdAt = DateTime.now();
model.createdAt = Carbon.now();
model.createdAt = Carbon.parse('2024-12-25');
model.createdAt = null;
```

## Error Handling

Codecs throw descriptive errors for invalid input:

```dart
// SqliteDateTimeCodec
throw ArgumentError(
  'SqliteDateTimeCodec.decode expects String or DateTime, got ${value.runtimeType}',
);

// SqliteCarbonCodec
throw ArgumentError(
  'SqliteCarbonCodec.decode expects String, DateTime, or Carbon, got ${value.runtimeType}',
);
```

## Testing

Test coverage includes:

- ✅ DateTime encoding/decoding
- ✅ Carbon encoding/decoding
- ✅ UTC preservation
- ✅ Timezone handling
- ✅ ISO8601 format validation
- ✅ Null handling
- ✅ Cast annotation resolution
- ✅ Automatic timestamp management

## Best Practices

1. **Always use UTC** for timestamps in database
2. **Use TimestampsTZ** mixin for automatic timestamp management
3. **Use Carbon** for date manipulation (format, diffForHumans, etc.)
4. **Use DateTime** for simple storage without manipulation
5. **Use `casts: {'field': 'datetime'}`** for compatibility with legacy code
6. **Validate timezones** when accepting user input

## See Also

- [TIMESTAMPS_USAGE.md](./TIMESTAMPS_USAGE.md) - Automatic timestamp management
- [ATTRIBUTE_TRACKING.md](./ATTRIBUTE_TRACKING.md) - Attribute system
- [SQLite Date/Time Functions](https://www.sqlite.org/lang_datefunc.html)
- [Carbonized Package](https://pub.dev/packages/carbonized)
