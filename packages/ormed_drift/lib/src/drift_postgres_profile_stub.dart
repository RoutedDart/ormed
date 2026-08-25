import 'package:ormed_sqlite_core/ormed_sqlite_core.dart';

/// PostgreSQL support is only available on native/server Dart platforms.
SqlRemoteAdapterProfile createDriftPostgresProfile() {
  throw UnsupportedError(
    'Drift PostgreSQL requires a native/server Dart platform.',
  );
}
