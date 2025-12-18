import 'dart:convert';

import 'package:characters/characters.dart';

import 'event.dart';
import 'key.dart';
import 'mouse.dart';
import 'cell.dart' show UvRgb;
import '../../unicode/grapheme.dart' as uni;

// Flags to control the behavior of the parser.
const int _flagCtrlAt = 1 << 0;
const int _flagCtrlI = 1 << 1;
const int _flagCtrlM = 1 << 2;
const int _flagCtrlOpenBracket = 1 << 3;
const int _flagBackspace = 1 << 4;
const int _flagFind = 1 << 5;
const int _flagSelect = 1 << 6;
const int _flagFKeys = 1 << 7;

/// Legacy key encoding behavior flags.
///
/// Upstream: `third_party/ultraviolet/decoder.go` (`LegacyKeyEncoding`).
final class LegacyKeyEncoding {
  const LegacyKeyEncoding([this.bits = 0]);

  final int bits;

  LegacyKeyEncoding ctrlAt(bool v) =>
      LegacyKeyEncoding(v ? (bits | _flagCtrlAt) : (bits & ~_flagCtrlAt));
  LegacyKeyEncoding ctrlI(bool v) =>
      LegacyKeyEncoding(v ? (bits | _flagCtrlI) : (bits & ~_flagCtrlI));
  LegacyKeyEncoding ctrlM(bool v) =>
      LegacyKeyEncoding(v ? (bits | _flagCtrlM) : (bits & ~_flagCtrlM));
  LegacyKeyEncoding ctrlOpenBracket(bool v) => LegacyKeyEncoding(
    v ? (bits | _flagCtrlOpenBracket) : (bits & ~_flagCtrlOpenBracket),
  );
  LegacyKeyEncoding backspace(bool v) =>
      LegacyKeyEncoding(v ? (bits | _flagBackspace) : (bits & ~_flagBackspace));
  LegacyKeyEncoding find(bool v) =>
      LegacyKeyEncoding(v ? (bits | _flagFind) : (bits & ~_flagFind));
  LegacyKeyEncoding select(bool v) =>
      LegacyKeyEncoding(v ? (bits | _flagSelect) : (bits & ~_flagSelect));
  LegacyKeyEncoding fKeys(bool v) =>
      LegacyKeyEncoding(v ? (bits | _flagFKeys) : (bits & ~_flagFKeys));

  bool has(int flag) => (bits & flag) != 0;

  @override
  bool operator ==(Object other) =>
      other is LegacyKeyEncoding && other.bits == bits;

  @override
  int get hashCode => bits.hashCode;
}

final class EventDecoder {
  EventDecoder({LegacyKeyEncoding? legacy, this.useTerminfo = false})
    : legacy = legacy ?? const LegacyKeyEncoding();

  LegacyKeyEncoding legacy;
  bool useTerminfo;

  int _lastCks = 0;

  /// Decode the first event in [buf].
  ///
  /// Returns `(bytesConsumed, event)` where `event` may be null if more data is needed.
  (int, Event?) decode(List<int> buf, {bool allowIncompleteEsc = false}) {
    if (buf.isEmpty) return (0, null);

    final b0 = buf[0];
    // 8-bit control sequence introducers (C1).
    switch (b0) {
      case 0x9b: // CSI
        final (n, ev) = _parseCsi(
          _to7Bit(buf, 0x5b),
          allowIncompleteEsc: allowIncompleteEsc,
        );
        return (n == 0 ? 0 : n - 1, ev);
      case 0x8f: // SS3
        final (n, ev) = _parseSs3(
          _to7Bit(buf, 0x4f),
          allowIncompleteEsc: allowIncompleteEsc,
        );
        return (n == 0 ? 0 : n - 1, ev);
      case 0x9d: // OSC
        return _parseOsc(buf, allowIncompleteEsc: allowIncompleteEsc);
      case 0x90: // DCS
        return _parseDcs(buf, allowIncompleteEsc: allowIncompleteEsc);
      case 0x9f: // APC
        return _parseApc(buf, allowIncompleteEsc: allowIncompleteEsc);
      case 0x9e: // PM
        return _parseStTerminated(
          intro8: 0x9e,
          intro7: 0x5e, // '^'
          kind: 'pm',
          makeUnknown: (s) => UnknownPmEvent(s),
          buf: buf,
          allowIncompleteEsc: allowIncompleteEsc,
        );
      case 0x98: // SOS
        return _parseStTerminated(
          intro8: 0x98,
          intro7: 0x58, // 'X'
          kind: 'sos',
          makeUnknown: (s) => UnknownSosEvent(s),
          buf: buf,
          allowIncompleteEsc: allowIncompleteEsc,
        );
    }

    if (b0 == 0x1b) {
      // ESC
      if (buf.length == 1) {
        return (1, KeyPressEvent(Key(code: keyEscape)));
      }

      // ESC ESC => a literal Escape key followed by another sequence.
      if (buf[1] == 0x1b) {
        return (1, KeyPressEvent(Key(code: keyEscape)));
      }

      // Broken escape-sequence introducers should be treated as Alt-modified keys.
      if (buf.length == 2) {
        final intro = buf[1];
        final shortcut = _brokenEscIntroducerAsKey(intro);
        if (shortcut != null) return (2, shortcut);
      }

      final b1 = buf[1];
      switch (b1) {
        case 0x4f: // 'O' SS3
          return _parseSs3(buf, allowIncompleteEsc: allowIncompleteEsc);
        case 0x50: // 'P' DCS
          return _parseDcs(buf, allowIncompleteEsc: allowIncompleteEsc);
        case 0x5b: // '[' CSI
          return _parseCsi(buf, allowIncompleteEsc: allowIncompleteEsc);
        case 0x5d: // ']' OSC
          return _parseOsc(buf, allowIncompleteEsc: allowIncompleteEsc);
        case 0x5f: // '_' APC
          return _parseApc(buf, allowIncompleteEsc: allowIncompleteEsc);
        case 0x5e: // '^' PM
          return _parseStTerminated(
            intro8: 0x9e,
            intro7: 0x5e,
            kind: 'pm',
            makeUnknown: (s) => UnknownPmEvent(s),
            buf: buf,
            allowIncompleteEsc: allowIncompleteEsc,
          );
        case 0x58: // 'X' SOS
          return _parseStTerminated(
            intro8: 0x98,
            intro7: 0x58,
            kind: 'sos',
            makeUnknown: (s) => UnknownSosEvent(s),
            buf: buf,
            allowIncompleteEsc: allowIncompleteEsc,
          );
        default:
          // Alt-modified sequences: ESC + <utf8/control>
          final (n, ev) = parseUtf8(buf.sublist(1));
          if (n == 0)
            return allowIncompleteEsc
                ? (1, KeyPressEvent(Key(code: keyEscape)))
                : (0, null);
          if (ev is KeyPressEvent) {
            final k = ev.key();
            return (
              1 + n,
              KeyPressEvent(
                Key(
                  code: k.code,
                  text: k.text,
                  mod: k.mod | KeyMod.alt,
                  shiftedCode: k.shiftedCode,
                  baseCode: k.baseCode,
                  isRepeat: k.isRepeat,
                ),
              ),
            );
          }
          return (1 + n, ev);
      }
    }

    return parseUtf8(buf);
  }

