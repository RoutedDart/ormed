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

import 'package:artisan_args/artisan_args.dart'
    show
        AnsiColor,
        BasicColor,
        Layout,
        LipList,
        ListEnumerators,
        Style,
        Table,
        Tree,
        TreeEnumerator,
        VerticalAlign;
import 'package:artisan_args/src/unicode/grapheme.dart' as uni;
import 'package:artisan_args/tui.dart' as tui;

enum _Page {
  overview('Overview'),
  input('Input'),
  listSelect('List'),
  renderer('Renderer'),
  lipgloss('Tree/List/Table'),
  unicode('Unicode'),
  ;

  const _Page(this.title);
  final String title;
}

class _TickMsg extends tui.Msg {
  const _TickMsg();
}

class _KitchenSinkModel extends tui.Model {
  _KitchenSinkModel({
    required this.useUvInput,
    required this.useUvRenderer,
  }) : spinner = tui.SpinnerModel(spinner: tui.Spinners.miniDot),
       progress = tui.ProgressModel(width: 44, useGradient: true),
       textInput = tui.TextInputModel(prompt: 'search: ', width: 32),
       textarea = tui.TextAreaModel(
         width: 48,
         height: 6,
         prompt: '',
       ),
       listSelection = _ListSelectionState.initial();

  final bool useUvInput;
  final bool useUvRenderer;

  int _width = 80;
  int _height = 24;
  int _pageIndex = 0;
  bool _showHelp = true;

  final tui.SpinnerModel spinner;
  tui.ProgressModel progress;
  final tui.TextInputModel textInput;
  final tui.TextAreaModel textarea;

  _ListSelectionState listSelection;
  final List<String> _eventLog = <String>[];

  _Page get _page => _Page.values[_pageIndex.clamp(0, _Page.values.length - 1)];

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

  void _nextPage([int delta = 1]) {
    final len = _Page.values.length;
    _pageIndex = (_pageIndex + delta) % len;
    if (_pageIndex < 0) _pageIndex += len;
  }

  @override
  tui.Cmd? init() {
    final cmds = <tui.Cmd>[
      spinner.tick(),
      _scheduleTick(),
      tui.Cmd.enableReportFocus(),
      tui.Cmd.enableBracketedPaste(),
      tui.Cmd.enableMouseCellMotion(),
    ];
    final focus = textInput.focus();
    if (focus != null) cmds.add(focus);
    return tui.Cmd.batch(cmds);
  }

  @override
  (tui.Model, tui.Cmd?) update(tui.Msg msg) {
    final cmds = <tui.Cmd>[];

    switch (msg) {
      case tui.WindowSizeMsg(:final width, :final height):
        _width = width;
        _height = height;
        return (this, null);

      case _TickMsg():
        cmds.add(_scheduleTick());
        // Nudge the progress bar on the Renderer page.
        if (_page == _Page.renderer) {
          final next =
              progress.percent >= 1 ? 0.0 : (progress.percent + 0.03);
          final (p, c) = progress.setPercent(next, animate: true);
          progress = p;
          if (c != null) cmds.add(c);
        }
        // Keep the spinner moving.
        cmds.add(spinner.tick());
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

        // Global page navigation.
        if (key.type == tui.KeyType.tab) {
          _nextPage(key.shift ? -1 : 1);
          return (this, null);
        }
        if (key.type == tui.KeyType.left) {
          _nextPage(-1);
          return (this, null);
        }
        if (key.type == tui.KeyType.right) {
          _nextPage(1);
          return (this, null);
        }
        if (key.type == tui.KeyType.runes && key.runes.isNotEmpty) {
          final r = key.runes.first;
          // 1..9 jump to page.
          if (r >= 0x31 && r <= 0x39) {
            final idx = (r - 0x31).clamp(0, _Page.values.length - 1);
            _pageIndex = idx;
            return (this, null);
          }
        }

        // Page-specific handling.
        switch (_page) {
          case _Page.input:
            _log('KeyMsg($key)');
            if (key.isChar('c')) {
              cmds.add(tui.Cmd.setClipboard('kitchen-sink: hello'));
            } else if (key.isChar('p')) {
              cmds.add(tui.Cmd.requestClipboard());
            } else if (key.isChar('s')) {
              cmds.add(tui.Cmd.requestWindowSizeReport());
            }

          case _Page.listSelect:
            final (next, cmd) = listSelection.update(key);
            listSelection = next;
            if (cmd != null) cmds.add(cmd);

          case _Page.renderer:
            if (key.isChar('r')) {
              final (p, c) = progress.setPercent(0, animate: false);
              progress = p;
              if (c != null) cmds.add(c);
            } else if (key.isChar('g')) {
              final (p, c) = progress.setPercent(1, animate: true);
              progress = p;
              if (c != null) cmds.add(c);
            }

          case _Page.unicode:
          case _Page.lipgloss:
          case _Page.overview:
            break;
        }

      case tui.ClipboardMsg(:final selection, :final content):
        _log(
          'ClipboardMsg(selection: $selection, ${content.length} bytes): ${content.replaceAll('\n', r'\n')}',
        );

      case tui.UvEventMsg(:final event):
        _log('UvEventMsg(${event.runtimeType}): $event');
    }

    // Let input controls keep their own state on relevant pages.
    if (_page == _Page.input) {
      final (newInput, inputCmd) = textInput.update(msg);
      if (newInput.value != textInput.value) {
        textInput.value = newInput.value;
      }
      if (inputCmd != null) cmds.add(inputCmd);

      final (newArea, areaCmd) = textarea.update(msg);
      if (newArea.value != textarea.value) {
        textarea.value = newArea.value;
      }
      if (areaCmd != null) cmds.add(areaCmd);
    }

    return (this, cmds.isEmpty ? null : tui.Cmd.batch(cmds));
  }

