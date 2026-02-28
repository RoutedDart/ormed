import 'dart:io';

import 'package:ormed/ormed.dart';
import 'package:ormed_fullstack_example/src/server/server.dart';

Future<void> main(List<String> args) async {
  final host = InternetAddress.anyIPv4.address;
  final port = OrmedEnvironment().intValue('PORT', fallback: 8080);
  await runServer(host: host, port: port);
}
