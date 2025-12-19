/// Fullscreen kitchen-sink TUI.
///
/// A manual test app that exercises multiple subsystems in one place:
/// - UV input decoder vs legacy input
/// - UV renderer vs default renderer
/// - tree/list/table (lipgloss v2 parity surfaces)
/// - interactive list selection (Enter/Space handling)
/// - unicode width / grapheme cluster clipping
///
/// Options:
///   --legacy-input     Use the legacy KeyParser (default is UV decoder)
///   --uv-renderer      Use UV renderer (cell-buffer diff)
library;

import 'dart:io' as io;
import 'dart:math' as math;

import 'package:artisan_args/artisan_args.dart'
    show
        AnsiColor,
        AdaptiveColor,
        BasicColor,
        Border,
        Color,
        Colors,
        ColorProfile,
        Layout,
        LipList,
        ListEnumerators,
        Style,
        blend1D,
        blend2D,
        stringForProfile,
        Table,
        Tree,
        TreeEnumerator,
        UnderlineStyle,
        VerticalAlign,
        Compositor,
        Layer,
        StyledString;
import 'package:artisan_args/src/unicode/grapheme.dart' as uni;
import 'package:artisan_args/tui.dart' as tui;
import 'package:image/image.dart' as img;
import 'package:artisan_args/src/tui/uv/capabilities.dart';
import 'package:artisan_args/src/tui/uv/event.dart' as uvev;
import 'package:artisan_args/src/tui/uv/terminal.dart' as uvt;

enum _Page {
  overview('Overview'),
  input('Input'),
  listSelect('List'),
  renderer('Renderer'),
  lipgloss('Tree/List/Table'),
  colors('Colors'),
  writer('Writer'),
  unicode('Unicode'),
  widgets('Widgets'),
  neofetch('Neofetch'),
  graphics('Graphics'),
  capabilities('Capabilities'),
  keyboard('Keyboard'),
  lipglossV2('Lipgloss v2'),
  compositor('Compositor'),
  selection('Selection');

  const _Page(this.title);
  final String title;
}

class _TickMsg extends tui.Msg {
  const _TickMsg();
}

class _KitchenSinkModel extends tui.Model {
  _KitchenSinkModel({required this.useUvInput, required this.useUvRenderer})
    : spinner = tui.SpinnerModel(spinner: tui.Spinners.miniDot),
      progress = tui.ProgressModel(width: 44, useGradient: true),
      textInput = tui.TextInputModel(prompt: 'search: ', width: 32),
      textarea = tui.TextAreaModel(width: 48, height: 6, prompt: ''),
      viewport = tui.ViewportModel(width: 60, height: 10),
      text = tui.TextModel(''),
      listSelection = _ListSelectionState.initial(),
      emojiEnabled = _defaultEmojiEnabled(io.Platform.environment),
      capabilities = TerminalCapabilities(
        env: io.Platform.environment.entries
            .map((e) => '${e.key}=${e.value}')
            .toList(growable: false),
      );

  final bool useUvInput;
  final bool useUvRenderer;
  bool emojiEnabled;
  final TerminalCapabilities capabilities;

  int _width = 80;
  int _height = 24;
  int _pageIndex = 0;
  bool _showHelp = true;
  int _headerLines = 4;
  int _footerLines = 0;

  tui.TerminalThemeState _theme = const tui.TerminalThemeState();

  tui.SpinnerModel spinner;
  tui.ProgressModel progress;
  final tui.TextInputModel textInput;
  final tui.TextAreaModel textarea;
  tui.ViewportModel viewport;
  tui.TextModel text;
  _SelectionLayout _selectionLayout = const _SelectionLayout();

  _ListSelectionState listSelection;
  final List<String> _eventLog = <String>[];
  final List<_TabHit> _tabHits = <_TabHit>[];

  late final Map<_Page, _KitchenSinkPage Function()> _pageFactories =
      <_Page, _KitchenSinkPage Function()>{
        _Page.overview: () => const _OverviewPage(),
        _Page.input: () => const _InputPage(),
        _Page.listSelect: () => const _ListSelectPage(),
        _Page.renderer: () => _RendererPage(),
        _Page.lipgloss: () => _LipglossPage(),
        _Page.colors: () => const _ColorsPage(),
        _Page.writer: () => const _WriterPage(),
        _Page.unicode: () => const _UnicodePage(),
        _Page.widgets: () => _WidgetsPage(),
        _Page.neofetch: () => const _NeofetchPage(),
        _Page.graphics: () => const _GraphicsPage(),
        _Page.capabilities: () => const _CapabilitiesPage(),
        _Page.keyboard: () => const _KeyboardPage(),
        _Page.lipglossV2: () => const _LipglossV2Page(),
        _Page.compositor: () => const _CompositorPage(),
        _Page.selection: () => const _SelectionPage(),
      };

  late final Map<_Page, _KitchenSinkPage> _pages = <_Page, _KitchenSinkPage>{
    _page: (_pageFactories[_page] ?? () => const _OverviewPage())(),
  };

  late _KitchenSinkPage _activePage = _pages[_page]!;

  _Page get _page => _Page.values[_pageIndex.clamp(0, _Page.values.length - 1)];

  int _wrapPageIndex(int i) {
    final len = _Page.values.length;
    var v = i % len;
    if (v < 0) v += len;
    return v;
  }

  void _setActivePage(
    int pageIndex,
    List<tui.Cmd> cmds, {
    required bool recreate,
  }) {
    _pageIndex = _wrapPageIndex(pageIndex);
    final page = _page;
    final factory = _pageFactories[page] ?? () => const _OverviewPage();
    if (recreate) {
      _pages[page] = factory();
    } else {
      _pages.putIfAbsent(page, factory);
    }
    _activePage = _pages[page]!;
    _activePage.onActivate(this, cmds);
  }

  void _log(String line) {
    _eventLog.add(line);
    if (_eventLog.length > 200) _eventLog.removeAt(0);
  }

  tui.Cmd _scheduleTick() {
    return tui.Cmd.tick(
      const Duration(milliseconds: 120),
      (_) => const _TickMsg(),
    );
  }

  static bool _defaultEmojiEnabled(Map<String, String> env) {
    final v = env['ARTISAN_EMOJI'];
    if (v == '1' || v == 'true') return true;
    final nv = env['ARTISAN_NO_EMOJI'] ?? env['NO_EMOJI'];
    if (nv == '1' || nv == 'true') return false;
    return true;
  }

  String emoji(String emoji, String fallback) =>
      emojiEnabled ? emoji : fallback;

  @override
  tui.Cmd? init() {
    final cmds = <tui.Cmd>[
      _scheduleTick(),
      spinner.tick(),
      tui.Cmd.enableReportFocus(),
      tui.Cmd.enableBracketedPaste(),
      tui.Cmd.enableMouseCellMotion(),
    ];
    _activePage.onActivate(this, cmds);
    if (useUvInput) {
      // Request background color so we can adapt styles to light/dark themes.
      cmds.add(tui.Cmd.requestBackgroundColorReport());
      // Capability probing (best-effort; replies arrive as UV events).
      cmds.add(
        tui.Cmd.writeRaw('\x1b_Gi=31,s=1,v=1,a=q,t=d,f=24;AAAA\x1b\\'),
      ); // Kitty graphics query
      cmds.add(
        tui.Cmd.writeRaw('\x1b[?u'),
      ); // Kitty keyboard enhancements query
      // Query a handful of palette entries (enough to know it's supported).
      for (var i = 0; i < 8; i++) {
        cmds.add(tui.Cmd.writeRaw('\x1b]4;$i;?\x1b\\'));
      }
    }
    final focus = textInput.focus();
    if (focus != null) cmds.add(focus);
    return tui.Cmd.batch(cmds);
  }

  Style _style([Style? base]) {
    final s = base ?? Style();
    s.hasDarkBackground = _theme.hasDarkBackground ?? true;
    return s;
  }

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    final cmds = <tui.Cmd>[];

    // Update shared widgets, but do not swallow the message: other widgets
    // (like ListModel's internal spinner) may also consume these.
    if (msg is tui.SpinnerTickMsg) {
      final (s, c) = spinner.update(msg);
      spinner = s;
      if (c != null) cmds.add(c);
    } else if (msg is tui.ProgressFrameMsg) {
      final (p, c) = progress.update(msg);
      progress = p;
      if (c != null) cmds.add(c);
    }