  @override
  String view() {
    final header = _renderHeader();
    final body = switch (_page) {
      _Page.overview => _viewOverview(),
      _Page.input => _viewInput(),
      _Page.listSelect => _viewListSelect(),
      _Page.renderer => _viewRenderer(),
      _Page.lipgloss => _viewLipgloss(),
      _Page.unicode => _viewUnicode(),
    };
    final footer = _showHelp ? _renderHelp() : '';

    // Keep a small bottom margin for terminals that overwrite last line.
    return [header, body, footer, ''].where((s) => s.isNotEmpty).join('\n');
  }

  String _renderHeader() {
    final title = Style().bold().render('Kitchen Sink');
    final mode = Style()
        .dim()
        .render(
          'input=${useUvInput ? 'uv' : 'legacy'}  renderer=${useUvRenderer ? 'uv' : 'default'}  size=${_width}x${_height}',
        );

    final tabs = <String>[];
    for (var i = 0; i < _Page.values.length; i++) {
      final p = _Page.values[i];
      final active = i == _pageIndex;
      final label = '${i + 1}:${p.title}';
      final chip = active
          ? Style()
              .foreground(const AnsiColor(16))
              .background(const AnsiColor(220))
              .padding(0, 1)
              .render(label)
          : Style().dim().padding(0, 1).render(label);
      tabs.add(chip);
    }

    final tabLine = tabs.join(' ');
    final divider = Style().dim().render('─' * _width.clamp(10, 200));
    return [title, mode, tabLine, divider].join('\n');
  }

  String _renderHelp() {
    final help =
        'q quit • ←/→ or Tab switch pages • 1-${_Page.values.length} jump • ? toggle help';
    final pageHelp = switch (_page) {
      _Page.input =>
        'Input: type in box • paste/mouse/focus/resize logs • c copy • p clipboard read • s size report',
      _Page.listSelect => 'List: ↑/↓ or j/k move • Enter select • r reset',
      _Page.renderer => 'Renderer: r reset progress • g complete progress',
      _Page.lipgloss => 'Tree/List/Table: static render parity surfaces',
      _Page.unicode => 'Unicode: width + grapheme clipping samples',
      _Page.overview => 'Overview: what this app covers',
    };
    return Style().dim().render('$help\n$pageHelp');
  }

  String _viewOverview() {
    final lines = <String>[
      Style().bold().render('What to test here'),
      '',
      '• UV renderer: dynamic updates (Renderer tab), tables/trees/lists (Tree/List/Table tab)',
      '• UV input decoder: Enter/Tab/arrows/paste/mouse (Input + List tabs)',
      '• Unicode width: emoji/CJK/grapheme clusters (Unicode tab)',
      '',
      Style().dim().render('Tip: run with `--uv-renderer` and resize the terminal.'),
    ];
    return lines.join('\n');
  }

