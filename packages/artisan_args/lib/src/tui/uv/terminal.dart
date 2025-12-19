import 'dart:async';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'buffer.dart';
import 'cancelreader.dart';
import 'capabilities.dart';
import 'cell.dart';
import 'event.dart';
import 'environ.dart';
import 'geometry.dart';
import 'iterm2_drawable.dart';
import 'kitty_drawable.dart';
import 'screen.dart';
import 'sixel_drawable.dart';
import 'terminal_reader.dart';
import 'terminal_renderer.dart';
import '../../unicode/width.dart';
import 'winch.dart';

/// Terminal represents a terminal screen that can be manipulated and drawn to.
///
/// Upstream: `third_party/ultraviolet/terminal.go` (`Terminal`).
class Terminal implements Screen, FillAreaScreen, ClearableScreen, CloneableScreen, CloneAreaScreen {
  Terminal({
    Stream<List<int>>? input,
    IOSink? output,
    List<String>? env,
  }) : _input = input ?? stdin,
       _output = output ?? stdout,
       _env = env ?? Platform.environment.entries.map((e) => '${e.key}=${e.value}').toList(),
       _buf = Buffer.create(0, 0),
       capabilities = TerminalCapabilities(env: env ?? Platform.environment.entries.map((e) => '${e.key}=${e.value}').toList()) {
    final isTty = _output is Stdout && (_output).hasTerminal;
    _renderer = TerminalRenderer(_output, env: _env, isTty: isTty);
    _reader = TerminalReader(
      CancelReader(_input),
      term: Environ(_env).getenv('TERM'),
    );
    _winch = SizeNotifier();
  }

  final Stream<List<int>> _input;
  final IOSink _output;
  final List<String> _env;
  
  late final TerminalRenderer _renderer;
  late final TerminalReader _reader;
  late final SizeNotifier _winch;
  
  final Buffer _buf;
  final TerminalCapabilities capabilities;
  bool _running = false;
  bool _inAltScreen = false;
  bool _mouseEnabled = false;
  bool _bracketedPasteEnabled = false;
  bool _focusReportingEnabled = false;
  bool _cursorHidden = false;
  int _keyboardEnhancements = 0;
  
  final _eventController = StreamController<Event>.broadcast();
  StreamSubscription? _readerSubscription;
  StreamSubscription? _winchSubscription;
  StreamSubscription? _sigintSubscription;

  /// Returns a stream of events from the terminal.
  Stream<Event> get events => _eventController.stream;

  /// Starts the terminal.
  Future<void> start() async {
    if (_running) return;
    _running = true;

    // Enter raw mode.
    if (_input == stdin) {
      try {
        if (stdin.hasTerminal) {
          stdin.echoMode = false;
          stdin.lineMode = false;
        }
      } catch (_) {}
    }

    // Handle SIGINT to ensure terminal state is restored.
    _sigintSubscription = ProcessSignal.sigint.watch().listen((_) {
      stop();
      exit(0);
    });

    _reader.start();
    _readerSubscription = _reader.events.listen((event) {
      if (event is WindowSizeEvent) {
        resize(event.width, event.height);
      }
      capabilities.updateFromEvent(event);
      _eventController.add(event);
    });

    _winch.start();
    _winchSubscription = _winch.stream.listen((_) async {
      final size = await getSize();
      _eventController.add(WindowSizeEvent(width: size.width, height: size.height));
    });

    // Initial size.
    final size = await getSize();
    _buf.resize(size.width, size.height);
    _renderer.resize(size.width, size.height);
    _eventController.add(WindowSizeEvent(width: size.width, height: size.height));

    // Query capabilities.
    queryCapabilities();
  }

  /// Stops the terminal and restores the original state.
  Future<void> stop() async {
    if (!_running) return;
    _running = false;

    // Restore terminal state in reverse order.
    if (_keyboardEnhancements != 0) disableKeyboardEnhancements();
    if (_mouseEnabled) disableMouse();
    if (_bracketedPasteEnabled) disableBracketedPaste();
    if (_focusReportingEnabled) disableFocusReporting();
    if (_cursorHidden) showCursor();
    if (_inAltScreen) exitAltScreen();

    // Restore terminal mode.
    if (_input == stdin) {
      try {
        if (stdin.hasTerminal) {
          stdin.echoMode = true;
          stdin.lineMode = true;
        }
      } catch (_) {}
    }

    await _readerSubscription?.cancel();
    await _winchSubscription?.cancel();
    await _sigintSubscription?.cancel();
    _winch.stop();
    await _reader.close();
  }

  /// Returns the current size of the terminal.
  Future<Size> getSize() async {
    if (_output == stdout && stdout.hasTerminal) {
      return Size(width: stdout.terminalColumns, height: stdout.terminalLines);
    }
    // Fallback to winch or default.
    final (w, h) = _winch.getSize();
    return Size(width: w, height: h);
  }