    switch (msg) {
      case tui.WindowSizeMsg(:final width, :final height):
        _width = width;
        _height = height;
        return (this, null);

      case tui.BackgroundColorMsg(:final hex):
        _log('BackgroundColorMsg(hex: $hex)');
        _theme = _theme.update(msg);
        return (this, null);

      case tui.ForegroundColorMsg(:final hex):
        _log('ForegroundColorMsg(hex: $hex)');
        _theme = _theme.update(msg);
        return (this, null);

      case tui.CursorColorMsg(:final hex):
        _log('CursorColorMsg(hex: $hex)');
        _theme = _theme.update(msg);
        return (this, null);

      case _TickMsg():
        cmds.add(_scheduleTick());
        _activePage.onTick(this, cmds);
        return (this, tui.Cmd.batch(cmds));

      case tui.FocusMsg(:final focused):
        _log('FocusMsg(focused: $focused)');

      case tui.PasteMsg(:final content):
        _log(
          'PasteMsg(${content.length} bytes): ${content.replaceAll('\n', r'\n')}',
        );

      case tui.MouseMsg(
        :final action,
        :final button,
        :final x,
        :final y,
        :final ctrl,
        :final alt,
        :final shift,
      ):
        _log(
          'MouseMsg(action: $action, button: $button, x: $x, y: $y, ctrl: $ctrl, alt: $alt, shift: $shift)',
        );
        if (action == tui.MouseAction.press && button == tui.MouseButton.left) {
          final idx = _tabIndexAt(x, y);
          if (idx != null) {
            // Per request: only mouse-activated tabs create a fresh page
            // instance. Keyboard navigation keeps existing instances.
            _setActivePage(idx, cmds, recreate: true);
            return (this, cmds.isEmpty ? null : tui.Cmd.batch(cmds));
          }
        }

      case tui.KeyMsg(key: final key):
        // Global quits.
        if (key.matchesSingle(tui.CommonKeyBindings.quit) ||
            key.isEscape ||
            key.isCtrlC ||
            key.isChar('q')) {
          return (this, tui.Cmd.quit());
        }

        // Global help toggle.
        if (key.isChar('?') || (key.ctrl && key.char == 'h')) {
          _showHelp = !_showHelp;
          return (this, null);
        }

        // Give the active page first right of refusal on keys so focused
        // widgets can prevent global navigation shortcuts.
        final consumed = _activePage.onKey(this, key, cmds);

        // Emoji toggle for terminals without emoji fonts.
        if (!consumed && (key.isChar('e') || key.isChar('E'))) {
          emojiEnabled = !emojiEnabled;
          return (this, null);
        }

        // Global page navigation.
        if (!consumed && key.type == tui.KeyType.tab) {
          _setActivePage(
            _wrapPageIndex(_pageIndex + (key.shift ? -1 : 1)),
            cmds,
            recreate: false,
          );
          return (this, cmds.isEmpty ? null : tui.Cmd.batch(cmds));
        }
        if (!consumed &&
            key.type == tui.KeyType.runes &&
            key.runes.isNotEmpty) {
          final r = key.runes.first;
          // 1..9 jump to page; 0 jumps to 10th page (if present).
          if (r >= 0x31 && r <= 0x39) {
            final idx = (r - 0x31).clamp(0, _Page.values.length - 1);
            _setActivePage(idx, cmds, recreate: false);
            return (this, cmds.isEmpty ? null : tui.Cmd.batch(cmds));
          }
          if (r == 0x30 /* '0' */ && _Page.values.length >= 10) {
            _setActivePage(9, cmds, recreate: false);
            return (this, cmds.isEmpty ? null : tui.Cmd.batch(cmds));
          }
        }

      case tui.ClipboardMsg(:final selection, :final content):
        _log(
          'ClipboardMsg(selection: $selection, ${content.length} bytes): ${content.replaceAll('\n', r'\n')}',
        );

      case tui.UvEventMsg(:final event):
        _log('UvEventMsg(${event.runtimeType}): $event');
        if (event is uvev.Event) {
          capabilities.updateFromEvent(event);
        }
    }

    _activePage.onMsg(this, msg, cmds);

    return (this, cmds.isEmpty ? null : tui.Cmd.batch(cmds));
  }

  int? _tabIndexAt(int x, int y) {
    // Header layout (0-based):
    // 0: title
    // 1: mode
    // 2: tabs
    // 3: divider
    const tabRow0 = 2;

    // Tolerate both 0-based and 1-based mouse coordinates.
    final candidates = <(int x, int y)>[
      (x, y),
      (x - 1, y),
      (x, y - 1),
      (x - 1, y - 1),
    ];

    for (final (cx, cy) in candidates) {
      if (cy != tabRow0) continue;
      for (final h in _tabHits) {
        if (cx >= h.startX && cx < h.endX) return h.pageIndex;
      }
    }
    return null;
  }

  @override
  String view() {
    final header = _renderHeader();
    // +1 for the newline added by join('\n') between header and body.
    _headerLines = header.split('\n').length + 1;

    final footer = _showHelp ? _renderHelp() : '';
    _footerLines = footer.isEmpty ? 0 : footer.split('\n').length;

    final body = _activePage.view(this);

    // Keep a small bottom margin for terminals that overwrite last line.
    return [header, body, footer, ''].where((s) => s.isNotEmpty).join('\n');
  }

  String _renderHeader() {
    _tabHits.clear();

    final title = _style(Style()).bold().render('Kitchen Sink');
    final mode = _style(Style()).dim().render(
      'input=${useUvInput ? 'uv' : 'legacy'}  renderer=${useUvRenderer ? 'uv' : 'default'}  size=${_width}x${_height}  bg=${_theme.backgroundHex ?? '(unknown)'}  dark=${_theme.hasDarkBackground ?? '(unknown)'}  emoji=${emojiEnabled ? 'on' : 'off'}',
    );

    final tabs = <String>[];
    var cursorX = 0;
    for (var i = 0; i < _Page.values.length; i++) {
      final p = _Page.values[i];
      final active = i == _pageIndex;
      final label = '${i + 1}:${p.title}';
      final chip = active
          ? _style(Style())
                .foreground(const AnsiColor(16))
                .background(const AnsiColor(220))
                .padding(0, 1)
                .render(label)
          : _style(Style()).dim().padding(0, 1).render(label);
      tabs.add(chip);

      final w = Style.visibleLength(chip);
      _tabHits.add(_TabHit(pageIndex: i, startX: cursorX, endX: cursorX + w));
      cursorX += w + 1; // +1 for the joining space
    }

    final tabLine = tabs.join(' ');
    final divider = _style(Style()).dim().render('─' * _width.clamp(10, 200));
    return [title, mode, tabLine, divider].join('\n');
  }

  String _renderHelp() {
    final help =
        'q quit • click tabs • Tab switch pages • 1-9 (0=10) jump • ? toggle help • e toggle emoji';
    final pageHelp = _activePage.help;
    return _style(Style()).dim().render('$help\n$pageHelp');
  }

  String _render2dGradient() {
    final w = (_width - 8).clamp(10, 50);
    final h = 6;
    final colors = blend2D(w, h, 45, [
      Colors.red,
      Colors.blue,
      Colors.green,
    ], hasDarkBackground: _theme.hasDarkBackground ?? true);
    if (colors.isEmpty) return '';

    final rows = <String>[];
    for (var y = 0; y < h; y++) {
      final buf = StringBuffer();
      for (var x = 0; x < w; x++) {
        final c = colors[y * w + x];
        buf.write((_style(Style())..background(c)).render(' '));
      }
      rows.add(buf.toString());
    }
    return rows.join('\n');
  }
}

final class _SelectionLayout {
  const _SelectionLayout({
    this.viewportTop = 0,
    this.textAreaTop = 0,
    this.textInputTop = 0,
    this.textTop = 0,
  });

  final int viewportTop;
  final int textAreaTop;
  final int textInputTop;
  final int textTop;
}

final class _TabHit {
  const _TabHit({
    required this.pageIndex,
    required this.startX,
    required this.endX,
  });

  final int pageIndex;
  final int startX;
  final int endX;
}

abstract class _KitchenSinkPage {
  const _KitchenSinkPage({required this.help});

  final String help;

  String view(_KitchenSinkModel m);

  void onActivate(_KitchenSinkModel m, List<tui.Cmd> cmds) {}

  bool onKey(_KitchenSinkModel m, tui.Key key, List<tui.Cmd> cmds) => false;

  void onMsg(_KitchenSinkModel m, tui.Msg msg, List<tui.Cmd> cmds) {}

  void onTick(_KitchenSinkModel m, List<tui.Cmd> cmds) {}
}

final class _OverviewPage extends _KitchenSinkPage {
  const _OverviewPage() : super(help: 'Overview: what this app covers');

  @override
  String view(_KitchenSinkModel m) {
    final lines = <String>[
      m._style(Style()).bold().render('What to test here'),
      '',
      '• UV renderer: dynamic updates (Renderer tab), tables/trees/lists (Tree/List/Table tab)',
      '• UV input decoder: Enter/Tab/arrows/paste/mouse (Input + List tabs)',
      '• Terminal theme: background detection + adaptive colors (Colors tab)',
      '• Graphics: Kitty/iTerm2/Sixel protocol detection (Graphics tab)',
      '• Capabilities: ANSI query results (Capabilities tab)',
      '• Keyboard: Enhanced keyboard protocol (Keyboard tab)',
      '• Lipgloss v2: Underline colors, padding chars, table inheritance (Lipgloss v2 tab)',
      '• Compositor: UV layering and canvas composition (Compositor tab)',
      '• Writer: ANSI downsampling (Writer tab)',
      '• Unicode width: emoji/CJK/grapheme clusters (Unicode tab)',
      '',
      m
          ._style(Style())
          .dim()
          .render('Tip: run with `--uv-renderer` and resize the terminal.'),
    ];
    return lines.join('\n');
  }
}

final class _InputPage extends _KitchenSinkPage {
  const _InputPage()
    : super(
        help:
            'Input: type in box • paste/mouse/focus/resize logs • c copy • p clipboard read • s size report',
      );

  @override
  String view(_KitchenSinkModel m) {
    final left = <String>[
      m._style(Style()).bold().render('Input controls'),
      '',
      'TextInput:',
      '  ${m.textInput.view()}',
      '',
      'TextArea:',
      m.textarea.view() as String,
      '',
      m._style(Style()).dim().render('Recent events (newest last):'),
    ];

    final maxLog = (m._height - 18).clamp(3, 9999);
    final logLines = m._eventLog.length <= maxLog
        ? m._eventLog
        : m._eventLog.sublist(m._eventLog.length - maxLog);
    final clipped = logLines.map((l) => _clipToWidth(l, m._width)).join('\n');

    return [left.join('\n'), '', clipped].join('\n');
  }

  @override
  bool onKey(_KitchenSinkModel m, tui.Key key, List<tui.Cmd> cmds) {
    m._log('KeyMsg($key)');
    if (key.isChar('c')) {
      cmds.add(tui.Cmd.setClipboard('kitchen-sink: hello'));
    } else if (key.isChar('p')) {
      cmds.add(tui.Cmd.requestClipboard());
    } else if (key.isChar('s')) {
      cmds.add(tui.Cmd.requestWindowSizeReport());
    }
    // This page is a key playground; avoid global navigation shortcuts while
    // typing.
    return true;
  }

  @override
  void onMsg(_KitchenSinkModel m, tui.Msg msg, List<tui.Cmd> cmds) {
    final (newInput, inputCmd) = m.textInput.update(msg);
    if (newInput.value != m.textInput.value) {
      m.textInput.value = newInput.value;
    }
    if (inputCmd != null) cmds.add(inputCmd);

    final (newArea, areaCmd) = m.textarea.update(msg);
    if (newArea.value != m.textarea.value) {
      m.textarea.value = newArea.value;
    }
    if (areaCmd != null) cmds.add(areaCmd);
  }
}