  (int, Event?) parseUtf8(List<int> buf) {
    if (buf.isEmpty) return (0, null);
    final b = buf[0];

    // Control codes + DEL (0x7F).
    if (b <= 0x1f || b == 0x7f) {
      return (1, parseControl(b));
    }

    // ASCII printable characters.
    if (b >= 0x20 && b < 0x7f) {
      if (b >= 0x41 && b <= 0x5a) {
        // Uppercase A-Z => lower code + shift modifier.
        final lower = b + 0x20;
        return (
          1,
          KeyPressEvent(
            Key(
              code: lower,
              shiftedCode: b,
              text: String.fromCharCode(b),
              mod: KeyMod.shift,
            ),
          ),
        );
      }
      return (1, KeyPressEvent(Key(code: b, text: String.fromCharCode(b))));
    }

    // UTF-8 grapheme clusters: decode runes until we have at least 2 clusters,
    // then return the first one.
    var consumed = 0;
    final sb = StringBuffer();

    while (consumed < buf.length) {
      final decoded = _decodeOneRune(buf.sublist(consumed));
      if (!decoded.ok) {
        if (decoded.consumed == 0) return (0, null); // need more bytes
        return (1, UnknownEvent(String.fromCharCode(b)));
      }
      consumed += decoded.consumed;
      sb.writeCharCode(decoded.rune);

      final s = sb.toString();
      final it = s.characters.iterator;
      if (!it.moveNext()) continue;
      final firstCluster = it.current;
      if (it.moveNext()) {
        final bytesConsumed = utf8.encode(firstCluster).length;
        return (bytesConsumed, _keyFromCluster(firstCluster));
      }
    }

    // Only one grapheme cluster in the available buffer.
    final cluster = sb.toString();
    return (consumed, _keyFromCluster(cluster));
  }

  Event parseControl(int b) {
    switch (b) {
      case 0x00: // NUL
        if (legacy.has(_flagCtrlAt)) {
          return KeyPressEvent(Key(code: 0x40 /* @ */, mod: KeyMod.ctrl));
        }
        return KeyPressEvent(Key(code: keySpace, mod: KeyMod.ctrl));
      case 0x09: // HT
        if (legacy.has(_flagCtrlI)) {
          return KeyPressEvent(Key(code: 0x69 /* i */, mod: KeyMod.ctrl));
        }
        return KeyPressEvent(Key(code: keyTab));
      case 0x0d: // CR
        if (legacy.has(_flagCtrlM)) {
          return KeyPressEvent(Key(code: 0x6d /* m */, mod: KeyMod.ctrl));
        }
        return KeyPressEvent(Key(code: keyEnter));
      case 0x1b: // ESC
        if (legacy.has(_flagCtrlOpenBracket)) {
          return KeyPressEvent(Key(code: 0x5b /* [ */, mod: KeyMod.ctrl));
        }
        return KeyPressEvent(Key(code: keyEscape));
      case 0x7f: // DEL
        if (legacy.has(_flagBackspace)) {
          return KeyPressEvent(Key(code: keyDelete));
        }
        return KeyPressEvent(Key(code: keyBackspace));
      case 0x20: // SP
        return KeyPressEvent(Key(code: keySpace, text: ' '));
      default:
        // Map C0 control codes to ctrl+<letter/symbol>.
        if (b >= 0x01 && b <= 0x1a) {
          final code = 0x60 + b; // 'a' - 1 + b
          return KeyPressEvent(Key(code: code, mod: KeyMod.ctrl));
        }
        switch (b) {
          case 0x1c: // FS
            return KeyPressEvent(Key(code: 0x5c /* \\ */, mod: KeyMod.ctrl));
          case 0x1d: // GS
            return KeyPressEvent(Key(code: 0x5d /* ] */, mod: KeyMod.ctrl));
          case 0x1e: // RS
            return KeyPressEvent(Key(code: 0x5e /* ^ */, mod: KeyMod.ctrl));
          case 0x1f: // US
            return KeyPressEvent(Key(code: 0x5f /* _ */, mod: KeyMod.ctrl));
        }
        return UnknownEvent(String.fromCharCode(b));
    }
  }

  (int, Event?) _parseSs3(List<int> buf, {required bool allowIncompleteEsc}) {
    // Port of `parseSs3`:
    // `third_party/ultraviolet/decoder.go` (parseSs3)
    if (buf.length == 2 && buf[0] == 0x1b /* ESC */ ) {
      // Shortcut if this is an alt+O key.
      final lower = String.fromCharCode(buf[1]).toLowerCase();
      final code = lower.isEmpty ? buf[1] : lower.codeUnitAt(0);
      return (
        2,
        KeyPressEvent(Key(code: code, mod: KeyMod.shift | KeyMod.alt)),
      );
    }

    var i = 0;
    if (buf[i] == 0x8f /* SS3 */ || buf[i] == 0x1b /* ESC */ ) i++;
    if (i < buf.length && buf[i - 1] == 0x1b && buf[i] == 0x4f /* O */ ) i++;

    // Scan numbers from 0-9 (weird SS3 <modifier> Func).
    var mod = 0;
    for (
      ;
      i < buf.length && buf[i] >= 0x30 /* 0 */ && buf[i] <= 0x39 /* 9 */;
      i++
    ) {
      mod *= 10;
      mod += buf[i] - 0x30;
    }

    // Scan a GL character (0x21..0x7E). If missing/invalid, return UnknownEvent
    // for just the introducer + digits (upstream behavior).
    if (i >= buf.length || buf[i] < 0x21 || buf[i] > 0x7e) {
      final consumed = i.clamp(0, buf.length);
      return (
        consumed,
        UnknownEvent(String.fromCharCodes(buf.sublist(0, consumed))),
      );
    }

    final gl = buf[i];
    i++;

    Key k;
    if (gl >= 0x61 /* a */ && gl <= 0x64 /* d */ ) {
      // Ctrl+arrows.
      k = Key(code: keyUp + (gl - 0x61), mod: KeyMod.ctrl);
    } else {
      switch (gl) {
        case 0x41: // A
        case 0x42: // B
        case 0x43: // C
        case 0x44: // D
          k = Key(code: keyUp + (gl - 0x41));
          break;
        case 0x45: // E
          k = const Key(code: keyBegin);
          break;
        case 0x46: // F
          k = const Key(code: keyEnd);
          break;
        case 0x48: // H
          k = const Key(code: keyHome);
          break;
        case 0x50: // P
        case 0x51: // Q
        case 0x52: // R
        case 0x53: // S
          k = Key(code: keyF1 + (gl - 0x50));
          break;
        case 0x4d: // M
          k = const Key(code: keyKpEnter);
          break;
        case 0x58: // X
          k = const Key(code: keyKpEqual);
          break;
        default:
          if (gl >= 0x6a /* j */ && gl <= 0x79 /* y */ ) {
            k = Key(code: keyKpMultiply + (gl - 0x6a));
          } else {
            return (
              i,
              UnknownSs3Event(String.fromCharCodes(buf.sublist(0, i))),
            );
          }
      }
    }

    if (mod > 0) {
      k = Key(
        code: k.code,
        text: k.text,
        mod: k.mod | (mod - 1),
        shiftedCode: k.shiftedCode,
        baseCode: k.baseCode,
        isRepeat: k.isRepeat,
      );
    }

    return (i, KeyPressEvent(k));
  }

