/// Simplified multi-line textarea bubble to satisfy examples and tests.
library;

import 'dart:math' as math;

import 'package:artisan_args/src/style/color.dart';
import 'package:artisan_args/src/style/style.dart';
import '../model.dart';
import '../msg.dart';
import '../cmd.dart';
import '../key.dart';
import 'key_binding.dart';
import 'runeutil.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Support types
// ─────────────────────────────────────────────────────────────────────────────

class LineInfo {
  LineInfo({
    this.width = 0,
    this.charWidth = 0,
    this.height = 0,
    this.startColumn = 0,
    this.columnOffset = 0,
    this.rowOffset = 0,
    this.charOffset = 0,
  });

  int width;
  int charWidth;
  int height;
  int startColumn;
  int columnOffset;
  int rowOffset;
  int charOffset;
}

class _DisplayLine {
  _DisplayLine(this.text, {this.hasCursor = false});

  final String text;
  final bool hasCursor;
}

class TextAreaStyle {
  TextAreaStyle({
    Style? base,
    Style? cursorLine,
    Style? cursorLineNumber,
    Style? endOfBuffer,
    Style? lineNumber,
    Style? placeholder,
    Style? prompt,
    Style? text,
  }) : base = base ?? Style(),
       cursorLine = cursorLine ?? Style(),
       cursorLineNumber = cursorLineNumber ?? Style(),
       endOfBuffer = endOfBuffer ?? Style(),
       lineNumber = lineNumber ?? Style(),
       placeholder = placeholder ?? Style(),
       prompt = prompt ?? Style(),
       text = text ?? Style();

  final Style base;
  final Style cursorLine;
  final Style cursorLineNumber;
  final Style endOfBuffer;
  final Style lineNumber;
  final Style placeholder;
  final Style prompt;
  final Style text;

  TextAreaStyle copyWith({
    Style? base,
    Style? cursorLine,
    Style? cursorLineNumber,
    Style? endOfBuffer,
    Style? lineNumber,
    Style? placeholder,
    Style? prompt,
    Style? text,
  }) {
    return TextAreaStyle(
      base: base ?? this.base,
      cursorLine: cursorLine ?? this.cursorLine,
      cursorLineNumber: cursorLineNumber ?? this.cursorLineNumber,
      endOfBuffer: endOfBuffer ?? this.endOfBuffer,
      lineNumber: lineNumber ?? this.lineNumber,
      placeholder: placeholder ?? this.placeholder,
      prompt: prompt ?? this.prompt,
      text: text ?? this.text,
    );
  }
}

TextAreaStyle defaultFocusedStyle() => TextAreaStyle(
  cursorLine: Style().background(const AnsiColor(0)),
  cursorLineNumber: Style().foreground(const AnsiColor(240)),
  endOfBuffer: Style().foreground(const AnsiColor(0)),
  lineNumber: Style().foreground(const AnsiColor(249)),
  placeholder: Style().foreground(const AnsiColor(240)),
  prompt: Style().foreground(const AnsiColor(7)),
  text: Style(),
);

TextAreaStyle defaultBlurredStyle() => TextAreaStyle(
  cursorLine: Style().foreground(const AnsiColor(245)),
  cursorLineNumber: Style().foreground(const AnsiColor(249)),
  endOfBuffer: Style().foreground(const AnsiColor(0)),
  lineNumber: Style().foreground(const AnsiColor(249)),
  placeholder: Style().foreground(const AnsiColor(240)),
  prompt: Style().foreground(const AnsiColor(7)),
  text: Style().foreground(const AnsiColor(245)),
);

class TextAreaPasteMsg implements Msg {
  TextAreaPasteMsg(this.content);
  final String content;
}

class TextAreaPasteErrorMsg implements Msg {
  TextAreaPasteErrorMsg(this.error);
  final Object error;
}

// ─────────────────────────────────────────────────────────────────────────────
// Key map
// ─────────────────────────────────────────────────────────────────────────────