final class _ListSelectPage extends _KitchenSinkPage {
  const _ListSelectPage()
    : super(help: 'List: ↑/↓ or j/k move • Enter select • r reset');

  @override
  String view(_KitchenSinkModel m) {
    final title = m
        ._style(Style())
        .bold()
        .render('Interactive list (accept/select)');
    final subtitle = m
        ._style(Style())
        .dim()
        .render(
          'Selected: ${m.listSelection.selected ?? '(none)'}  (Enter should select)',
        );
    return [title, subtitle, '', m.listSelection.view(m)].join('\n');
  }

  @override
  bool onKey(_KitchenSinkModel m, tui.Key key, List<tui.Cmd> cmds) {
    final (next, cmd) = m.listSelection.update(key);
    m.listSelection = next;
    if (cmd != null) cmds.add(cmd);
    return true;
  }
}

final class _RendererPage extends _KitchenSinkPage {
  _RendererPage()
    : super(
        help:
            'Renderer: r reset • g complete • ←/→ (or h/l) nudge • t toggle auto-tick',
      );

  bool _autoTick = false;
  int _manualCooldownTicks = 0;

  @override
  String view(_KitchenSinkModel m) {
    final title = m._style(Style()).bold().render('Renderer stress');
    final status =
        '${m.spinner.view()}  ${m.progress.view()}  ${m._style(Style()).dim().render('auto=${_autoTick ? 'on' : 'off'} (t to toggle)')}';

    final sample =
        (Tree()
              ..root('Render surfaces')
              ..child(LipList.create(['alpha', 'beta', 'gamma']))
              ..child(
                (Table()
                      ..headers(['A', 'B'])
                      ..row(['left', 'right'])
                      ..row(['wrap', 'test']))
                    .render(),
              ))
            .enumerator(TreeEnumerator.rounded)
            .render();

    return [title, '', status, '', sample].join('\n');
  }

  @override
  void onTick(_KitchenSinkModel m, List<tui.Cmd> cmds) {
    if (!_autoTick) return;
    if (_manualCooldownTicks > 0) {
      _manualCooldownTicks--;
      return;
    }

    // Nudge the progress bar while incomplete. Once complete, hold at 100%
    // until the user resets (so keybinds visibly "work").
    if (m.progress.percent >= 1) return;
    final next = (m.progress.percent + 0.03).clamp(0.0, 1.0);
    final (p, c) = m.progress.setPercent(next, animate: true);
    m.progress = p;
    if (c != null) cmds.add(c);
  }

  @override
  bool onKey(_KitchenSinkModel m, tui.Key key, List<tui.Cmd> cmds) {
    bool isCharAny(String a, String b) => key.isChar(a) || key.isChar(b);

    if (isCharAny('t', 'T')) {
      _autoTick = !_autoTick;
      return true;
    }

    if (isCharAny('r', 'R')) {
      final (p, c) = m.progress.setPercent(0, animate: false);
      m.progress = p;
      if (c != null) cmds.add(c);
      return true;
    }
    if (isCharAny('g', 'G')) {
      final (p, c) = m.progress.setPercent(1, animate: true);
      m.progress = p;
      if (c != null) cmds.add(c);
      return true;
    }

    // Nudge with arrows/+/- for quick manual testing (useful on keypads too).
    final delta = switch (key.type) {
      tui.KeyType.left => -0.05,
      tui.KeyType.right => 0.05,
      _ => switch (key.char) {
        'h' => -0.05,
        'l' => 0.05,
        _ => null,
      },
    };
    if (delta != null) {
      _manualCooldownTicks = 8;
      final next = (m.progress.percent + delta).clamp(0.0, 1.0);
      final (p, c) = m.progress.setPercent(next, animate: false);
      m.progress = p;
      if (c != null) cmds.add(c);
      return true;
    }

    if (key.isChar('+') || key.isChar('=')) {
      _manualCooldownTicks = 8;
      final next = (m.progress.percent + 0.05).clamp(0.0, 1.0);
      final (p, c) = m.progress.setPercent(next, animate: false);
      m.progress = p;
      if (c != null) cmds.add(c);
      return true;
    } else if (key.isChar('-') || key.isChar('_')) {
      _manualCooldownTicks = 8;
      final next = (m.progress.percent - 0.05).clamp(0.0, 1.0);
      final (p, c) = m.progress.setPercent(next, animate: false);
      m.progress = p;
      if (c != null) cmds.add(c);
      return true;
    }

    return false;
  }
}

final class _LipglossPage extends _KitchenSinkPage {
  _LipglossPage()
    : _pane = tui.ViewportScrollPane(
        viewport: tui.ViewportModel(width: 0, height: 0, horizontalStep: 4),
      ),
      super(
        help:
            'Tree/List/Table: scroll with ↑/↓ j/k, PgUp/PgDn, mouse wheel • drag scrollbar',
      );

  final tui.ViewportScrollPane _pane;

  @override
  String view(_KitchenSinkModel m) {
    final title = m
        ._style(Style())
        .bold()
        .render('Tree/List/Table (lipgloss v2 parity)');

    final tree1 =
        (Tree()
              ..root('Root')
              ..child('Foo')
              ..child(
                Tree()
                  ..root('Bar')
                  ..child('Line 1\nLine 2\nLine 3')
                  ..child('Baz'),
              )
              ..child('Qux'))
            .enumerator(TreeEnumerator.rounded)
            .render();

    final tree2 =
        (Tree()
              ..root('Packages')
              ..child('🍞 bread')
              ..child('🥬 kale')
              ..child(
                Tree()
                  ..root('Nested')
                  ..child('one')
                  ..child('two'),
              ))
            .enumerator(TreeEnumerator.heavy)
            .rootStyle(
              m._style(Style())
                ..bold()
                ..foreground(Colors.sky),
            )
            .enumeratorStyle(m._style(Style()).dim())
            .indenterStyle(m._style(Style()).dim())
            .itemStyleFunc((children, index) {
              final v = children[index].value.toString();
              if (v.contains('🍞'))
                return m._style(Style()).foreground(Colors.rose);
              if (v.contains('🥬'))
                return m._style(Style()).foreground(Colors.lime);
              return m._style(Style());
            })
            .render();

    final tree3 =
        (Tree()
              ..root('Offset + hidden (double-line)')
              ..child('trim-start')
              ..child(
                (Tree()
                  ..root('hidden subtree')
                  ..hide(true)),
              )
              ..child('shown A')
              ..child('shown B')
              ..child('trim-end'))
            .offset(1, 1)
            .enumerator(TreeEnumerator.doubleLine)
            .enumeratorStyle(m._style(Style()).dim())
            .indenterStyle(m._style(Style()).dim())
            .itemStyleFunc((children, index) {
              final v = children[index].value.toString();
              if (v.contains('shown A')) {
                return m._style(Style()).foreground(Colors.teal);
              }
              if (v.contains('shown B')) {
                return m._style(Style()).foreground(Colors.indigo);
              }
              return m._style(Style());
            })
            .render();

    final list1 = (LipList.create([
      'Foo',
      'Bar',
      LipList.create(['Hi', 'Hello', 'Halo']).enumerator(ListEnumerators.roman),
      'Qux',
    ])).render();

    final list2 = (LipList.create([
      m._style(Style()).foreground(Colors.teal).render('teal item'),
      m._style(Style()).foreground(Colors.indigo).render('indigo item'),
      m._style(Style()).foreground(Colors.rose).render('rose item'),
    ])..enumerator(ListEnumerators.bullet)).render();

    final table1 =
        (Table()
              ..width(34)
              ..headers(['Pkg', 'Status', 'Notes'])
              ..row(['artisan_args', 'OK', 'styled + uv'])
              ..row(['ultraviolet', 'WIP', 'decoder+renderer'])
              ..row(['lipgloss', 'v2', 'parity pass']))
            .border(Border.rounded)
            .padding(0)
            .styleFunc((row, col, data) {
              if (row == Table.headerRow) {
                return m._style(Style()).bold().foreground(Colors.sky);
              }
              if (col == 1 && data == 'OK') {
                return m._style(Style()).foreground(Colors.lime);
              }
              if (col == 1 && data == 'WIP') {
                return m._style(Style()).foreground(Colors.rose);
              }
              if (row.isEven) return m._style(Style()).dim();
              return null;
            })
            .render();

    final table2 =
        (Table()
              ..width(26)
              ..headers(['Key', 'Value'])
              ..row(['emoji', '🍕🍔🌮'])
              ..row(['wrap', 'a long cell that should truncate']))
            .border(Border.double)
            .borderRow(true)
            .padding(0)
            .render();

    final table3 =
        (Table()
              ..width(34)
              ..height(7)
              ..offset(1)
              ..headers(['#', 'Step', 'Dur'])
              ..rows([
                ['1', 'decode', '2ms'],
                ['2', 'layout', '4ms'],
                ['3', 'diff', '1ms'],
                ['4', 'flush', '3ms'],
              ]))
            .border(Border.ascii)
            .borderColumn(false)
            .borderRow(true)
            .padding(0)
            .styleFunc((row, col, data) {
              if (row == Table.headerRow) {
                return m._style(Style()).bold().foreground(Colors.sky);
              }
              return switch (col) {
                0 => m._style(Style()).dim(),
                2 =>
                  m
                      ._style(Style())
                      .width(4)
                      .alignRight()
                      .foreground(Colors.lime),
                _ => null,
              };
            })
            .render();

    final innerTable =
        (Table()
              ..width(34)
              ..headers(['Col', 'Value'])
              ..row(['alpha', 'one'])
              ..row(['beta', 'two'])
              ..row(['gamma', 'three']))
            .border(Border.normal)
            .borderTop(false)
            .borderBottom(false)
            .borderLeft(false)
            .borderRight(false)
            .borderHeader(true)
            .borderRow(false)
            .padding(0)
            .styleFunc((row, col, data) {
              if (row == Table.headerRow) {
                return m._style(Style()).bold().foreground(Colors.sky);
              }
              if (col == 0) return m._style(Style()).foreground(Colors.indigo);
              return null;
            })
            .render();

    final blendedBorderTable = m
        ._style(Style())
        .border(Border.rounded)
        .borderForegroundBlend([Colors.rose, Colors.indigo, Colors.teal])
        .borderForegroundBlendOffset(3)
        .padding(0, 1)
        .render(innerTable);

    final left = [
      m._style(Style()).dim().render('Tree (rounded):'),
      tree1,
      '',
      m._style(Style()).dim().render('Tree (heavy + styled):'),
      tree2,
      '',
      m._style(Style()).dim().render('Tree (offset + hidden + double-line):'),
      tree3,
    ].join('\n');

    final right = [
      m._style(Style()).dim().render('List (nested):'),
      list1,
      '',
      m._style(Style()).dim().render('List (styled):'),
      list2,
      '',
      m._style(Style()).dim().render('Table (styled + zebra):'),
      table1,
      '',
      m._style(Style()).dim().render('Table (borders + row dividers):'),
      table2,
      '',
      m
          ._style(Style())
          .dim()
          .render('Table (ascii + no columns + offset/height):'),
      table3,
      '',
      m
          ._style(Style())
          .dim()
          .render('Table (blended outer border via Style.border):'),
      blendedBorderTable,
    ].join('\n');

    final columns = Layout.joinHorizontal(VerticalAlign.top, [
      left,
      '   ',
      right,
    ]);

    // Header can wrap when many tabs are present; use the measured line count.
    final topRow0 = m._headerLines + 2;
    final contentHeight = (m._height - m._headerLines - m._footerLines - 1)
        .clamp(0, 9999);
    final bodyHeight = (contentHeight - 2).clamp(1, 9999);

    final viewportWidth = (m._width - 2).clamp(10, 9999);
    _pane.viewport = _pane.viewport.copyWith(
      width: viewportWidth,
      height: bodyHeight,
    );
    _pane.viewport = _pane.viewport.setContent(columns);
    _pane.originX = 0;
    _pane.originY = topRow0;

    final pane = _pane.view();

    return [title, '', pane].join('\n');
  }

