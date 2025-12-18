import 'dart:async';
import 'dart:io' as io;

import 'ansi.dart';

/// Abstract terminal interface for all terminal operations.
///
/// This interface provides a unified API for terminal control used by both
/// static components and the TUI runtime. Implementations can target different
/// platforms or provide testing capabilities.
///
/// ```dart
/// // Use the standard implementation
/// final terminal = StdioTerminal();
///
/// // Basic operations
/// terminal.write('Hello');
/// terminal.writeln(' World');
///
/// // Cursor control
/// terminal.hideCursor();
/// terminal.moveCursor(10, 5);
/// terminal.showCursor();
///
/// // Screen control
/// terminal.clearScreen();
/// terminal.enterAltScreen();
/// ```
abstract class Terminal {
  // ─────────────────────────────────────────────────────────────────────────────
  // Terminal Information
  // ─────────────────────────────────────────────────────────────────────────────

  /// The terminal width in columns.
  int get width;

  /// The terminal height in rows.
  int get height;

  /// The terminal size as a record of (width, height).
  ({int width, int height}) get size => (width: width, height: height);

  /// Whether the terminal supports ANSI escape sequences.
  bool get supportsAnsi;

  /// Whether output is connected to a real terminal (vs piped/redirected).
  bool get isTerminal;

  // ─────────────────────────────────────────────────────────────────────────────
  // Output Operations
  // ─────────────────────────────────────────────────────────────────────────────

  /// Writes text to the terminal without a trailing newline.
  void write(String text);

  /// Writes text to the terminal followed by a newline.
  void writeln([String text = '']);

  /// Flushes any buffered output.
  Future<void> flush();

  // ─────────────────────────────────────────────────────────────────────────────
  // Cursor Visibility
  // ─────────────────────────────────────────────────────────────────────────────

  /// Hides the terminal cursor.
  void hideCursor();

  /// Shows the terminal cursor.
  void showCursor();

  /// Saves the current cursor position.
  void saveCursor();

  /// Restores the previously saved cursor position.
  void restoreCursor();

  // ─────────────────────────────────────────────────────────────────────────────
  // Cursor Movement
  // ─────────────────────────────────────────────────────────────────────────────

  /// Moves the cursor to the specified [row] and [col] (1-based).
  void moveCursor(int row, int col);

  /// Moves the cursor to home position (1, 1).
  void cursorHome();

  /// Moves the cursor up by [lines] rows.
  void cursorUp([int lines = 1]);

  /// Moves the cursor down by [lines] rows.
  void cursorDown([int lines = 1]);

  /// Moves the cursor right by [cols] columns.
  void cursorRight([int cols = 1]);

  /// Moves the cursor left by [cols] columns.
  void cursorLeft([int cols = 1]);

  /// Moves the cursor to the specified [col] on the current line (1-based).
  void cursorToColumn(int col);

  // ─────────────────────────────────────────────────────────────────────────────
  // Screen Control
  // ─────────────────────────────────────────────────────────────────────────────

  /// Clears the entire screen.
  void clearScreen();

  /// Clears from the cursor to the end of the screen.
  void clearToEnd();

  /// Clears from the cursor to the beginning of the screen.
  void clearToStart();

  /// Clears the current line.
  void clearLine();

  /// Clears from the cursor to the end of the line.
  void clearLineToEnd();

  /// Clears from the cursor to the beginning of the line.
  void clearLineToStart();

  /// Clears the specified number of lines above the cursor.
  void clearPreviousLines(int lines);

  /// Scrolls the screen up by [lines] rows.
  void scrollUp([int lines = 1]);

  /// Scrolls the screen down by [lines] rows.
  void scrollDown([int lines = 1]);

  // ─────────────────────────────────────────────────────────────────────────────
  // Alternate Screen Buffer
  // ─────────────────────────────────────────────────────────────────────────────

  /// Enters the alternate screen buffer (fullscreen mode).
  void enterAltScreen();

  /// Exits the alternate screen buffer.
  void exitAltScreen();

  /// Whether the terminal is currently in alternate screen mode.
  bool get isAltScreen;

  // ─────────────────────────────────────────────────────────────────────────────
  // Input Mode Control
  // ─────────────────────────────────────────────────────────────────────────────

  /// Enables raw mode (character-by-character input, no echo).
  ///
  /// Returns a [RawModeGuard] that can be used to restore the original mode.
  RawModeGuard enableRawMode();