class TextAreaKeyMap implements KeyMap {
  TextAreaKeyMap({
    KeyBinding? characterForward,
    KeyBinding? characterBackward,
    KeyBinding? wordForward,
    KeyBinding? wordBackward,
    KeyBinding? lineStart,
    KeyBinding? lineEnd,
    KeyBinding? lineNext,
    KeyBinding? linePrevious,
    KeyBinding? insertNewline,
    KeyBinding? deleteBeforeCursor,
    KeyBinding? deleteCharacterForward,
    KeyBinding? deleteWordBackward,
    KeyBinding? deleteWordForward,
    KeyBinding? deleteToLineStart,
    KeyBinding? deleteToLineEnd,
    KeyBinding? deleteAfterCursor,
    KeyBinding? inputBegin,
    KeyBinding? inputEnd,
    KeyBinding? transposeCharacterBackward,
    KeyBinding? uppercaseWordForward,
    KeyBinding? lowercaseWordForward,
    KeyBinding? capitalizeWordForward,
  }) : characterForward =
           characterForward ??
           KeyBinding.withHelp(['right', 'ctrl+f'], '→', 'character forward'),
       characterBackward =
           characterBackward ??
           KeyBinding.withHelp(['left', 'ctrl+b'], '←', 'character backward'),
       wordForward =
           wordForward ??
           KeyBinding.withHelp(['Alt+f'], 'alt+f', 'word forward'),
       wordBackward =
           wordBackward ??
           KeyBinding.withHelp(['Alt+b'], 'alt+b', 'word backward'),
       lineStart =
           lineStart ??
           KeyBinding.withHelp(['home', 'Ctrl+a'], 'home', 'line start'),
       lineEnd =
           lineEnd ?? KeyBinding.withHelp(['end', 'Ctrl+e'], 'end', 'line end'),
       lineNext =
           lineNext ??
           KeyBinding.withHelp(['down', 'ctrl+n'], '↓', 'next line'),
       linePrevious =
           linePrevious ??
           KeyBinding.withHelp(['up', 'ctrl+p'], '↑', 'previous line'),
       insertNewline =
           insertNewline ??
           KeyBinding.withHelp(['enter'], '↵', 'insert newline'),
       deleteBeforeCursor =
           deleteBeforeCursor ??
           KeyBinding.withHelp(['backspace'], '⌫', 'delete'),
       deleteCharacterForward =
           deleteCharacterForward ??
           KeyBinding.withHelp(['delete', 'ctrl+d'], 'del', 'del char forward'),
       deleteWordBackward =
           deleteWordBackward ??
           KeyBinding.withHelp(['alt+backspace'], 'alt+⌫', 'delete word'),
       deleteWordForward =
           deleteWordForward ??
           KeyBinding.withHelp(['Alt+delete', 'Alt+d'], 'alt+del', 'del word'),
       deleteToLineStart =
           deleteToLineStart ??
           KeyBinding.withHelp(['Ctrl+u'], 'ctrl+u', 'del to start'),
       deleteToLineEnd =
           deleteToLineEnd ??
           KeyBinding.withHelp(['Ctrl+k'], 'ctrl+k', 'del to end'),
       deleteAfterCursor =
           deleteAfterCursor ??
           KeyBinding.withHelp(['Ctrl+k'], 'ctrl+k', 'del after cursor'),
       inputBegin =
           inputBegin ??
           KeyBinding.withHelp(['alt+<', 'ctrl+home'], 'alt+<', 'input start'),
       inputEnd =
           inputEnd ??
           KeyBinding.withHelp(['alt+>', 'ctrl+end'], 'alt+>', 'input end'),
       transposeCharacterBackward =
           transposeCharacterBackward ??
           KeyBinding.withHelp(['Ctrl+t'], 'ctrl+t', 'transpose'),
       uppercaseWordForward =
           uppercaseWordForward ??
           KeyBinding.withHelp(['alt+u'], 'alt+u', 'uppercase word'),
       lowercaseWordForward =
           lowercaseWordForward ??
           KeyBinding.withHelp(['alt+l'], 'alt+l', 'lowercase word'),
       capitalizeWordForward =
           capitalizeWordForward ??
           KeyBinding.withHelp(['alt+c'], 'alt+c', 'capitalize word');

