# Documentation Code Snippets Inventory

This document lists all code snippets in the documentation that need to be migrated to the `.site/examples/` project using remark-code-region.

## Progress Summary

### Completed ✅
- `docs/intro.md` - Model and query examples migrated
- `docs/models/defining-models.md` - Basic model, options, field examples migrated
- `docs/models/factories.md` - All factory examples migrated
- `docs/models/relationships.md` - All relationship types and loading examples migrated
- `docs/models/soft-deletes.md` - Model and migration examples migrated
- `docs/models/timestamps.md` - Model and migration examples migrated
- `docs/models/model-methods.md` - Replicate, comparison, fresh/refresh migrated
- `docs/queries/query-builder.md` - Where clauses, ordering, aggregates, relations migrated
- `docs/queries/repository.md` - All CRUD operations migrated
- `docs/queries/data-source.md` - Overview, querying, transactions migrated
- `docs/queries/relations.md` - Eager/lazy loading, aggregates, attach/detach migrated
- `docs/queries/caching.md` - Remember, flush, vacuum, stats migrated
- `docs/migrations/overview.md` - Basic structure, create/alter table migrated
- `docs/migrations/running-migrations.md` - Runner and ledger examples migrated
- `docs/migrations/schema-builder.md` - Column types, modifiers, indexes, foreign keys migrated
- `docs/getting-started/quick-start.md` - Model, migration, setup examples migrated
- `docs/getting-started/configuration.md` - Programmatic config migrated
- `docs/getting-started/code-generation.md` - Registry usage migrated
- `docs/guides/testing.md` - Basic setup, seeders, real DB, migration harness migrated
- `docs/guides/multi-database.md` - Setup, named connections, tenant examples migrated
- `docs/guides/best-practices.md` - N+1, aggregates, pagination, loading strategies migrated
- `docs/guides/observability.md` - Query logging, events, structured logger migrated
- `docs/guides/examples.md` - All workflow examples migrated (SQLite, PostgreSQL, relations, mutations, joins, seeding)

### Remaining (Low Priority) 🔄
- `docs/getting-started/installation.md` - Mostly YAML/shell config (skip Dart snippets)
- `docs/migrations/squashing.md` - All shell/YAML commands (no Dart snippets)
- `docs/cli/commands.md` - Mostly shell commands and yaml (skip)
- `docs/reference/driver-capabilities.md` - Reference tables, small inline patterns (kept inline for reference style)

## Syntax Reference

```markdown
```dart file=../../examples/lib/path/to/file.dart#region-name

```
```

## Existing Examples Structure

```
.site/examples/lib/
├── models/
│   ├── admin.dart          # model-with-options
│   ├── comment.dart
│   ├── post.dart
│   ├── product.dart
│   └── user.dart           # basic-model
├── queries.dart            # basic-query, where-clauses, ordering-limiting, aggregates, relations
└── orm_registry.g.dart
```

---

## Documentation Pages Inventory

### 1. `docs/intro.md` (79 lines)
| # | Snippet Description | Lines | Priority | Target File | Region Name |
|---|---------------------|-------|----------|-------------|-------------|
| 1 | User model definition | 12-24 | High | models/user.dart | intro-model |
| 2 | Query and repo example | 38-47 | High | queries.dart | intro-query |
| 3 | pubspec.yaml deps | 53-59 | Low | - | (shell/yaml, skip) |
| 4 | dart commands | 63-65 | Low | - | (shell, skip) |

---

### 2. `docs/getting-started/installation.md` (83 lines)
| # | Snippet Description | Lines | Priority | Target File | Region Name |
|---|---------------------|-------|----------|-------------|-------------|
| 1 | pubspec.yaml | 17-25 | Low | - | (yaml, skip) |
| 2 | dart pub get | 29-30 | Low | - | (shell, skip) |
| 3 | Project structure | 36-52 | Low | - | (text, skip) |
| 4 | build_runner commands | 56-62 | Low | - | (shell, skip) |

---