  /// Disables raw mode and restores original terminal settings.
  void disableRawMode();

  /// Whether raw mode is currently enabled.
  bool get isRawMode;

  // ─────────────────────────────────────────────────────────────────────────────
  // Mouse Tracking
  // ─────────────────────────────────────────────────────────────────────────────

  /// Enables mouse tracking.
  ///
  /// When enabled, mouse events (clicks, motion, wheel) are reported as
  /// escape sequences that can be parsed from input.
  void enableMouse();

  /// Enables mouse cell motion tracking (clicks, wheel, drag).
  void enableMouseCellMotion();

  /// Enables mouse all motion tracking (includes hover events).
  void enableMouseAllMotion();

  /// Disables mouse tracking.
  void disableMouse();

  /// Whether mouse tracking is currently enabled.
  bool get isMouseEnabled;

  // ─────────────────────────────────────────────────────────────────────────────
  // Bracketed Paste Mode
  // ─────────────────────────────────────────────────────────────────────────────

  /// Enables bracketed paste mode.
  ///
  /// When enabled, pasted content is wrapped in escape sequences, allowing
  /// it to be distinguished from typed input.
  void enableBracketedPaste();

  /// Disables bracketed paste mode.
  void disableBracketedPaste();

  /// Whether bracketed paste mode is currently enabled.
  bool get isBracketedPasteEnabled;

  // ─────────────────────────────────────────────────────────────────────────────
  // Focus Reporting
  // ─────────────────────────────────────────────────────────────────────────────

  /// Enables focus reporting.
  ///
  /// When enabled, focus gain/loss events are reported as escape sequences.
  void enableFocusReporting();

  /// Disables focus reporting.
  void disableFocusReporting();

  // ─────────────────────────────────────────────────────────────────────────────
  // Window/Terminal Control
  // ─────────────────────────────────────────────────────────────────────────────

  /// Sets the terminal window title.
  void setTitle(String title);

  /// Rings the terminal bell.
  void bell();

  // ─────────────────────────────────────────────────────────────────────────────
  // Input Stream (for TUI mode)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Stream of raw input bytes from the terminal.
  ///
  /// This is primarily used by the TUI runtime for async input handling.
  /// For synchronous input, use [readByte] or [readLine].
  Stream<List<int>> get input;

  /// Reads a single byte from input (blocking).
  ///
  /// Returns -1 on EOF.
  int readByte();

  /// Reads a line of input (blocking).
  ///
  /// Returns null on EOF.
  String? readLine();

  // ─────────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────────

  /// Disposes of terminal resources and restores original state.
  ///
  /// This should restore:
  /// - Cursor visibility
  /// - Raw mode
  /// - Alt screen
  /// - Mouse tracking
  /// - Bracketed paste
  void dispose();
}

/// Guard object returned by [Terminal.enableRawMode].
///
/// Can be used to restore the original terminal mode.
class RawModeGuard {
  /// Creates a raw mode guard.
  RawModeGuard({
    required this.wasEchoMode,
    required this.wasLineMode,
    required void Function() restore,
  }) : _restore = restore;

  /// The original echo mode setting.
  final bool wasEchoMode;

  /// The original line mode setting.
  final bool wasLineMode;

  final void Function() _restore;

  /// Restores the original terminal mode.
  void restore() => _restore();
}

/// Standard terminal implementation using dart:io.
///
/// Works on Unix-like systems (Linux, macOS) and Windows.
class StdioTerminal implements Terminal {
  /// Creates a terminal using the standard I/O streams.
  ///
  /// If [stdout] or [stdin] are not provided, uses the process's
  /// standard streams.
  StdioTerminal({io.Stdout? stdout, io.Stdin? stdin})
    : _stdout = stdout ?? io.stdout,
      _stdin = stdin ?? io.stdin;

  final io.Stdout _stdout;
  final io.Stdin _stdin;

  // Stdout flush in Dart binds the underlying StreamSink; any concurrent write
  // while a flush is in flight will throw:
  //   StateError: Bad state: StreamSink is bound to a stream
  //
  // We coalesce and serialize flushes, and buffer writes that happen while a
  // flush is in progress so TUI control messages (e.g. resize handlers) cannot
  // crash the program.
  Future<void>? _stdoutFlushInFlight;
  final StringBuffer _stdoutPending = StringBuffer();
  int _stdoutPendingLen = 0;

