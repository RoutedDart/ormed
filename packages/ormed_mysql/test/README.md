# MySQL/MariaDB Driver Tests

## Running Tests

### With Concurrency Limitation

Due to shared database state, MySQL/MariaDB driver tests must run with limited concurrency:

```bash
dart test --concurrency=1
```

This ensures that only one test file runs at a time, preventing race conditions during schema operations (table creation/deletion).

### Why Concurrency=1 is Required

1. **Shared Database**: All test files connect to the same database (`orm_test`)
2. **Schema Operations**: Each test file runs `resetDriverTestSchema()` which drops and recreates all tables
3. **Race Condition**: Without serialization, multiple test files would simultaneously drop/create the same tables, causing conflicts

### Alternative: Use Unique Databases Per Test File

For true parallel execution, each test file would need its own database. This requires:
- Dynamic database creation before tests
- Proper cleanup after tests  
- Database-specific infrastructure

This is not currently implemented as the `--concurrency=1` solution works universally across all database drivers.

## Test Structure

### Shared Tests (`mysql_driver_shared_test.dart`, `mariadb_driver_shared_test.dart`)

These run the complete driver test suite from the `driver_tests` package using `runAllDriverTests()`.

### Specific Tests  

- `mysql_driver_join_test.dart` - MySQL-specific JOIN syntax tests
- `codec_test.dart` - Codec registration and JSON handling
- `test_qb_only.dart` - Query builder tests
- Grammar tests - SQL generation verification

## Database Configuration

Tests use environment variables or fallback to defaults:

```bash
# MySQL
export MYSQL_URL='mysql://root:secret@localhost:6605/orm_test'

# MariaDB  
export MARIADB_URL='mariadb://root:secret@localhost:6604/orm_test'
```

## CI/CD Recommendations

For CI/CD pipelines, always use `--concurrency=1` for MySQL/MariaDB tests:

```yaml
# GitHub Actions example
- name: Run MySQL Tests
  run: dart test --concurrency=1
  working-directory: packages/ormed_mysql
```