  String _viewInput() {
    final left = <String>[
      Style().bold().render('Input controls'),
      '',
      'TextInput:',
      '  ${textInput.view()}',
      '',
      'TextArea:',
      textarea.view(),
      '',
      Style().dim().render('Recent events (newest last):'),
    ];

    final maxLog = (_height - 18).clamp(3, 9999);
    final logLines = _eventLog.length <= maxLog
        ? _eventLog
        : _eventLog.sublist(_eventLog.length - maxLog);
    final clipped = logLines.map((l) => _clipToWidth(l, _width)).join('\n');

    return [left.join('\n'), '', clipped].join('\n');
  }

  String _viewListSelect() {
    final title = Style().bold().render('Interactive list (accept/select)');
    final subtitle = Style()
        .dim()
        .render(
          'Selected: ${listSelection.selected ?? '(none)'}  (Enter should select)',
        );
    return [title, subtitle, '', listSelection.view()].join('\n');
  }

  String _viewRenderer() {
    final title = Style().bold().render('Renderer stress');
    final status =
        '${spinner.view()}  ${progress.view()}  ${Style().dim().render('(tick-driven)')}';

    final sample = (Tree()
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

  String _viewLipgloss() {
    final title = Style().bold().render('Tree/List/Table (lipgloss v2 parity)');

    final tree = (Tree()
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

    final list = (LipList.create([
      'Foo',
      'Bar',
      LipList.create(['Hi', 'Hello', 'Halo']).enumerator(ListEnumerators.roman),
      'Qux',
    ])).render();

    final table =
        (Table()
              ..width(26)
              ..headers(['Col A', 'Col B'])
              ..row(['a', 'b'])
              ..row(['longer text', 'ok']))
            .render();

    final left = [Style().dim().render('Tree:'), tree].join('\n');
    final right = [
      Style().dim().render('List:'),
      list,
      '',
      Style().dim().render('Table:'),
      table,
    ].join('\n');

    final columns = Layout.joinHorizontal(
      VerticalAlign.top,
      [
        left,
        '   ',
        right,
      ],
    );

    return [title, '', columns].join('\n');
  }

  String _viewUnicode() {
    final title = Style().bold().render('Unicode width + grapheme clusters');
    final samples = <String>[
      'ASCII: hello',
      'CJK: 漢字かなカナ',
      'Emoji: 🍕🍔🌮',
      'Flags: 🇺🇸🇯🇵🇫🇷',
      'ZWJ: 👩‍💻👨‍👩‍👧‍👦',
      'Combining: e\u0301  a\u0308  n\u0303',
    ];

    final rows = <String>[];
    for (final s in samples) {
      final graphemes = uni.graphemes(s).toList(growable: false);
      rows.add(
        '${Style().dim().render('w=${Style.visibleLength(s).toString().padLeft(2)}  g=${graphemes.length.toString().padLeft(2)}')}  ${_clipToWidth(s, _width - 10)}',
      );
    }

    final explain = Style()
        .dim()
        .render(
          'The widths above use ANSI-aware display width and grapheme iteration; compare with resize + renderer.',
        );

    return [title, '', ...rows, '', explain].join('\n');
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
          'Pizza',
          'Burger',
          'Tacos',
          'Ramen',
          'Salad',
          'Sushi',
          'Sandwich',
          'Pasta',
        ],
        cursor: 0,
        selected: null,
      );

  final List<String> items;
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

      _ when key.isAccept => (
        copyWith(selected: items[cursor]),
        null,
      ),

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

  String view() {
    final buf = StringBuffer();
    buf.writeln();
    buf.writeln('  What would you like?');
    buf.writeln();

    for (var i = 0; i < items.length; i++) {
      final isSelected = i == cursor;
      final prefix = isSelected ? '▸ ' : '  ';
      final item = items[i];
      buf.writeln(
        isSelected
            ? Style().foreground(const BasicColor('14')).render('  $prefix$item')
            : '  $prefix$item',
      );
    }

    buf.writeln();
    buf.writeln(
      Style()
          .dim()
          .render('  ↑/k: up • ↓/j: down • Enter: select • r: reset'),
    );
    return buf.toString();
  }
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
