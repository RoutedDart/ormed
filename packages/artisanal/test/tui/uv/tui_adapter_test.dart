import 'package:artisanal/src/terminal/keys.dart' as term;
import 'package:artisanal/src/tui/msg.dart';
import 'package:artisanal/src/uv/uv.dart';
import 'package:test/test.dart';

void main() {
  group('UvTuiInputParser', () {
    test('maps key press events to KeyMsg', () {
      final p = UvTuiInputParser();
      final msgs = p.parseAll('\x1b[A'.codeUnits); // CSI A (up)
      expect(msgs, hasLength(1));
      expect(msgs[0], isA<KeyMsg>());
      final k = (msgs[0] as KeyMsg).key;
      expect(k.type, term.KeyType.up);
    });

    test('maps focus/blur to FocusMsg', () {
      final p = UvTuiInputParser();
      expect(p.parseAll('\x1b[I'.codeUnits), [const FocusMsg(true)]);
      expect(p.parseAll('\x1b[O'.codeUnits), [const FocusMsg(false)]);
    });

    test('emits PasteMsg for bracketed paste content', () {
      final p = UvTuiInputParser();
      final msgs = p.parseAll('\x1b[200~hello\x1b[201~'.codeUnits);
      expect(msgs, [const PasteMsg('hello')]);
    });
  });
}