  (int, Event?) _parseCsi(List<int> buf, {required bool allowIncompleteEsc}) {
    // Find CSI final byte (0x40..0x7E).
    var i = 2; // after ESC[
    while (i < buf.length && (buf[i] < 0x40 || buf[i] > 0x7e)) {
      i++;
    }
    if (i >= buf.length) {
      return allowIncompleteEsc
          ? (buf.length, UnknownEvent(String.fromCharCodes(buf)))
          : (0, null);
    }

    final finalByte = buf[i];
    // Parse private + params + intermediates.
    var idx = 2;
    final priv = StringBuffer();
    while (idx < i && buf[idx] >= 0x3c && buf[idx] <= 0x3f) {
      priv.writeCharCode(buf[idx]);
      idx++;
    }

    final paramsStart = idx;
    while (idx < i &&
        (buf[idx] == 0x3a ||
            buf[idx] == 0x3b ||
            (buf[idx] >= 0x30 && buf[idx] <= 0x39))) {
      idx++;
    }
    final paramsBytes = buf.sublist(paramsStart, idx);
    final inter = StringBuffer();
    while (idx < i && (buf[idx] >= 0x20 && buf[idx] <= 0x2f)) {
      inter.writeCharCode(buf[idx]);
      idx++;
    }

    final params = _parseParams(paramsBytes);
    final cmd = '${priv}${inter}${String.fromCharCode(finalByte)}';

    // Handle SGR mouse: CSI < ... (M|m)
    if (priv.toString() == '<' && (finalByte == 0x4d || finalByte == 0x6d)) {
      final release = finalByte == 0x6d;
      return (i + 1, _parseSgrMouseEvent(params, release));
    }

    // Handle X10 mouse: CSI M <3bytes>
    if (finalByte == 0x4d && cmd == 'M') {
      // Upstream treats short X10 sequences as an unknown CSI introducer and
      // continues parsing the remaining bytes (no "need more data" stall).
      if (i + 3 >= buf.length) {
        return (
          i + 1,
          UnknownCsiEvent(String.fromCharCodes(buf.sublist(0, i + 1))),
        );
      }
      final seq = buf.sublist(0, i + 4);
      return (i + 4, _parseX10MouseEvent(seq));
    }

    // Key and other CSI handling (subset ported from upstream).
    switch (cmd) {
      case '?c':
        return (i + 1, parsePrimaryDevAttrs(_paramsToInts(params)));
      case '>c':
        return (i + 1, parseSecondaryDevAttrs(_paramsToInts(params)));
      case '?u':
        final flags = params.param(0, 0).value;
        return (i + 1, KeyboardEnhancementsEvent(flags));
      case '?R':
        final row = params.param(0, 1).value;
        final colResult = params.param(1, 1);
        if (!colResult.ok) break;
        return (i + 1, CursorPositionEvent(x: colResult.value - 1, y: row - 1));
      case '?n':
        final report = params.param(0, -1).value;
        final darkLight = params.param(1, -1).value;
        if (report == 997) {
          if (darkLight == 1) return (i + 1, const DarkColorSchemeEvent());
          if (darkLight == 2) return (i + 1, const LightColorSchemeEvent());
        }
        break;
      case '>m':
        // XTerm modifyOtherKeys response: CSI > 4 ; <mode> m
        final mok = params.param(0, 0);
        final val = params.param(1, -1);
        if (!mok.ok || mok.value != 4) break;
        if (!val.ok || val.value == -1) break;
        return (i + 1, ModifyOtherKeysEvent(val.value));
      case 'I':
        return (i + 1, const FocusEvent());
      case 'O':
        return (i + 1, const BlurEvent());
      case 'R':
        // Cursor position report OR modified F3.
        if (params.length == 2) {
          final row = params.param(0, 1);
          final col = params.param(1, 1);
          if (row.ok && col.ok) {
            final m = CursorPositionEvent(x: col.value - 1, y: row.value - 1);
            if (row.value == 1 &&
                (col.value - 1) <=
                    (KeyMod.meta | KeyMod.shift | KeyMod.alt | KeyMod.ctrl)) {
              return (
                i + 1,
                MultiEvent([
                  KeyPressEvent(Key(code: keyF3, mod: col.value - 1)),
                  m,
                ]),
              );
            }
            return (i + 1, m);
          }
        }
        // Unmodified key F3 (CSI R).
        if (params.length == 0) {
          return (i + 1, KeyPressEvent(Key(code: keyF3)));
        }
        break;
      case 'A':
      case 'B':
      case 'C':
      case 'D':
      case 'E':
      case 'F':
      case 'H':
      case 'P':
      case 'Q':
      case 'S':
      case 'Z':
      case 'a':
      case 'b':
      case 'c':
      case 'd':
        final event = _parseArrowAndFunctionCSI(cmd, params);
        if (event != null) return (i + 1, event);
        break;
      case '~':
      case '^':
      case '@':
        final event = _parseTildeCSI(cmd, params);
        if (event != null) return (i + 1, event);
        break;
      case r'?$y':
      case r'$y':
        final mode = params.param(0, -1);
        if (!mode.ok) break;
        // Require a second param (even if missing) to match upstream:
        // - CSI 2$y => UnknownCsiEvent
        // - CSI 2;$y => ModeNotRecognized
        if (params.length < 2) break;
        final val = params.param(1, 0);
        final setting = val.ok
            ? _modeSettingFromInt(val.value)
            : ModeSetting.notRecognized;
        return (i + 1, ModeReportEvent(mode: mode.value, value: setting));
      case 't':
        // Window operation reports (xterm):
        // `third_party/ultraviolet/decoder.go` (parseCsi: case 't')
        final op = params.param(0, 0);
        if (!op.ok) break;

        int? p1(int idx) {
          final r = params.param(idx, 0);
          return r.ok ? r.value : null;
        }

        switch (op.value) {
          case 4: // window size in pixels: 4;h;w
            if (params.length == 3) {
              final h = p1(1);
              final w = p1(2);
              if (h != null && w != null) {
                return (i + 1, WindowPixelSizeEvent(width: w, height: h));
              }
            }
            break;
          case 6: // cell size: 6;h;w
            if (params.length == 3) {
              final h = p1(1);
              final w = p1(2);
              if (h != null && w != null) {
                return (i + 1, CellSizeEvent(width: w, height: h));
              }
            }
            break;
          case 8: // window size in cells: 8;h;w
            if (params.length == 3) {
              final h = p1(1);
              final w = p1(2);
              if (h != null && w != null) {
                return (i + 1, WindowSizeEvent(width: w, height: h));
              }
            }
            break;
          case 48: // in-band terminal size report: 48;ch;cw;ph;pw
            if (params.length == 5) {
              final ch = p1(1);
              final cw = p1(2);
              final ph = p1(3);
              final pw = p1(4);
              if (ch != null && cw != null && ph != null && pw != null) {
                return (
                  i + 1,
                  MultiEvent([
                    WindowSizeEvent(width: cw, height: ch),
                    WindowPixelSizeEvent(width: pw, height: ph),
                  ]),
                );
              }
            }
            break;
        }

        // Any other window operation event.
        final args = <int>[];
        for (var j = 1; j < params.length; j++) {
          final v = params.param(j, 0);
          if (v.ok) args.add(v.value);
        }
        return (i + 1, WindowOpEvent(op: op.value, args: args));
      case '_':
        if (params.length != 6) break;
        final vk = params.param(0, 0).value;
        final sc = params.param(1, 0).value;
        final uc = params.param(2, 0).value;
        final kd = params.param(3, 0).value;
        final cs = params.param(4, 0).value;
        final rc = params.param(5, 0).value;
        return (
          i + 1,
          parseWin32InputKeyEvent(vk, sc, uc, kd == 1, cs, rc < 1 ? 1 : rc),
        );
      default:
        break;
    }

    return (
      i + 1,
      UnknownCsiEvent(String.fromCharCodes(buf.sublist(0, i + 1))),
    );
  }