  final KeyBinding characterForward;
  final KeyBinding characterBackward;
  final KeyBinding wordForward;
  final KeyBinding wordBackward;
  final KeyBinding lineStart;
  final KeyBinding lineEnd;
  final KeyBinding lineNext;
  final KeyBinding linePrevious;
  final KeyBinding insertNewline;
  final KeyBinding deleteBeforeCursor;
  final KeyBinding deleteCharacterForward;
  final KeyBinding deleteWordBackward;
  final KeyBinding deleteWordForward;
  final KeyBinding deleteToLineStart;
  final KeyBinding deleteToLineEnd;
  final KeyBinding deleteAfterCursor;
  final KeyBinding inputBegin;
  final KeyBinding inputEnd;
  final KeyBinding transposeCharacterBackward;
  final KeyBinding uppercaseWordForward;
  final KeyBinding lowercaseWordForward;
  final KeyBinding capitalizeWordForward;

  TextAreaKeyMap copyWith({
    KeyBinding? characterForward,
    KeyBinding? characterBackward,
    KeyBinding? wordForward,
    KeyBinding? wordBackward,
    KeyBinding? lineStart,
    KeyBinding? lineEnd,
    KeyBinding? lineNext,
    KeyBinding? linePrevious,
    KeyBinding? insertNewline,
    KeyBinding? deleteBeforeCursor,
    KeyBinding? deleteCharacterForward,
    KeyBinding? deleteWordBackward,
    KeyBinding? deleteWordForward,
    KeyBinding? deleteToLineStart,
    KeyBinding? deleteToLineEnd,
    KeyBinding? deleteAfterCursor,
    KeyBinding? inputBegin,
    KeyBinding? inputEnd,
    KeyBinding? transposeCharacterBackward,
    KeyBinding? uppercaseWordForward,
    KeyBinding? lowercaseWordForward,
    KeyBinding? capitalizeWordForward,
  }) {
    return TextAreaKeyMap(
      characterForward: characterForward ?? this.characterForward,
      characterBackward: characterBackward ?? this.characterBackward,
      wordForward: wordForward ?? this.wordForward,
      wordBackward: wordBackward ?? this.wordBackward,
      lineStart: lineStart ?? this.lineStart,
      lineEnd: lineEnd ?? this.lineEnd,
      lineNext: lineNext ?? this.lineNext,
      linePrevious: linePrevious ?? this.linePrevious,
      insertNewline: insertNewline ?? this.insertNewline,
      deleteBeforeCursor: deleteBeforeCursor ?? this.deleteBeforeCursor,
      deleteCharacterForward:
          deleteCharacterForward ?? this.deleteCharacterForward,
      deleteWordBackward: deleteWordBackward ?? this.deleteWordBackward,
      deleteWordForward: deleteWordForward ?? this.deleteWordForward,
      deleteToLineStart: deleteToLineStart ?? this.deleteToLineStart,
      deleteToLineEnd: deleteToLineEnd ?? this.deleteToLineEnd,
      deleteAfterCursor: deleteAfterCursor ?? this.deleteAfterCursor,
      inputBegin: inputBegin ?? this.inputBegin,
      inputEnd: inputEnd ?? this.inputEnd,
      transposeCharacterBackward:
          transposeCharacterBackward ?? this.transposeCharacterBackward,
      uppercaseWordForward: uppercaseWordForward ?? this.uppercaseWordForward,
      lowercaseWordForward: lowercaseWordForward ?? this.lowercaseWordForward,
      capitalizeWordForward:
          capitalizeWordForward ?? this.capitalizeWordForward,
    );
  }

