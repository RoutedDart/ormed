library;

import '../unicode/width.dart';
import '../unicode/grapheme.dart' as uni;

/// Unified ANSI escape sequence constants and utilities.
///
/// This module provides a single source of truth for all ANSI escape sequences
/// used throughout the artisan_args package, including both static components
/// and the TUI runtime.
///
/// ```dart
/// import 'package:artisan_args/src/terminal/ansi.dart';
///
/// // Use constants
/// stdout.write(Ansi.cursorHide);
/// stdout.write(Ansi.clearScreen);
///
/// // Use helper methods
/// stdout.write(Ansi.cursorTo(10, 5));
/// stdout.write(Ansi.cursorUp(3));
/// ```
/// ANSI escape sequence constants and helpers.
///
/// Provides all escape sequences needed for terminal control:
/// - Cursor visibility and movement
/// - Screen and line clearing
/// - Alternate screen buffer
/// - Mouse tracking
/// - Bracketed paste mode
/// - Focus reporting
/// - Style reset
abstract final class Ansi {
  // ─────────────────────────────────────────────────────────────────────────────
  // Escape Sequences
  // ─────────────────────────────────────────────────────────────────────────────

  /// The escape character (ESC, 0x1B).
  static const escape = '\x1b';

  /// The Control Sequence Introducer (ESC [).
  static const csi = '\x1b[';

  /// The Operating System Command introducer (ESC ]).
  static const osc = '\x1b]';

  /// The String Terminator (ESC \).
  static const st = '\x1b\\';

  /// The Bell character (BEL, 0x07).
  static const bel = '\x07';

  // ─────────────────────────────────────────────────────────────────────────────
  // Cursor Visibility
  // ─────────────────────────────────────────────────────────────────────────────

  /// Hides the cursor.
  static const cursorHide = '\x1b[?25l';

  /// Shows the cursor.
  static const cursorShow = '\x1b[?25h';

  /// Saves the current cursor position (ANSI.SYS).
  static const cursorSave = '\x1b[s';

  /// Restores the previously saved cursor position (ANSI.SYS).
  static const cursorRestore = '\x1b[u';

  /// Saves cursor position (DEC private mode).
  static const cursorSaveDec = '\x1b7';

  /// Restores cursor position (DEC private mode).
  static const cursorRestoreDec = '\x1b8';

  // ─────────────────────────────────────────────────────────────────────────────
  // Cursor Movement - Constants
  // ─────────────────────────────────────────────────────────────────────────────

  /// Moves cursor up one line.
  static const cursorUp = '\x1b[A';

  /// Moves cursor down one line.
  static const cursorDown = '\x1b[B';

  /// Moves cursor right one column.
  static const cursorRight = '\x1b[C';

  /// Moves cursor left one column.
  static const cursorLeft = '\x1b[D';

  /// Moves cursor to home position (1, 1).
  static const cursorHome = '\x1b[H';

  /// Moves cursor to beginning of next line.
  static const cursorNextLine = '\x1b[E';

  /// Moves cursor to beginning of previous line.
  static const cursorPrevLine = '\x1b[F';

  // ─────────────────────────────────────────────────────────────────────────────
  // Cursor Movement - Functions
  // ─────────────────────────────────────────────────────────────────────────────

  /// Moves cursor up by [n] lines.
  static String cursorUpBy(int n) => '\x1b[${n}A';

  /// Moves cursor down by [n] lines.
  static String cursorDownBy(int n) => '\x1b[${n}B';

  /// Moves cursor right by [n] columns.
  static String cursorRightBy(int n) => '\x1b[${n}C';

  /// Moves cursor left by [n] columns.
  static String cursorLeftBy(int n) => '\x1b[${n}D';

  /// Moves cursor to beginning of line [n] lines down.
  static String cursorNextLineBy(int n) => '\x1b[${n}E';

  /// Moves cursor to beginning of line [n] lines up.
  static String cursorPrevLineBy(int n) => '\x1b[${n}F';

  /// Moves cursor to column [n] (1-based).
  static String cursorToColumn(int n) => '\x1b[${n}G';

  /// Moves cursor to [row] and [col] (1-based).
  static String cursorTo(int row, int col) => '\x1b[$row;${col}H';

  /// Alias for [cursorTo] using 'f' terminator.
  static String cursorPosition(int row, int col) => '\x1b[$row;${col}f';

  // ─────────────────────────────────────────────────────────────────────────────
  // Screen Clearing
  // ─────────────────────────────────────────────────────────────────────────────

  /// Clears the entire screen.
  static const clearScreen = '\x1b[2J';

  /// Clears from cursor to end of screen.
  static const clearScreenToEnd = '\x1b[J';

  /// Clears from cursor to end of screen (explicit mode).
  static const clearScreenToEndExplicit = '\x1b[0J';

