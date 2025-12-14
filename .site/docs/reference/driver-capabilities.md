---
sidebar_position: 6
---

# Driver Capabilities

Ormed supports multiple database drivers (SQLite, PostgreSQL, MySQL), but not all databases support the same features. The Driver Capabilities system allows you to query what features are available at runtime.

## Overview

Different databases have varying levels of SQL feature support:

| Feature | SQLite | PostgreSQL | MySQL |
|---------|--------|------------|-------|
| Raw SQL Expressions | ✅ | ✅ | ✅ |
| Ad-hoc Updates/Deletes | ✅ | ✅ | ✅ |
| Complex Joins | ✅ | ✅ | ✅ |
| Window Functions | ✅ 3.25+ | ✅ | ✅ 8.0+ |
| Subqueries | ✅ | ✅ | ✅ |
| CTEs (WITH clause) | ✅ 3.8+ | ✅ | ✅ 8.0+ |

## Available Capabilities

```dart file=../../examples/lib/capabilities/driver_capabilities.dart#capability-enum
```

## Checking Capabilities at Runtime

```dart file=../../examples/lib/capabilities/driver_capabilities.dart#check-capabilities
```

## Driver-Specific Behavior

### SQLite

**Supported Capabilities:**
- ✅ `rawExpressions`
- ✅ `adHocQueryUpdates`
- ✅ `complexJoins`
- ✅ `windowFunctions` (SQLite 3.25+)
- ✅ `cte` (SQLite 3.8+)
- ✅ `subqueries`

**Notes:**
- Window functions require SQLite 3.25 or higher
- CTEs require SQLite 3.8 or higher
- Full-text search available via FTS5 extension

### PostgreSQL

**Supported Capabilities:**
- ✅ `rawExpressions`
- ✅ `adHocQueryUpdates`
- ✅ `complexJoins`
- ✅ `windowFunctions`
- ✅ `cte`
- ✅ `subqueries`

**Notes:**
- Most feature-complete SQL implementation
- Supports advanced features like LATERAL joins, JSONB operators
- Excellent subquery optimization

### MySQL

**Supported Capabilities:**
- ✅ `rawExpressions`
- ✅ `adHocQueryUpdates`
- ✅ `complexJoins`
- ✅ `windowFunctions` (MySQL 8.0+)
- ✅ `cte` (MySQL 8.0+)
- ✅ `subqueries`

**Notes:**
- Window functions and CTEs require MySQL 8.0+
- MariaDB has similar but slightly different feature set

## Writing Cross-Database Code

### Strategy 1: Capability Checks

```dart file=../../examples/lib/capabilities/driver_capabilities.dart#capability-checks-strategy
```

### Strategy 2: Prefer Query Builder Over Raw

The query builder API works across all drivers:

```dart file=../../examples/lib/capabilities/driver_capabilities.dart#query-builder-vs-raw
```

### Strategy 3: Feature Detection

```dart file=../../examples/lib/capabilities/driver_capabilities.dart#feature-detection-strategy
```

## Testing Across Drivers

### Skipping Incompatible Tests

```dart file=../../examples/lib/capabilities/driver_capabilities.dart#skip-incompatible-tests
```

## Migration Considerations

### Conditional Migrations

```dart file=../../examples/lib/capabilities/driver_capabilities.dart#conditional-migrations
```

## Best Practices

### 1. Use Query Builder First

```dart file=../../examples/lib/capabilities/driver_capabilities.dart#best-practice-query-builder
```

### 2. Check Capabilities, Don't Assume

```dart file=../../examples/lib/capabilities/driver_capabilities.dart#best-practice-check-capabilities
```

### 3. Document Driver Requirements

```dart file=../../examples/lib/capabilities/driver_capabilities.dart#document-driver-requirements
```

### 4. Fallback to Compatible Alternatives

```dart file=../../examples/lib/capabilities/driver_capabilities.dart#fallback-alternatives
```

## Summary

- **Driver capabilities** let you detect database feature support at runtime
- **Query builder API** provides maximum cross-database compatibility
- **Capability checks** enable graceful feature degradation
- For most applications, sticking to the standard query builder API provides excellent cross-database portability without manual capability checks
