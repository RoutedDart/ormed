import 'dart:io';

Future<void> main(List<String> args) async {
  final outputPath = args.isEmpty ? 'example/web/sqlite3.wasm' : args.first;
  final output = File(outputPath);
  await output.parent.create(recursive: true);

  final uri = Uri.parse(
    'https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.1.4/sqlite3.wasm',
  );

  final client = HttpClient();
  final request = await client.getUrl(uri);
  request.followRedirects = true;
  final response = await request.close();

  if (response.statusCode != HttpStatus.ok) {
    stderr.writeln(
      'Failed to download sqlite3.wasm: HTTP ${response.statusCode}',
    );
    exitCode = response.statusCode;
    client.close();
    return;
  }

  final sink = output.openWrite();
  await response.pipe(sink);
  await sink.close();
  client.close();

  stdout.writeln('Wrote ${output.path}');
}