  @override
  bool onKey(_KitchenSinkModel m, tui.Key key, List<tui.Cmd> cmds) {
    final (_, cmd) = _pane.update(tui.KeyMsg(key));
    if (cmd != null) cmds.add(cmd);
    return false;
  }

  @override
  void onMsg(_KitchenSinkModel m, tui.Msg msg, List<tui.Cmd> cmds) {
    if (msg is! tui.MouseMsg) return;
    final (_, cmd) = _pane.update(msg);
    if (cmd != null) cmds.add(cmd);
  }
}

final class _ColorsPage extends _KitchenSinkPage {
  const _ColorsPage()
    : super(
        help:
            'Colors: shows background detection + adaptive colors + gradients',
      );

  @override
  String view(_KitchenSinkModel m) {
    final title = m._style(Style()).bold().render('Colors + theme detection');
    final bg = m.capabilities.backgroundColor;
    final bgStr = bg != null ? 'rgb(${bg.r},${bg.g},${bg.b})' : '(unknown)';
    final detected = m
        ._style(Style())
        .dim()
        .render(
          'background=${m._theme.backgroundHex ?? '(unknown)'} (UV: $bgStr)  dark=${m._theme.hasDarkBackground ?? '(unknown)'}',
        );

    final adaptive = m._style(Style())
      ..foreground(AdaptiveColor(light: Colors.black, dark: Colors.white));
    final adaptiveChip = adaptive
        .background(AdaptiveColor(light: Colors.white, dark: Colors.black))
        .padding(0, 1)
        .render('AdaptiveColor chip');

    final demoWidth = (m._width - 8).clamp(10, 80);
    final stops = <Color>[Colors.red, Colors.blue, Colors.green];
    final grad = blend1D(
      demoWidth,
      stops,
      hasDarkBackground: m._theme.hasDarkBackground ?? true,
    );
    final bar = grad
        .map((c) => m._style(Style())..background(c))
        .map((s) => s.render(' '))
        .join();

    final box = m
        ._style(Style())
        .border(Border.rounded)
        .borderForegroundBlend([Colors.red, Colors.blue])
        .borderForegroundBlendOffset(2)
        .padding(0, 1)
        .render('Border foreground blend');

    final grid = m._render2dGradient();

    return [
      title,
      detected,
      '',
      adaptiveChip,
      '',
      m._style(Style()).dim().render('1D gradient (blend1D):'),
      bar,
      '',
      m._style(Style()).dim().render('Border blend + offset:'),
      box,
      '',
      m._style(Style()).dim().render('2D gradient (blend2D):'),
      grid,
    ].join('\n');
  }
}

final class _WriterPage extends _KitchenSinkPage {
  const _WriterPage()
    : super(
        help:
            'Writer: downsampling (trueColor→ansi256/ansi/noColor/ascii) demos',
      );

  @override
  String view(_KitchenSinkModel m) {
    final title = m
        ._style(Style())
        .bold()
        .render('Writer (downsampling demos)');
    final hint = m
        ._style(Style())
        .dim()
        .render(
          'These show how our v2-style Writer can downsample ANSI sequences for different terminal profiles.',
        );

    final sample = m
        ._style(Style())
        .bold()
        .foreground(Colors.rose)
        .background(Colors.black)
        .padding(0, 1)
        .render('Who wants marmalade? 🍊');

    String sim(ColorProfile p) => stringForProfile(sample, p);

    final rows = <String>[
      m._style(Style()).dim().render('trueColor:'),
      sim(ColorProfile.trueColor),
      '',
      m._style(Style()).dim().render('ansi256:'),
      sim(ColorProfile.ansi256),
      '',
      m._style(Style()).dim().render('ansi16:'),
      sim(ColorProfile.ansi),
      '',
      m._style(Style()).dim().render('noColor (keep attrs):'),
      sim(ColorProfile.noColor),
      '',
      m._style(Style()).dim().render('ascii (strip all):'),
      sim(ColorProfile.ascii),
    ];

    return [title, '', hint, '', ...rows].join('\n');
  }
}

final class _UnicodePage extends _KitchenSinkPage {
  const _UnicodePage()
    : super(help: 'Unicode: width + grapheme clipping samples');

  @override
  String view(_KitchenSinkModel m) {
    final title = m
        ._style(Style())
        .bold()
        .render('Unicode width + grapheme clusters');
    final hint = m
        ._style(Style())
        .dim()
        .render(
          'If you see boxes, your terminal font lacks emoji glyphs. Press "e" to toggle emoji samples.',
        );
    final samples = <String>[
      'ASCII: hello',
      'CJK: 漢字かなカナ',
      'Emoji: ${m.emoji('🍕🍔🌮', '[pizza][burger][taco]')}',
      'Flags: ${m.emoji('🇺🇸🇯🇵🇫🇷', '[US][JP][FR]')}',
      'ZWJ: ${m.emoji('👩‍💻👨‍👩‍👧‍👦', '[coder][family]')}',
      'Combining: e\u0301  a\u0308  n\u0303',
    ];

    final rows = <String>[];
    for (final s in samples) {
      final graphemes = uni.graphemes(s).toList(growable: false);
      rows.add(
        '${m._style(Style()).dim().render('w=${Style.visibleLength(s).toString().padLeft(2)}  g=${graphemes.length.toString().padLeft(2)}')}  ${_clipToWidth(s, m._width - 10)}',
      );
    }

    final explain = m
        ._style(Style())
        .dim()
        .render(
          'The widths above use ANSI-aware display width and grapheme iteration; compare with resize + renderer.',
        );

    return [title, hint, '', ...rows, '', explain].join('\n');
  }
}

final class _WidgetsPage extends _KitchenSinkPage {
  _WidgetsPage()
    : _pane = tui.ViewportScrollPane(
        viewport: tui.ViewportModel(width: 0, height: 0, horizontalStep: 4),
      ),
      _confirmToggle = tui.ConfirmModel(
        prompt: 'Continue?',
        displayMode: tui.ConfirmDisplayMode.toggle,
        showHelp: true,
      ),
      _confirmHint = tui.ConfirmModel(
        prompt: 'Continue?',
        displayMode: tui.ConfirmDisplayMode.hint,
        showHelp: false,
      ),
      _confirmInline = tui.ConfirmModel(
        prompt: 'Continue?',
        displayMode: tui.ConfirmDisplayMode.inline,
        showHelp: false,
      ),
      _destructive = tui.DestructiveConfirmModel(
        prompt: 'Type DELETE to confirm:',
        confirmText: 'DELETE',
        showHelp: true,
      ),
      _password = tui.PasswordModel(
        prompt: 'Password: ',
        echoMode: tui.PasswordEchoMode.mask,
        showHelp: true,
      ),
      _anticipate = tui.AnticipateModel(
        prompt: 'pkg: ',
        placeholder: 'type to search…',
        suggestions: const [
          'artisan_args',
          'ultraviolet',
          'lipgloss',
          'bubbletea',
          'bubbles',
          'markdown',
          'http',
          'path',
        ],
        defaultValue: '',
      ),
      _select = tui.SelectModel<String>(
        title: 'Choose a color:',
        items: const ['Red', 'Green', 'Blue', 'Indigo', 'Teal', 'Rose'],
        height: 8,
      ),
      _search = tui.SearchModel<String>(
        title: 'Search files:',
        items: const [
          'pubspec.yaml',
          'README.md',
          'lib/src/tui/program.dart',
          'lib/src/tui/uv/decoder.dart',
          'example/tui/examples/kitchen-sink/main.dart',
          'test/tui/uv_keypad_mapping_test.dart',
        ],
        height: 9,
      ),
      _list = tui.ListModel(
        title: 'Packages',
        items: const [
          'artisan_args',
          'ultraviolet',
          'lipgloss',
          'chalkdart',
          'characters',
          'path',
          'args',
          'collection',
          'test',
        ].map(tui.StringItem.new).toList(growable: false),
        width: 72,
        height: 12,
        filteringEnabled: true,
        showHelp: true,
        showPagination: true,
      ),
      _tableModel = tui.TableModel(
        width: 72,
        height: 8,
        columns: [
          tui.Column(title: 'Widget', width: 16),
          tui.Column(title: 'Status', width: 10),
          tui.Column(title: 'Notes', width: 42),
        ],
        rows: const [
          ['Viewport', 'OK', 'scroll + wheel + drag'],
          ['List', 'OK', 'filter + paging'],
          ['Select', 'OK', 'single selection'],
          ['Search', 'OK', 'query + highlight'],
          ['Confirm', 'OK', 'toggle/hint/inline'],
          ['FilePicker', 'OK', 'directory browsing'],
        ],
      ),
      _viewportPreview = tui.ViewportModel(width: 60, height: 4)
          .setContent(List.generate(20, (i) => 'line ${i + 1}').join('\n'))
          .setYOffset(6),
      _timer = tui.TimerModel(timeout: const Duration(minutes: 2, seconds: 34)),
      _stopwatch = tui.StopwatchModel(),
      _pause = tui.PauseModel(message: 'Press any key to continue…'),
      _countdown = tui.CountdownModel(duration: const Duration(seconds: 10)),
      _filePicker = tui.FilePickerModel(
        currentDirectory: io.Directory.current.path,
        dirAllowed: true,
        fileAllowed: true,
        showHidden: false,
        height: 12,
      ),
      super(
        help:
            'Widgets: click a panel to focus; Esc unfocus; when unfocused you can scroll/drag the scrollbar',
      );