### 3. `docs/getting-started/quick-start.md` (159 lines)
| # | Snippet Description | Lines | Priority | Target File | Region Name |
|---|---------------------|-------|----------|-------------|-------------|
| 1 | User model | 12-31 | High | models/user.dart | quickstart-user-model |
| 2 | Migration class | 43-61 | High | migrations/create_users.dart | create-users-migration |
| 3 | Database setup + useOrm | 66-118 | High | setup.dart | quickstart-setup |

---

### 4. `docs/getting-started/configuration.md` (219 lines)
| # | Snippet Description | Lines | Priority | Target File | Region Name |
|---|---------------------|-------|----------|-------------|-------------|
| 1 | Basic orm.yaml | 11-23 | Low | - | (yaml, skip) |
| 2 | Connection options | 28-52 | Low | - | (yaml, skip) |
| 3 | SQLite driver | 58-62 | Low | - | (yaml, skip) |
| 4 | PostgreSQL driver | 66-75 | Low | - | (yaml, skip) |
| 5 | MySQL driver | 79-87 | Low | - | (yaml, skip) |
| 6 | Multiple connections | 93-119 | Low | - | (yaml, skip) |
| 7 | Env vars | 134-140 | Low | - | (yaml, skip) |
| 8 | Programmatic config | 155-181 | High | setup.dart | programmatic-config |

---

### 5. `docs/getting-started/code-generation.md` (212 lines)
| # | Snippet Description | Lines | Priority | Target File | Region Name |
|---|---------------------|-------|----------|-------------|-------------|
| 1 | build.yaml model gen | 51-57 | Low | - | (yaml, skip) |
| 2 | build.yaml registry | 61-67 | Low | - | (yaml, skip) |
| 3 | Registry usage | 82-90 | High | setup.dart | registry-usage |
| 4 | Constructor targeting | 98-115 | High | models/targeted_constructor.dart | constructor-targeting |
| 5 | Generated relation getters | 122-142 | Med | - | (generated, skip) |
| 6 | Driver-specific overrides | 162-176 | High | models/driver_override_model.dart | driver-field-overrides |

---

### 6. `docs/models/defining-models.md` (184 lines)
| # | Snippet Description | Lines | Priority | Target File | Region Name |
|---|---------------------|-------|----------|-------------|-------------|
| 1 | Basic model | 12-28 | High | models/user.dart | basic-model (exists) |
| 2 | Model annotation options | 34-44 | High | models/admin.dart | model-with-options (exists) |
| 3 | Primary key examples | 50-58 | High | models/field_examples.dart | primary-key-examples |
| 4 | Column options | 62-70 | High | models/field_examples.dart | column-options |
| 5 | Custom codecs | 74-91 | High | codecs/json_map_codec.dart | json-codec-definition |
| 6 | Tracked model usage | 100-108 | High | usage/tracked_model.dart | tracked-model-usage |
| 7 | Definition usage | 112-117 | High | usage/definition_usage.dart | definition-usage |
| 8 | Partial entity | 121-128 | High | usage/partial_entity.dart | partial-entity-usage |
| 9 | DTOs | 132-139 | High | usage/dto_usage.dart | dto-usage |

---

### 7. `docs/models/factories.md` (410 lines)
| # | Snippet Description | Lines | Priority | Target File | Region Name |
|---|---------------------|-------|----------|-------------|-------------|
| 1 | Quick start | 14-22 | High | factories/basic.dart | factory-quickstart |
| 2 | Factory-capable model | 28-40 | High | models/factory_user.dart | factory-capable-model |
| 3 | Inheritance support | 46-64 | High | models/factory_inheritance.dart | factory-inheritance |
| 4 | Field overrides | 93-103 | High | factories/overrides.dart | factory-field-overrides |
| 5 | Deterministic seeding | 111-120 | High | factories/seeding.dart | factory-seeding |
| 6 | Batch creation | 126-141 | High | factories/batch.dart | factory-batch |
| 7 | State transformations | 149-165 | High | factories/states.dart | factory-states |
| 8 | Sequences | 173-186 | High | factories/sequences.dart | factory-sequences |
| 9 | Callbacks | 194-214 | High | factories/callbacks.dart | factory-callbacks |
| 10 | Soft-deleted | 222-237 | High | factories/trashed.dart | factory-trashed |
| 11 | Custom generators | 241-256 | High | factories/custom_generators.dart | factory-custom-generators |
| 12 | Carbon fields | 262-276 | High | factories/carbon.dart | factory-carbon |
| 13 | Custom provider | 298-320 | High | factories/custom_provider.dart | factory-custom-provider |
| 14 | Testing patterns | 328-354 | High | factories/testing.dart | factory-testing-patterns |

