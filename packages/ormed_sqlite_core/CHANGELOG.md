## 0.2.1

- **Fixed**: SQLite-like codegen-free inserts compile their write columns from
  the mutation plan without changing the ad-hoc read projection.

## 0.2.0

- **Breaking**: Requires Dart 3.12 or newer.
- **Updated**: Widened the Ormed support range to `>=0.2.0 <1.0.0`.
- **Updated**: Synced the shared SQLite core with the Analyzer 14 workspace release.

## 0.1.0

- Initial release.
- Extracted shared SQLite grammar, schema dialect, type mapper, codecs, and migration helpers from `ormed_sqlite`.