  final tui.ViewportScrollPane _pane;
  final tui.ConfirmModel _confirmToggle;
  final tui.ConfirmModel _confirmHint;
  final tui.ConfirmModel _confirmInline;
  tui.DestructiveConfirmModel _destructive;
  tui.PasswordModel _password;
  tui.AnticipateModel _anticipate;
  tui.SelectModel<String> _select;
  tui.SearchModel<String> _search;
  tui.ListModel _list;
  tui.TableModel _tableModel;
  tui.ViewportModel _viewportPreview;
  tui.TimerModel _timer;
  tui.StopwatchModel _stopwatch;
  final tui.PauseModel _pause;
  tui.CountdownModel _countdown;
  tui.FilePickerModel _filePicker;
  bool _filePickerInitSent = false;

  _WidgetsFocus _focus = _WidgetsFocus.none;
  bool _liveTextArea = false;
  final List<_PanelRange> _panelRanges = <_PanelRange>[];

  @override
  void onActivate(_KitchenSinkModel m, List<tui.Cmd> cmds) {
    if (_filePickerInitSent) return;
    _filePickerInitSent = true;
    final c = _filePicker.init();
    if (c != null) cmds.add(c);
  }

  @override
  String view(_KitchenSinkModel m) {
    final title = m._style(Style()).bold().render('Widgets showcase');

    final paginator = tui.PaginatorModel(
      type: tui.PaginationType.dots,
    ).setTotalPages(12).copyWith(page: 3);

    final helpShort = tui.HelpModel(width: 72).view(tui.ViewportKeyMap());
    final helpFull = tui.HelpModel(
      width: 72,
      showAll: true,
    ).view(tui.TableKeyMap());

    final status = [
      '${m.spinner.view()}  spinner',
      m.progress.view(),
      '',
      m
          ._style(Style())
          .dim()
          .render(
            _focus == _WidgetsFocus.live
                ? 'focused: ${_liveTextArea ? 'TextArea' : 'TextInput'} (press i to toggle)'
                : 'click this panel to edit; Esc to unfocus',
          ),
      '',
      m._style(Style()).dim().render('TextInput:'),
      m.textInput.view(),
      '',
      m._style(Style()).dim().render('TextArea:'),
      m.textarea.view(),
    ].join('\n');

    final panels = <({String text, _WidgetsFocus focus})>[
      (
        text: _box(m, 'Live (shared state)', status, focus: _WidgetsFocus.live),
        focus: _WidgetsFocus.live,
      ),
      (
        text: _box(
          m,
          'Paginator + Help',
          [
            paginator.view(),
            m._style(Style()).dim().render('short help:'),
            helpShort,
            m._style(Style()).dim().render('full help:'),
            helpFull,
          ].join('\n'),
          focus: _WidgetsFocus.help,
        ),
        focus: _WidgetsFocus.help,
      ),
      (
        text: _box(
          m,
          'Confirm',
          Layout.joinHorizontal(VerticalAlign.top, [
            _confirmToggle.view(),
            '  ',
            [_confirmHint.view(), _confirmInline.view()].join('\n'),
          ]),
          focus: _WidgetsFocus.confirm,
        ),
        focus: _WidgetsFocus.confirm,
      ),
      (
        text: _box(
          m,
          'Destructive confirm',
          _destructive.view(),
          focus: _WidgetsFocus.destructive,
        ),
        focus: _WidgetsFocus.destructive,
      ),
      (
        text: _box(
          m,
          'Password',
          _password.view(),
          focus: _WidgetsFocus.password,
        ),
        focus: _WidgetsFocus.password,
      ),
      (
        text: _box(
          m,
          'Anticipate (autocomplete)',
          _anticipate.view(),
          focus: _WidgetsFocus.anticipate,
        ),
        focus: _WidgetsFocus.anticipate,
      ),
      (
        text: _box(m, 'Select', _select.view(), focus: _WidgetsFocus.select),
        focus: _WidgetsFocus.select,
      ),
      (
        text: _box(m, 'Search', _search.view(), focus: _WidgetsFocus.search),
        focus: _WidgetsFocus.search,
      ),
      (
        text: _box(m, 'List', _list.view(), focus: _WidgetsFocus.list),
        focus: _WidgetsFocus.list,
      ),
      (
        text: _box(
          m,
          'TableModel',
          _tableModel.view(),
          focus: _WidgetsFocus.table,
        ),
        focus: _WidgetsFocus.table,
      ),
      (
        text: _box(
          m,
          'ViewportModel',
          [
            _viewportPreview.view(),
            m
                ._style(Style())
                .dim()
                .render(
                  'scroll=${(_viewportPreview.scrollPercent * 100).round()}% (focus this panel to use j/k)',
                ),
          ].join('\n'),
          focus: _WidgetsFocus.viewport,
        ),
        focus: _WidgetsFocus.viewport,
      ),
      (
        text: _box(
          m,
          'FilePicker',
          _filePicker.view(),
          focus: _WidgetsFocus.filePicker,
        ),
        focus: _WidgetsFocus.filePicker,
      ),
      (
        text: _box(
          m,
          'Timer + Stopwatch + Pause',
          [
            'Timer: ${_timer.view()}',
            'Stopwatch: ${_stopwatch.view()}',
            _pause.view(),
            _countdown.view(),
          ].join('\n'),
          focus: _WidgetsFocus.timer,
        ),
        focus: _WidgetsFocus.timer,
      ),
    ];

    _panelRanges.clear();
    var lineCursor = 0;
    final renderedPanels = <String>[];
    for (var i = 0; i < panels.length; i++) {
      final p = panels[i];
      final panelLines = p.text.split('\n');
      final lines = panelLines.length;
      var maxCols = 0;
      for (final l in panelLines) {
        maxCols = math.max(maxCols, Style.visibleLength(l));
      }
      _panelRanges.add(
        _PanelRange(
          focus: p.focus,
          startLine: lineCursor,
          endLine: lineCursor + lines,
          endCol: maxCols,
        ),
      );
      renderedPanels.add(p.text);
      lineCursor += lines;
      if (i != panels.length - 1) {
        lineCursor += 1; // join('\n\n') adds exactly 1 blank line
      }
    }
    final columns = renderedPanels.join('\n\n');

    final topRow0 = m._headerLines + 2;
    final contentHeight = (m._height - m._headerLines - m._footerLines - 1)
        .clamp(0, 9999);
    final bodyHeight = (contentHeight - 2).clamp(1, 9999);

    final viewportWidth = (m._width - 2).clamp(10, 9999);
    _pane.viewport = _pane.viewport.copyWith(
      width: viewportWidth,
      height: bodyHeight,
    );
    _pane.viewport = _pane.viewport.setContent(columns);
    _pane.originX = 0;
    _pane.originY = topRow0;

    final pane = _pane.view();

    return [title, '', pane].join('\n');
  }

  @override
  bool onKey(_KitchenSinkModel m, tui.Key key, List<tui.Cmd> cmds) {
    if (key.isEscape) {
      _focus = _WidgetsFocus.none;
      return true;
    }

    if (_focus == _WidgetsFocus.none) {
      final (_, cmd) = _pane.update(tui.KeyMsg(key));
      if (cmd != null) cmds.add(cmd);
      return false;
    }

    if (_focus == _WidgetsFocus.live && key.isChar('i')) {
      _liveTextArea = !_liveTextArea;
      if (_liveTextArea) {
        final c = m.textarea.focus();
        if (c != null) cmds.add(c);
      } else {
        final c = m.textInput.focus();
        if (c != null) cmds.add(c);
      }
      return true;
    }

    switch (_focus) {
      case _WidgetsFocus.live:
        if (_liveTextArea) {
          final (next, cmd) = m.textarea.update(tui.KeyMsg(key));
          m.textarea.value = next.value;
          if (cmd != null) cmds.add(cmd);
        } else {
          final (next, cmd) = m.textInput.update(tui.KeyMsg(key));
          m.textInput.value = next.value;
          if (cmd != null) cmds.add(cmd);
        }
        return true;
      case _WidgetsFocus.confirm:
        final (cm, cmd) = _confirmToggle.update(tui.KeyMsg(key));
        // ConfirmModel is mutable-ish internally; keep reference.
        if (cmd != null) cmds.add(cmd);
        return true;
      case _WidgetsFocus.destructive:
        final (dm, cmd) = _destructive.update(tui.KeyMsg(key));
        _destructive = dm;
        if (cmd != null) cmds.add(cmd);
        return true;
      case _WidgetsFocus.password:
        final (pm, cmd) = _password.update(tui.KeyMsg(key));
        _password = pm;
        if (cmd != null) cmds.add(cmd);
        return true;
      case _WidgetsFocus.anticipate:
        final (am, cmd) = _anticipate.update(tui.KeyMsg(key));
        _anticipate = am;
        if (cmd != null) cmds.add(cmd);
        return true;
      case _WidgetsFocus.select:
        final (sm, cmd) = _select.update(tui.KeyMsg(key));
        _select = sm;
        if (cmd != null) cmds.add(cmd);
        return true;
      case _WidgetsFocus.search:
        final (sm, cmd) = _search.update(tui.KeyMsg(key));
        _search = sm;
        if (cmd != null) cmds.add(cmd);
        return true;
      case _WidgetsFocus.list:
        final (lm, cmd) = _list.update(tui.KeyMsg(key));
        _list = lm;
        if (cmd != null) cmds.add(cmd);
        return true;
      case _WidgetsFocus.table:
        final (tm, cmd) = _tableModel.update(tui.KeyMsg(key));
        _tableModel = tm;
        if (cmd != null) cmds.add(cmd);
        return true;
      case _WidgetsFocus.viewport:
        final (vp, cmd) = _viewportPreview.update(tui.KeyMsg(key));
        _viewportPreview = vp;
        if (cmd != null) cmds.add(cmd);
        return true;
      case _WidgetsFocus.filePicker:
        final (fp, cmd) = _filePicker.update(tui.KeyMsg(key));
        _filePicker = fp;
        if (cmd != null) cmds.add(cmd);
        return true;
      case _WidgetsFocus.timer:
        // Preview only (no interactive controls wired yet).
        return true;
      case _WidgetsFocus.help:
      case _WidgetsFocus.none:
        return false;
    }
  }