---

### 8. `docs/models/relationships.md` (217 lines)
| # | Snippet Description | Lines | Priority | Target File | Region Name |
|---|---------------------|-------|----------|-------------|-------------|
| 1 | Has one | 14-32 | High | models/relations/has_one.dart | relation-has-one |
| 2 | Has many | 38-55 | High | models/relations/has_many.dart | relation-has-many |
| 3 | Belongs to | 61-76 | High | models/relations/belongs_to.dart | relation-belongs-to |
| 4 | Belongs to many | 82-103 | High | models/relations/belongs_to_many.dart | relation-belongs-to-many |
| 5 | Eager loading | 111-124 | High | relations/eager_loading.dart | eager-loading |
| 6 | Lazy loading | 130-144 | High | relations/lazy_loading.dart | lazy-loading |
| 7 | Relation manipulation | 148-160 | High | relations/manipulation.dart | relation-manipulation |
| 8 | Aggregate loading | 166-185 | High | relations/aggregates.dart | relation-aggregates |
| 9 | N+1 prevention | 191-198 | Med | - | (short, skip) |

---

### 9. `docs/models/soft-deletes.md` (176 lines)
| # | Snippet Description | Lines | Priority | Target File | Region Name |
|---|---------------------|-------|----------|-------------|-------------|
| 1 | Soft deletes mixin | 12-30 | High | models/soft_delete_model.dart | soft-deletes-model |
| 2 | Timezone-aware | 36-40 | Med | models/soft_delete_model.dart | soft-deletes-tz |
| 3 | Migration | 46-57 | High | migrations/soft_deletes.dart | soft-deletes-migration |
| 4 | Query scopes | 65-85 | High | queries/soft_deletes.dart | soft-delete-queries |
| 5 | Operations | 91-106 | High | queries/soft_deletes.dart | soft-delete-operations |
| 6 | Force delete | 112-116 | Med | queries/soft_deletes.dart | soft-delete-force |
| 7 | Status check | 120-126 | Med | queries/soft_deletes.dart | soft-delete-status |

---

### 10. `docs/models/timestamps.md` (123 lines)
| # | Snippet Description | Lines | Priority | Target File | Region Name |
|---|---------------------|-------|----------|-------------|-------------|
| 1 | Timestamps mixin | 12-28 | High | models/timestamp_model.dart | timestamps-model |
| 2 | Timezone-aware | 34-38 | Med | models/timestamp_model.dart | timestamps-tz |
| 3 | Migration | 50-62 | High | migrations/timestamps.dart | timestamps-migration |
| 4 | Manual control | 80-85 | Med | usage/timestamps.dart | timestamps-manual |
| 5 | Without timestamps | 91-106 | Med | models/log_model.dart | no-timestamps-model |

---

### 11. `docs/models/model-methods.md` (286 lines)
| # | Snippet Description | Lines | Priority | Target File | Region Name |
|---|---------------------|-------|----------|-------------|-------------|
| 1 | Replicate | 12-19 | High | usage/model_methods.dart | model-replicate |
| 2 | Replicate exclude | 25-31 | High | usage/model_methods.dart | model-replicate-exclude |
| 3 | Replicate use cases | 39-54 | High | usage/model_methods.dart | model-replicate-usecases |
| 4 | isSameAs | 60-69 | High | usage/model_methods.dart | model-comparison |
| 5 | isDifferentFrom | 75-82 | Med | usage/model_methods.dart | model-different |
| 6 | Deduplication | 88-96 | Med | usage/model_methods.dart | model-dedupe |
| 7 | fresh() | 104-115 | High | usage/model_methods.dart | model-fresh |
| 8 | refresh() | 121-130 | High | usage/model_methods.dart | model-refresh |
| 9 | With relations | 144-147 | Med | usage/model_methods.dart | model-refresh-relations |
| 10 | Optimistic locking | 155-170 | High | usage/model_methods.dart | model-optimistic-lock |