  /// Clears from cursor to beginning of screen.
  static const clearScreenToStart = '\x1b[1J';

  /// Clears entire screen and scrollback buffer.
  static const clearScreenAndScrollback = '\x1b[3J';

  // ─────────────────────────────────────────────────────────────────────────────
  // Line Clearing
  // ─────────────────────────────────────────────────────────────────────────────

  /// Clears the entire current line.
  static const clearLine = '\x1b[2K';

  /// Clears from cursor to end of line.
  static const clearLineToEnd = '\x1b[K';

  /// Clears from cursor to end of line (explicit mode).
  static const clearLineToEndExplicit = '\x1b[0K';

  /// Clears from cursor to beginning of line.
  static const clearLineToStart = '\x1b[1K';

  // ─────────────────────────────────────────────────────────────────────────────
  // Scrolling
  // ─────────────────────────────────────────────────────────────────────────────

  /// Scrolls screen up by one line.
  static const scrollUp = '\x1b[S';

  /// Scrolls screen down by one line.
  static const scrollDown = '\x1b[T';

  /// Scrolls screen up by [n] lines.
  static String scrollUpBy(int n) => '\x1b[${n}S';

  /// Scrolls screen down by [n] lines.
  static String scrollDownBy(int n) => '\x1b[${n}T';

  // ─────────────────────────────────────────────────────────────────────────────
  // Alternate Screen Buffer
  // ─────────────────────────────────────────────────────────────────────────────

  /// Enters the alternate screen buffer (fullscreen mode).
  static const altScreenEnter = '\x1b[?1049h';

  /// Exits the alternate screen buffer.
  static const altScreenExit = '\x1b[?1049l';

  // ─────────────────────────────────────────────────────────────────────────────
  // Mouse Tracking
  // ─────────────────────────────────────────────────────────────────────────────

  /// Enables X10 mouse reporting (button press only).
  static const mouseEnableX10 = '\x1b[?9h';

  /// Disables X10 mouse reporting.
  static const mouseDisableX10 = '\x1b[?9l';

  /// Enables normal mouse tracking (button press and release).
  static const mouseEnableNormal = '\x1b[?1000h';

  /// Disables normal mouse tracking.
  static const mouseDisableNormal = '\x1b[?1000l';

  /// Enables button event tracking (press, release, motion with button).
  static const mouseEnableButton = '\x1b[?1002h';

  /// Disables button event tracking.
  static const mouseDisableButton = '\x1b[?1002l';

  /// Enables any-event tracking (all motion events).
  static const mouseEnableAny = '\x1b[?1003h';

  /// Disables any-event tracking.
  static const mouseDisableAny = '\x1b[?1003l';

  /// Enables SGR extended mouse mode (supports coordinates > 223).
  static const mouseEnableSgr = '\x1b[?1006h';

  /// Disables SGR extended mouse mode.
  static const mouseDisableSgr = '\x1b[?1006l';

  /// Enables UTF-8 mouse mode.
  static const mouseEnableUtf8 = '\x1b[?1005h';

  /// Disables UTF-8 mouse mode.
  static const mouseDisableUtf8 = '\x1b[?1005l';

  // ─────────────────────────────────────────────────────────────────────────────
  // Bracketed Paste Mode
  // ─────────────────────────────────────────────────────────────────────────────

  /// Enables bracketed paste mode.
  static const bracketedPasteEnable = '\x1b[?2004h';

  /// Disables bracketed paste mode.
  static const bracketedPasteDisable = '\x1b[?2004l';

  /// Start of bracketed paste content.
  static const bracketedPasteStart = '\x1b[200~';

  /// End of bracketed paste content.
  static const bracketedPasteEnd = '\x1b[201~';

  // ─────────────────────────────────────────────────────────────────────────────
  // Focus Reporting
  // ─────────────────────────────────────────────────────────────────────────────

  /// Enables focus reporting.
  static const focusEnable = '\x1b[?1004h';

  /// Disables focus reporting.
  static const focusDisable = '\x1b[?1004l';

  /// Focus gained sequence.
  static const focusIn = '\x1b[I';

  /// Focus lost sequence.
  static const focusOut = '\x1b[O';

  // ─────────────────────────────────────────────────────────────────────────────
  // Style/SGR (Select Graphic Rendition)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Resets all attributes to default.
  static const reset = '\x1b[0m';

  /// Enables bold/bright mode.
  static const bold = '\x1b[1m';

  /// Enables dim/faint mode.
  static const dim = '\x1b[2m';

  /// Enables italic mode.
  static const italic = '\x1b[3m';

  /// Enables underline mode.
  static const underline = '\x1b[4m';

  /// Enables slow blink mode.
  static const blink = '\x1b[5m';

  /// Enables rapid blink mode.
  static const rapidBlink = '\x1b[6m';

  /// Enables reverse/inverse mode.
  static const reverse = '\x1b[7m';

