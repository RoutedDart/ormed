import 'package:artisan_args/src/tui/msg.dart';
import 'package:artisan_args/src/tui/theme.dart';
import 'package:artisan_args/src/tui/uv/event.dart' as uvev;
import 'package:test/test.dart';

void main() {
  test('TerminalThemeState updates from BackgroundColorMsg', () {
    var s = const TerminalThemeState();
    s = s.update(
      const BackgroundColorMsg(hex: '#ffffff'),
    );
    expect(s.backgroundHex, '#ffffff');
    expect(s.hasDarkBackground, false);

    s = s.update(
      const BackgroundColorMsg(hex: '#000000'),
    );
    expect(s.backgroundHex, '#000000');
    expect(s.hasDarkBackground, true);
  });

  test('TerminalThemeState keeps dark flag on unparseable hex', () {
    var s = const TerminalThemeState(backgroundHex: '#000000', hasDarkBackground: true);
    s = s.update(
      const BackgroundColorMsg(hex: 'rgb:aa/bb/cc'),
    );
    expect(s.backgroundHex, 'rgb:aa/bb/cc');
    expect(s.hasDarkBackground, true);
  });

  test('TerminalThemeState updates from UV color scheme events', () {
    var s = const TerminalThemeState(backgroundHex: '#101010', hasDarkBackground: null);
    s = s.update(UvEventMsg(const uvev.LightColorSchemeEvent()));
    expect(s.backgroundHex, '#101010');
    expect(s.hasDarkBackground, false);

    s = s.update(UvEventMsg(const uvev.DarkColorSchemeEvent()));
    expect(s.hasDarkBackground, true);
  });
}