---

### 12. `docs/queries/query-builder.md` (294 lines)
| # | Snippet Description | Lines | Priority | Target File | Region Name |
|---|---------------------|-------|----------|-------------|-------------|
| 1 | Getting started | 12-13 | Med | queries.dart | query-getting-started |
| 2 | Get all | 19-20 | Med | queries.dart | query-get-all |
| 3 | Select columns | 26-29 | Med | queries.dart | query-select |
| 4 | First record | 35-40 | Med | queries.dart | query-first |
| 5 | Find by PK | 46-48 | Med | queries.dart | query-find |
| 6 | Basic where | 56-67 | High | queries.dart | where-basic (exists) |
| 7 | Comparison operators | 73-77 | High | queries.dart | where-comparison |
| 8 | In/NotIn | 83-90 | High | queries.dart | where-in |
| 9 | Null checks | 96-103 | High | queries.dart | where-null |
| 10 | Between | 109-112 | Med | queries.dart | where-between |
| 11 | Like | 118-121 | Med | queries.dart | where-like |
| 12 | Or Where | 127-131 | Med | queries.dart | where-or |
| 13 | Grouped | 137-144 | High | queries.dart | where-grouped |
| 14 | Ordering | 150-163 | High | queries.dart | ordering |
| 15 | Limiting/Pagination | 169-186 | High | queries.dart | limiting-pagination |
| 16 | Aggregates | 192-205 | High | queries.dart | aggregates (exists) |
| 17 | Distinct | 211-214 | Med | queries.dart | distinct |
| 18 | Eager loading | 220-232 | High | queries.dart | relations (exists) |
| 19 | Raw expressions | 238-244 | Med | queries.dart | raw-expressions |
| 20 | Partial projections | 250-258 | Med | queries.dart | partial-projections |
| 21 | Soft delete scopes | 264-276 | Med | queries.dart | soft-delete-scopes |
| 22 | Query caching | 282-294 | Med | queries.dart | query-caching |

---

### 13. `docs/queries/repository.md` (248 lines)
| # | Snippet Description | Lines | Priority | Target File | Region Name |
|---|---------------------|-------|----------|-------------|-------------|
| 1 | Get repository | 12-13 | Med | repository.dart | repo-get |
| 2 | Insert single | 19-34 | High | repository.dart | repo-insert |
| 3 | Insert many | 40-44 | High | repository.dart | repo-insert-many |
| 4 | Upsert | 50-54 | Med | repository.dart | repo-upsert |
| 5 | Find operations | 60-65 | High | repository.dart | repo-find |
| 6 | First/Count/Exists | 71-76 | Med | repository.dart | repo-first-count |
| 7 | Update single | 82-97 | High | repository.dart | repo-update |
| 8 | Update many | 103-107 | Med | repository.dart | repo-update-many |
| 9 | Where types | 113-129 | High | repository.dart | repo-where-types |
| 10 | Delete operations | 147-160 | High | repository.dart | repo-delete |
| 11 | Delete many | 166-172 | Med | repository.dart | repo-delete-many |
| 12 | Soft delete ops | 180-190 | Med | repository.dart | repo-soft-delete |
| 13 | Relations | 198-210 | Med | repository.dart | repo-relations |
| 14 | Error handling | 216-227 | Med | repository.dart | repo-errors |

---

### 14. `docs/queries/data-source.md` (303 lines)
| # | Snippet Description | Lines | Priority | Target File | Region Name |
|---|---------------------|-------|----------|-------------|-------------|
| 1 | Overview | 12-22 | High | datasource.dart | datasource-overview |
| 2 | Options example | 36-52 | High | datasource.dart | datasource-options |
| 3 | Initialization | 58-62 | Med | datasource.dart | datasource-init |
| 4 | Static helpers | 68-80 | High | datasource.dart | datasource-static-helpers |
| 5 | Querying | 86-101 | High | datasource.dart | datasource-querying |
| 6 | Repository | 107-121 | High | datasource.dart | datasource-repository |
| 7 | Transactions | 127-147 | High | datasource.dart | datasource-transactions |
| 8 | Ad-hoc table | 153-162 | Med | datasource.dart | datasource-adhoc |
| 9 | Query logging | 168-185 | Med | datasource.dart | datasource-logging |

