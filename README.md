# Ormed

[![Pub Version](https://img.shields.io/pub/v/ormed)](https://pub.dev/packages/ormed)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![GitHub](https://img.shields.io/github/stars/RoutedDart/ormed?style=social)](https://github.com/RoutedDart/ormed)

A **strongly typed ORM for Dart** inspired by [Laravel Eloquent](https://laravel.com/docs/eloquent), bringing familiar patterns from Eloquent, GORM, SQLAlchemy, and ActiveRecord to Dart developers.

Part of the [Routed](https://github.com/RoutedDart) ecosystem.

---

## ✨ Features

- **Annotation-based models** — Define tables, columns, and relationships with `@OrmModel`, `@OrmField`, `@OrmRelation`
- **Code generation** — Auto-generate model definitions, codecs, and factories via `build_runner`
- **Fluent query builder** — Laravel-style API with `where`, `orderBy`, `join`, `limit`, and more
- **Eager & lazy loading** — Load relations upfront or on-demand, with nested paths (`'comments.author'`)
- **Lazy loading prevention** — Catch N+1 queries in development with `ModelRelations.preventsLazyLoading`
- **Aggregate loaders** — Load counts, sums, averages without fetching full collections (`loadCount()`, `loadSum()`, etc.)
- **Relation mutations** — `associate()`, `attach()`, `detach()`, `sync()` for managing relationships
- **Schema migrations** — CLI tooling for creating, applying, and rolling back migrations
- **Multi-database support** — SQLite, PostgreSQL, MySQL/MariaDB, MongoDB
- **Driver capabilities** — Runtime feature detection for cross-database compatibility
- **Multi-tenant connections** — Manage multiple database connections with role-based routing
- **Observability** — Structured logging, query instrumentation, and tracing hooks
- **Soft deletes** — Built-in `SoftDeletes` mixin with scoped queries
- **Repository pattern** — Bulk inserts, upserts, and JSON updates

---

## 🗄️ Supported Databases

| Database       | Package                                        |
|----------------|------------------------------------------------|
| SQLite         | [ormed_sqlite](packages/ormed_sqlite)          |
| PostgreSQL     | [ormed_postgres](packages/ormed_postgres)      |
| MySQL / MariaDB| [ormed_mysql](packages/ormed_mysql)            |
| MongoDB        | [ormed_mongo](packages/ormed_mongo)            |

---

## 🚀 Quick Start

### 1. Add dependencies

```yaml
dependencies:
  ormed: ^0.1.0
  ormed_sqlite: ^0.1.0  # or your preferred driver

dev_dependencies:
  build_runner: ^2.4.0
```

### 2. Define a model

```dart
import 'package:ormed/ormed.dart';

part 'user.orm.dart';

@OrmModel(table: 'users')
class User extends Model<User> {
  const User({required this.id, required this.email, this.name});

  @OrmField(isPrimaryKey: true, autoIncrement: true)
  final int id;

  @OrmField(isUnique: true)
  final String email;

  final String? name;
}
```

### 3. Generate code

```bash
dart run build_runner build
```

### 4. Query your data

```dart
import 'package:ormed/ormed.dart';
import 'package:ormed_sqlite/ormed_sqlite.dart';

void main() async {
  // Setup with DataSource (recommended)
  final ds = DataSource(DataSourceOptions(
    driver: SqliteDriverAdapter.file('app.sqlite'),
    entities: [UserOrmDefinition.definition],
  ));
  await ds.init();

  // Query
  final users = await ds.query<User>()
      .whereEquals('active', true)
      .orderBy('created_at', descending: true)
      .limit(10)
      .get();

  // Create
  await ds.repo<User>().insert(
    const User(id: 0, email: 'hello@example.com', name: 'Jane'),
  );

  // Update
  await ds.query<User>()
      .whereEquals('id', 1)
      .update({'name': 'Jane Doe'});

  // Eager load relations
  final posts = await ds.query<Post>()
      .withRelation('author')
      .withRelation('tags')
      .withCount('comments')
      .get();

  // Lazy load relations
  final post = await ds.query<Post>().firstOrFail();
  await post.load('author');
  await post.loadMissing(['tags', 'comments']);

  // Transaction
  await ds.transaction(() async {
    await ds.repo<User>().insert(user1);
    await ds.repo<User>().insert(user2);
  });

  // Cleanup
  await ds.dispose();
}
```

<details>
<summary>Alternative: Manual Setup (advanced)</summary>

```dart
import 'package:ormed_sqlite/ormed_sqlite.dart';

void main() async {
  final registry = ModelRegistry()..register(UserOrmDefinition.definition);
  final adapter = SqliteDriverAdapter.file('app.sqlite');
  final context = QueryContext(registry: registry, driver: adapter);

  final users = await context.query<User>()
      .whereEquals('active', true)
      .get();
}
```

</details>

---

## 📦 Packages

| Package | Description |
|---------|-------------|
| [ormed](packages/ormed) | Core ORM with annotations, query builder, codecs, and code generator |
| [ormed_sqlite](packages/ormed_sqlite) | SQLite driver adapter via `package:sqlite3` |
| [ormed_postgres](packages/ormed_postgres) | PostgreSQL driver adapter via `package:postgres` |
| [ormed_mysql](packages/ormed_mysql) | MySQL/MariaDB driver adapter via `package:mysql_client_plus` |
| [ormed_mongo](packages/ormed_mongo) | MongoDB driver adapter via `package:mongo_dart` |
| [ormed_cli](packages/ormed_cli) | CLI for migrations, seeding, and project scaffolding |
| [driver_tests](packages/driver_tests) | Shared driver-agnostic integration test suites |
| [orm_playground](packages/orm_playground) | Demo application with end-to-end examples |

---

## 🛠️ CLI Commands

```bash
# Initialize project structure
dart run ormed_cli:orm init

# Create a new migration
dart run ormed_cli:orm make --name create_users_table

# Apply pending migrations
dart run ormed_cli:orm apply

# Apply to a specific connection (multi-tenant)
dart run ormed_cli:orm apply --connection analytics

# Preview migrations without executing
dart run ormed_cli:orm apply --pretend

# Rollback migrations
dart run ormed_cli:orm rollback --steps 1

# Check migration status
dart run ormed_cli:orm status

# Describe current schema
dart run ormed_cli:orm schema:describe

# Run database seeders
dart run ormed_cli:orm seed
dart run ormed_cli:orm seed --class DemoContentSeeder
```

See the [CLI Reference](docs/cli.md) for complete documentation of all commands and options.

---

## 📚 Documentation

### Core Guides
- [CLI Reference](docs/cli.md) — Complete CLI commands and options
- [Query Builder](docs/query_builder.md) — Full query API reference
- [Relations & Lazy Loading](docs/relations.md) — Eager/lazy loading and relation mutations
- [Migrations](docs/migrations.md) — Schema migrations and schema builder API
- [Data Source](docs/data_source.md) — Runtime database access patterns
- [Code Generation](docs/code_generation.md) — Model annotations and generated code
- [Model Factories](docs/model_factories.md) — Test data generation and seeding
- [Connectors](docs/connectors.md) — Connection management and multi-tenancy
- [Observability](docs/observability.md) — Logging, instrumentation, and tracing
- [Examples](docs/examples.md) — Common usage patterns

### Advanced Topics
- [Driver Capabilities](docs/driver_capabilities.md) — Cross-database compatibility and feature detection
- [Recent Improvements](docs/RECENT_IMPROVEMENTS.md) — New features and enhancements
- [Grammar Parity Matrix](docs/grammar_parity_matrix.md) — Laravel grammar compatibility

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 💖 Support

If you find this project helpful, consider supporting its development:

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow?logo=buy-me-a-coffee)](https://www.buymeacoffee.com/kingwill101)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
