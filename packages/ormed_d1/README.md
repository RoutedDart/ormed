# ormed_d1

Cloudflare D1 adapter for Ormed.

`ormed_d1` uses `ormed_sqlite_core` to compile SQLite-compatible SQL and executes
statements through the Cloudflare D1 HTTP API.

## Installation

```yaml
dependencies:
  ormed: ^0.3.0
  ormed_d1: ^0.2.0
```

## Quick start without code generation

Code generation is optional for direct database access:

```dart
import 'package:ormed_d1/ormed_d1.dart';

Future<void> main() async {
  final db = await D1Database.connect(
    accountId: 'account-id',
    databaseId: 'database-id',
    apiToken: 'api-token',
  );
  final rows = await db.queryRaw('SELECT 1 AS ok');
  print(rows.first['ok']);
  await db.close();
}
```

To use generated models, pass `registry: buildOrmRegistry()` to
`D1Database.connect`.

For a browser or Worker client, use an application-owned endpoint instead of
shipping a Cloudflare API token to the client:

```dart
import 'package:ormed_d1/ormed_d1.dart';

final db = await D1Database.fromEndpoint(
  endpoint: Uri.parse('https://example.com/api/database/query'),
  batchEndpoint: Uri.parse('https://example.com/api/database/batch'),
);
```

The query endpoint receives `{sql, params}` and returns either the D1 binding
shape (`success`, `results`, `meta`) or the Cloudflare API shape
(`success`, `result: [{results, meta}]`). The optional batch endpoint receives
`{statements: [{sql, params}, ...]}` and returns the result entries in
`results` or `result`. Authentication is supplied through `headers` or by the
endpoint's session/cookie policy.

Inside a Cloudflare Worker, a native D1 binding can be used without an HTTP
hop:

```dart
final db = await D1Database.fromBinding(binding: env.d1('DB'));
```

`D1DatabaseBinding`, `D1PreparedStatementBinding`, and the related result
types are exported from `package:ormed_d1/d1_binding.dart` for platform
bridges.

## Quick start with the existing DataSource API

```dart
import 'package:your_app/src/database/datasource.dart';

Future<void> main() async {
  final ds = createDataSource(connection: 'd1');
  await ds.init();

  final rows = await ds.connection.driver.queryRaw('SELECT 1 AS ok');
  print(rows.first['ok']);

  await ds.dispose();
}
```

Generated apps should use `ormed init` scaffolding (`lib/src/database/config.dart` +
`datasource.dart`) as the primary runtime entrypoint.

## Using `DataSource`

### Helper extensions (recommended, from `.env`)

```dart
import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:ormed_d1/ormed_d1.dart';
import 'package:your_app/src/models/user.orm.dart';

Future<void> main() async {
  final env = OrmedEnvironment.fromDirectory(Directory.current);
  final registry = ModelRegistry()..register(UserOrmDefinition.definition);
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
import 'package:your_app/src/models/user.orm.dart';

Future<void> main() async {
  final registry = ModelRegistry()..register(UserOrmDefinition.definition);
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
- `maxAttempts` / `max_attempts` / `retryAttempts` (default: `5`)
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
just test                 # unit tests + shared driver suite (mock by default)
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

## Troubleshooting

### Tests appear to hang

This is usually retry/timeout behavior. For faster failure while debugging:

```bash
export D1_RETRY_ATTEMPTS=1
export D1_REQUEST_TIMEOUT_MS=5000
export D1_DEBUG_LOG=1
```

### `not authorized to use function: sqlite_version`

D1 blocks some SQLite functions. Prefer health checks like:

```sql
SELECT 1 AS ok;
```

instead of `SELECT sqlite_version()`.
