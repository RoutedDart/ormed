import 'package:artisan_args/artisan_args.dart';
import 'package:test/test.dart';

void main() {
  group('Style hyperlink + underline variants', () {
    test('hyperlink wraps rendered output with OSC 8 open/close', () {
      final style = Style().hyperlink('https://example.com');
      final rendered = style.render('Hello');

      expect(rendered, contains('\x1b]8;;https://example.com\x1b\\'));
      expect(rendered, contains('\x1b]8;;\x1b\\'));
      expect(Style.stripAnsi(rendered), equals('Hello'));
    });

    test('hyperlink is applied per rendered line', () {
      final style = Style().width(4).hyperlink('https://example.com');
      final rendered = style.render('AAA BBB');
      final lines = rendered.split('\n');

      expect(lines.length, greaterThanOrEqualTo(2));
      for (final line in lines) {
        expect(line, contains('\x1b]8;;https://example.com\x1b\\'));
        expect(line, contains('\x1b]8;;\x1b\\'));
      }
    });

    test('underlineStyle emits expected SGR sequences', () {
      final style = Style().underlineStyle(UnderlineStyle.dotted);
      final rendered = style.render('Hi');

      expect(rendered, contains('\x1b[4:4m'));
      expect(rendered, contains('\x1b[24m'));
      expect(Style.stripAnsi(rendered), equals('Hi'));
    });

    test('underline() defaults to a single underline', () {
      final style = Style().underline();
      final rendered = style.render('Hi');

      expect(rendered, contains('\x1b[4m'));
      expect(rendered, contains('\x1b[24m'));
    });

    test('underlineColor emits SGR 58/59 sequences', () {
      final style = Style().underline().underlineColor(const BasicColor('1')); // Red
      final rendered = style.render('Hi');

      // SGR 58:2:1m (TrueColor) or 58:5:1m (256) or 58:1m (Basic)
      // Our implementation uses sgrColor which handles the profile.
      // For BasicColor('1'), it should be 58:5:1m or similar depending on profile.
      expect(rendered, contains('\x1b[58'));
      expect(rendered, contains('\x1b[59m'));
    });
  });

  group('Style.styleRunes', () {
    test('styles rune indices with matched/unmatched styles', () {
      final matched = Style().bold();
      final unmatched = Style();

      final rendered = Style.styleRunes('abcd', [1, 2], matched, unmatched);
      expect(Style.stripAnsi(rendered), equals('abcd'));
      expect(rendered, contains('\x1b[1m'));
      expect(rendered, contains('bc'));
    });
  });
}