  /// Enables hidden/invisible mode.
  static const hidden = '\x1b[8m';

  /// Enables strikethrough mode.
  static const strikethrough = '\x1b[9m';

  /// Disables bold mode.
  static const boldOff = '\x1b[21m';

  /// Disables bold and dim modes.
  static const normalIntensity = '\x1b[22m';

  /// Disables italic mode.
  static const italicOff = '\x1b[23m';

  /// Disables underline mode.
  static const underlineOff = '\x1b[24m';

  /// Disables blink mode.
  static const blinkOff = '\x1b[25m';

  /// Disables reverse mode.
  static const reverseOff = '\x1b[27m';

  /// Disables hidden mode.
  static const hiddenOff = '\x1b[28m';

  /// Disables strikethrough mode.
  static const strikethroughOff = '\x1b[29m';

  // ─────────────────────────────────────────────────────────────────────────────
  // Window/Terminal Control
  // ─────────────────────────────────────────────────────────────────────────────

  /// Sets the window title. Use with [bel] to terminate.
  ///
  /// Example: `Ansi.setTitle('My App')` produces `\x1b]0;My App\x07`
  static String setTitle(String title) => '\x1b]0;$title\x07';

  /// Rings the terminal bell.
  static const bell = '\x07';

  /// Requests cursor position report. Terminal responds with `\x1b[{row};{col}R`.
  static const requestCursorPosition = '\x1b[6n';

  /// Requests device attributes.
  static const requestDeviceAttributes = '\x1b[c';

  // ─────────────────────────────────────────────────────────────────────────────
  // Line Drawing
  // ─────────────────────────────────────────────────────────────────────────────

  /// Enables line drawing character set.
  static const lineDrawingEnable = '\x1b(0';

  /// Disables line drawing character set (return to ASCII).
  static const lineDrawingDisable = '\x1b(B';

  // ─────────────────────────────────────────────────────────────────────────────
  // Color Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  /// Sets foreground color using ANSI 16-color palette (0-15).
  static String fg16(int color) {
    if (color < 8) {
      return '\x1b[${30 + color}m';
    } else {
      return '\x1b[${90 + color - 8}m';
    }
  }

  /// Sets background color using ANSI 16-color palette (0-15).
  static String bg16(int color) {
    if (color < 8) {
      return '\x1b[${40 + color}m';
    } else {
      return '\x1b[${100 + color - 8}m';
    }
  }

  /// Sets foreground color using 256-color palette.
  static String fg256(int color) => '\x1b[38;5;${color}m';

  /// Sets background color using 256-color palette.
  static String bg256(int color) => '\x1b[48;5;${color}m';

  /// Sets foreground color using RGB true color.
  static String fgRgb(int r, int g, int b) => '\x1b[38;2;$r;$g;${b}m';

  /// Sets background color using RGB true color.
  static String bgRgb(int r, int g, int b) => '\x1b[48;2;$r;$g;${b}m';

  /// Resets foreground color to default.
  static const fgDefault = '\x1b[39m';

  /// Resets background color to default.
  static const bgDefault = '\x1b[49m';

  // ─────────────────────────────────────────────────────────────────────────────
  // Utility Methods
  // ─────────────────────────────────────────────────────────────────────────────

  /// Pattern matching all ANSI escape sequences.
  ///
  /// Supports CSI, OSC, DCS, and common control sequences.
  static final ansiPattern = RegExp(
    r'\x1b'
    r'(?:'
    // CSI sequences.
    //
    // Support both the common semicolon SGR form (\x1b[38;2;...m) and the
    // ITU colon form (\x1b[38:2::...m).
    r'\[[0-9;:]*[ -/]*[@-~]'
    r'|'
    r'\][^\x07]*\x07' // OSC sequences (terminated by BEL)
    r'|'
    r'\][^\x1b]*\x1b\\' // OSC sequences (terminated by ST)
    r'|'
    r'P[^\x1b]*\x1b\\' // DCS sequences
    r'|'
    r'[()][AB012]' // Character set selection
    r'|'
    r'[78]' // DEC cursor save/restore
    r')',
  );

  /// Strips all ANSI escape sequences from a string.
  static String stripAnsi(String text) {
    return text.replaceAll(ansiPattern, '');
  }

  /// Calculates the visible width of a string (excluding ANSI sequences).
  static int visibleLength(String text) {
    final stripped = stripAnsi(text);
    var width = 0;
    for (final g in uni.graphemes(stripped)) {
      width += runeWidth(uni.firstCodePoint(g));
    }
    return width;
  }

  /// Wraps text in ANSI sequences that will be stripped by [stripAnsi].
  ///
  /// Useful for applying styles that can be conditionally removed.
  static String wrap(String text, String startSeq, String endSeq) {
    return '$startSeq$text$endSeq';
  }
}
