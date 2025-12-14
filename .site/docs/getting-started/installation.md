---
sidebar_position: 1
---

# Installation

## Requirements

- Dart SDK >= 3.0.0
- A supported database driver package

## Install Dependencies

Add Ormed and a database driver to your `pubspec.yaml`:

```yaml
dependencies:
  ormed: ^0.1.0
  # Choose your database driver:
  ormed_sqlite: ^0.1.0   # SQLite (file or in-memory)
  # ormed_postgres: ^0.1.0  # PostgreSQL (coming soon)
  # ormed_mysql: ^0.1.0     # MySQL (coming soon)

dev_dependencies:
  build_runner: ^2.4.0
```

Then run:

```bash
dart pub get
```

## Project Structure

A typical Ormed project structure looks like:

```
my_app/
├── lib/
│   ├── src/
│   │   ├── models/
│   │   │   ├── user.dart
│   │   │   ├── user.orm.dart  (generated)
│   │   │   └── post.dart
│   │   └── database/
│   │       └── migrations/
│   │           ├── migrations.dart
│   │           └── m_20241201_create_users_table.dart
│   └── main.dart
├── orm.yaml           (CLI configuration)
└── pubspec.yaml
```

## Code Generation

After defining your models, run the build runner to generate the ORM code:

```bash
# One-time build
dart run build_runner build

# Watch mode for development
dart run build_runner watch
```

This generates `.orm.dart` files alongside your model files containing:
- `$ModelName` - Tracked model class with change tracking
- `ModelNameOrmDefinition` - Model metadata and static helpers
- `$ModelNamePartial` - Partial entity for projections
- `ModelNameInsertDto` / `ModelNameUpdateDto` - Data transfer objects

It also generates a centralized `orm_registry.g.dart` file with:
- `buildOrmRegistry()` - Creates a `ModelRegistry` with all models registered
- `buildOrmRegistryWithFactories()` - Registry + factory registration
- `registerOrmFactories()` - Registers factories for `Model.factory<T>()`
- `GeneratedOrmModels` extension for fluent registration

## Next Steps

- [Quick Start Guide](./quick-start) - Build your first Ormed app
- [Configuration](./configuration) - Configure the CLI and database connections