  Event? _parseArrowAndFunctionCSI(String cmd, _AnsiParams params) {
    Key? base;
    final codeUnit = cmd.codeUnitAt(0);
    if (codeUnit >= 0x61 && codeUnit <= 0x64) {
      // a..d => shift+arrows
      base = Key(code: keyUp + (codeUnit - 0x61), mod: KeyMod.shift);
    } else {
      switch (cmd) {
        case 'A':
        case 'B':
        case 'C':
        case 'D':
          base = Key(code: keyUp + (codeUnit - 0x41));
          break;
        case 'E':
          base = const Key(code: keyBegin);
          break;
        case 'F':
          base = const Key(code: keyEnd);
          break;
        case 'H':
          base = const Key(code: keyHome);
          break;
        case 'P':
        case 'Q':
        case 'R':
        case 'S':
          base = Key(code: keyF1 + (codeUnit - 0x50));
          break;
        case 'Z':
          base = const Key(code: keyTab, mod: KeyMod.shift);
          break;
      }
    }
    if (base == null) return null;

    // Modifiers: CSI 1 ; <mod> <cmd>
    final id = params.param(0, 1).value;
    final mod = params.param(1, 1).value;
    if (params.length > 1 && id == 1 && mod != -1) {
      final m = keyModFromXTerm(mod - 1);
      base = Key(
        code: base.code,
        text: base.text,
        mod: base.mod | m,
        shiftedCode: base.shiftedCode,
        baseCode: base.baseCode,
        isRepeat: base.isRepeat,
      );
    }
    return _parseKittyKeyboardExt(params, KeyPressEvent(base));
  }

  Event? _parseTildeCSI(String cmd, _AnsiParams params) {
    if (params.length == 0) return null;
    final p = params.param(0, 0).value;

    if (cmd == '~') {
      if (p == 200) return const PasteStartEvent();
      if (p == 201) return const PasteEndEvent();
    }

    Key? k;
    switch (p) {
      case 1:
        k = legacy.has(_flagFind)
            ? const Key(code: keyFind)
            : const Key(code: keyHome);
        break;
      case 2:
        k = const Key(code: keyInsert);
        break;
      case 3:
        k = const Key(code: keyDelete);
        break;
      case 4:
        k = legacy.has(_flagSelect)
            ? const Key(code: keySelect)
            : const Key(code: keyEnd);
        break;
      case 5:
        k = const Key(code: keyPgUp);
        break;
      case 6:
        k = const Key(code: keyPgDown);
        break;
      case 7:
        k = const Key(code: keyHome);
        break;
      case 8:
        k = const Key(code: keyEnd);
        break;
      case 11:
      case 12:
      case 13:
      case 14:
      case 15:
        k = Key(code: keyF1 + (p - 11));
        break;
      case 17:
      case 18:
      case 19:
      case 20:
      case 21:
        k = Key(code: keyF6 + (p - 17));
        break;
      case 23:
      case 24:
      case 25:
      case 26:
        k = Key(code: keyF11 + (p - 23));
        break;
      case 28:
      case 29:
        k = Key(code: keyF15 + (p - 28));
        break;
      case 31:
      case 32:
      case 33:
      case 34:
        k = Key(code: keyF17 + (p - 31));
        break;
    }
    if (k == null) return null;

    final mod = params.param(1, -1).value;
    if (params.length > 1 && mod != -1) {
      k = Key(
        code: k.code,
        text: k.text,
        mod: k.mod | keyModFromXTerm(mod - 1),
        shiftedCode: k.shiftedCode,
        baseCode: k.baseCode,
        isRepeat: k.isRepeat,
      );
    }
    return _parseKittyKeyboardExt(params, KeyPressEvent(k));
  }

  Event _parseX10MouseEvent(List<int> seq) {
    // ESC [ M b x y ; b is 32+button, x and y are 32+coords (1-based)
    // Keep it minimal and tolerant.
    if (seq.length < 6) return UnknownCsiEvent(String.fromCharCodes(seq));
    final b = seq[3] - 32;
    final x = seq[4] - 33;
    final y = seq[5] - 33;

    final (btn, mod, isMotion, isRelease) = _decodeX10Button(b);
    final m = Mouse(x: x, y: y, button: btn, mod: mod);
    if (isMotion) return MouseMotionEvent(m);
    if (btn >= MouseButton.wheelUp && btn <= MouseButton.wheelRight)
      return MouseWheelEvent(m);
    if (isRelease) return MouseReleaseEvent(m);
    return MouseClickEvent(m);
  }

