import 'dart:io' as io;

import 'package:artisan_args/src/tui/uv/terminal.dart';
import 'package:image/image.dart' as img;
import 'package:test/test.dart';

void main() {
  group('Terminal.bestImageDrawable', () {
    test('prefers kitty, then iTerm2, then sixel', () {
      final term = Terminal(output: io.stdout, env: const []);
      final image = img.Image(width: 1, height: 1);

      term.capabilities
        ..hasKittyGraphics = true
        ..hasITerm2 = true
        ..hasSixel = true;
      expect(Terminal.bestImageDrawable(image, capabilities: term.capabilities), isA<KittyImageDrawable>());

      term.capabilities
        ..hasKittyGraphics = false
        ..hasITerm2 = true
        ..hasSixel = true;
      expect(Terminal.bestImageDrawable(image, capabilities: term.capabilities), isA<ITerm2ImageDrawable>());

      term.capabilities
        ..hasKittyGraphics = false
        ..hasITerm2 = false
        ..hasSixel = true;
      expect(Terminal.bestImageDrawable(image, capabilities: term.capabilities), isA<SixelImageDrawable>());
    });

    test('falls back to EmptyDrawable when no protocol is supported', () {
      final term = Terminal(output: io.stdout, env: const []);
      final image = img.Image(width: 1, height: 1);

      term.capabilities
        ..hasKittyGraphics = false
        ..hasITerm2 = false
        ..hasSixel = false;

      expect(
        Terminal.bestImageDrawable(image,
            capabilities: term.capabilities, columns: 10, rows: 4),
        isA<EmptyDrawable>(),
      );
    });
  });
}