---

### 15. `docs/queries/relations.md` (240 lines)
| # | Snippet Description | Lines | Priority | Target File | Region Name |
|---|---------------------|-------|----------|-------------|-------------|
| 1 | Basic eager | 16-24 | High | relations/loading.dart | eager-basic |
| 2 | Multiple relations | 30-33 | High | relations/loading.dart | eager-multiple |
| 3 | Nested relations | 39-45 | High | relations/loading.dart | eager-nested |
| 4 | Load after fetch | 55-62 | High | relations/loading.dart | lazy-load |
| 5 | Load missing | 68-70 | Med | relations/loading.dart | lazy-load-missing |
| 6 | Check loaded | 76-81 | Med | relations/loading.dart | check-loaded |
| 7 | Get/Set relation | 89-99 | High | relations/access.dart | relation-access |
| 8 | Count | 107-110 | High | relations/aggregates.dart | relation-count |
| 9 | Sum | 116-118 | Med | relations/aggregates.dart | relation-sum |
| 10 | Exists | 128-132 | Med | relations/aggregates.dart | relation-exists |
| 11 | Attach/Detach | 140-150 | High | relations/many_to_many.dart | relation-attach |
| 12 | Sync/Toggle | 156-162 | Med | relations/many_to_many.dart | relation-sync |
| 13 | Associate | 168-174 | High | relations/belongs_to.dart | relation-associate |

---

### 16. `docs/queries/caching.md` (328 lines)
| # | Snippet Description | Lines | Priority | Target File | Region Name |
|---|---------------------|-------|----------|-------------|-------------|
| 1 | Remember | 17-31 | High | caching.dart | cache-remember |
| 2 | Remember forever | 37-45 | Med | caching.dart | cache-forever |
| 3 | Don't remember | 55-66 | Med | caching.dart | cache-dont-remember |
| 4 | Chaining | 72-86 | Med | caching.dart | cache-chaining |
| 5 | Flush cache | 94-100 | Med | caching.dart | cache-flush |
| 6 | Vacuum | 106-112 | Med | caching.dart | cache-vacuum |
| 7 | Statistics | 118-127 | Med | caching.dart | cache-stats |

---

### 17. `docs/migrations/overview.md` (134 lines)
| # | Snippet Description | Lines | Priority | Target File | Region Name |
|---|---------------------|-------|----------|-------------|-------------|
| 1 | Basic structure | 24-43 | High | migrations/basic.dart | migration-basic |
| 2 | Creating tables | 49-74 | High | migrations/create_table.dart | migration-create-table |
| 3 | Modifying tables | 80-96 | High | migrations/alter_table.dart | migration-alter-table |

---

### 18. `docs/migrations/schema-builder.md` (231 lines)
| # | Snippet Description | Lines | Priority | Target File | Region Name |
|---|---------------------|-------|----------|-------------|-------------|
| 1 | Creating tables | 12-20 | High | schema/creating.dart | schema-create |
| 2 | Primary keys | 26-32 | High | schema/columns.dart | schema-primary-keys |
| 3 | Strings | 38-45 | High | schema/columns.dart | schema-strings |
| 4 | Numbers | 51-58 | High | schema/columns.dart | schema-numbers |
| 5 | Dates | 64-72 | High | schema/columns.dart | schema-dates |
| 6 | Boolean/Binary | 78-81 | Med | schema/columns.dart | schema-bool-binary |
| 7 | JSON | 87-89 | Med | schema/columns.dart | schema-json |
| 8 | Column modifiers | 95-111 | High | schema/modifiers.dart | schema-modifiers |
| 9 | Timestamps/SoftDeletes | 117-127 | High | schema/timestamps.dart | schema-timestamps |
| 10 | Indexes | 133-149 | High | schema/indexes.dart | schema-indexes |
| 11 | Foreign keys | 155-176 | High | schema/foreign_keys.dart | schema-foreign-keys |
| 12 | Altering tables | 186-202 | High | schema/altering.dart | schema-alter |
| 13 | Dropping/Renaming | 208-214 | Med | schema/dropping.dart | schema-drop-rename |
| 14 | Driver overrides | 220-232 | Med | schema/driver_overrides.dart | schema-driver-overrides |

