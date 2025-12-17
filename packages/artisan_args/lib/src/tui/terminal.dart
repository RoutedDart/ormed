/// TUI terminal abstraction layer.
///
/// This module re-exports the unified terminal primitives from the shared
/// terminal module, providing backward compatibility for existing TUI code.
///
/// ## Migration
///
/// The TUI terminal types are now aliases to the unified terminal module:
/// - `TuiTerminal` → `Terminal`
/// - `StdioTerminal` (TUI) → `StdioTerminal` (unified)
/// - `AnsiCodes` → `Ansi`
/// - `TerminalState` → Use `Terminal` state properties directly
///
/// New code should import from the unified terminal module:
/// ```dart
/// import 'package:artisan_args/src/terminal/terminal.dart';
/// ```
library;

import '../terminal/terminal.dart' as unified;

// Re-export unified terminal types with TUI-compatible names
export '../terminal/terminal.dart'
    show Terminal, StdioTerminal, StringTerminal, RawModeGuard, Ansi;

/// Alias for backward compatibility.
///
/// The TUI terminal interface is now unified with the package-wide
/// [Terminal] interface. This typedef maintains compatibility with
/// existing code that uses `TuiTerminal`.
///
/// **Migration**: Replace `TuiTerminal` with `Terminal`.
typedef TuiTerminal = unified.Terminal;

/// Terminal state snapshot for saving/restoring.
///
/// This class captures the current state of terminal modes for
/// saving and restoring during operations like external process
/// execution.
class TerminalState {
  const TerminalState({
    required this.rawModeEnabled,
    required this.altScreenEnabled,
    required this.cursorHidden,
    required this.mouseEnabled,
    required this.bracketedPasteEnabled,
  });

  /// Creates a state snapshot from a terminal.
  factory TerminalState.capture(unified.Terminal terminal) {
    return TerminalState(
      rawModeEnabled: terminal.isRawMode,
      altScreenEnabled: terminal.isAltScreen,
      cursorHidden: false, // Terminal doesn't track cursor visibility
      mouseEnabled: terminal.isMouseEnabled,
      bracketedPasteEnabled: terminal.isBracketedPasteEnabled,
    );
  }

  final bool rawModeEnabled;
  final bool altScreenEnabled;
  final bool cursorHidden;
  final bool mouseEnabled;
  final bool bracketedPasteEnabled;

  /// Restores this state to the given terminal.
  void restore(unified.Terminal terminal) {
    // Restore in reverse order of typical setup
    if (bracketedPasteEnabled) {
      terminal.enableBracketedPaste();
    }
    if (mouseEnabled) {
      terminal.enableMouse();
    }
    if (altScreenEnabled) {
      terminal.enterAltScreen();
    }
    if (rawModeEnabled) {
      terminal.enableRawMode();
    }
    // Note: cursor visibility is handled by the renderer
  }
}

/// ANSI escape sequence constants.
///
/// @Deprecated('Use Ansi from the unified terminal module instead')
/// This class is provided for backward compatibility.
/// New code should use [Ansi] directly.
class AnsiCodes {
  AnsiCodes._();

  // Cursor control
  static const cursorUp = '\x1b[A';
  static const cursorDown = '\x1b[B';
  static const cursorRight = '\x1b[C';
  static const cursorLeft = '\x1b[D';
  static const cursorHome = '\x1b[H';
  static const cursorHide = '\x1b[?25l';
  static const cursorShow = '\x1b[?25h';
  static const cursorSave = '\x1b[s';
  static const cursorRestore = '\x1b[u';

  // Screen control
  static const clearScreen = '\x1b[2J';
  static const clearToEnd = '\x1b[J';
  static const clearToStart = '\x1b[1J';
  static const clearLine = '\x1b[2K';
  static const clearLineToEnd = '\x1b[K';
  static const clearLineToStart = '\x1b[1K';

  // Alt screen
  static const altScreenEnter = '\x1b[?1049h';
  static const altScreenExit = '\x1b[?1049l';

  // Mouse
  static const mouseEnableBasic = '\x1b[?1000h';
  static const mouseEnableMotion = '\x1b[?1002h';
  static const mouseEnableSgr = '\x1b[?1006h';
  static const mouseDisableBasic = '\x1b[?1000l';
  static const mouseDisableMotion = '\x1b[?1002l';
  static const mouseDisableSgr = '\x1b[?1006l';

  // Bracketed paste
  static const bracketedPasteEnable = '\x1b[?2004h';
  static const bracketedPasteDisable = '\x1b[?2004l';

  // Style reset
  static const reset = '\x1b[0m';

  /// Creates a cursor position sequence (1-based row and column).
  static String cursorPosition(int row, int col) => '\x1b[$row;${col}H';

  /// Creates a cursor up sequence.
  static String cursorUpBy(int n) => '\x1b[${n}A';

  /// Creates a cursor down sequence.
  static String cursorDownBy(int n) => '\x1b[${n}B';

  /// Creates a cursor right sequence.
  static String cursorRightBy(int n) => '\x1b[${n}C';

  /// Creates a cursor left sequence.
  static String cursorLeftBy(int n) => '\x1b[${n}D';

  /// Creates a scroll up sequence.
  static String scrollUp(int n) => '\x1b[${n}S';

  /// Creates a scroll down sequence.
  static String scrollDown(int n) => '\x1b[${n}T';
}
