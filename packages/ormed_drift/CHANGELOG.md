# Changelog

## 0.1.0

- **Added**: `DriftDriverAdapter` now opens its wrapped executor automatically
  through `OrmDatabase.connect()` and can publish invalidation after an
  external synchronization callback.
- Added the optional `DriftDriverAdapter` integration for shared Ormed and
  Drift executor access.
- Added reactive Ormed watchers that observe direct Drift writes and commit
  boundaries.
