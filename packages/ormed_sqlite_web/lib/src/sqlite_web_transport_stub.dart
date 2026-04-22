import 'sqlite_web_transport.dart';

Future<SqliteWebTransport> sqliteWebTransportFromOptions(
  Map<String, Object?> options,
) async {
  throw UnsupportedError(
    'ormed_sqlite_web requires a browser runtime. '
    'Provide a custom SqliteWebTransport when testing on the VM.',
  );
}