  @override
  void onMsg(_KitchenSinkModel m, tui.Msg msg, List<tui.Cmd> cmds) {
    if (msg is tui.MouseMsg) {
      final consumed = _pane.consumesMouse(msg);
      final (_, cmd) = _pane.update(msg);
      if (cmd != null) cmds.add(cmd);
      if (consumed) return;

      if (msg.button == tui.MouseButton.left &&
          msg.action == tui.MouseAction.press) {
        // Click-to-focus (sticky until Esc).
        _focus = _focusForMouseLine(msg);
        return;
      }

      if (msg.button == tui.MouseButton.none &&
          msg.action == tui.MouseAction.motion) {
        // Hover-to-focus (matches "mouse focus" behavior). Keep click-to-focus
        // sticky: once a widget is focused, don't change focus on hover.
        if (_focus == _WidgetsFocus.none) {
          _focus = _focusForMouseLine(msg);
        }
        return;
      }

      return;
    }

    // Route non-key background messages to embedded widgets so they can process
    // their own async/tick events.
    if (msg is tui.KeyMsg) return;

    {
      final (lm, cmd) = _list.update(msg);
      _list = lm;
      if (cmd != null) cmds.add(cmd);
    }
    {
      final (sm, cmd) = _search.update(msg);
      _search = sm;
      if (cmd != null) cmds.add(cmd);
    }
    {
      final (fp, cmd) = _filePicker.update(msg);
      _filePicker = fp;
      if (cmd != null) cmds.add(cmd);
    }
    {
      final (vp, cmd) = _viewportPreview.update(msg);
      _viewportPreview = vp;
      if (cmd != null) cmds.add(cmd);
    }
    {
      final (dm, cmd) = _destructive.update(msg);
      _destructive = dm;
      if (cmd != null) cmds.add(cmd);
    }
    {
      final (pm, cmd) = _password.update(msg);
      _password = pm;
      if (cmd != null) cmds.add(cmd);
    }
    {
      final (am, cmd) = _anticipate.update(msg);
      _anticipate = am;
      if (cmd != null) cmds.add(cmd);
    }
    {
      final (sm, cmd) = _select.update(msg);
      _select = sm;
      if (cmd != null) cmds.add(cmd);
    }
    {
      final (tm, cmd) = _tableModel.update(msg);
      _tableModel = tm;
      if (cmd != null) cmds.add(cmd);
    }
    {
      final (tm, cmd) = _timer.update(msg);
      _timer = tm;
      if (cmd != null) cmds.add(cmd);
    }
    {
      final (sw, cmd) = _stopwatch.update(msg);
      _stopwatch = sw;
      if (cmd != null) cmds.add(cmd);
    }
    {
      final (cd, cmd) = _countdown.update(msg);
      _countdown = cd;
      if (cmd != null) cmds.add(cmd);
    }
  }

  _WidgetsFocus _focusForMouseLine(tui.MouseMsg msg) {
    final pos = _pane.contentPosAtMouse(msg);
    if (pos == null) return _WidgetsFocus.none;
    final (line, col) = pos;
    final hit = _panelRanges.firstWhere(
      (r) => line >= r.startLine && line < r.endLine && col < r.endCol,
      orElse: () => const _PanelRange(
        focus: _WidgetsFocus.none,
        startLine: -1,
        endLine: -1,
        endCol: 0,
      ),
    );
    return hit.focus;
  }
}

enum _WidgetsFocus {
  none,
  live,
  help,
  confirm,
  destructive,
  password,
  anticipate,
  select,
  search,
  list,
  table,
  viewport,
  filePicker,
  timer,
}

final class _PanelRange {
  const _PanelRange({
    required this.focus,
    required this.startLine,
    required this.endLine,
    required this.endCol,
  });

  final _WidgetsFocus focus;
  final int startLine;
  final int endLine;
  final int endCol;
}

String _box(
  _KitchenSinkModel m,
  String heading,
  String body, {
  required _WidgetsFocus focus,
}) {
  final focused =
      m._activePage is _WidgetsPage &&
      (m._activePage as _WidgetsPage)._focus == focus &&
      focus != _WidgetsFocus.none;

  final base = m._style(Style()).border(Border.rounded).padding(0, 1);
  final style = focused
      ? (base..borderForeground(Colors.yellow))
      : (base
          ..borderForegroundBlend([Colors.rose, Colors.indigo, Colors.teal])
          ..borderForegroundBlendOffset(2));

  final h = m._style(Style()).bold().render(heading);
  return style.render([h, '', body].join('\n'));
}

final class _NeofetchPage extends _KitchenSinkPage {
  const _NeofetchPage()
    : super(help: 'Neofetch: static-ish system summary (no external commands)');

  @override
  String view(_KitchenSinkModel m) {
    final title = m._style(Style()).bold().render('Neofetch (demo)');

    final user = io.Platform.environment['USER'] ?? 'user';
    final host = io.Platform.localHostname;
    final header = m
        ._style(Style())
        .bold()
        .foreground(Colors.lime)
        .render('$user@$host');
    final underline = m
        ._style(Style())
        .dim()
        .render('-' * math.min(Style.visibleLength('$user@$host'), 28));

    final os =
        _readOsPrettyName() ??
        '${io.Platform.operatingSystem} ${io.Platform.operatingSystemVersion}'
            .trim();
    final kernel =
        _extractKernel(io.Platform.operatingSystemVersion) ??
        io.Platform.operatingSystemVersion;
    final shell = (io.Platform.environment['SHELL'] ?? '').split('/').last;
    final term = io.Platform.environment['TERM'] ?? '(unknown)';
    final uptime = _readUptimePretty() ?? '(unknown)';
    final mem = _readMemPretty() ?? '(unknown)';

    String kv(String k, String v) {
      final key = m
          ._style(Style())
          .bold()
          .foreground(Colors.lime)
          .render('$k:');
      return '$key $v';
    }

    final infoLines = <String>[
      header,
      underline,
      kv('OS', os),
      kv('Kernel', kernel),
      kv('Uptime', uptime),
      kv('Shell', shell.isEmpty ? '(unknown)' : shell),
      kv('Terminal', term),
      kv('Resolution', '${m._width}x${m._height} (cells)'),
      kv('Renderer', m.useUvRenderer ? 'uv' : 'default'),
      kv('Input', m.useUvInput ? 'uv' : 'legacy'),
      kv('Memory', mem),
      '',
      _colorSwatches(m),
    ].join('\n');

    final logo = _neofetchLogo(m);
    final columns = Layout.joinHorizontal(VerticalAlign.top, [
      logo,
      '  ',
      infoLines,
    ]);

    return [title, '', columns].join('\n');
  }
}

final class _GraphicsPage extends _KitchenSinkPage {
  const _GraphicsPage()
    : super(help: 'Graphics: demonstrates Kitty/iTerm2/Sixel image support');

  @override
  String view(_KitchenSinkModel m) {
    final title = m._style(Style()).bold().render('Graphics (Image Protocols)');

    final caps = m.capabilities;
    final best = uvt.Terminal.bestImageDrawable(
      img.Image(width: 1, height: 1),
      capabilities: caps,
    );

    final protocolName = switch (best.runtimeType.toString()) {
      'KittyImageDrawable' => 'Kitty Graphics Protocol',
      'ITerm2ImageDrawable' => 'iTerm2 Inline Images',
      'SixelImageDrawable' => 'Sixel Graphics',
      _ => 'None (Fallback to ASCII)',
    };

    return [
      title,
      '',
      'Your terminal supports the following image protocols:',
      '',
      '  Kitty Graphics: ${caps.hasKittyGraphics ? "✅" : "❌"}',
      '  iTerm2 Images:  ${caps.hasITerm2 ? "✅" : "❌"}',
      '  Sixel Graphics: ${caps.hasSixel ? "✅" : "❌"}',
      '',
      'Best available: $protocolName',
      '',
      'Note: To see real images, check out the dedicated image demos:',
      '  - example/compositor_image_demo.dart',
      '  - example/uv/image.dart',
    ].join('\n');
  }
}

final class _CapabilitiesPage extends _KitchenSinkPage {
  const _CapabilitiesPage()
    : super(help: 'Capabilities: shows detected terminal features');

  @override
  String view(_KitchenSinkModel m) {
    final title = m._style(Style()).bold().render('Terminal Capabilities');

    final caps = m.capabilities;

    String boolIcon(bool b) => b ? '✅' : '❌';

    final rows = [
      ['Kitty Graphics', boolIcon(caps.hasKittyGraphics)],
      ['Sixel Graphics', boolIcon(caps.hasSixel)],
      ['iTerm2 Images', boolIcon(caps.hasITerm2)],
      ['Keyboard Protocol', boolIcon(caps.hasKeyboardEnhancements)],
      ['Color Palette', boolIcon(caps.hasColorPalette)],
      ['Background Color', boolIcon(caps.hasBackgroundColor)],
    ];

    final table = Table()
      ..border(Border.rounded)
      ..style(m._style(Style()).foreground(Colors.cyan))
      ..headerStyle(m._style(Style()).bold())
      ..headers(['Feature', 'Supported'])
      ..rows(rows);

    final details = [
      'Terminal: ${io.Platform.environment['TERM'] ?? 'unknown'}',
      'Program: ${io.Platform.environment['TERM_PROGRAM'] ?? 'unknown'}',
      '',
      'These capabilities are discovered via ANSI queries (DA1, DA2, etc.)',
      'and environment variable hints.',
    ].join('\n');

    return [title, '', table.render(), '', details].join('\n');
  }
}