  (int button, int mod, bool motion, bool release) _decodeX10Button(int b) {
    const bitShift = 1 << 2;
    const bitAlt = 1 << 3;
    const bitCtrl = 1 << 4;
    const bitMotion = 1 << 5;
    const bitWheel = 1 << 6;
    const bitAdd = 1 << 7;
    const bitsMask = 0x03;

    var mod = 0;
    if ((b & bitShift) != 0) mod |= KeyMod.shift;
    if ((b & bitAlt) != 0) mod |= KeyMod.alt;
    if ((b & bitCtrl) != 0) mod |= KeyMod.ctrl;

    var btn = MouseButton.none;
    var isRelease = false;
    var isMotion = false;

    if ((b & bitAdd) != 0) {
      btn = MouseButton.backward + (b & bitsMask);
    } else if ((b & bitWheel) != 0) {
      btn = MouseButton.wheelUp + (b & bitsMask);
    } else {
      btn = MouseButton.left + (b & bitsMask);
      if ((b & bitsMask) == bitsMask) {
        btn = MouseButton.none;
        isRelease = true;
      }
    }

    if ((b & bitMotion) != 0 &&
        !(btn >= MouseButton.wheelUp && btn <= MouseButton.wheelRight)) {
      isMotion = true;
    }

    return (btn, mod, isMotion, isRelease);
  }

  Event _parseSgrMouseEvent(_AnsiParams params, bool release) {
    final x = params.param(1, 1).value;
    final y = params.param(2, 1).value;
    final b = params.param(0, 0).value;

    final (btn, mod, motion, isRelease) = _decodeX10Button(b);
    final m = Mouse(x: x - 1, y: y - 1, button: btn, mod: mod);
    if (motion) return MouseMotionEvent(m);
    if (btn >= MouseButton.wheelUp && btn <= MouseButton.wheelRight)
      return MouseWheelEvent(m);
    if (release || isRelease) return MouseReleaseEvent(m);
    return MouseClickEvent(m);
  }

  (int, Event?) _parseOsc(List<int> buf, {required bool allowIncompleteEsc}) {
    // Port of `parseOsc` (supports both 7-bit ESC ] and 8-bit OSC 0x9d).
    KeyPressEvent defaultKey() =>
        KeyPressEvent(Key(code: 0x5d /* ] */, mod: KeyMod.alt));

    if (buf.length == 2 && buf[0] == 0x1b) {
      // ESC ] (Alt+]) shortcut.
      return (2, defaultKey());
    }

    var i = 0;
    if (buf[i] == 0x9d /* OSC */ || buf[i] == 0x1b /* ESC */ ) i++;
    if (i < buf.length && buf[i - 1] == 0x1b && buf[i] == 0x5d /* ] */ ) i++;

    var cmd = -1;
    for (; i < buf.length && buf[i] >= 0x30 && buf[i] <= 0x39; i++) {
      cmd = cmd == -1 ? 0 : cmd * 10;
      cmd += (buf[i] - 0x30);
    }

    var start = 0;
    if (i < buf.length && buf[i] == 0x3b /* ; */ ) {
      i++;
      start = i;
    }

    // Scan for OSC terminator.
    for (; i < buf.length; i++) {
      final b = buf[i];
      if (b == 0x07 /* BEL */ ||
          b == 0x1b /* ESC */ ||
          b == 0x9c /* ST */ ||
          b == 0x18 /* CAN */ ||
          b == 0x1a /* SUB */ ) {
        break;
      }
    }

    if (i >= buf.length) {
      return allowIncompleteEsc
          ? (buf.length, UnknownEvent(String.fromCharCodes(buf)))
          : (0, null);
    }

    final end = i;
    i++; // consume terminator (or ESC)

    final consumedSeq = String.fromCharCodes(buf.sublist(0, i));
    Event ignored() => IgnoredEvent(consumedSeq);

    switch (buf[i - 1]) {
      case 0x18: // CAN
      case 0x1a: // SUB
        return (i, ignored());
      case 0x1b: // ESC
        if (i >= buf.length || buf[i] != 0x5c /* \\ */ ) {
          // If this is not a valid ST terminator, treat as cancelled.
          if (cmd == -1 || (start == 0 && end == 2 && buf[0] == 0x1b)) {
            return (2, defaultKey());
          }
          return (i, ignored());
        }
        i++; // consume '\\'
        break;
      default:
        // BEL / 8-bit ST already consumed.
        break;
    }

    if (end <= start) {
      return (i, UnknownEvent(String.fromCharCodes(buf.sublist(0, i))));
    }

    final data = String.fromCharCodes(buf.sublist(start, end));
    switch (cmd) {
      case 10:
        return (i, ForegroundColorEvent(_xParseColor(data)));
      case 11:
        return (i, BackgroundColorEvent(_xParseColor(data)));
      case 12:
        return (i, CursorColorEvent(_xParseColor(data)));
      case 52:
        final parts = data.split(';');
        if (parts.length != 2 || parts[0].isEmpty) {
          return (i, const ClipboardEvent());
        }

        final b64 = parts[1];
        try {
          final decoded = utf8.decode(base64.decode(b64), allowMalformed: true);
          final sel = parts[0].codeUnitAt(0);
          return (i, ClipboardEvent(selection: sel, content: decoded));
        } catch (_) {
          // Upstream leaves selection at the zero value for malformed base64.
          return (i, ClipboardEvent(content: b64));
        }
    }

    return (i, UnknownOscEvent(String.fromCharCodes(buf.sublist(0, i))));
  }

