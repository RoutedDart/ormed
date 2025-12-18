import 'package:artisan_args/artisan_args.dart';
import 'package:test/test.dart';

void main() {
  group('ANSI stripping + width', () {
    test('Layout.stripAnsi removes OSC 8 hyperlinks (ST terminated)', () {
      const s =
          '\x1b]8;;https://example.com\x1b\\Hello\x1b]8;;\x1b\\';
      expect(Layout.stripAnsi(s), equals('Hello'));
    });

    test('Layout.visibleLength ignores OSC 8 hyperlinks', () {
      const s =
          '\x1b]8;;https://example.com\x1b\\Hello\x1b]8;;\x1b\\';
      expect(Layout.visibleLength(s), equals(5));
    });

    test('Layout.visibleLength ignores non-SGR CSI sequences', () {
      const s = '\x1b[2CHi\x1b[1D!';
      expect(Layout.visibleLength(s), equals(3));
      expect(Layout.stripAnsi(s), equals('Hi!'));
    });

    test('Style.stripAnsi removes OSC 8 hyperlinks (BEL terminated)', () {
      const s = '\x1b]8;;https://example.com\x07Hello\x1b]8;;\x07';
      expect(Style.stripAnsi(s), equals('Hello'));
    });

    test('Style.visibleLength ignores OSC 8 hyperlinks', () {
      const s = '\x1b]8;;https://example.com\x07Hello\x1b]8;;\x07';
      expect(Style.visibleLength(s), equals(5));
    });
  });
}