---

### 19. `docs/migrations/running-migrations.md` (144 lines)
| # | Snippet Description | Lines | Priority | Target File | Region Name |
|---|---------------------|-------|----------|-------------|-------------|
| 1 | Programmatic usage | 12-44 | High | migrations/runner.dart | migration-runner |
| 2 | Ledger API | 50-66 | Med | migrations/ledger.dart | migration-ledger |
| 3 | Registry file | 72-92 | Med | - | (generated, skip) |

---

### 20. `docs/migrations/squashing.md` (93 lines)
| # | Snippet Description | Lines | Priority | Target File | Region Name |
|---|---------------------|-------|----------|-------------|-------------|
| (No Dart snippets - all shell/yaml) |

---

### 21. `docs/cli/commands.md` (321 lines)
| # | Snippet Description | Lines | Priority | Target File | Region Name |
|---|---------------------|-------|----------|-------------|-------------|
| (Mostly shell commands and yaml - skip) |

---

### 22. `docs/guides/testing.md` (362 lines)
| # | Snippet Description | Lines | Priority | Target File | Region Name |
|---|---------------------|-------|----------|-------------|-------------|
| 1 | Basic setup | 12-36 | High | testing/basic_setup.dart | testing-basic-setup |
| 2 | In-memory executor | 42-50 | High | testing/in_memory.dart | testing-in-memory |
| 3 | Seeder | 56-72 | High | testing/seeders.dart | testing-seeder |
| 4 | Real databases | 78-98 | High | testing/real_db.dart | testing-real-db |
| 5 | Migration harness | 104-126 | High | testing/migration_harness.dart | testing-migration-harness |
| 6 | Static helpers | 132-148 | Med | testing/static_helpers.dart | testing-static-helpers |
| 7 | Testing relations | 154-176 | Med | testing/relations.dart | testing-relations |
| 8 | Parallel testing | 182-196 | Med | testing/parallel.dart | testing-parallel |

---

### 23. `docs/guides/multi-database.md` (267 lines)
| # | Snippet Description | Lines | Priority | Target File | Region Name |
|---|---------------------|-------|----------|-------------|-------------|
| 1 | Multiple DataSources | 14-42 | High | multi_db/setup.dart | multi-db-setup |
| 2 | Named connections | 48-60 | High | multi_db/named.dart | multi-db-named |
| 3 | Transaction caveat | 68-84 | Med | multi_db/transactions.dart | multi-db-transaction-caveat |
| 4 | Coordinating DBs | 90-114 | Med | multi_db/coordinating.dart | multi-db-coordinating |
| 5 | Multi-tenant | 120-144 | High | multi_db/tenant.dart | multi-db-tenant |
| 6 | Tenant scope | 150-158 | Med | multi_db/tenant_scope.dart | multi-db-tenant-scope |
| 7 | Connection factory | 164-182 | Med | multi_db/factory.dart | multi-db-factory |
| 8 | ConnectionManager | 188-202 | Med | multi_db/manager.dart | multi-db-manager |

---

### 24. `docs/guides/best-practices.md` (383 lines)
| # | Snippet Description | Lines | Priority | Target File | Region Name |
|---|---------------------|-------|----------|-------------|-------------|
| 1 | N+1 bad | 18-24 | High | best_practices/n_plus_one.dart | n-plus-one-bad |
| 2 | N+1 good | 30-38 | High | best_practices/n_plus_one.dart | n-plus-one-good |
| 3 | Aggregate bad | 44-47 | Med | best_practices/aggregates.dart | aggregate-bad |
| 4 | Aggregate good | 53-56 | Med | best_practices/aggregates.dart | aggregate-good |
| 5 | Select columns | 62-65 | Med | best_practices/select.dart | select-bad |
| 6 | Pluck | 71-73 | Med | best_practices/select.dart | select-good |
| 7 | Pagination | 79-85 | Med | best_practices/pagination.dart | pagination |
| 8 | Indexes | 91-97 | Med | best_practices/indexes.dart | indexes |
| 9 | Eager loading | 107-115 | Med | best_practices/loading.dart | when-eager |
| 10 | Lazy loading | 121-128 | Med | best_practices/loading.dart | when-lazy |
| 11 | loadMissing | 134-139 | Med | best_practices/loading.dart | load-missing |
| 12 | Prevent lazy | 145-152 | Med | best_practices/loading.dart | prevent-lazy |
| 13 | Extend Model | 158-172 | High | best_practices/model_design.dart | extend-model |
| 14 | Immutable | 178-190 | Med | best_practices/model_design.dart | immutable-model |
| 15 | Soft deletes | 196-207 | Med | best_practices/soft_deletes.dart | soft-deletes-wise |

