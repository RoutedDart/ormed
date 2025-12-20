import 'package:artisanal/src/uv/uv.dart';
import 'package:test/test.dart';

// Behavior parity reference:
// - `third_party/lipgloss/wrap.go` (`WrapWriter`: reset/reapply style/link around newlines)

void main() {
  group('wrapAnsiPreserving', () {
    test('wraps and preserves SGR pen state across inserted newlines', () {
      const red = '\x1b[31m';
      const reset = UvAnsi.resetStyle;

      final input = '${red}AB CD$reset';
      final expected = '${red}AB$reset\n${red}CD$reset';

      expect(wrapAnsiPreserving(input, 2), expected);
    });

    test(
      'wraps and preserves OSC 8 hyperlink state across inserted newlines',
      () {
        final open = UvAnsi.setHyperlink('https://example.com', '');
        final close = UvAnsi.resetHyperlink();

        final input = '${open}AB CD$close';
        final expected = '${open}AB$close\n${open}CD$close';

        expect(wrapAnsiPreserving(input, 2), expected);
      },
    );

    test(
      'preserves both OSC 8 and SGR with correct reset/reapply ordering',
      () {
        final open = UvAnsi.setHyperlink('https://example.com', '');
        final close = UvAnsi.resetHyperlink();
        const red = '\x1b[31m';
        const reset = UvAnsi.resetStyle;

        final input = '$open${red}AB CD$reset$close';
        final expected = '$open${red}AB$reset$close\n$open${red}CD$reset$close';

        expect(wrapAnsiPreserving(input, 2), expected);
      },
    );
  });
}
