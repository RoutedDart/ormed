import '../../terminal/keys.dart' as term;
import '../../unicode/grapheme.dart' as uni;
import '../msg.dart';
import 'decoder.dart';
import 'event_stream.dart';
import 'event.dart' as uvev;
import 'key.dart' as uvk;
import 'mouse.dart' as uvm;

/// Adapts Ultraviolet-style input events to the current TUI message types.
///
/// This is an opt-in compatibility layer so the TUI runtime can consume the UV
/// decoder without rewriting the entire Msg/Key pipeline.
final class UvTuiInputParser {
  UvTuiInputParser({EventDecoder? decoder})
    : _events = UvEventStreamParser(decoder: decoder);

  final UvEventStreamParser _events;

  bool get hasPending => _events.hasPending;

  /// Parses raw input bytes and returns translated TUI [Msg] instances.
  ///
  /// The parser buffers incomplete sequences across calls.
  ///
  /// When [expired] is true, the parser flushes incomplete sequences (e.g. on
  /// EOF or after an escape timeout).
  List<Msg> parseAll(List<int> bytes, {bool expired = false}) {
    final out = <Msg>[];
    final evs = _events.parseAll(bytes, expired: expired);
    for (final ev in evs) {
      if (ev is uvev.PasteEvent) {
        out.add(PasteMsg(ev.content));
        continue;
      }
      out.addAll(_eventToMsgs(ev));
    }

    return out;
  }

  void clear() {
    _events.clear();
  }
}

List<Msg> _eventToMsgs(uvev.Event ev) {
  if (ev is uvev.IgnoredEvent) return const [];
  if (ev is uvev.MultiEvent) {
    final out = <Msg>[];
    for (final e in ev.events) {
      out.addAll(_eventToMsgs(e));
    }
    return out;
  }

  if (ev is uvev.KeyPressEvent) {
    return [KeyMsg(_toTermKey(ev.key()))];
  }

  if (ev is uvev.FocusEvent) return const [FocusMsg(true)];
  if (ev is uvev.BlurEvent) return const [FocusMsg(false)];

  if (ev is uvev.WindowSizeEvent) {
    return [WindowSizeMsg(ev.width, ev.height)];
  }
  if (ev is uvev.Size) return [WindowSizeMsg(ev.width, ev.height)];

  if (ev is uvev.PasteEvent) return [PasteMsg(ev.content)];

  if (ev is uvev.MouseClickEvent)
    return [_mouseMsg(MouseAction.press, ev.mouse())];
  if (ev is uvev.MouseReleaseEvent)
    return [_mouseMsg(MouseAction.release, ev.mouse())];
  if (ev is uvev.MouseMotionEvent)
    return [_mouseMsg(MouseAction.motion, ev.mouse())];
  if (ev is uvev.MouseWheelEvent)
    return [_mouseMsg(MouseAction.wheel, ev.mouse())];

  // Unknown/unsupported UV events are currently dropped.
  return const [];
}

term.Key _toTermKey(uvk.Key key) {
  final alt = uvk.KeyMod.contains(key.mod, uvk.KeyMod.alt);
  final ctrl = uvk.KeyMod.contains(key.mod, uvk.KeyMod.ctrl);
  final shift = uvk.KeyMod.contains(key.mod, uvk.KeyMod.shift);

  // Printable keys (including multi-codepoint grapheme clusters).
  if (key.text.isNotEmpty) {
    return term.Key(
      term.KeyType.runes,
      runes: uni.codePoints(key.text),
      alt: alt,
      ctrl: ctrl,
    );
  }

  // Common control/special keys (represented as ASCII codes in UV).
  switch (key.code) {
    case uvk.keyEnter:
      return term.Key(term.KeyType.enter, alt: alt, ctrl: ctrl, shift: shift);
    case uvk.keyTab:
      return term.Key(term.KeyType.tab, alt: alt, ctrl: ctrl, shift: shift);
    case uvk.keyBackspace:
      return term.Key(
        term.KeyType.backspace,
        alt: alt,
        ctrl: ctrl,
        shift: shift,
      );
    case uvk.keyEscape:
      return term.Key(term.KeyType.escape, alt: alt, ctrl: ctrl, shift: shift);
  }

  // C0/C1 mapped to ctrl+<letter> in UV (code points in ASCII range).
  if (key.code < uvk.keyExtended) {
    return term.Key(
      term.KeyType.runes,
      runes: [key.code],
      alt: alt,
      ctrl: ctrl,
    );
  }

  // Special keys.
  final (type, keepShift) = _toKeyType(key.code);
  return term.Key(type, alt: alt, ctrl: ctrl, shift: keepShift ? shift : false);
}

(term.KeyType, bool keepShift) _toKeyType(int code) {
  switch (code) {
    case uvk.keyUp:
      return (term.KeyType.up, true);
    case uvk.keyDown:
      return (term.KeyType.down, true);
    case uvk.keyLeft:
      return (term.KeyType.left, true);
    case uvk.keyRight:
      return (term.KeyType.right, true);
    case uvk.keyHome:
      return (term.KeyType.home, true);
    case uvk.keyEnd:
      return (term.KeyType.end, true);
    case uvk.keyPgUp:
      return (term.KeyType.pageUp, true);
    case uvk.keyPgDown:
      return (term.KeyType.pageDown, true);
    case uvk.keyInsert:
      return (term.KeyType.insert, true);
    case uvk.keyDelete:
      return (term.KeyType.delete, true);
    case uvk.keyBackspace:
      return (term.KeyType.backspace, true);
    case uvk.keyTab:
      return (term.KeyType.tab, true);
    case uvk.keyEnter:
      return (term.KeyType.enter, true);
    case uvk.keyEscape:
      return (term.KeyType.escape, true);
    case uvk.keySpace:
      return (term.KeyType.space, true);
  }

  if (code >= uvk.keyF1 && code <= uvk.keyF20) {
    return (
      term.KeyType.values[term.KeyType.f1.index + (code - uvk.keyF1)],
      true,
    );
  }

  return (term.KeyType.unknown, true);
}

MouseMsg _mouseMsg(MouseAction action, uvm.Mouse m) {
  return MouseMsg(
    action: action,
    button: _toMouseButton(m.button),
    x: m.x,
    y: m.y,
    ctrl: uvk.KeyMod.contains(m.mod, uvk.KeyMod.ctrl),
    alt: uvk.KeyMod.contains(m.mod, uvk.KeyMod.alt),
    shift: uvk.KeyMod.contains(m.mod, uvk.KeyMod.shift),
  );
}

MouseButton _toMouseButton(int button) {
  switch (button) {
    case uvm.MouseButton.left:
      return MouseButton.left;
    case uvm.MouseButton.middle:
      return MouseButton.middle;
    case uvm.MouseButton.right:
      return MouseButton.right;
    case uvm.MouseButton.wheelUp:
      return MouseButton.wheelUp;
    case uvm.MouseButton.wheelDown:
      return MouseButton.wheelDown;
    case uvm.MouseButton.wheelLeft:
      return MouseButton.wheelLeft;
    case uvm.MouseButton.wheelRight:
      return MouseButton.wheelRight;
    case uvm.MouseButton.backward:
      return MouseButton.button4;
    case uvm.MouseButton.forward:
      return MouseButton.button5;
    default:
      return MouseButton.none;
  }
}