---

### 25. `docs/guides/observability.md` (296 lines)
| # | Snippet Description | Lines | Priority | Target File | Region Name |
|---|---------------------|-------|----------|-------------|-------------|
| 1 | Query logging | 12-26 | High | observability/logging.dart | query-logging |
| 2 | Log events | 70-79 | High | observability/events.dart | query-events |
| 3 | Structured logger | 106-115 | High | observability/structured.dart | structured-logger |
| 4 | SQL preview | 141-150 | Med | observability/preview.dart | sql-preview |
| 5 | Before hooks | 160-176 | Med | observability/hooks.dart | before-hooks |

---

### 26. `docs/guides/examples.md` (330 lines)
| # | Snippet Description | Lines | Priority | Target File | Region Name |
|---|---------------------|-------|----------|-------------|-------------|
| 1 | Model definition | 17-33 | High | examples/sqlite_workflow.dart | sqlite-model |
| 2 | Query example | 49-68 | High | examples/sqlite_workflow.dart | sqlite-query |
| 3 | Static helpers | 74-84 | Med | examples/static_helpers.dart | static-helpers-pattern |
| 4 | PostgreSQL | 90-110 | High | examples/postgres.dart | postgres-example |
| 5 | Observability | 116-125 | Med | examples/observability.dart | observability-example |
| 6 | Eager loading | 131-144 | High | examples/relations.dart | eager-loading-example |
| 7 | Eager aggregates | 150-164 | Med | examples/relations.dart | eager-aggregates-example |

---

### 27. `docs/reference/driver-capabilities.md` (302 lines)
| # | Snippet Description | Lines | Priority | Target File | Region Name |
|---|---------------------|-------|----------|-------------|-------------|
| 1 | Capabilities enum | 34-52 | Low | - | (reference, skip) |
| 2 | Check capabilities | 58-74 | Med | capabilities.dart | check-capabilities |

---

## Summary Statistics

| Category | Total Snippets | High Priority | Medium Priority | Low/Skip |
|----------|----------------|---------------|-----------------|----------|
| Getting Started | ~25 | 10 | 5 | 10 |
| Models | ~50 | 35 | 10 | 5 |
| Queries | ~60 | 40 | 15 | 5 |
| Migrations | ~20 | 12 | 5 | 3 |
| CLI | ~5 | 0 | 0 | 5 |
| Guides | ~45 | 25 | 15 | 5 |
| Reference | ~5 | 1 | 2 | 2 |
| **TOTAL** | **~210** | **~123** | **~52** | **~35** |

## Recommended Execution Order

### Phase 1: Core Models & Queries (High Impact)
1. `models/user.dart` - Expand with more regions
2. `models/admin.dart` - Already has region
3. `queries.dart` - Already has regions, expand
4. `repository.dart` - New file
5. `datasource.dart` - New file

### Phase 2: Factories & Relations
1. `factories/*.dart` - Multiple files for factory examples
2. `relations/*.dart` - Multiple files for relation examples
3. `models/relations/*.dart` - Relation model definitions

### Phase 3: Migrations & Schema
1. `migrations/*.dart` - Migration examples
2. `schema/*.dart` - Schema builder examples

### Phase 4: Advanced Guides
1. `testing/*.dart` - Testing examples
2. `multi_db/*.dart` - Multi-database examples
3. `best_practices/*.dart` - Best practice examples
4. `observability/*.dart` - Observability examples

### Phase 5: Miscellaneous
1. `codecs/*.dart` - Custom codec examples
2. `usage/*.dart` - Model usage examples
3. `examples/*.dart` - Complete workflow examples

