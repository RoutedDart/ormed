---
sidebar_position: 4
---

# Model Events

Ormed emits rich lifecycle events for every model: `saving`, `saved`, `creating`, `created`, `updating`, `updated`, `deleting`, `deleted`, `trashed`, `forceDeleted`, `restoring`, `restored`, `retrieved`, and `replicating`.

- Cancellable: `saving`, `creating`, `updating`, `deleting`, `restoring`, `replicating`
- Soft delete aware: `trashed` (soft delete), `forceDeleted` (hard delete)
- Global listeners: subscribe on the shared `EventBus.instance`

## Handler Requirements

Handlers are **static** methods that take the event type you annotate with `@OrmEvent`. Instance methods are not supported because models are immutable and generated tracked instances are created by the ORM; static handlers keep the signature predictable for codegen.

Rules:
- Signature: `static void onXyz(ModelXyzEvent event)`
- Public/`static` only; no return value
- Use `event.cancel()` on cancellable events to abort the operation

```dart file=../../examples/lib/events/model_events.dart#model-event-annotation
```

If you need per-request state, capture it via closures on the `EventBus` instead of instance fields.

## Listen Globally

Attach listeners once when your app boots:

```dart file=../../examples/lib/events/model_events.dart#model-event-listeners
```

Use the global bus (default for `QueryContext`/`DataSource`) so every query/repository call emits into the same stream.

## Guard Operations (cancel)

Cancel dangerous deletes or updates in a listener by calling `event.cancel()`:

```dart file=../../examples/lib/events/model_events.dart#model-delete-guard
```

## Annotation-Based Handlers

You can register handlers directly on the model with `@OrmEvent`:

```dart file=../../examples/lib/events/model_events.dart#model-event-annotation
```

The generator wires these static handlers into `registerModelEventHandlers`, which is invoked by `bootstrapOrm`.

## Full Lifecycle Walkthrough

```dart file=../../examples/lib/events/model_events.dart#model-events-usage
```

This example logs every phase for a `User` insert, update, delete, and retrieval.

## Event Ordering

For a create + update + soft delete + restore flow, events fire in this order:

1) `saving` → `creating` → `created` → `saved`  
2) `saving` → `updating` → `updated` → `saved`  
3) `deleting` → `deleted` → `trashed` (soft delete)  
4) `restoring` → `restored`

Hard deletes emit `deleting` → `deleted` → `forceDeleted`.

## Replication

`ModelReplicatingEvent` fires before `Repository.replicate` returns the copy. Cancel it to block replication or attach metadata to the new instance.

## Compatibility Notes

Event names follow familiar patterns from popular ORMs, so existing observer logic typically translates directly. Ormed adds `forceDeleted`/`trashed` flags to distinguish delete modes on drivers that lack “returning” support.
