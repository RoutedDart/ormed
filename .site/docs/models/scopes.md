---
sidebar_position: 5
---

# Model Scopes

Scopes let you package reusable query constraints on a model. They are **static methods** annotated with `@OrmScope`, and the generator creates typed helpers on `Query<Model>` so you can call them fluently.

## Defining scopes

- First parameter: required positional `Query<T>` for the model.
- Must be `static`.
- Optional parameters are supported (positional or named).  
- Set `global: true` to have the scope applied to every query for the model; global scopes must not declare extra required parameters beyond the initial `Query<T>`.

```dart file=../../examples/lib/models/model_scopes.dart#model-scopes-definition
```

## Using scopes

The generator adds:
- Extensions on `Query<Model>` (and the tracked `$Model`) for every `@OrmScope`.
- `register<Model>Scopes(ScopeRegistry)` that registers all scopes (global and local). `registerModelScopes()` calls every generated registrar; `bootstrapOrm(registerScopes: true)` wires them automatically.

```dart file=../../examples/lib/models/model_scopes.dart#model-scopes-usage
```

Notes:
- Global scopes run once per query and can be disabled with `withoutGlobalScope('identifier')` or `withoutGlobalScopes()`.
- Local scopes can be chained with other builder methods and support both positional and named arguments.
- Scope identifiers default to the method name; override with `@OrmScope(identifier: 'custom')` if you need a different name.

## Inline / ad-hoc scopes

You can also register scopes at runtime without touching the model by using the `ScopeRegistry` on your `QueryContext`. This is handy for environment-specific filters or tests.

```dart file=../../examples/lib/models/model_scopes.dart#model-scopes-inline
```

Ad-hoc scopes share the same APIs (`scope('name')`, `withoutGlobalScope('name')`) as generated scopes; mix and match as needed.
