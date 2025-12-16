---
sidebar_position: 1
---

# Testing

Ormed provides comprehensive testing facilities for isolated, reliable database tests.

## Basic Test Setup

Create a fresh DataSource for each test suite:

```dart file=../../examples/lib/testing/testing.dart#testing-basic-setup
```

## Using SQLite In-Memory

For fast, isolated tests:

```dart file=../../examples/lib/testing/testing.dart#testing-in-memory
```

## Test Data with Seeders

Define a seeder class for consistent test data:

```dart file=../../examples/lib/testing/testing.dart#testing-seeder
```

## Testing with Real Databases

For integration tests with SQLite:

```dart file=../../examples/lib/testing/testing.dart#testing-real-db
```

## Migration-Aware Test Harness

```dart file=../../examples/lib/testing/testing.dart#testing-migration-harness
```

## Static Helpers in Tests

Set a default DataSource for `Model` static helpers:

```dart file=../../examples/lib/testing/testing.dart#testing-static-helpers
```

## Testing Relations

Ensure all related entities are registered:

```dart file=../../examples/lib/testing/testing.dart#testing-relations
```

## Parallel Testing

For parallel test execution without conflicts:

```dart file=../../examples/lib/testing/testing.dart#testing-parallel
```

## Best Practices

### Use SQLite In-Memory for Unit Tests

```dart file=../../examples/lib/testing/testing.dart#testing-best-practices-in-memory
```

### Use Real Databases for Integration Tests

```dart file=../../examples/lib/testing/testing.dart#testing-best-practices-real-db
```

### Keep Tests Isolated

```dart file=../../examples/lib/testing/testing.dart#testing-keep-isolated
```

### Use Factories for Test Data

```dart file=../../examples/lib/testing/testing.dart#testing-factories
```

### Test Both Success and Failure Cases

```dart file=../../examples/lib/testing/testing.dart#testing-success-failure
```

## Example Test Suite

### Setup

```dart file=../../examples/lib/testing/testing.dart#testing-example-suite-setup
```

### Tests

```dart file=../../examples/lib/testing/testing.dart#testing-example-suite-tests
```

### Tear Down

```dart file=../../examples/lib/testing/testing.dart#testing-example-suite-teardown
```
