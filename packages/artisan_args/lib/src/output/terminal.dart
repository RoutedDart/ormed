import 'dart:io' as io;

/// Terminal control utilities.
///
/// Provides low-level terminal control functions like cursor movement,
/// screen clearing, and more.
class Terminal {
  Terminal({io.Stdout? stdout, io.Stdin? stdin})
    : _stdout = stdout ?? io.stdout,
      _stdin = stdin ?? io.stdin;

  final io.Stdout _stdout;
  final io.Stdin _stdin;

  // ─────────────────────────────────────────────────────────────────────────────
  // Terminal Info
  // ─────────────────────────────────────────────────────────────────────────────

  /// Returns the terminal width, or a default if not available.
  int get width {
    try {
      return _stdout.hasTerminal ? _stdout.terminalColumns : 80;
    } catch (_) {
      return 80;
    }
  }

  /// Returns the terminal height, or a default if not available.
  int get height {
    try {
      return _stdout.hasTerminal ? _stdout.terminalLines : 24;
    } catch (_) {
      return 24;
    }
  }

  /// Whether the terminal supports ANSI escape sequences.
  bool get supportsAnsi {
    try {
      return _stdout.supportsAnsiEscapes;
    } catch (_) {
      return false;
    }
  }

  /// Whether we're running in a real terminal.
  bool get isTerminal {
    try {
      return _stdout.hasTerminal;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Cursor Control
  // ─────────────────────────────────────────────────────────────────────────────

  /// Hides the cursor.
  void hideCursor() {
    if (supportsAnsi) _stdout.write('\x1B[?25l');
  }

  /// Shows the cursor.
  void showCursor() {
    if (supportsAnsi) _stdout.write('\x1B[?25h');
  }

  /// Moves the cursor up by [lines] rows.
  void cursorUp([int lines = 1]) {
    if (supportsAnsi) _stdout.write('\x1B[${lines}A');
  }

  /// Moves the cursor down by [lines] rows.
  void cursorDown([int lines = 1]) {
    if (supportsAnsi) _stdout.write('\x1B[${lines}B');
  }

  /// Moves the cursor right by [columns] columns.
  void cursorRight([int columns = 1]) {
    if (supportsAnsi) _stdout.write('\x1B[${columns}C');
  }

  /// Moves the cursor left by [columns] columns.
  void cursorLeft([int columns = 1]) {
    if (supportsAnsi) _stdout.write('\x1B[${columns}D');
  }

  /// Moves the cursor to the specified [row] and [column] (1-based).
  void cursorTo(int row, int column) {
    if (supportsAnsi) _stdout.write('\x1B[$row;${column}H');
  }

  /// Moves the cursor to the beginning of the current line.
  void cursorToColumn(int column) {
    if (supportsAnsi) _stdout.write('\x1B[${column}G');
  }

  /// Saves the current cursor position.
  void saveCursor() {
    if (supportsAnsi) _stdout.write('\x1B[s');
  }

  /// Restores the previously saved cursor position.
  void restoreCursor() {
    if (supportsAnsi) _stdout.write('\x1B[u');
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Screen Control
  // ─────────────────────────────────────────────────────────────────────────────

  /// Clears the entire screen.
  void clearScreen() {
    if (supportsAnsi) {
      _stdout.write('\x1B[2J');
      cursorTo(1, 1);
    }
  }

  /// Clears from the cursor to the end of the screen.
  void clearToEnd() {
    if (supportsAnsi) _stdout.write('\x1B[J');
  }

  /// Clears from the cursor to the beginning of the screen.
  void clearToStart() {
    if (supportsAnsi) _stdout.write('\x1B[1J');
  }

  /// Clears the current line.
  void clearLine() {
    if (supportsAnsi) _stdout.write('\x1B[2K\r');
  }

  /// Clears from the cursor to the end of the line.
  void clearLineToEnd() {
    if (supportsAnsi) _stdout.write('\x1B[K');
  }

  /// Clears from the cursor to the beginning of the line.
  void clearLineToStart() {
    if (supportsAnsi) _stdout.write('\x1B[1K');
  }

  /// Clears the previous [lines] lines.
  void clearPreviousLines(int lines) {
    if (!supportsAnsi) return;
    for (var i = 0; i < lines; i++) {
      cursorUp();
      clearLine();
    }
  }

  /// Scrolls the screen up by [lines] rows.
  void scrollUp([int lines = 1]) {
    if (supportsAnsi) _stdout.write('\x1B[${lines}S');
  }

  /// Scrolls the screen down by [lines] rows.
  void scrollDown([int lines = 1]) {
    if (supportsAnsi) _stdout.write('\x1B[${lines}T');
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Alternate Screen Buffer
  // ─────────────────────────────────────────────────────────────────────────────

  /// Switches to the alternate screen buffer.
  void enterAlternateScreen() {
    if (supportsAnsi) _stdout.write('\x1B[?1049h');
  }

  /// Returns to the main screen buffer.
  void exitAlternateScreen() {
    if (supportsAnsi) _stdout.write('\x1B[?1049l');
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Notifications
  // ─────────────────────────────────────────────────────────────────────────────

  /// Rings the terminal bell.
  void bell() {
    _stdout.write('\x07');
  }

  /// Sets the terminal title (may not work in all terminals).
  void setTitle(String title) {
    if (supportsAnsi) _stdout.write('\x1B]0;$title\x07');
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Input Control
  // ─────────────────────────────────────────────────────────────────────────────

  /// Enables raw mode for character-by-character input.
  ///
  /// Returns a function to restore the original mode.
  RawModeState enableRawMode() {
    final wasEchoMode = _stdin.echoMode;
    final wasLineMode = _stdin.lineMode;

    try {
      _stdin.echoMode = false;
      _stdin.lineMode = false;
    } catch (_) {
      // Terminal doesn't support raw mode
    }

    return RawModeState._(
      stdin: _stdin,
      wasEchoMode: wasEchoMode,
      wasLineMode: wasLineMode,
    );
  }

  /// Reads a single key press (requires raw mode).
  int readKey() {
    return _stdin.readByteSync();
  }
}

/// Saved terminal state for raw mode.
class RawModeState {
  RawModeState._({
    required io.Stdin stdin,
    required this.wasEchoMode,
    required this.wasLineMode,
  }) : _stdin = stdin;

  final io.Stdin _stdin;
  final bool wasEchoMode;
  final bool wasLineMode;

  /// Restores the original terminal mode.
  void restore() {
    try {
      _stdin.echoMode = wasEchoMode;
      _stdin.lineMode = wasLineMode;
    } catch (_) {
      // Ignore errors
    }
  }
}

/// Key codes for common keys.
class KeyCode {
  KeyCode._();

  static const enter = 10;
  static const enterCR = 13;
  static const escape = 27;
  static const space = 32;
  static const backspace = 127;
  static const delete = 8;
  static const tab = 9;

  static const ctrlC = 3;
  static const ctrlD = 4;
  static const ctrlZ = 26;

  // Arrow keys (after escape + '[')
  static const arrowUp = 65;
  static const arrowDown = 66;
  static const arrowRight = 67;
  static const arrowLeft = 68;

  /// Checks if a byte is the start of an escape sequence.
  static bool isEscape(int byte) => byte == escape;

  /// Checks if a byte is a printable ASCII character.
  static bool isPrintable(int byte) => byte >= 32 && byte < 127;
}