  (int, Event?) _parseDcs(List<int> buf, {required bool allowIncompleteEsc}) {
    // Port of `parseDcs` for the response cases we care about (DA3/XTGETTCAP/XTVersion).
    if (buf.length == 2 && buf[0] == 0x1b) {
      // ESC P (Alt+Shift+p) shortcut.
      return (
        2,
        KeyPressEvent(Key(code: 0x70 /* p */, mod: KeyMod.shift | KeyMod.alt)),
      );
    }

    var i = 0;
    if (buf[i] == 0x90 /* DCS */ || buf[i] == 0x1b /* ESC */ ) i++;
    if (i < buf.length && buf[i - 1] == 0x1b && buf[i] == 0x50 /* P */ ) i++;

    // Optional prefix byte (<..?)
    var prefix = '';
    if (i < buf.length && buf[i] >= 0x3c && buf[i] <= 0x3f) {
      prefix = String.fromCharCode(buf[i]);
      i++;
    }

    // Params (0x30..0x3f)
    final paramsStart = i;
    while (i < buf.length && buf[i] >= 0x30 && buf[i] <= 0x3f) i++;
    final params = _parseParams(buf.sublist(paramsStart, i));

    // Intermediates (0x20..0x2f) - keep the last one.
    var inter = '';
    while (i < buf.length && buf[i] >= 0x20 && buf[i] <= 0x2f) {
      inter = String.fromCharCode(buf[i]);
      i++;
    }

    // Final (0x40..0x7e)
    if (i >= buf.length || buf[i] < 0x40 || buf[i] > 0x7e) {
      return allowIncompleteEsc
          ? (buf.length, UnknownEvent(String.fromCharCodes(buf)))
          : (0, null);
    }
    final finalByte = String.fromCharCode(buf[i]);
    i++;

    final start = i;
    while (i < buf.length && buf[i] != 0x9c && buf[i] != 0x1b) {
      i++;
    }
    if (i >= buf.length) {
      return allowIncompleteEsc
          ? (buf.length, UnknownEvent(String.fromCharCodes(buf)))
          : (0, null);
    }

    final end = i;
    i++; // consume terminator (or ESC)
    if (buf[i - 1] == 0x1b && i < buf.length && buf[i] == 0x5c /* \\ */ ) {
      i++;
    }

    final payload = buf.sublist(start, end);
    final cmd = '$prefix$inter$finalByte';
    if (cmd == '>|') {
      return (
        i,
        TerminalVersionEvent(utf8.decode(payload, allowMalformed: true)),
      );
    }
    if (cmd == '!|') {
      return (i, parseTertiaryDevAttrs(payload));
    }
    if (cmd == '+r') {
      final p0 = params.param(0, 0).value;
      if (p0 == 1) return (i, parseTermcap(payload));
    }

    return (i, UnknownDcsEvent(String.fromCharCodes(buf.sublist(0, i))));
  }

  (int, Event?) _parseApc(List<int> buf, {required bool allowIncompleteEsc}) {
    // ESC _ as a broken introducer is an Alt+_ key.
    if (buf.length == 2 && buf[0] == 0x1b) {
      return (2, KeyPressEvent(Key(code: 0x5f /* _ */, mod: KeyMod.alt)));
    }
    return _parseStTerminated(
      intro8: 0x9f,
      intro7: 0x5f,
      kind: 'apc',
      makeUnknown: (s) => UnknownApcEvent(s),
      buf: buf,
      allowIncompleteEsc: allowIncompleteEsc,
    );
  }

  (int, Event?) _parseStTerminated({
    required int intro8,
    required int intro7,
    required String kind,
    required Event Function(String) makeUnknown,
    required List<int> buf,
    required bool allowIncompleteEsc,
  }) {
    // ignore: unused_local_variable
    final _ = kind;
    // Port of `parseStTerminated`:
    // - Introduced by either the 8-bit control (intro8) or ESC intro7.
    // - Terminated by ST (8-bit 0x9c or 7-bit ESC \\).
    // - CAN/SUB cancel the sequence.
    KeyPressEvent defaultKey() {
      // SOS uses Shift+Alt with a lowercased introducer.
      if (intro8 == 0x98 /* SOS */ ) {
        final lower = (intro7 >= 0x41 && intro7 <= 0x5a)
            ? intro7 + 0x20
            : intro7;
        return KeyPressEvent(Key(code: lower, mod: KeyMod.shift | KeyMod.alt));
      }
      return KeyPressEvent(Key(code: intro7, mod: KeyMod.alt));
    }

    if (buf.length == 2 && buf[0] == 0x1b) {
      return (2, defaultKey());
    }

    var i = 0;
    if (buf[i] == intro8 || buf[i] == 0x1b) i++;
    if (i < buf.length && buf[i - 1] == 0x1b && buf[i] == intro7) i++;

    final start = i;
    while (i < buf.length) {
      final b = buf[i];
      if (b == 0x1b /* ESC */ ||
          b == 0x9c /* ST */ ||
          b == 0x18 /* CAN */ ||
          b == 0x1a /* SUB */ ) {
        break;
      }
      i++;
    }

    if (i >= buf.length) {
      return allowIncompleteEsc
          ? (buf.length, UnknownEvent(String.fromCharCodes(buf)))
          : (0, null);
    }

    final end = i;
    i++; // consume terminator byte (or ESC)

    Event ignored() => IgnoredEvent(String.fromCharCodes(buf.sublist(0, i)));

    switch (buf[i - 1]) {
      case 0x18: // CAN
      case 0x1a: // SUB
        return (i, ignored());
      case 0x1b: // ESC
        if (i >= buf.length || buf[i] != 0x5c /* \\ */ ) {
          if (start == end) return (2, defaultKey());
          return (i, ignored());
        }
        i++; // consume '\\'
        break;
      default:
        // 8-bit ST already consumed.
        break;
    }

    // No specialized parsing for these sequences yet; always return unknown.
    return (i, makeUnknown(String.fromCharCodes(buf.sublist(0, i))));
  }

  Event _parseKittyKeyboardExt(_AnsiParams params, KeyPressEvent k) {
    // Minimal port of `parseKittyKeyboardExt`.
    if (params.length > 2 &&
        params.params[0].param(1) == 1 &&
        params.params.length > 1 &&
        params.params[1].hasMore) {
      final type = params.params[2].param(1);
      if (type == 2) {
        final key = k.key();
        return KeyPressEvent(
          Key(
            code: key.code,
            text: key.text,
            mod: key.mod,
            shiftedCode: key.shiftedCode,
            baseCode: key.baseCode,
            isRepeat: true,
          ),
        );
      }
      if (type == 3) return KeyReleaseEvent(k.key());
    }
    return k;
  }
}

// --- Helpers / parser utilities ---

List<int> _to7Bit(List<int> buf, int intro7) {
  if (buf.isEmpty) return const [];
  return <int>[0x1b, intro7, ...buf.sublist(1)];
}

KeyPressEvent? _brokenEscIntroducerAsKey(int intro) {
  switch (intro) {
    case 0x5b: // '['
    case 0x5d: // ']'
    case 0x5e: // '^'
    case 0x5f: // '_'
      return KeyPressEvent(Key(code: intro, mod: KeyMod.alt));
    case 0x50: // 'P' (DCS)
    case 0x58: // 'X' (SOS)
    case 0x4f: // 'O' (SS3)
      final lower = intro + 0x20;
      return KeyPressEvent(Key(code: lower, mod: KeyMod.shift | KeyMod.alt));
  }
  return null;
}

List<int> _paramsToInts(_AnsiParams params) {
  if (params.length == 0) return const [];
  return List<int>.generate(
    params.length,
    (i) => params.param(i, -1).value,
    growable: false,
  );
}

