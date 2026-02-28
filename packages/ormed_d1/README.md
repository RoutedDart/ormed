# ormed_d1

Cloudflare D1 adapter for Ormed.

`ormed_d1` uses `ormed_sqlite_core` to compile SQLite-compatible SQL and executes
statements through the Cloudflare D1 HTTP API.

## Installation

```yaml
dependencies:
  ormed: ^0.1.0
  ormed_d1: ^0.1.0
```

## Quick start with Ormed

```dart
import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:ormed_d1/ormed_d1.dart';
import 'package:your_app/src/database/orm_registry.g.dart';

DataSourceOptions buildDataSourceOptions({String connection = 'd1'}) {
  final env = OrmedEnvironment.fromDirectory(Directory.current);
  final registry = bootstrapOrm();
  return registry.d1DataSourceOptionsFromEnv(
    name: connection,
    environment: env.values,
  );
}

DataSource createDataSource({
  DataSourceOptions? options,
  String connection = 'd1',
}) {
  return DataSource(options ?? buildDataSourceOptions(connection: connection));
}

Future<void> main() async {
  final ds = createDataSource();
  await ds.init();

  final rows = await ds.connection.driver.queryRaw('SELECT 1 AS ok');
  print(rows.first['ok']);

  await ds.dispose();
}
```

## Using `DataSource`

### Helper extensions (recommended, from `.env`)

```dart
import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:ormed_d1/ormed_d1.dart';
import 'package:your_app/src/database/orm_registry.g.dart';

Future<void> main() async {
  final env = OrmedEnvironment.fromDirectory(Directory.current);
  final registry = bootstrapOrm();
  final dataSource = DataSource(
    registry.d1DataSourceOptionsFromEnv(
      name: 'd1',
      environment: env.values,
    ),
  );
  await dataSource.init();

  final rows = await dataSource.connection.driver.queryRaw('SELECT 1 AS ok');
  print(rows.first['ok']);

  await dataSource.dispose();
}
```

### Helper extensions (explicit credentials)

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_d1/ormed_d1.dart';
import 'package:your_app/src/database/orm_registry.g.dart';

Future<void> main() async {
  final registry = bootstrapOrm();
  final dataSource = DataSource(
    registry.d1DataSourceOptions(
      name: 'd1',
      accountId: 'your-cloudflare-account-id',
      databaseId: 'your-d1-database-id',
      apiToken: 'your-d1-api-token',
    ),
  );
  await dataSource.init();
  await dataSource.dispose();
}
```

### `DataSource(DataSourceOptions(...))` (direct adapter style)

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_d1/ormed_d1.dart';

Future<void> main() async {
  final registry = ModelRegistry()
    ..register(UserOrmDefinition.definition);

  final adapter = D1DriverAdapter.custom(
    config: DatabaseConfig(
      driver: 'd1',
      options: {
        'accountId': 'your-cloudflare-account-id',
        'databaseId': 'your-d1-database-id',
        'apiToken': 'your-d1-api-token',
      },
    ),
  );

  final dataSource = DataSource(
    DataSourceOptions(
      name: 'd1',
      driver: adapter,
      registry: registry,
    ),
  );

  await dataSource.init();

  final rows = await dataSource.connection.driver.queryRaw('SELECT 1 AS ok');
  print(rows.first['ok']);

  await dataSource.dispose();
}
```

## Connection options

Required:
- `accountId` (or `account_id`)
- `databaseId` (or `database_id`)
- `apiToken` (or `api_token` / `token`)

Optional:
- `baseUrl` / `base_url` (default: `https://api.cloudflare.com/client/v4`)
- `maxAttempts` / `max_attempts` / `retryAttempts` (default: `4`)
- `requestTimeoutMs` / `request_timeout_ms` / `timeoutMs` (default: `30000`)
- `retryBaseDelayMs` / `retry_base_delay_ms` (default: `250`)
- `retryMaxDelayMs` / `retry_max_delay_ms` (default: `3000`)
- `debugLog` / `debug_log` / `debug` (default: `false`)

## `.env` example for local integration tests

```bash
# Required
D1_SECRET=your_d1_api_token
CF_ACCOUNT_ID=your_cloudflare_account_id
D1_DATABASE_ID=your_d1_database_id

# Optional
D1_BASE_URL=https://api.cloudflare.com/client/v4
D1_DEBUG_LOG=1
D1_RETRY_ATTEMPTS=5
D1_REQUEST_TIMEOUT_MS=30000
D1_RETRY_BASE_DELAY_MS=250
D1_RETRY_MAX_DELAY_MS=3000
```

`D1_ACCOUNT_ID` can be used instead of `CF_ACCOUNT_ID`, and `D1_API_TOKEN` can
be used instead of `D1_SECRET`.

## Test commands

From `packages/ormed_d1`:

```bash
just test                 # unit tests
just test-integration     # integration smoke tests (shared excluded)
just test-shared          # shared driver tests (slow)
just verify-datasource    # verifies both DataSource approaches
just verify-generated-helpers # verifies generated model helpers on D1
```

From repo root:

```bash
task d1:test-integration
task d1:test-shared
```

### Run example directly

```bash
cd packages/ormed_d1
# export D1_* vars first, or define them in packages/ormed_d1/.env
# (examples auto-load .env from the current directory)
dart run example/data_source_verification.dart both
dart run example/data_source_verification.dart from-config
dart run example/data_source_verification.dart direct
dart run example/generated_helpers_verification.dart
```

## Notes

- D1 HTTP does not support explicit SQL transaction statements (`BEGIN`,
  `COMMIT`, `ROLLBACK`) via this adapter.
- The adapter includes retry/backoff support for transient HTTP/network errors.
