import 'dart:async';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:artisanal/src/colorprofile/profile.dart' as cp;
import 'ansi.dart';
import 'buffer.dart';
import 'cancelreader.dart';
import 'capabilities.dart';
import 'cell.dart';
import 'drawable.dart';
import 'event.dart';
import 'environ.dart';
import 'geometry.dart';
import 'iterm2_drawable.dart';
import 'kitty_drawable.dart';
import 'screen.dart';
import 'sixel_drawable.dart';
import 'halfblock_drawable.dart';
import 'terminal_reader.dart';
import 'terminal_renderer.dart';
import '../unicode/width.dart';
import 'winch.dart';

export 'buffer.dart';
export 'capabilities.dart';
export 'cell.dart';
export 'event.dart';
export 'geometry.dart';
export 'screen.dart';
export 'drawable.dart';
export 'styled_string.dart';
export 'kitty_drawable.dart';
export 'iterm2_drawable.dart';
export 'sixel_drawable.dart';
export 'halfblock_drawable.dart';

/// Terminal represents a terminal screen that can be manipulated and drawn to.
///
/// It manages a [Buffer] representing the screen state, handles input event
/// decoding, and provides methods for drawing text, shapes, and images.
///
/// Upstream: `third_party/ultraviolet/terminal.go` (`Terminal`).
class Terminal implements Screen, FillableScreen, FillAreaScreen, ClearableScreen, CloneableScreen, CloneAreaScreen {
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
    _renderer = UvTerminalRenderer(_output, env: _env, isTty: isTty);
    _reader = TerminalReader(
      CancelReader(_input),
      term: Environ(_env).getenv('TERM'),
    );
    _winch = SizeNotifier();
  }

  final Stream<List<int>> _input;
  final IOSink _output;
  final List<String> _env;
  
  late final UvTerminalRenderer _renderer;
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
  final List<String> _prepend = [];
  
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
      final size = _winch.getWindowSize();
      _eventController.add(WindowSizeEvent(
        width: size.cells.width,
        height: size.cells.height,
        widthPx: size.pixels.width,
        heightPx: size.pixels.height,
      ));
    });

    // Initial size.
    final size = _winch.getWindowSize();
    _buf.resize(size.cells.width, size.cells.height);
    _renderer.resize(size.cells.width, size.cells.height);
    _eventController.add(WindowSizeEvent(
      width: size.cells.width,
      height: size.cells.height,
      widthPx: size.pixels.width,
      heightPx: size.pixels.height,
    ));

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
    
    if (_inAltScreen) {
      exitAltScreen();
    } else {
      // Go to the bottom of the screen.
      _renderer.moveTo(0, _buf.height() - 1);
      _renderer.writeString('\r${UvAnsi.eraseScreenBelow}');
      _renderer.flush();
    }

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
    final size = _winch.getWindowSize();
    return Size(
      width: size.cells.width,
      height: size.cells.height,
      widthPx: size.pixels.width,
      heightPx: size.pixels.height,
    );
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
    if (_prepend.isNotEmpty) {
      for (final s in _prepend) {
        _prependLine(s);
      }
      _prepend.clear();
    }
    _renderer.flush();
  }

  void _prependLine(String line) {
    final lines = line.split('\n');
    final width = _buf.width();
    for (var i = 0; i < lines.length; i++) {
      // Simple truncation for now.
      // TODO: use a proper ANSI-aware truncate if needed.
      if (lines[i].length > width && width > 0) {
        lines[i] = lines[i].substring(0, width);
      }
    }
    _renderer.prependString(_buf, lines.join('\n'));
  }

  /// Adds the given string to the top of the terminal screen.
  ///
  /// Upstream: `third_party/ultraviolet/terminal.go` (`Terminal.PrependString`).
  void prependString(String s) {
    _prepend.add(s);
  }

  /// Sets whether to use backspace as a movement optimization.
  void setBackspace(bool v) {
    _renderer.setBackspace(v);
  }

  /// Sets whether to use hard tabs as a movement optimization.
  void setHasTab(bool v) {
    _renderer.setHasTab(v);
  }

  /// Sets the tab stops for the terminal and enables hard tabs movement optimizations.
  void setTabStops(int width) {
    _renderer.setTabStops(width);
  }

  /// Sets the color profile to use for downsampling colors.
  void setColorProfile(cp.Profile profile) {
    _renderer.setColorProfile(profile);
  }

  /// Sets whether the terminal is in fullscreen mode.
  void setFullscreen(bool v) {
    _renderer.setFullscreen(v);
  }

  /// Sets whether to use relative cursor movements.
  void setRelativeCursor(bool v) {
    _renderer.setRelativeCursor(v);
  }

  /// Sets whether to use scroll optimizations.
  void setScrollOptim(bool v) {
    _renderer.setScrollOptim(v);
  }

  /// Sets the logger for debugging.
  /// Sets the escape sequence timeout.
  void setEscTimeout(Duration d) {
    _reader.escTimeout = d;
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
  void fill(Cell? cell) {
    _buf.fill(cell);
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
  static Drawable bestImageDrawable(
    img.Image image, {
    required TerminalCapabilities capabilities,
    int? columns,
    int? rows,
  }) {
    if (capabilities.hasKittyGraphics) {
      return KittyImageDrawable(image, columns: columns, rows: rows);
    }
    if (capabilities.hasITerm2) {
      return ITerm2ImageDrawable(image, columns: columns, rows: rows);
    }
    if (capabilities.hasSixel) {
      return SixelImageDrawable(image, columns: columns, rows: rows);
    }
    // Fallback to half-block rendering.
    return HalfBlockImageDrawable(image, columns: columns, rows: rows);
  }

  /// Returns the best [Drawable] for the given image based on this terminal's capabilities.
  Drawable bestImageDrawableForTerminal(img.Image image, {int? columns, int? rows}) {
    return bestImageDrawable(image, capabilities: capabilities, columns: columns, rows: rows);
  }

  // NOTE: environment variable lookups are handled by [Environ].
}