  // State tracking
  bool _rawModeEnabled = false;
  bool _altScreenEnabled = false;
  bool _mouseEnabled = false;
  bool _bracketedPasteEnabled = false;

  // Original terminal settings
  bool? _originalEchoMode;
  bool? _originalLineMode;

  // Input stream management
  StreamController<List<int>>? _inputController;
  StreamSubscription<List<int>>? _inputSubscription;

  // ─────────────────────────────────────────────────────────────────────────────
  // Terminal Information
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  int get width {
    try {
      return _stdout.hasTerminal ? _stdout.terminalColumns : 80;
    } catch (_) {
      return 80;
    }
  }

  @override
  int get height {
    try {
      return _stdout.hasTerminal ? _stdout.terminalLines : 24;
    } catch (_) {
      return 24;
    }
  }

  @override
  ({int width, int height}) get size => (width: width, height: height);

  @override
  bool get supportsAnsi {
    try {
      return _stdout.supportsAnsiEscapes;
    } catch (_) {
      return false;
    }
  }

  @override
  bool get isTerminal {
    try {
      return _stdout.hasTerminal;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Output Operations
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void write(String text) {
    if (text.isEmpty) return;
    if (_stdoutFlushInFlight != null) {
      _stdoutPending.write(text);
      _stdoutPendingLen += text.length;
      return;
    }
    try {
      _stdout.write(text);
    } on StateError catch (e) {
      if (_isStdoutBoundToStream(e)) {
        _stdoutPending.write(text);
        _stdoutPendingLen += text.length;
        unawaited(flush());
        return;
      }
      rethrow;
    }
  }

  @override
  void writeln([String text = '']) =>
      write('$text${io.Platform.lineTerminator}');

  @override
  Future<void> flush() {
    final existing = _stdoutFlushInFlight;
    if (existing != null) return existing;

    final f = _flushStdoutAll();
    _stdoutFlushInFlight = f.whenComplete(() {
      _stdoutFlushInFlight = null;
    });
    return _stdoutFlushInFlight!;
  }

  static bool _isStdoutBoundToStream(StateError e) =>
      e.message == 'Bad state: StreamSink is bound to a stream';

  Future<void> _flushStdoutAll() async {
    // Keep flushing until no more writes arrived during the previous flush.
    while (true) {
      if (_stdoutPendingLen != 0) {
        final pending = _stdoutPending.toString();
        _stdoutPending.clear();
        _stdoutPendingLen = 0;

        while (true) {
          try {
            _stdout.write(pending);
            break;
          } on StateError catch (e) {
            if (_isStdoutBoundToStream(e)) {
              await Future<void>.delayed(Duration.zero);
              continue;
            }
            rethrow;
          }
        }
      }

      while (true) {
        try {
          await _stdout.flush();
          break;
        } on StateError catch (e) {
          if (_isStdoutBoundToStream(e)) {
            await Future<void>.delayed(Duration.zero);
            continue;
          }
          rethrow;
        }
      }

      if (_stdoutPendingLen == 0) return;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Cursor Visibility
  // ─────────────────────────────────────────────────────────────────────────────

  // Cursor state tracking
  bool _cursorVisible = true;

  @override
  void hideCursor() {
    if (!_cursorVisible || !supportsAnsi) return;
    write(Ansi.cursorHide);
    _cursorVisible = false;
  }

  @override
  void showCursor() {
    if (_cursorVisible || !supportsAnsi) return;
    write(Ansi.cursorShow);
    _cursorVisible = true;
  }

  @override
  void saveCursor() {
    if (supportsAnsi) write(Ansi.cursorSave);
  }

  @override
  void restoreCursor() {
    if (supportsAnsi) write(Ansi.cursorRestore);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Cursor Movement
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void moveCursor(int row, int col) {
    if (supportsAnsi) write(Ansi.cursorTo(row, col));
  }

  @override
  void cursorHome() {
    if (supportsAnsi) write(Ansi.cursorHome);
  }

  @override
  void cursorUp([int lines = 1]) {
    if (supportsAnsi) write(Ansi.cursorUpBy(lines));
  }

  @override
  void cursorDown([int lines = 1]) {
    if (supportsAnsi) write(Ansi.cursorDownBy(lines));
  }

  @override
  void cursorRight([int cols = 1]) {
    if (supportsAnsi) write(Ansi.cursorRightBy(cols));
  }

  @override
  void cursorLeft([int cols = 1]) {
    if (supportsAnsi) write(Ansi.cursorLeftBy(cols));
  }

  @override
  void cursorToColumn(int col) {
    if (supportsAnsi) write(Ansi.cursorToColumn(col));
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Screen Control
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void clearScreen() {
    if (!supportsAnsi) return;
    write(Ansi.clearScreen);
    cursorHome();
  }

  @override
  void clearToEnd() {
    if (supportsAnsi) write(Ansi.clearScreenToEnd);
  }

  @override
  void clearToStart() {
    if (supportsAnsi) write(Ansi.clearScreenToStart);
  }

  @override
  void clearLine() {
    if (supportsAnsi) write('${Ansi.clearLine}\r');
  }

  @override
  void clearLineToEnd() {
    if (supportsAnsi) write(Ansi.clearLineToEnd);
  }

  @override
  void clearLineToStart() {
    if (supportsAnsi) write(Ansi.clearLineToStart);
  }

  @override
  void clearPreviousLines(int lines) {
    if (!supportsAnsi) return;
    for (var i = 0; i < lines; i++) {
      cursorUp();
      clearLine();
    }
  }

  @override
  void scrollUp([int lines = 1]) {
    if (supportsAnsi) write(Ansi.scrollUpBy(lines));
  }

  @override
  void scrollDown([int lines = 1]) {
    if (supportsAnsi) write(Ansi.scrollDownBy(lines));
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Alternate Screen Buffer
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void enterAltScreen() {
    if (_altScreenEnabled || !supportsAnsi) return;
    write(Ansi.altScreenEnter);
    _altScreenEnabled = true;
  }

  @override
  void exitAltScreen() {
    if (!_altScreenEnabled || !supportsAnsi) return;
    write(Ansi.altScreenExit);
    _altScreenEnabled = false;
  }

  @override
  bool get isAltScreen => _altScreenEnabled;

  // ─────────────────────────────────────────────────────────────────────────────
  // Input Mode Control
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  RawModeGuard enableRawMode() {
    bool wasEchoMode = true;
    bool wasLineMode = true;

    if (!_rawModeEnabled) {
      try {
        _originalEchoMode = _stdin.echoMode;
        _originalLineMode = _stdin.lineMode;
        wasEchoMode = _originalEchoMode ?? true;
        wasLineMode = _originalLineMode ?? true;
        _stdin.echoMode = false;
        _stdin.lineMode = false;
        _rawModeEnabled = true;
      } catch (_) {
        // Terminal doesn't support raw mode (e.g., piped input)
      }
    }

    return RawModeGuard(
      wasEchoMode: wasEchoMode,
      wasLineMode: wasLineMode,
      restore: disableRawMode,
    );
  }

  @override
  void disableRawMode() {
    if (!_rawModeEnabled) return;

    try {
      if (_originalEchoMode != null) {
        _stdin.echoMode = _originalEchoMode!;
      }
      if (_originalLineMode != null) {
        _stdin.lineMode = _originalLineMode!;
      }
      _rawModeEnabled = false;
    } catch (_) {
      // Ignore errors during restoration
    }
  }

  @override
  bool get isRawMode => _rawModeEnabled;

  // ─────────────────────────────────────────────────────────────────────────────
  // Mouse Tracking
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void enableMouse() {
    if (_mouseEnabled || !supportsAnsi) return;
    // Enable normal mouse tracking + button events + SGR extended mode
    write(Ansi.mouseEnableNormal);
    write(Ansi.mouseEnableButton);
    write(Ansi.mouseEnableSgr);
    _mouseEnabled = true;
  }

  @override
  void enableMouseCellMotion() {
    enableMouse();
  }

  @override
  void enableMouseAllMotion() {
    if (!supportsAnsi) return;
    // All motion includes hover events
    write(Ansi.mouseEnableAny);
    enableMouse();
  }

  @override
  void disableMouse() {
    if (!_mouseEnabled || !supportsAnsi) return;
    write(Ansi.mouseDisableSgr);
    write(Ansi.mouseDisableButton);
    write(Ansi.mouseDisableNormal);
    write(Ansi.mouseDisableAny);
    _mouseEnabled = false;
  }

  @override
  bool get isMouseEnabled => _mouseEnabled;

  // ─────────────────────────────────────────────────────────────────────────────
  // Bracketed Paste Mode
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void enableBracketedPaste() {
    if (_bracketedPasteEnabled || !supportsAnsi) return;
    write(Ansi.bracketedPasteEnable);
    _bracketedPasteEnabled = true;
  }

  @override
  void disableBracketedPaste() {
    if (!_bracketedPasteEnabled || !supportsAnsi) return;
    write(Ansi.bracketedPasteDisable);
    _bracketedPasteEnabled = false;
  }

  @override
  bool get isBracketedPasteEnabled => _bracketedPasteEnabled;

  // ─────────────────────────────────────────────────────────────────────────────
  // Focus Reporting
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void enableFocusReporting() {
    if (supportsAnsi) write(Ansi.focusEnable);
  }

  @override
  void disableFocusReporting() {
    if (supportsAnsi) write(Ansi.focusDisable);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Window/Terminal Control
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void setTitle(String title) {
    if (supportsAnsi) write(Ansi.setTitle(title));
  }

  @override
  void bell() => write(Ansi.bell);

  // ─────────────────────────────────────────────────────────────────────────────
  // Input Stream
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Stream<List<int>> get input {
    _inputController ??= StreamController<List<int>>.broadcast(
      onListen: _startInputListener,
      onCancel: _stopInputListener,
    );
    return _inputController!.stream;
  }

  void _startInputListener() {
    _inputSubscription ??= _stdin.listen(
      (data) => _inputController?.add(data),
      onError: (error) => _inputController?.addError(error),
      cancelOnError: false,
    );
  }

  void _stopInputListener() {
    _inputSubscription?.cancel();
    _inputSubscription = null;
  }

  @override
  int readByte() => _stdin.readByteSync();

  @override
  String? readLine() => _stdin.readLineSync();

  // ─────────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    // Restore terminal state in reverse order of enabling
    if (_bracketedPasteEnabled) disableBracketedPaste();
    if (_mouseEnabled) disableMouse();
    if (!_cursorVisible) showCursor();
    if (_altScreenEnabled) exitAltScreen();
    if (_rawModeEnabled) disableRawMode();

    // Stop input listener
    _stopInputListener();
    _inputController?.close();
    _inputController = null;
  }
}

/// A terminal that captures output to a string buffer (for testing).
///
/// This implementation does not interact with any real terminal and is
/// useful for unit testing components that use terminal operations.
class StringTerminal implements Terminal {
  /// Creates a string terminal with optional configuration.
  StringTerminal({
    this.terminalWidth = 80,
    this.terminalHeight = 24,
    this.ansiSupport = true,
  });

  /// The simulated terminal width.
  final int terminalWidth;

  /// The simulated terminal height.
  final int terminalHeight;

  /// Whether to simulate ANSI support.
  final bool ansiSupport;

  /// The captured output.
  final StringBuffer buffer = StringBuffer();

  /// List of operations performed (for testing).
  final List<String> operations = [];

  // State tracking
  bool _rawModeEnabled = false;
  bool _altScreenEnabled = false;
  bool _mouseEnabled = false;
  bool _bracketedPasteEnabled = false;

  // Input simulation
  final _inputController = StreamController<List<int>>.broadcast();
  final List<int> _inputQueue = [];

  /// Clears the output buffer and operation log.
  void clear() {
    buffer.clear();
    operations.clear();
  }

  /// The captured output as a string.
  String get output => buffer.toString();

  /// Simulates input by adding bytes to the input queue.
  void simulateInput(List<int> bytes) {
    _inputQueue.addAll(bytes);
    _inputController.add(bytes);
  }

  /// Simulates typing a string.
  void simulateTyping(String text) {
    simulateInput(text.codeUnits);
  }

  @override
  int get width => terminalWidth;

  @override
  int get height => terminalHeight;

  @override
  ({int width, int height}) get size => (width: width, height: height);

  @override
  bool get supportsAnsi => ansiSupport;

  @override
  bool get isTerminal => true;

  @override
  void write(String text) {
    buffer.write(text);
    operations.add('write: $text');
  }

  @override
  void writeln([String text = '']) {
    buffer.writeln(text);
    operations.add('writeln: $text');
  }

  @override
  Future<void> flush() async {
    operations.add('flush');
  }

  @override
  void hideCursor() {
    operations.add('hideCursor');
  }

  @override
  void showCursor() {
    operations.add('showCursor');
  }

  @override
  void saveCursor() => operations.add('saveCursor');

  @override
  void restoreCursor() => operations.add('restoreCursor');

  @override
  void moveCursor(int row, int col) => operations.add('moveCursor($row, $col)');

  @override
  void cursorHome() => operations.add('cursorHome');

  @override
  void cursorUp([int lines = 1]) => operations.add('cursorUp($lines)');

  @override
  void cursorDown([int lines = 1]) => operations.add('cursorDown($lines)');

  @override
  void cursorRight([int cols = 1]) => operations.add('cursorRight($cols)');

  @override
  void cursorLeft([int cols = 1]) => operations.add('cursorLeft($cols)');

  @override
  void cursorToColumn(int col) => operations.add('cursorToColumn($col)');

  @override
  void clearScreen() => operations.add('clearScreen');

  @override
  void clearToEnd() => operations.add('clearToEnd');

  @override
  void clearToStart() => operations.add('clearToStart');

  @override
  void clearLine() => operations.add('clearLine');

  @override
  void clearLineToEnd() => operations.add('clearLineToEnd');

  @override
  void clearLineToStart() => operations.add('clearLineToStart');

  @override
  void clearPreviousLines(int lines) =>
      operations.add('clearPreviousLines($lines)');

  @override
  void scrollUp([int lines = 1]) => operations.add('scrollUp($lines)');

  @override
  void scrollDown([int lines = 1]) => operations.add('scrollDown($lines)');

  @override
  void enterAltScreen() {
    _altScreenEnabled = true;
    operations.add('enterAltScreen');
  }

  @override
  void exitAltScreen() {
    _altScreenEnabled = false;
    operations.add('exitAltScreen');
  }

  @override
  bool get isAltScreen => _altScreenEnabled;

  @override
  RawModeGuard enableRawMode() {
    _rawModeEnabled = true;
    operations.add('enableRawMode');
    return RawModeGuard(
      wasEchoMode: true,
      wasLineMode: true,
      restore: disableRawMode,
    );
  }

  @override
  void disableRawMode() {
    _rawModeEnabled = false;
    operations.add('disableRawMode');
  }

  @override
  bool get isRawMode => _rawModeEnabled;

  @override
  void enableMouse() {
    _mouseEnabled = true;
    operations.add('enableMouse');
  }

  @override
  void enableMouseCellMotion() {
    _mouseEnabled = true;
    operations.add('enableMouseCellMotion');
  }

  @override
  void enableMouseAllMotion() {
    _mouseEnabled = true;
    operations.add('enableMouseAllMotion');
  }

  @override
  void disableMouse() {
    _mouseEnabled = false;
    operations.add('disableMouse');
  }

  @override
  bool get isMouseEnabled => _mouseEnabled;

  @override
  void enableBracketedPaste() {
    _bracketedPasteEnabled = true;
    operations.add('enableBracketedPaste');
  }

  @override
  void disableBracketedPaste() {
    _bracketedPasteEnabled = false;
    operations.add('disableBracketedPaste');
  }

  @override
  bool get isBracketedPasteEnabled => _bracketedPasteEnabled;

  @override
  void enableFocusReporting() => operations.add('enableFocusReporting');

  @override
  void disableFocusReporting() => operations.add('disableFocusReporting');

  @override
  void setTitle(String title) => operations.add('setTitle($title)');

  @override
  void bell() => operations.add('bell');

  @override
  Stream<List<int>> get input => _inputController.stream;

  @override
  int readByte() {
    if (_inputQueue.isEmpty) return -1;
    return _inputQueue.removeAt(0);
  }

  @override
  String? readLine() {
    if (_inputQueue.isEmpty) return null;
    final lineEnd = _inputQueue.indexOf(10); // newline
    if (lineEnd == -1) {
      final result = String.fromCharCodes(_inputQueue);
      _inputQueue.clear();
      return result;
    }
    final result = String.fromCharCodes(_inputQueue.sublist(0, lineEnd));
    _inputQueue.removeRange(0, lineEnd + 1);
    return result;
  }

  @override
  void dispose() {
    operations.add('dispose');
    _inputController.close();
  }
}