UvRgb? _xParseColor(String data) {
  final s = data.trim();
  if (s.isEmpty || s == '?') return null;

  if (s.startsWith('#')) {
    final hex = s.substring(1);
    if (hex.length != 6) return null;
    final r = int.tryParse(hex.substring(0, 2), radix: 16);
    final g = int.tryParse(hex.substring(2, 4), radix: 16);
    final b = int.tryParse(hex.substring(4, 6), radix: 16);
    if (r == null || g == null || b == null) return null;
    return UvRgb(r, g, b);
  }

  if (s.startsWith('rgb:')) {
    final body = s.substring(4);
    final parts = body.split('/');
    if (parts.length != 3) return null;
    final r = _xParseRgbComponent(parts[0]);
    final g = _xParseRgbComponent(parts[1]);
    final b = _xParseRgbComponent(parts[2]);
    if (r == null || g == null || b == null) return null;
    return UvRgb(r, g, b);
  }

  // Best-effort: bare hex without '#'.
  if (s.length == 6) {
    final r = int.tryParse(s.substring(0, 2), radix: 16);
    final g = int.tryParse(s.substring(2, 4), radix: 16);
    final b = int.tryParse(s.substring(4, 6), radix: 16);
    if (r == null || g == null || b == null) return null;
    return UvRgb(r, g, b);
  }

  return null;
}

int? _xParseRgbComponent(String hex) {
  if (hex.isEmpty) return null;
  final v = int.tryParse(hex, radix: 16);
  if (v == null) return null;
  final max = (1 << (4 * hex.length)) - 1;
  if (max <= 0) return null;
  // Scale to 0..255.
  return (((v * 255) / max).round().clamp(0, 255) as int);
}

({int consumed, int rune, bool ok}) _decodeOneRune(List<int> buf) {
  if (buf.isEmpty) return (consumed: 0, rune: 0, ok: false);
  final b0 = buf[0] & 0xff;
  if (b0 < 0x80) return (consumed: 1, rune: b0, ok: true);

  int need;
  int min;
  int rune;
  if ((b0 & 0xE0) == 0xC0) {
    need = 2;
    min = 0x80;
    rune = b0 & 0x1F;
  } else if ((b0 & 0xF0) == 0xE0) {
    need = 3;
    min = 0x800;
    rune = b0 & 0x0F;
  } else if ((b0 & 0xF8) == 0xF0) {
    need = 4;
    min = 0x10000;
    rune = b0 & 0x07;
  } else {
    return (consumed: 1, rune: b0, ok: false);
  }

  if (buf.length < need) return (consumed: 0, rune: 0, ok: false);

  for (var i = 1; i < need; i++) {
    final bx = buf[i] & 0xff;
    if ((bx & 0xC0) != 0x80) return (consumed: 1, rune: b0, ok: false);
    rune = (rune << 6) | (bx & 0x3F);
  }

  // Reject overlongs, surrogates, and out-of-range code points.
  if (rune < min) return (consumed: 1, rune: b0, ok: false);
  if (rune > 0x10ffff) return (consumed: 1, rune: b0, ok: false);
  if (rune >= 0xD800 && rune <= 0xDFFF)
    return (consumed: 1, rune: b0, ok: false);

  return (consumed: need, rune: rune, ok: true);
}

Event _keyFromCluster(String text) {
  if (text.isEmpty) {
    return const KeyPressEvent(Key(code: keyExtended, text: ''));
  }
  final cps = uni.codePoints(text);
  if (cps.length == 1) {
    return KeyPressEvent(Key(code: cps[0], text: text));
  }
  return KeyPressEvent(Key(code: keyExtended, text: text));
}

ModeSetting _modeSettingFromInt(int v) {
  switch (v) {
    case 0:
      return ModeSetting.notRecognized;
    case 1:
      return ModeSetting.set;
    case 2:
      return ModeSetting.reset;
    case 3:
      return ModeSetting.permanentlySet;
    case 4:
      return ModeSetting.permanentlyReset;
    default:
      return ModeSetting.reset;
  }
}

final class _AnsiParam {
  _AnsiParam(this.values);
  final List<int?> values;
  bool get hasMore => values.length > 1;
  int param(int defaultValue, [int subIndex = 0]) {
    if (subIndex >= values.length) return defaultValue;
    final v = values[subIndex];
    return v ?? defaultValue;
  }
}

final class _AnsiParams {
  _AnsiParams(this.params);
  final List<_AnsiParam> params;

  int get length => params.length;

  ({int value, bool ok}) param(
    int index,
    int defaultValue, {
    int subIndex = 0,
  }) {
    if (index < 0 || index >= params.length)
      return (value: defaultValue, ok: false);
    final p = params[index];
    if (subIndex >= p.values.length) return (value: defaultValue, ok: false);
    final v = p.values[subIndex];
    if (v == null) return (value: defaultValue, ok: false);
    return (value: v, ok: true);
  }
}

_AnsiParams _parseParams(List<int> bytes) {
  if (bytes.isEmpty) return _AnsiParams(const []);
  final s = String.fromCharCodes(bytes);
  final parts = s.split(';');
  final out = <_AnsiParam>[];
  for (final part in parts) {
    if (part.isEmpty) {
      out.add(_AnsiParam([null]));
      continue;
    }
    final sub = part.split(':');
    final vals = <int?>[];
    for (final item in sub) {
      if (item.isEmpty) {
        vals.add(null);
      } else {
        vals.add(int.tryParse(item));
      }
    }
    out.add(_AnsiParam(vals));
  }
  return _AnsiParams(out);
}

// --- Device attributes helpers ---

Event parsePrimaryDevAttrs(List<int> params) =>
    PrimaryDeviceAttributesEvent(List<int>.from(params));

Event parseSecondaryDevAttrs(List<int> params) =>
    SecondaryDeviceAttributesEvent(List<int>.from(params));

Event parseTertiaryDevAttrs(List<int> data) {
  try {
    final hexStr = String.fromCharCodes(data);
    final bytes = _decodeHex(hexStr);
    return TertiaryDeviceAttributesEvent(
      utf8.decode(bytes, allowMalformed: true),
    );
  } catch (_) {
    final s = String.fromCharCodes(data);
    return UnknownDcsEvent('\x1bP!|$s\x1b\\');
  }
}

