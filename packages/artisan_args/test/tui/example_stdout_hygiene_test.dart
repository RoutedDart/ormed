import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('tui examples avoid direct stdout/stderr writes', () {
    final root = Directory('packages/artisan_args/example/tui');
    expect(root.existsSync(), isTrue, reason: 'Missing ${root.path}');

    final allowlisted = <String>{
      // Prints help text; does not run the TUI.
      'packages/artisan_args/example/tui/examples/uv-input/main.dart',
      // Demonstrates daemon + help paths outside TUI.
      'packages/artisan_args/example/tui/examples/tui-daemon-combo/main.dart',
      // Demonstrates non-TUI pipe behavior.
      'packages/artisan_args/example/tui/examples/pipe/main.dart',
    };

    final bannedPatterns = <RegExp>[
      RegExp(r'\bprint\s*\('),
      RegExp(r'\bio\.(stdout|stderr)\s*\.'),
      // Catch unprefixed `stdout.*` / `stderr.*` (dart:io globals) but avoid
      // false-positives like `result.stderr`.
      RegExp(r'(^|[^\w.])stdout\s*\.'),
      RegExp(r'(^|[^\w.])stderr\s*\.'),
    ];

    final violations = <String>[];

    for (final entity in root.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;

      final normalized = entity.path.replaceAll('\\', '/');
      if (allowlisted.contains(normalized)) continue;

      final contents = entity.readAsStringSync();
      for (final pattern in bannedPatterns) {
        if (pattern.hasMatch(contents)) {
          violations.add('$normalized matches ${pattern.pattern}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Direct stdout/stderr writes desync UV renderer; use Cmd.println/WriteRawMsg instead.\n'
          '${violations.join('\n')}',
    );
  });
}
