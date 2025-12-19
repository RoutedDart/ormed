import 'dart:io';
import 'package:artisan_args/src/tui/uv/terminal.dart';

void main() async {
  final t = Terminal();
  if (!stdin.hasTerminal) {
    print('Not a TTY');
    return;
  }

  await t.start();
  t.enterAltScreen();
  t.hideCursor();

  try {
    void render() {
      final view = '''
Image Example
=============

This example demonstrates image rendering in the terminal.
In the Go version, this supports:
- Kitty Graphics Protocol
- Sixel
- iTerm2 Inline Images
- Half-block character fallback

Currently, the Dart port of Ultraviolet supports decoding these
protocols in the EventDecoder, but high-level rendering utilities
for encoding images into these protocols are still under development.

Press 'q' to exit.
''';
      final ss = StyledString(view);
      t.clear();
      ss.draw(t, t.bounds());
      t.draw();
    }

    render();

    await for (final event in t.events) {
      if (event is KeyPressEvent) {
        final key = event.keystroke();
        if (key == 'q' || key == 'esc' || key == 'ctrl+c') {
          break;
        }
      }
      if (event is WindowSizeEvent) {
        render();
      }
    }
  } finally {
    t.exitAltScreen();
    t.showCursor();
    t.stop();
  }
}