  @override
  List<KeyBinding> shortHelp() => [
    characterForward,
    characterBackward,
    wordForward,
    wordBackward,
    lineNext,
    linePrevious,
  ];

  @override
  List<List<KeyBinding>> fullHelp() => [
    [characterBackward, characterForward],
    [wordBackward, wordForward],
    [lineStart, lineEnd],
    [linePrevious, lineNext],
    [
      deleteBeforeCursor,
      deleteCharacterForward,
      deleteWordBackward,
      deleteWordForward,
      deleteToLineStart,
      deleteToLineEnd,
      deleteAfterCursor,
    ],
    [
      inputBegin,
      inputEnd,
      transposeCharacterBackward,
      uppercaseWordForward,
      lowercaseWordForward,
      capitalizeWordForward,
    ],
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// TextArea model (simplified)
// ─────────────────────────────────────────────────────────────────────────────

class TextAreaModel implements Model {
  TextAreaModel({
    this.prompt = '│ ',
    this.placeholder = '',
    this.showLineNumbers = true,
    this.charLimit = 0,
    this.softWrap = false,
    int width = 0,
    int height = 6,
    TextAreaKeyMap? keyMap,
  }) : keyMap = keyMap ?? TextAreaKeyMap(),
       _width = width,
       _height = height {
    _lines = [''];
  }

  String prompt;
  String placeholder;
  bool showLineNumbers;
  int charLimit;
  bool softWrap;
  TextAreaKeyMap keyMap;

  TextAreaStyle focusedStyle = defaultFocusedStyle();
  TextAreaStyle blurredStyle = defaultBlurredStyle();

  bool _focused = false;
  late List<String> _lines;
  int _row = 0;
  int _col = 0;
  int _width;
  int _height;

  bool get focused => _focused;
  int get line => _row;
  int get column => _col;
  int get width => _width;
  int get height => _height;
  int get lineCount => _lines.length;
  int get length => value.length;

  String get value => _lines.join('\n');
  set value(String v) {
    final limited = _applyCharLimit(v);
    _lines = limited.split('\n');
    _row = _lines.length - 1;
    _col = _lines.isNotEmpty ? _lines.last.length : 0;
  }

  @override
  Cmd? init() => null;

  Cmd? focus() {
    _focused = true;
    return null;
  }

  void blur() {
    _focused = false;
  }

  void reset() {
    _lines = [''];
    _row = 0;
    _col = 0;
  }

  void setWidth(int w) {
    _width = w;
  }

  void setHeight(int h) {
    _height = h;
  }

  void insertString(String s) {
    for (final r in s.runes) {
      if (r == 0x0a) {
        _newline();
      } else {
        _insertChar(String.fromCharCode(r));
      }
    }
  }

  void _insertChar(String ch) {
    final current = _lines[_row];
    final newText = current.substring(0, _col) + ch + current.substring(_col);
    final merged = [
      ..._lines.sublist(0, _row),
      newText,
      ..._lines.sublist(_row + 1),
    ].join('\n');
    final limited = _applyCharLimit(merged);
    _lines = limited.split('\n');
    _col += stringWidth(ch);
    if (_col > _lines[_row].length) _col = _lines[_row].length;
  }

  void _newline() {
    final current = _lines[_row];
    final before = current.substring(0, _col);
    final after = current.substring(_col);
    final merged = [
      ..._lines.sublist(0, _row),
      before,
      after,
      ..._lines.sublist(_row + 1),
    ].join('\n');
    final limited = _applyCharLimit(merged);
    _lines = limited.split('\n');
    _row = (_row + 1).clamp(0, _lines.length - 1);
    _col = 0;
  }

  void _backspace() {
    if (_row == 0 && _col == 0) return;
    if (_col > 0) {
      final current = _lines[_row];
      _lines[_row] = current.substring(0, _col - 1) + current.substring(_col);
      _col -= 1;
    } else if (_row > 0) {
      final prev = _lines[_row - 1];
      final current = _lines[_row];
      final merged = prev + current;
      _lines
        ..removeAt(_row)
        ..[_row - 1] = merged;
      _row -= 1;
      _col = prev.length;
    }
  }

  String _applyCharLimit(String text) {
    if (charLimit <= 0) return text;
    if (text.length <= charLimit) return text;
    return text.substring(0, charLimit);
  }

  void cursorStart() {
    _col = 0;
  }

  void cursorEnd() {
    _col = _lines[_row].length;
  }

  @override
  (Model, Cmd?) update(Msg msg) {
    switch (msg) {
      case TextAreaPasteMsg(:final content):
        insertString(content);
        return (this, null);
      case PasteMsg(:final content):
        insertString(content);
        return (this, null);
      case KeyMsg(key: final key):
        // deletion
        if (key.matchesSingle(keyMap.deleteBeforeCursor)) {
          _backspace();
          return (this, null);
        }
        if (key.matchesSingle(keyMap.deleteCharacterForward)) {
          _deleteCharForward();
          return (this, null);
        }
        if (key.matchesSingle(keyMap.deleteWordBackward)) {
          _deleteWordBackward();
          return (this, null);
        }
        if (key.matchesSingle(keyMap.deleteWordForward)) {
          _deleteWordForward();
          return (this, null);
        }
        if (key.matchesSingle(keyMap.deleteToLineStart)) {
          _deleteToLineStart();
          return (this, null);
        }
        if (key.matchesSingle(keyMap.deleteToLineEnd)) {
          _deleteToLineEnd();
          return (this, null);
        }
        if (key.matchesSingle(keyMap.deleteAfterCursor)) {
          _deleteToLineEnd();
          return (this, null);
        }

        // navigation
        if (key.matchesSingle(keyMap.wordForward)) {
          _moveWordForward();
          return (this, null);
        }
        if (key.matchesSingle(keyMap.wordBackward)) {
          _moveWordBackward();
          return (this, null);
        }
        if (key.matchesSingle(keyMap.lineStart)) {
          _cursorStartOfLine();
          return (this, null);
        }
        if (key.matchesSingle(keyMap.lineEnd)) {
          _cursorEndOfLine();
          return (this, null);
        }
        if (key.matchesSingle(keyMap.inputBegin)) {
          _cursorStartOfInput();
          return (this, null);
        }
        if (key.matchesSingle(keyMap.inputEnd)) {
          _cursorEndOfInput();
          return (this, null);
        }
        if (key.matchesSingle(keyMap.characterForward)) {
          _moveRight();
          return (this, null);
        }
        if (key.matchesSingle(keyMap.characterBackward)) {
          _moveLeft();
          return (this, null);
        }
        if (key.matchesSingle(keyMap.lineNext)) {
          _lineNext();
          return (this, null);
        }
        if (key.matchesSingle(keyMap.linePrevious)) {
          _linePrev();
          return (this, null);
        }
        if (key.matchesSingle(keyMap.transposeCharacterBackward)) {
          _transposeBackward();
          return (this, null);
        }
        if (key.matchesSingle(keyMap.uppercaseWordForward)) {
          _uppercaseWordForward();
          return (this, null);
        }
        if (key.matchesSingle(keyMap.lowercaseWordForward)) {
          _lowercaseWordForward();
          return (this, null);
        }
        if (key.matchesSingle(keyMap.capitalizeWordForward)) {
          _capitalizeWordForward();
          return (this, null);
        }

        // Fallback direct modifier checks for common combos.
        if (key.type == KeyType.delete && key.alt) {
          _deleteWordForward();
          return (this, null);
        }
        if (key.ctrl && key.type == KeyType.runes && key.runes.isNotEmpty) {
          final r = key.runes.first;
          if (r == 0x74) {
            // ctrl+t
            _transposeBackward();
            return (this, null);
          }
        }
        if (key.alt && key.type == KeyType.runes && key.runes.isNotEmpty) {
          final r = key.runes.first;
          if (r == 0x75) {
            _uppercaseWordForward();
            return (this, null);
          }
          if (r == 0x6c) {
            _lowercaseWordForward();
            return (this, null);
          }
          if (r == 0x63) {
            _capitalizeWordForward();
            return (this, null);
          }
        }

        if (key.type == KeyType.space) {
          _insertChar(' ');
          return (this, null);
        }

        if (key.type == KeyType.enter && keyMap.insertNewline.enabled) {
          _newline();
          return (this, null);
        }

        if (key.type == KeyType.runes && key.runes.isNotEmpty) {
          final rune = key.runes.first;
          if (rune == 0x0a) {
            _newline();
          } else {
            _insertChar(String.fromCharCode(rune));
          }
          return (this, null);
        }
    }

    return (this, null);
  }

  @override
  String view() {
    final style = _focused ? focusedStyle : blurredStyle;
    final lineNumberDigits = showLineNumbers ? '${_lines.length}'.length : 0;
    final displayLines = _softWrappedLines(lineNumberDigits);
    final lines = displayLines;
    final buffer = StringBuffer();

    if (value.isEmpty && placeholder.isNotEmpty) {
      final ph = style.placeholder.render(placeholder);
      buffer.write('${style.prompt.render(prompt)}$ph');
    } else {
      for (var i = 0; i < lines.length; i++) {
        final lnNumber = showLineNumbers
            ? style.lineNumber.render(
                '${(i + 1).toString().padLeft(lineNumberDigits)} ',
              )
            : '';
        final lineBody = lines[i].text;
        final renderedLine = lines[i].hasCursor
            ? style.cursorLine.render(lineBody)
            : lineBody;
        buffer.writeln(
          '${style.prompt.render(prompt)}$lnNumber${style.text.render(renderedLine)}',
        );
      }

      // end of buffer indicator
      final remaining = (_height - lines.length);
      if (remaining > 0) {
        final eob = style.endOfBuffer.render('~');
        for (var i = 0; i < remaining; i++) {
          buffer.writeln(eob);
        }
      }
    }

    final str = buffer.toString().trimRight();
    return str.isEmpty ? style.prompt.render(prompt) : str;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  int _effectiveWrapWidth(int lineNumberDigits) {
    var wrapWidth = _width;
    if (wrapWidth <= 0) return wrapWidth;

    wrapWidth -= stringWidth(prompt);
    if (showLineNumbers) {
      // add a trailing space after the number
      wrapWidth -= (lineNumberDigits + 1);
    }
    return wrapWidth;
  }

  List<_DisplayLine> _softWrappedLines(int lineNumberDigits) {
    final result = <_DisplayLine>[];
    final wrapWidth = softWrap ? _effectiveWrapWidth(lineNumberDigits) : 0;

    for (var rowIndex = 0; rowIndex < _lines.length; rowIndex++) {
      final line = _lines[rowIndex];
      if (!softWrap || wrapWidth <= 0) {
        result.add(_DisplayLine(line, hasCursor: rowIndex == _row));
        continue;
      }

      final runes = line.runes.toList();
      var start = 0;
      while (start < runes.length) {
        var width = 0;
        var end = start;
        while (end < runes.length) {
          final w = runeWidth(runes[end]);
          if (width + w > wrapWidth) break;
          width += w;
          end += 1;
        }

        // Safety to avoid infinite loop if wrapWidth is too small
        if (end == start) {
          end = start + 1;
        }

        final segment = String.fromCharCodes(runes.sublist(start, end));
        final cursorRune = _row == rowIndex ? _col.clamp(0, runes.length) : -1;
        final hasCursor =
            _row == rowIndex && cursorRune >= start && cursorRune <= end;

        result.add(_DisplayLine(segment, hasCursor: hasCursor));
        start = end;
      }

      if (line.isEmpty) {
        // Preserve empty lines when soft wrapping is on.
        result.add(_DisplayLine('', hasCursor: rowIndex == _row));
      }
    }

    // Respect the configured height by showing the most recent lines.
    if (_height > 0 && result.length > _height) {
      final start = (result.length - _height).clamp(0, result.length);
      return result.sublist(start);
    }

    return result;
  }

  void _deleteWordBackward() {
    final text = value;
    final pos = _globalOffset();
    if (pos == 0) return;

    var newPos = pos - 1;
    while (newPos > 0 && !_isWordChar(text.codeUnitAt(newPos))) {
      newPos--;
    }
    while (newPos > 0 && _isWordChar(text.codeUnitAt(newPos - 1))) {
      newPos--;
    }

    final updated = text.substring(0, newPos) + text.substring(pos);
    _setValueAndCursor(updated, newPos);
  }

  void _deleteToLineStart() {
    if (_col == 0) return;
    final lineText = _lines[_row];
    _lines[_row] = lineText.substring(_col);
    _col = 0;
  }

  void _deleteToLineEnd() {
    final lineText = _lines[_row];
    if (_col >= lineText.length) return;
    _lines[_row] = lineText.substring(0, _col);
  }

  void _moveWordForward() {
    final text = value;
    var pos = _globalOffset();
    if (pos >= text.length) return;

    // Skip current character and any non-word chars.
    pos++;
    while (pos < text.length && !_isWordChar(text.codeUnitAt(pos))) {
      pos++;
    }
    while (pos < text.length && _isWordChar(text.codeUnitAt(pos))) {
      pos++;
    }
    _setCursorFromGlobal(pos);
  }

  void _moveWordBackward() {
    final text = value;
    var pos = _globalOffset();
    if (pos == 0) return;

    pos--;
    while (pos > 0 && !_isWordChar(text.codeUnitAt(pos))) {
      pos--;
    }
    while (pos > 0 && _isWordChar(text.codeUnitAt(pos - 1))) {
      pos--;
    }
    _setCursorFromGlobal(pos);
  }

  void _cursorStartOfLine() {
    _col = 0;
  }

  void _cursorEndOfLine() {
    _col = _lines[_row].length;
  }

  void _cursorStartOfInput() {
    _row = 0;
    _col = 0;
  }

  void _cursorEndOfInput() {
    _row = _lines.length - 1;
    _col = _lines.last.length;
  }

  void _deleteCharForward() {
    final line = _lines[_row];
    if (_col < line.length) {
      _lines[_row] = line.substring(0, _col) + line.substring(_col + 1);
      return;
    }
    if (_row < _lines.length - 1) {
      final merged = line + _lines[_row + 1];
      _lines
        ..removeAt(_row + 1)
        ..[_row] = merged;
    }
  }

  void _deleteWordForward() {
    final text = value;
    final pos = _globalOffset();
    if (pos >= text.length) return;

    var end = pos;
    if (_isWordChar(text.codeUnitAt(pos))) {
      while (end < text.length && _isWordChar(text.codeUnitAt(end))) {
        end++;
      }
    } else {
      while (end < text.length && !_isWordChar(text.codeUnitAt(end))) {
        end++;
      }
      while (end < text.length && _isWordChar(text.codeUnitAt(end))) {
        end++;
      }
    }

    final updated = text.substring(0, pos) + text.substring(end);
    _setValueAndCursor(updated, pos);
  }

  void _transposeBackward() {
    final line = _lines[_row];
    if (line.isEmpty) return;
    if (_col == 0) return;

    // Swap char before cursor with the one at cursor (Bubble Tea behavior).
    final runes = line.runes.toList();
    final at = math.min(_col, runes.length - 1);
    final before = at - 1;
    if (before < 0) return;
    final tmp = runes[before];
    runes[before] = runes[at];
    runes[at] = tmp;
    _lines[_row] = String.fromCharCodes(runes);
    _col = math.min(at + 1, _lines[_row].length);
  }

  void _uppercaseWordForward() {
    final (start, end) = _wordRangeForTransform();
    if (start == -1) return;
    final text = value;
    final segment = text.substring(start, end).toUpperCase();
    final updated = text.replaceRange(start, end, segment);
    _setValueAndCursor(updated, end);
  }

  void _lowercaseWordForward() {
    final (start, end) = _wordRangeForTransform();
    if (start == -1) return;
    final text = value;
    final segment = text.substring(start, end).toLowerCase();
    final updated = text.replaceRange(start, end, segment);
    _setValueAndCursor(updated, end);
  }

  void _capitalizeWordForward() {
    final (start, end) = _wordRangeForTransform();
    if (start == -1) return;
    final text = value;
    final word = text.substring(start, end);
    if (word.isEmpty) return;
    final runes = word.runes.toList();
    if (runes.isEmpty) return;
    final first = String.fromCharCode(runes.first).toUpperCase();
    final rest = String.fromCharCodes(runes.skip(1)).toLowerCase();
    final updated = text.replaceRange(start, end, '$first$rest');
    _setValueAndCursor(updated, end);
  }

  (int, int) _nextWordRange() {
    final text = value;
    var pos = _globalOffset();
    while (pos < text.length && !_isWordChar(text.codeUnitAt(pos))) {
      pos++;
    }
    if (pos >= text.length) return (-1, -1);
    var end = pos;
    while (end < text.length && _isWordChar(text.codeUnitAt(end))) {
      end++;
    }
    return (pos, end);
  }

  (int, int) _prevWordRange() {
    final text = value;
    var pos = _globalOffset() - 1;
    while (pos >= 0 && !_isWordChar(text.codeUnitAt(pos))) {
      pos--;
    }
    if (pos < 0) return (-1, -1);
    var end = pos + 1;
    while (pos >= 0 && _isWordChar(text.codeUnitAt(pos))) {
      pos--;
    }
    final start = pos + 1;
    return (start, end);
  }

  /// Returns forward word range; if none forward, use previous word.
  (int, int) _wordRangeForTransform() {
    final forward = _nextWordRange();
    if (forward.$1 != -1) return forward;
    return _prevWordRange();
  }

  void _moveLeft() {
    if (_col > 0) {
      _col -= 1;
    } else if (_row > 0) {
      _row -= 1;
      _col = _lines[_row].length;
    }
  }

  void _moveRight() {
    if (_col < _lines[_row].length) {
      _col += 1;
    } else if (_row < _lines.length - 1) {
      _row += 1;
      _col = 0;
    }
  }

  void _lineNext() {
    if (_row < _lines.length - 1) {
      _row += 1;
      _col = _col.clamp(0, _lines[_row].length);
    }
  }

  void _linePrev() {
    if (_row > 0) {
      _row -= 1;
      _col = _col.clamp(0, _lines[_row].length);
    }
  }

  int _globalOffset() {
    var offset = 0;
    for (var i = 0; i < _row; i++) {
      offset += _lines[i].length + 1; // include newline
    }
    offset += _col;
    return offset;
  }

  void _setCursorFromGlobal(int offset) {
    var remaining = offset;
    for (var i = 0; i < _lines.length; i++) {
      final lineLength = _lines[i].length;
      if (remaining <= lineLength) {
        _row = i;
        _col = remaining;
        return;
      }
      remaining -= lineLength + 1;
    }
    // fallback to end
    _row = _lines.length - 1;
    _col = _lines.last.length;
  }

  void _setValueAndCursor(String newValue, int cursorPos) {
    final limited = _applyCharLimit(newValue);
    _lines = limited.split('\n');
    _setCursorFromGlobal(cursorPos.clamp(0, limited.length));
  }

  bool _isWordChar(int codeUnit) {
    final ch = String.fromCharCode(codeUnit);
    return RegExp(r'[A-Za-z0-9_]').hasMatch(ch);
  }
}
