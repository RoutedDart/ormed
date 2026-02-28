import 'dart:io';
import 'dart:isolate';

import 'package:ormed_cli/src/commands/base/shared.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('uses a single driver-neutral fallback config notice', () {
    expect(
      configFallbackNoticeForTest,
      equals('No ormed.yaml found; using convention defaults.'),
    );
  });

  test(
    'command sources no longer contain sqlite-specific fallback text',
    () async {
      final packageConfigUri = await Isolate.resolvePackageUri(
        Uri.parse('package:ormed_cli/src/config.dart'),
      );
      expect(packageConfigUri, isNotNull);
      final packageRoot = p.normalize(
        p.join(File.fromUri(packageConfigUri!).parent.path, '..', '..'),
      );
      final commandsDir = Directory(
        p.join(packageRoot, 'lib', 'src', 'commands'),
      );
      final stalePhrase = 'No ormed.yaml found; using sqlite conventions.';
      for (final entity in commandsDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final text = entity.readAsStringSync();
        expect(
          text.contains(stalePhrase),
          isFalse,
          reason: 'Found stale fallback phrase in ${entity.path}',
        );
      }
    },
  );
}
