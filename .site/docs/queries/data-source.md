---
sidebar_position: 4
---

# DataSource

The `DataSource` class provides a modern, declarative API for configuring and using the ORM. It bundles driver configuration, entity registration, and connection management into a single interface.

## Overview

```dart file=../../examples/lib/datasource.dart#datasource-overview

```

## DataSourceOptions

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `driver` | `DriverAdapter` | **required** | The database driver adapter |
| `entities` | `List<ModelDefinition>` | **required** | Models to register. Pass the generated registry output (e.g., `buildOrmRegistry().definitions.values.toList()`) or a curated subset. |
| `name` | `String` | `'default'` | Logical name for the connection |
| `database` | `String?` | `null` | Database/catalog identifier for observability |
| `tablePrefix` | `String` | `''` | Prefix applied to table names |
| `defaultSchema` | `String?` | `null` | Default schema for ad-hoc queries |
| `codecs` | `Map<String, ValueCodec>` | `{}` | Custom value codecs to register |
| `logging` | `bool` | `false` | Enable query logging |

### Example Configuration (with generated registry)

```dart file=../../examples/lib/datasource.dart#datasource-options

```

## Initialization

Always call `init()` before using the data source:

```dart file=../../examples/lib/datasource.dart#datasource-init

```

The `init()` method:
- Is idempotent—calling it multiple times has no effect
- Automatically registers the DataSource with `ConnectionManager`
- Automatically sets it as default if it's the first DataSource initialized

## Using Static Model Helpers

Once initialized, the first DataSource automatically becomes the default:

```dart file=../../examples/lib/datasource.dart#datasource-static-helpers

```

## Querying Data

Use `query<T>()` to create a typed query builder:

```dart file=../../examples/lib/datasource.dart#datasource-querying

```

## Repository Operations

Use `repo<T>()` for CRUD operations:

```dart file=../../examples/lib/datasource.dart#datasource-repository

```

## Transactions

Execute multiple operations atomically:

```dart file=../../examples/lib/datasource.dart#datasource-transactions

```

## Ad-hoc Table Queries

Query tables without a model definition:

```dart file=../../examples/lib/datasource.dart#datasource-adhoc

```

## Query Logging & Debugging

```dart file=../../examples/lib/datasource.dart#datasource-logging

```

```dart file=../../examples/lib/datasource.dart#datasource-logging-options

```

### Access Query Log

```dart file=../../examples/lib/datasource.dart#datasource-query-log-access

```

### Pretend Mode

Preview SQL without executing:

```dart file=../../examples/lib/datasource.dart#datasource-pretend-mode

```

### Execution Hooks

```dart file=../../examples/lib/datasource.dart#datasource-execution-hooks

```

## Multiple DataSources

Create separate data sources for different databases:

```dart file=../../examples/lib/datasource.dart#datasource-multiple

```

## Lifecycle Management

```dart file=../../examples/lib/datasource.dart#datasource-lifecycle

```

### Access Underlying Components

```dart file=../../examples/lib/datasource.dart#datasource-underlying

```

## Custom Codecs

```dart file=../../examples/lib/datasource.dart#datasource-custom-codecs

```