final class _KeyboardPage extends _KitchenSinkPage {
  const _KeyboardPage()
    : super(help: 'Keyboard: demonstrates enhanced keyboard protocol');

  @override
  String view(_KitchenSinkModel m) {
    final title = m._style(Style()).bold().render('Keyboard Enhancements');

    final caps = m.capabilities;

    final info = [
      'Enhanced Protocol: ${caps.hasKeyboardEnhancements ? "Enabled ✅" : "Disabled ❌"}',
      '',
      'If enabled, you can detect:',
      '- Release events (KeyUp)',
      '- Modifier keys (Super, Hyper, Meta)',
      '- Distinguish between Esc and Alt+key',
      '',
      'Try pressing keys with various modifiers!',
    ].join('\n');

    final logTitle = m._style(Style()).bold().render('Recent Events:');
    final log = m._eventLog.reversed.take(10).join('\n');

    return [title, '', info, '', logTitle, log].join('\n');
  }
}

final class _ListSelectionState {
  const _ListSelectionState({
    required this.items,
    required this.cursor,
    required this.selected,
  });

  factory _ListSelectionState.initial() => const _ListSelectionState(
    items: [
      _EmojiItem(emoji: '🍕', fallback: '[P]', label: 'Pizza'),
      _EmojiItem(emoji: '🍔', fallback: '[B]', label: 'Burger'),
      _EmojiItem(emoji: '🌮', fallback: '[T]', label: 'Tacos'),
      _EmojiItem(emoji: '🍜', fallback: '[R]', label: 'Ramen'),
      _EmojiItem(emoji: '🥗', fallback: '[S]', label: 'Salad'),
      _EmojiItem(emoji: '🍣', fallback: '[S]', label: 'Sushi'),
      _EmojiItem(emoji: '🥪', fallback: '[S]', label: 'Sandwich'),
      _EmojiItem(emoji: '🍝', fallback: '[P]', label: 'Pasta'),
    ],
    cursor: 0,
    selected: null,
  );

  final List<_EmojiItem> items;
  final int cursor;
  final String? selected;

  (_ListSelectionState, tui.Cmd?) update(tui.Key key) {
    return switch (key) {
      _ when key.type == tui.KeyType.up || key.isChar('k') => (
        copyWith(cursor: (cursor - 1).clamp(0, items.length - 1)),
        null,
      ),

      _ when key.type == tui.KeyType.down || key.isChar('j') => (
        copyWith(cursor: (cursor + 1).clamp(0, items.length - 1)),
        null,
      ),

      _ when key.isAccept => (copyWith(selected: items[cursor].label), null),

      _ when key.isChar('r') => (_ListSelectionState.initial(), null),

      _ => (this, null),
    };
  }

  _ListSelectionState copyWith({int? cursor, String? selected}) {
    return _ListSelectionState(
      items: items,
      cursor: cursor ?? this.cursor,
      selected: selected ?? this.selected,
    );
  }

  String view(_KitchenSinkModel m) {
    final buf = StringBuffer();
    buf.writeln();
    buf.writeln('  What would you like?');
    buf.writeln();

    for (var i = 0; i < items.length; i++) {
      final isSelected = i == cursor;
      final prefix = isSelected ? '▸ ' : '  ';
      final item = items[i];
      final icon = m.emoji(item.emoji, item.fallback);
      final line = '  $prefix$icon ${item.label}';
      buf.writeln(
        isSelected
            ? Style().foreground(const BasicColor('14')).render(line)
            : line,
      );
    }

    buf.writeln();
    buf.writeln(
      Style().dim().render('  ↑/k: up • ↓/j: down • Enter: select • r: reset'),
    );
    return buf.toString();
  }
}

final class _EmojiItem {
  const _EmojiItem({
    required this.emoji,
    required this.fallback,
    required this.label,
  });

  final String emoji;
  final String fallback;
  final String label;
}

String _clipToWidth(String s, int maxWidth) {
  if (maxWidth <= 0) return '';
  if (Style.visibleLength(s) <= maxWidth) return s;

  var w = 0;
  final out = StringBuffer();
  for (final g in uni.graphemes(s)) {
    final gw = Style.visibleLength(g);
    if (w + gw > maxWidth) break;
    out.write(g);
    w += gw;
  }
  return out.toString();
}

String _neofetchLogo(_KitchenSinkModel m) {
  final s = m._style(Style());
  final a = s.copy()..background(const BasicColor('#a8b85b'));
  final b = s.copy()..background(const BasicColor('#6d7a2b'));

  String block(Style bg, int w) => bg.render(' ' * w);

  final w = 12;
  final rows = <String>[
    '${block(a, w)}${block(a, w)}',
    '${block(a, w)}${block(a, w)}',
    '${block(a, w)}${block(b, 3)}${block(a, w - 3)}${block(a, w)}',
    '${block(a, w)}${block(b, 3)}${block(a, w - 3)}${block(a, w)}',
    '${block(a, w)}${block(b, 3)}${block(a, w - 3)}${block(a, w)}',
    '${block(a, w)}${block(a, w)}',
    '${block(a, w)}${block(a, w)}',
  ];

  return rows.join('\n');
}

String _colorSwatches(_KitchenSinkModel m) {
  final s = m._style(Style());
  final colors = <Color>[
    Colors.black,
    Colors.red,
    Colors.green,
    Colors.yellow,
    Colors.blue,
    Colors.magenta,
    Colors.cyan,
    Colors.white,
  ];
  final top = colors.map((c) => (s.copy()..background(c)).render('   ')).join();
  final dim = colors
      .map(
        (c) =>
            (s.copy()
                  ..background(c)
                  ..dim())
                .render('   '),
      )
      .join();
  return '$dim\n$top';
}

String? _readOsPrettyName() {
  try {
    final f = io.File('/etc/os-release');
    if (!f.existsSync()) return null;
    final lines = f.readAsLinesSync();
    for (final line in lines) {
      if (!line.startsWith('PRETTY_NAME=')) continue;
      var v = line.substring('PRETTY_NAME='.length).trim();
      v = v.replaceAll('"', '');
      return v.isEmpty ? null : v;
    }
  } catch (_) {
    // ignore
  }
  return null;
}

String? _extractKernel(String osVersion) {
  final m = RegExp(r'(\\d+\\.\\d+\\.\\d+[^\\s)]*)').firstMatch(osVersion);
  return m?.group(1);
}

String? _readUptimePretty() {
  try {
    final f = io.File('/proc/uptime');
    if (!f.existsSync()) return null;
    final parts = f.readAsStringSync().trim().split(' ');
    if (parts.isEmpty) return null;
    final seconds = double.tryParse(parts.first);
    if (seconds == null) return null;
    final total = seconds.round();
    final days = total ~/ 86400;
    final hours = (total % 86400) ~/ 3600;
    final mins = (total % 3600) ~/ 60;
    if (days > 0)
      return '$days day${days == 1 ? '' : 's'}, $hours hour${hours == 1 ? '' : 's'}, $mins min';
    if (hours > 0) return '$hours hour${hours == 1 ? '' : 's'}, $mins min';
    return '$mins min';
  } catch (_) {
    return null;
  }
}

String? _readMemPretty() {
  try {
    final f = io.File('/proc/meminfo');
    if (!f.existsSync()) return null;
    int? totalKb;
    int? availKb;
    for (final line in f.readAsLinesSync()) {
      if (line.startsWith('MemTotal:')) {
        totalKb = int.tryParse(line.split(RegExp(r'\\s+'))[1]);
      } else if (line.startsWith('MemAvailable:')) {
        availKb = int.tryParse(line.split(RegExp(r'\\s+'))[1]);
      }
      if (totalKb != null && availKb != null) break;
    }
    if (totalKb == null || availKb == null) return null;
    final usedKb = (totalKb - availKb).clamp(0, totalKb);
    String mib(int kb) => (kb / 1024).round().toString();
    return '${mib(usedKb)}MiB / ${mib(totalKb)}MiB';
  } catch (_) {
    return null;
  }
}

Future<void> main(List<String> args) async {
  if (args.contains('-h') || args.contains('--help')) {
    io.stdout.writeln(''' // tui:allow-stdout
Kitchen-sink TUI

Usage:
  dart run packages/artisan_args/example/tui/examples/kitchen-sink/main.dart [options]

Options:
  --legacy-input     Use legacy KeyParser input
  --uv-renderer      Use UV renderer (cell-buffer diff)
''');
    return;
  }

  final legacy = args.contains('--legacy-input');
  final uvRenderer = args.contains('--uv-renderer');

  await tui.runProgram(
    _KitchenSinkModel(useUvInput: !legacy, useUvRenderer: uvRenderer),
    options: tui.ProgramOptions(
      altScreen: true,
      mouse: true,
      bracketedPaste: true,
      useUltravioletInputDecoder: !legacy,
      useUltravioletRenderer: uvRenderer,
    ),
  );
}

class _LipglossV2Page extends _KitchenSinkPage {
  const _LipglossV2Page() : super(help: 'Lipgloss v2 parity features');

