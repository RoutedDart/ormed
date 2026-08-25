import 'package:ormed_d1/ormed_d1.dart';

/// The browser/Worker entrypoint uses an application-owned endpoint.
///
/// The endpoint should authenticate the request and execute the SQL against
/// its native D1 binding. A Cloudflare API token must not be included in a
/// browser bundle.
Future<void> main() async {
  final database = await D1Database.fromEndpoint(
    endpoint: Uri.parse('https://example.com/api/database/query'),
    batchEndpoint: Uri.parse('https://example.com/api/database/batch'),
  );

  final rows = await database.queryRaw('SELECT 1 AS ok');
  print(rows.first['ok']);
  await database.close();
}