  /// Resizes the terminal buffer.
  void resize(int width, int height) {
    _buf.resize(width, height);
    _renderer.resize(width, height);
  }
  /// Moves the cursor to the given position.
  void moveTo(int x, int y) {
    _renderer.moveTo(x, y);
  }

  /// Hides the cursor.
  void hideCursor() {
    _cursorHidden = true;
    _renderer.hideCursor();
    _renderer.flush();
  }

  /// Shows the cursor.
  void showCursor() {
    _cursorHidden = false;
    _renderer.showCursor();
    _renderer.flush();
  }

  /// Enables mouse tracking.
  void enableMouse() {
    _mouseEnabled = true;
    _renderer.enableMouseAllEvents();
    _renderer.flush();
  }

  /// Disables mouse tracking.
  void disableMouse() {
    _mouseEnabled = false;
    _renderer.disableMouseAllEvents();
    _renderer.flush();
  }

  /// Enables bracketed paste mode.
  void enableBracketedPaste() {
    _bracketedPasteEnabled = true;
    _renderer.enableBracketedPaste();
    _renderer.flush();
  }

  /// Disables bracketed paste mode.
  void disableBracketedPaste() {
    _bracketedPasteEnabled = false;
    _renderer.disableBracketedPaste();
    _renderer.flush();
  }

  /// Enables focus reporting.
  void enableFocusReporting() {
    _focusReportingEnabled = true;
    _renderer.enableFocusReporting();
    _renderer.flush();
  }

  /// Disables focus reporting.
  void disableFocusReporting() {
    _focusReportingEnabled = false;
    _renderer.disableFocusReporting();
    _renderer.flush();
  }

  /// Enables keyboard enhancements (Kitty Keyboard Protocol).
  void enableKeyboardEnhancements(int flags) {
    _keyboardEnhancements = flags;
    _renderer.pushKeyboardEnhancements(flags);
    _renderer.flush();
  }

  /// Disables keyboard enhancements (Kitty Keyboard Protocol).
  void disableKeyboardEnhancements() {
    _keyboardEnhancements = 0;
    _renderer.popKeyboardEnhancements();
    _renderer.flush();
  }

  /// Queries terminal capabilities.
  void queryCapabilities() {
    _renderer.queryPrimaryDeviceAttributes();
    _renderer.queryKittyGraphics();
    _renderer.queryKeyboardEnhancements();
    _renderer.queryBackgroundColor();
    _renderer.flush();
  }


  /// Clears the physical screen on the next draw.
  void clearScreen() {
    _renderer.erase();
  }

  /// Flushes any pending output to the terminal.
  void flush() {
    _renderer.flush();
  }

  /// Draws the current buffer to the terminal.
  void draw() {
    _renderer.render(_buf);
    _renderer.flush();
  }

  /// Returns the terminal buffer.
  Buffer get buffer => _buf;

  @override
  Rectangle bounds() => _buf.bounds();

  @override
  Cell? cellAt(int x, int y) => _buf.cellAt(x, y);

  /// Sets a cell in the buffer.
  @override
  void setCell(int x, int y, Cell? cell) {
    _buf.setCell(x, y, cell);
  }

  @override
  void fillArea(Cell? cell, Rectangle area) {
    _buf.fillArea(cell, area);
  }

  @override
  void clear() {
    _buf.clear();
  }

  @override
  Buffer clone() => _buf.clone();

  @override
  Buffer? cloneArea(Rectangle area) => _buf.cloneArea(area);

  @override
  WidthMethod widthMethod() => WidthMethod.wcwidth;

  /// Enters the alternate screen buffer.
  void enterAltScreen() {
    _inAltScreen = true;
    _renderer.enterAltScreen();
    _renderer.flush();
  }

  /// Exits the alternate screen buffer.
  void exitAltScreen() {
    _inAltScreen = false;
    _renderer.exitAltScreen();
    _renderer.flush();
  }

  /// Returns the best [Drawable] for the given image based on terminal capabilities.
  Drawable bestImageDrawable(img.Image image, {int? columns, int? rows}) {
    if (capabilities.hasKittyGraphics) {
      return KittyImageDrawable(image, columns: columns, rows: rows);
    }
    if (capabilities.hasITerm2) {
      return ITerm2ImageDrawable(image, columns: columns, rows: rows);
    }
    if (capabilities.hasSixel) {
      return SixelImageDrawable(image, columns: columns, rows: rows);
    }
    // Fallback to nothing or a block-based renderer if we had one.
    return KittyImageDrawable(image, columns: columns, rows: rows);
  }

  // NOTE: environment variable lookups are handled by [Environ].
}