  @override
  String view(_KitchenSinkModel model) {
    final buffer = StringBuffer();

    final titleStyle = Style().bold().foreground(Colors.success);
    final labelStyle = Style().foreground(Colors.muted).width(20);

    buffer.writeln(titleStyle.render('Lipgloss v2 Parity Features'));
    buffer.writeln();

    // 1. Underline Color
    final ulColorStyle = Style()
        .underline()
        .underlineStyle(UnderlineStyle.curly)
        .underlineColor(Colors.error)
        .bold();
    buffer.writeln(
      '${labelStyle.render('Underline Color:')} ${ulColorStyle.render('Curly red underline on bold text')}',
    );
    buffer.writeln(
      '${labelStyle.render('Underline Stress:')} '
      '${Style().underline().underlineColor(Colors.error).render('single')}  '
      '${Style().underlineStyle(UnderlineStyle.double).underline().underlineColor(Colors.warning).render('double')}  '
      '${Style().underlineStyle(UnderlineStyle.dotted).underline().underlineColor(Colors.info).render('dotted')}  '
      '${Style().underlineStyle(UnderlineStyle.dashed).underline().underlineColor(Colors.success).render('dashed')}',
    );
    buffer.writeln(
      '${labelStyle.render('Underline 256:')} '
      '${Style().underlineStyle(UnderlineStyle.curly).underline().underlineColor(const AnsiColor(196)).render('idx196')}  '
      '${Style().underlineStyle(UnderlineStyle.curly).underline().underlineColor(const AnsiColor(21)).render('idx21')}',
    );
    buffer.writeln(
      '${labelStyle.render('Underline RGB:')} '
      '${Style().underlineStyle(UnderlineStyle.curly).underline().underlineColor(const BasicColor('#ff0000')).render('#ff0000')}  '
      '${Style().underlineStyle(UnderlineStyle.curly).underline().underlineColor(const BasicColor('#00ff00')).render('#00ff00')}  '
      '${Style().underlineStyle(UnderlineStyle.curly).underline().underlineColor(const BasicColor('#0000ff')).render('#0000ff')}',
    );

    // 2. Padding Character
    final padCharStyle = Style()
        .background(Colors.muted)
        .padding(1, 2)
        .paddingChar('.')
        .foreground(Colors.white);
    buffer.writeln(
      '${labelStyle.render('Padding Char:')} ${padCharStyle.render('Dots as padding')}',
    );

    // 3. Margin Character & Background
    final marginStyle = Style()
        .background(Colors.success)
        .margin(1, 2)
        .marginChar('#')
        .marginBackground(Colors.warning)
        .foreground(Colors.white);
    buffer.writeln('${labelStyle.render('Margin Char/Bg:')}');
    buffer.writeln(
      marginStyle.render('Styled box with hash margins on yellow background'),
    );

    // 4. Underline Spaces
    final ulSpacesStyle = Style().underline().underlineSpaces(true);
    final noUlSpacesStyle = Style().underline().underlineSpaces(false);
    buffer.writeln(
      '${labelStyle.render('Underline Spaces:')} ${ulSpacesStyle.render('Underlined  Spaces')} vs ${noUlSpacesStyle.render('No  Underlined  Spaces')}',
    );

    // 5. Strikethrough Spaces
    final stSpacesStyle = Style().strikethrough().strikethroughSpaces(true);
    final noStSpacesStyle = Style().strikethrough().strikethroughSpaces(false);
    buffer.writeln(
      '${labelStyle.render('Strikethrough Spaces:')} ${stSpacesStyle.render('Strikethrough  Spaces')} vs ${noStSpacesStyle.render('No  Strikethrough  Spaces')}',
    );

    // 6. Faint & Reverse Aliases
    final faintStyle = Style().faint();
    final reverseStyle = Style().reverse();
    buffer.writeln(
      '${labelStyle.render('Faint/Reverse:')} ${faintStyle.render('Faint text')} and ${reverseStyle.render('Reverse text')}',
    );

    // 7. Multi-string Render
    final multiStyle = Style().bold().foreground(Colors.warning);
    buffer.writeln(
      '${labelStyle.render('Multi-string Render:')} ${multiStyle.render(['Joined', 'with', 'spaces'])}',
    );

    // 7b. A noisy ANSI line to stress state transitions in the UV renderer.
    final ulA = Style().underline().underlineColor(Colors.error);
    final ulB = Style()
        .underlineStyle(UnderlineStyle.curly)
        .underline()
        .underlineColor(Colors.warning);
    final ulC = Style()
        .underlineStyle(UnderlineStyle.dotted)
        .underline()
        .underlineColor(Colors.info);
    buffer.writeln(
      '${labelStyle.render('ANSI Stress:')} '
      '${ulA.render('A')}'
      '${Style().bold().render('B')}'
      '${ulB.render('C')}'
      '${Style().italic().render('D')}'
      '${ulC.render('E')}'
      '${Style().render('F')}',
    );

    // 8. Table BaseStyle
    final baseStyle = Style().foreground(Colors.muted).italic();
    final table = Table()
        .headers(['Feature', 'Status'])
        .row(['BaseStyle', 'Inherited'])
        .row(['StyleFunc', 'Overrides'])
        .baseStyle(baseStyle)
        .styleFunc((row, col, data) {
          if (data == 'Overrides')
            return Style().foreground(Colors.success).bold().unsetItalic();
          return null;
        })
        .border(Border.rounded);

    buffer.writeln();
    buffer.writeln(titleStyle.render('Table BaseStyle Inheritance'));
    buffer.writeln(table.render());

    return buffer.toString();
  }
}

final class _CompositorPage extends _KitchenSinkPage {
  const _CompositorPage()
    : super(
        help: 'Compositor: demonstrates UV layering and canvas composition',
      );

  @override
  String view(_KitchenSinkModel m) {
    final title = m._style(Style()).bold().render('UV Compositor & Layering');

    // Create some styled content.
    final bgBox = Style()
        .background(Colors.muted)
        .width(40)
        .height(10)
        .render('');

    final foregroundBox = Style()
        .background(Colors.indigo)
        .foreground(Colors.white)
        .padding(1, 2)
        .border(Border.rounded)
        .render('I am a floating layer');

    final textLayer = StyledString(
      m
          ._style(Style())
          .bold()
          .foreground(Colors.warning)
          .render('Topmost Text'),
    );

    // Build a composition.
    final comp = Compositor([
      Layer(StyledString(bgBox)).setId('bg').setZ(0),
      Layer(StyledString(foregroundBox)).setId('fg').setX(5).setY(2).setZ(10),
      Layer(textLayer).setId('text').setX(15).setY(4).setZ(20),
    ]);

    final rendered = comp.render();

    final info = [
      '',
      'The Compositor allows you to:',
      '- Layer multiple [Drawable]s with Z-index',
      '- Position elements with X/Y offsets',
      '- Perform hit-testing (useful for mouse interaction)',
      '- Render to a [Canvas] for final output',
      '',
      'Composition Result:',
      rendered,
    ].join('\n');

    return [title, info].join('\n');
  }
}

final class _SelectionPage extends _KitchenSinkPage {
  const _SelectionPage()
    : super(
        help:
            'Selection: Click and drag to select text in any component below. Press Ctrl+C to copy.',
      );

  @override
  void onActivate(_KitchenSinkModel m, List<tui.Cmd> cmds) {
    if (m.viewport.lines.isEmpty) {
      m.viewport = m.viewport.setContent('''
Text Selection Demo
===================

This page demonstrates the new text selection and clipboard features.

1. Viewport Selection:
   You can click and drag anywhere in this scrollable area to select text.
   Once selected, press 'Ctrl+C' or 'y' to copy it to your system clipboard.

2. Multi-line TextArea:
   The box below is a TextArea. It supports multi-line selection,
   soft-wrapping, and standard editing shortcuts.

3. Single-line TextInput:
   The search box at the bottom also supports selection.

Try selecting this paragraph and copying it!
The selection will persist even if you scroll the viewport.
''');
    }

    if (m.text.lines.isEmpty) {
      m.text = m.text.setContent('''
4. Text Component (Auto-height):
   This is a TextModel component. It is built on top of ViewportModel
   but defaults to auto-height (no scrolling) and soft-wrapping.
   It also supports selection and copying just like the Viewport.
''');
    }
  }

  @override
  String view(_KitchenSinkModel m) {
    final out = <String>[];

    out.add(
      m._style(Style()).bold().render('1. Viewport (Scrollable & Selectable)'),
    );
    final vpTop = out.length;
    out.addAll(m.viewport.view().split('\n'));
    out.add('');

    out.add(m._style(Style()).bold().render('2. TextArea (Multi-line Input)'));
    final taTop = out.length;
    out.addAll((m.textarea.view() as String).split('\n'));
    out.add('');

    out.add(
      m._style(Style()).bold().render('3. TextInput (Single-line Input)'),
    );
    final tiTop = out.length;
    out.addAll((m.textInput.view() as String).split('\n'));
    out.add('');

    out.add(
      m._style(Style()).bold().render('4. Text (Auto-height & Selectable)'),
    );
    final txTop = out.length;
    out.addAll(m.text.view().split('\n'));
    out.add('');

    out.add(
      m
          ._style(Style())
          .dim()
          .render(
            'Tip: Use your mouse to select text. Press Ctrl+C to copy to clipboard.',
          ),
    );

    m._selectionLayout = _SelectionLayout(
      viewportTop: vpTop,
      textAreaTop: taTop,
      textInputTop: tiTop,
      textTop: txTop,
    );

    return out.join('\n');
  }

  @override
  void onMsg(_KitchenSinkModel m, tui.Msg msg, List<tui.Cmd> cmds) {
    var vpMsg = msg;
    var taMsg = msg;
    var tiMsg = msg;
    var txMsg = msg;

    if (msg is tui.MouseMsg) {
      final pageY = msg.y - m._headerLines;
      vpMsg = msg.copyWith(y: pageY - m._selectionLayout.viewportTop);
      taMsg = msg.copyWith(y: pageY - m._selectionLayout.textAreaTop);
      tiMsg = msg.copyWith(y: pageY - m._selectionLayout.textInputTop);
      txMsg = msg.copyWith(y: pageY - m._selectionLayout.textTop);
    }

    // Update Viewport
    final (newVp, vpCmd) = m.viewport.update(vpMsg);
    m.viewport = newVp;
    if (vpCmd != null) cmds.add(vpCmd);

    // Update TextArea
    final (_, taCmd) = m.textarea.update(taMsg);
    if (taCmd != null) cmds.add(taCmd);

    // Update TextInput
    final (_, tiCmd) = m.textInput.update(tiMsg);
    if (tiCmd != null) cmds.add(tiCmd);

    // Update Text
    final (newTx, txCmd) = m.text.update(txMsg);
    m.text = newTx;
    if (txCmd != null) cmds.add(txCmd);
  }
}
