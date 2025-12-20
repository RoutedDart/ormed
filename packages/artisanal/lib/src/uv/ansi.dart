/// ANSI escape sequence constants and utilities for terminal control.
///
/// This library provides a comprehensive set of ANSI escape sequences used by
/// the Ultraviolet renderer to control cursor position, screen clearing,
/// mouse tracking, and more.
///
/// {@category Ultraviolet}
/// {@subCategory Rendering}
///
/// {@macro artisanal_uv_renderer_overview}
library;

/// A collection of ANSI escape sequence constants and utilities.
///
/// This class provides static constants for common terminal control sequences
/// such as cursor movement, screen clearing, and mode switching.
///
/// Upstream: `github.com/charmbracelet/x/ansi` (used by `third_party/ultraviolet/*`).
abstract final class UvAnsi {
  // Upstream: `github.com/charmbracelet/x/ansi` (`ResetStyle`).
  static const resetStyle = '\x1b[m';

  static const cursorHomePosition = '\x1b[H';
  static const eraseEntireScreen = '\x1b[2J';
  static const eraseScreenBelow = '\x1b[J';

  static const eraseLineRight = '\x1b[K';
  static const eraseLineLeft = '\x1b[1K';
  static const eraseEntireLine = '\x1b[2K';

  static const reverseIndex = '\x1bM';

  // Auto wrap mode (DECAWM).
  static const resetModeAutoWrap = '\x1b[?7l';
  static const setModeAutoWrap = '\x1b[?7h';

  // Alternate screen buffer (DECSET/DECRST 1049).
  static const setModeAltScreenSaveCursor = '\x1b[?1049h';
  static const resetModeAltScreenSaveCursor = '\x1b[?1049l';

  // Cursor visibility (DECTCEM).
  static const hideCursor = '\x1b[?25l';
  static const showCursor = '\x1b[?25h';

  // Mouse tracking.
  static const enableMouseAllEvents = '\x1b[?1003h';
  static const disableMouseAllEvents = '\x1b[?1003l';
  static const enableMouseSgr = '\x1b[?1006h';
  static const disableMouseSgr = '\x1b[?1006l';

  // Bracketed paste.
  static const enableBracketedPaste = '\x1b[?2004h';
  static const disableBracketedPaste = '\x1b[?2004l';

  // Focus reporting.
  static const enableFocusReporting = '\x1b[?1004h';
  static const disableFocusReporting = '\x1b[?1004l';

  static String cursorUp(int n) => n == 1 ? '\x1b[A' : '\x1b[${n}A';
  static String cursorDown(int n) => n == 1 ? '\x1b[B' : '\x1b[${n}B';
  static String cursorForward(int n) => n == 1 ? '\x1b[C' : '\x1b[${n}C';
  static String cursorBackward(int n) => n == 1 ? '\x1b[D' : '\x1b[${n}D';

  static String cursorPosition(int col1, int row1) {
    // Upstream (`x/ansi`): `CursorPosition(1,1)` compacts to `ESC [ H`.
    if (col1 == 1 && row1 == 1) return cursorHomePosition;
    return '\x1b[${row1};${col1}H';
  }

  static String verticalPositionAbsolute(int row1) => '\x1b[${row1}d';
  static String horizontalPositionAbsolute(int col1) => '\x1b[${col1}G';
  static String cursorHorizontalForwardTab(int n) =>
      n == 1 ? '\x1b[I' : '\x1b[${n}I';
  static String cursorBackwardTab(int n) => n == 1 ? '\x1b[Z' : '\x1b[${n}Z';

  static String insertLine(int n) => n == 1 ? '\x1b[L' : '\x1b[${n}L';
  static String deleteLine(int n) => n == 1 ? '\x1b[M' : '\x1b[${n}M';

  static String deleteCharacter(int n) => n == 1 ? '\x1b[P' : '\x1b[${n}P';
  static String insertCharacter(int n) => n == 1 ? '\x1b[@' : '\x1b[${n}@';

  static String eraseCharacter(int n) => n == 1 ? '\x1b[X' : '\x1b[${n}X';
  static String repeatPreviousCharacter(int n) =>
      n == 1 ? '\x1b[b' : '\x1b[${n}b';

  static String scrollUp(int n) => n == 1 ? '\x1b[S' : '\x1b[${n}S';
  static String scrollDown(int n) => n == 1 ? '\x1b[T' : '\x1b[${n}T';

  static String setTopBottomMargins(int top1, int bottom1) =>
      '\x1b[${top1};${bottom1}r';

  static String setHyperlink(String url, String params) {
    // OSC 8: ESC ] 8 ; params ; url BEL
    //
    // Upstream uses BEL terminator (also supported by most terminals).
    return '\x1b]8;$params;$url\x07';
  }

  static String resetHyperlink() => setHyperlink('', '');
}