CapabilityEvent parseTermcap(List<int> data) {
  if (data.isEmpty) return const CapabilityEvent('');
  final raw = String.fromCharCodes(data);
  final parts = raw.split(';');
  final out = <String>[];
  for (final p in parts) {
    if (p.isEmpty) continue;
    final kv = p.split('=');
    if (kv.isEmpty) return const CapabilityEvent('');

    final nameHex = kv[0];
    List<int> name;
    try {
      name = _decodeHex(nameHex);
    } catch (_) {
      continue;
    }
    if (name.isEmpty) continue;

    List<int> value = const [];
    if (kv.length > 1) {
      try {
        value = _decodeHex(kv.sublist(1).join('='));
      } catch (_) {
        continue;
      }
    }

    final nameStr = utf8.decode(name, allowMalformed: true);
    if (value.isEmpty) {
      out.add(nameStr);
    } else {
      out.add('$nameStr=${utf8.decode(value, allowMalformed: true)}');
    }
  }
  return CapabilityEvent(out.join(';'));
}

List<int> _decodeHex(String hexStr) {
  if (hexStr.length.isOdd) throw const FormatException('odd length hex');
  final out = <int>[];
  for (var i = 0; i < hexStr.length; i += 2) {
    final byte = int.parse(hexStr.substring(i, i + 2), radix: 16);
    out.add(byte);
  }
  return out;
}

// --- Win32 helpers (ported for parity tests) ---

abstract final class Win32ControlKeyState {
  static const int rightAltPressed = 0x0001;
  static const int leftAltPressed = 0x0002;
  static const int rightCtrlPressed = 0x0004;
  static const int leftCtrlPressed = 0x0008;
  static const int shiftPressed = 0x0010;
  static const int numLockOn = 0x0020;
  static const int scrollLockOn = 0x0040;
  static const int capsLockOn = 0x0080;
  static const int enhancedKey = 0x0100;
}

Key ensureKeyCase(Key key, int cks) {
  if (key.text.isEmpty) return key;
  final hasShift = (cks & Win32ControlKeyState.shiftPressed) != 0;
  final hasCaps = (cks & Win32ControlKeyState.capsLockOn) != 0;

  final text = key.text;
  if (text.isEmpty) return key;

  final codeChar = String.fromCharCode(key.code);
  if (hasShift || hasCaps) {
    if (codeChar == codeChar.toLowerCase() &&
        codeChar != codeChar.toUpperCase()) {
      final shifted = codeChar.toUpperCase();
      return Key(
        code: key.code,
        text: shifted,
        mod: key.mod,
        shiftedCode: uni.firstCodePoint(shifted),
        baseCode: key.baseCode,
        isRepeat: key.isRepeat,
      );
    }
  } else {
    if (codeChar == codeChar.toUpperCase() &&
        codeChar != codeChar.toLowerCase()) {
      final shifted = codeChar.toLowerCase();
      return Key(
        code: key.code,
        text: shifted,
        mod: key.mod,
        shiftedCode: uni.firstCodePoint(shifted),
        baseCode: key.baseCode,
        isRepeat: key.isRepeat,
      );
    }
  }
  return key;
}

int translateControlKeyState(int cks) {
  var m = 0;
  if ((cks & Win32ControlKeyState.leftCtrlPressed) != 0 ||
      (cks & Win32ControlKeyState.rightCtrlPressed) != 0) {
    m |= KeyMod.ctrl;
  }
  if ((cks & Win32ControlKeyState.leftAltPressed) != 0 ||
      (cks & Win32ControlKeyState.rightAltPressed) != 0) {
    m |= KeyMod.alt;
  }
  if ((cks & Win32ControlKeyState.shiftPressed) != 0) {
    m |= KeyMod.shift;
  }
  if ((cks & Win32ControlKeyState.capsLockOn) != 0) {
    m |= KeyMod.capsLock;
  }
  if ((cks & Win32ControlKeyState.numLockOn) != 0) {
    m |= KeyMod.numLock;
  }
  if ((cks & Win32ControlKeyState.scrollLockOn) != 0) {
    m |= KeyMod.scrollLock;
  }
  return m;
}

Event? parseWin32InputKeyEvent(
  int vkc,
  int _sc,
  int uc,
  bool keyDown,
  int cks,
  int repeatCount,
) {
  // Partial port of `parseWin32InputKeyEvent` for VT input mode sequences.
  //
  // Upstream: `third_party/ultraviolet/decoder.go` (parseWin32InputKeyEvent)
  final mod = translateControlKeyState(cks);

  bool isControl(int r) => r <= 0x1f || (r >= 0x7f && r <= 0x9f);
  bool isPrintable(int r) => r >= 0x20 && !isControl(r) && r <= 0x10ffff;

  // vkc==0 indicates a serialized UTF-16 code unit; upstream defers decoding
  // these in the TerminalReader. We still surface them as a "base code" event.
  if (vkc == 0) {
    final k = Key(code: 0, baseCode: uc, mod: mod);
    if (repeatCount > 1 && keyDown) {
      return MultiEvent(
        List<Event>.generate(repeatCount, (_) => KeyPressEvent(k)),
      );
    }
    return keyDown ? KeyPressEvent(k) : KeyReleaseEvent(k);
  }

  var baseCode = 0;
  var shiftedCode = 0;
  var text = '';

  switch (vkc) {
    case 0x08: // VK_BACK
      baseCode = keyBackspace;
      break;
    case 0x09: // VK_TAB
      baseCode = keyTab;
      break;
    case 0x0d: // VK_RETURN
      baseCode = keyEnter;
      break;
    case 0x1b: // VK_ESCAPE
      baseCode = keyEscape;
      break;
    case 0x20: // VK_SPACE
      baseCode = keySpace;
      text = ' ';
      break;
    default:
      if (vkc >= 0x30 && vkc <= 0x39) {
        // 0-9
        baseCode = vkc;
      } else if (vkc >= 0x41 && vkc <= 0x5a) {
        // A-Z => lowercase base code.
        baseCode = vkc + 0x20;
      } else if (vkc >= 0x70 && vkc <= 0x87) {
        // F1..F24
        baseCode = keyF1 + (vkc - 0x70);
      } else {
        baseCode = uc != 0 ? uc : vkc;
      }
  }

  var code = baseCode;
  if (uc != 0 && !isControl(uc)) {
    code = uc;
    if (text.isEmpty && isPrintable(code) && mod == 0) {
      text = String.fromCharCode(code);
    }
  }

  // If the key is printable and only shift/caps locks are active, keep text.
  if (text.isEmpty && isPrintable(code) && (mod == 0 || mod == KeyMod.shift)) {
    text = String.fromCharCode(code);
  }

  var key = Key(
    code: code,
    text: text,
    mod: mod,
    shiftedCode: shiftedCode,
    baseCode: baseCode,
  );
  key = ensureKeyCase(key, cks);

  if (repeatCount > 1 && keyDown) {
    return MultiEvent(
      List<Event>.generate(
        repeatCount,
        (_) => KeyPressEvent(key),
        growable: false,
      ),
    );
  }

  return keyDown ? KeyPressEvent(key) : KeyReleaseEvent(key);
}
