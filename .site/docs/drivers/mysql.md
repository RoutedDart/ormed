---
sidebar_position: 4
---

# MySQL / MariaDB

The MySQL adapter also supports MariaDB. Configure via URL or explicit fields; common alias keys are accepted.

## orm.yaml

```yaml
driver:
  type: mysql          # or mariadb
  options:
    url: mysql://root:secret@localhost:6605/orm_test
    ssl: false
    charset: utf8mb4
    collation: utf8mb4_general_ci
    timezone: "+00:00"
    sqlMode: STRICT_ALL_TABLES
    timeoutMs: 10000
    session:
      sql_notes: 0
    init:
      - SET NAMES utf8mb4
      - SET time_zone = "+00:00"
migrations:
  directory: lib/src/database/migrations
  registry: lib/src/database/migrations.dart
seeds:
  directory: lib/src/database/seeders
  registry: lib/src/database/seeders.dart
```

### Options

- `url` / `uri` / `dsn` — full connection string; overrides individual fields.
- `host` (default `127.0.0.1`)
- `port` (default `3306`)
- `database` (default connection name or `test`)
- `username` (default `root`)
- `password` (optional)
- `ssl` / `secure` (bool) — enable TLS.
- `timeoutMs` / `connectTimeout` — connect timeout in milliseconds (default 10s).
- `charset` (default `utf8mb4`)
- `collation` (default `utf8mb4_general_ci` if charset set)
- `timezone` (default `+00:00`)
- `sqlMode` / `sql_mode` — session SQL mode string.
- `session` / `sessionVariables` (map) — arbitrary session variables.
- `init` (list of strings) — SQL statements executed right after connect.

### Notes

- Uses `ON DUPLICATE KEY UPDATE` for upserts and supports JSON columns on MySQL 8+/MariaDB 10.5+.
- Set `driver.type: mariadb` to target MariaDB specifically; the same options apply.
