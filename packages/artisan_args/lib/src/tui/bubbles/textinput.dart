/// Text input component for TUI applications.
///
/// This provides a single-line text input field with cursor navigation,
/// word editing, suggestions/autocomplete, and password echo modes.
///
/// Based on the Bubble Tea textinput component.
library;

import 'dart:math' as math;

import 'package:artisan_args/src/tui/tui.dart';
import 'package:artisan_args/src/style/style.dart';
import 'package:artisan_args/src/style/color.dart';

import 'cursor.dart';
import 'key_binding.dart';
import 'runeutil.dart';
import '../../unicode/grapheme.dart' as uni;

/// Echo mode for text input display.
enum EchoMode {
  /// Display text as-is. This is the default.
  normal,

  /// Display mask character instead of actual characters (for passwords).
  password,

  /// Display nothing as characters are entered.
  none,
}

/// Validation function that returns an error message if input is invalid.
typedef ValidateFunc = String? Function(String value);

/// Key map for text input navigation and editing.
class TextInputKeyMap implements KeyMap {
  /// Creates a text input key map with default bindings.
  TextInputKeyMap({
    KeyBinding? characterForward,
    KeyBinding? characterBackward,
    KeyBinding? wordForward,
    KeyBinding? wordBackward,
    KeyBinding? deleteWordBackward,
    KeyBinding? deleteWordForward,
    KeyBinding? deleteAfterCursor,
    KeyBinding? deleteBeforeCursor,
    KeyBinding? deleteCharacterBackward,
    KeyBinding? deleteCharacterForward,
    KeyBinding? lineStart,
    KeyBinding? lineEnd,
    KeyBinding? paste,
    KeyBinding? acceptSuggestion,
    KeyBinding? nextSuggestion,
    KeyBinding? prevSuggestion,
  }) : characterForward =
           characterForward ??
           KeyBinding(
             keys: ['right', 'ctrl+f'],
             help: Help(key: '→/^f', desc: 'Move forward'),
           ),
       characterBackward =
           characterBackward ??
           KeyBinding(
             keys: ['left', 'ctrl+b'],
             help: Help(key: '←/^b', desc: 'Move backward'),
           ),
       wordForward =
           wordForward ??
           KeyBinding(
             keys: ['alt+right', 'ctrl+right', 'alt+f'],
             help: Help(key: 'alt+→', desc: 'Move word forward'),
           ),
       wordBackward =
           wordBackward ??
           KeyBinding(
             keys: ['alt+left', 'ctrl+left', 'alt+b'],
             help: Help(key: 'alt+←', desc: 'Move word backward'),
           ),
       deleteWordBackward =
           deleteWordBackward ??
           KeyBinding(
             keys: ['alt+backspace', 'ctrl+w'],
             help: Help(key: 'alt+⌫', desc: 'Delete word backward'),
           ),
       deleteWordForward =
           deleteWordForward ??
           KeyBinding(
             keys: ['alt+delete', 'alt+d'],
             help: Help(key: 'alt+del', desc: 'Delete word forward'),
           ),
       deleteAfterCursor =
           deleteAfterCursor ??
           KeyBinding(
             keys: ['ctrl+k'],
             help: Help(key: '^k', desc: 'Delete after cursor'),
           ),
       deleteBeforeCursor =
           deleteBeforeCursor ??
           KeyBinding(
             keys: ['ctrl+u'],
             help: Help(key: '^u', desc: 'Delete before cursor'),
           ),
       deleteCharacterBackward =
           deleteCharacterBackward ??
           KeyBinding(
             keys: ['backspace', 'ctrl+h'],
             help: Help(key: '⌫', desc: 'Delete character'),
           ),
       deleteCharacterForward =
           deleteCharacterForward ??
           KeyBinding(
             keys: ['delete', 'ctrl+d'],
             help: Help(key: 'del', desc: 'Delete forward'),
           ),
       lineStart =
           lineStart ??
           KeyBinding(
             keys: ['home', 'ctrl+a'],
             help: Help(key: 'home', desc: 'Go to start'),
           ),
       lineEnd =
           lineEnd ??
           KeyBinding(
             keys: ['end', 'ctrl+e'],
             help: Help(key: 'end', desc: 'Go to end'),
           ),
       paste =
           paste ??
           KeyBinding(
             keys: ['ctrl+v'],
             help: Help(key: '^v', desc: 'Paste'),
           ),
       acceptSuggestion =
           acceptSuggestion ??
           KeyBinding(
             keys: ['tab'],
             help: Help(key: 'tab', desc: 'Accept suggestion'),
           ),
       nextSuggestion =
           nextSuggestion ??
           KeyBinding(
             keys: ['down', 'ctrl+n'],
             help: Help(key: '↓', desc: 'Next suggestion'),
           ),
       prevSuggestion =
           prevSuggestion ??
           KeyBinding(
             keys: ['up', 'ctrl+p'],
             help: Help(key: '↑', desc: 'Previous suggestion'),
           );

  /// Move cursor forward one character.
  final KeyBinding characterForward;

  /// Move cursor backward one character.
  final KeyBinding characterBackward;

  /// Move cursor forward one word.
  final KeyBinding wordForward;

  /// Move cursor backward one word.
  final KeyBinding wordBackward;

  /// Delete word before cursor.
  final KeyBinding deleteWordBackward;

  /// Delete word after cursor.
  final KeyBinding deleteWordForward;

  /// Delete all text after cursor.
  final KeyBinding deleteAfterCursor;

  /// Delete all text before cursor.
  final KeyBinding deleteBeforeCursor;

  /// Delete character before cursor.
  final KeyBinding deleteCharacterBackward;

  /// Delete character after cursor.
  final KeyBinding deleteCharacterForward;

  /// Move cursor to start of line.
  final KeyBinding lineStart;

  /// Move cursor to end of line.
  final KeyBinding lineEnd;

  /// Paste from clipboard.
  final KeyBinding paste;

  /// Accept current suggestion.
  final KeyBinding acceptSuggestion;

  /// Move to next suggestion.
  final KeyBinding nextSuggestion;

  /// Move to previous suggestion.
  final KeyBinding prevSuggestion;

  @override
  List<KeyBinding> shortHelp() => [
    characterForward,
    characterBackward,
    deleteCharacterBackward,
  ];

  @override
  List<List<KeyBinding>> fullHelp() => [
    [characterForward, characterBackward, wordForward, wordBackward],
    [lineStart, lineEnd],
    [
      deleteCharacterBackward,
      deleteCharacterForward,
      deleteWordBackward,
      deleteWordForward,
    ],
    [deleteBeforeCursor, deleteAfterCursor],
    [paste, acceptSuggestion, nextSuggestion, prevSuggestion],
  ];
}

/// Message for paste events.
class PasteMsg implements Msg {
  /// Creates a paste message with the pasted content.
  PasteMsg(this.content);

  /// The pasted content.
  final String content;
}

/// Message for paste errors.
class PasteErrorMsg implements Msg {
  /// Creates a paste error message.
  PasteErrorMsg(this.error);

  /// The error that occurred.
  final Object error;
}

/// Text input model for single-line text entry.
///
/// Features:
/// - Character and word navigation
/// - Delete operations (character, word, line)
/// - Echo modes (normal, password, none)
/// - Suggestions/autocomplete
/// - Horizontal scrolling for long text
/// - Validation
///
/// Example:
/// ```dart
/// final input = TextInputModel(
///   prompt: 'Name: ',
///   placeholder: 'Enter your name',
/// );
/// ```
class TextInputModel extends ViewComponent {
  /// Creates a new text input model.
  TextInputModel({
    this.prompt = '> ',
    this.placeholder = '',
    this.echoMode = EchoMode.normal,
    this.echoCharacter = '*',
    this.charLimit = 0,
    this.width = 0,
    this.showSuggestions = false,
    TextInputKeyMap? keyMap,
    CursorModel? cursor,
    this.validate,
    Style? promptStyle,
    Style? textStyle,
    Style? placeholderStyle,
    Style? completionStyle,
  }) : keyMap = keyMap ?? TextInputKeyMap(),
       cursor = cursor ?? CursorModel(),
       _promptStyle = promptStyle ?? Style(),
       _textStyle = textStyle ?? Style(),
       _placeholderStyle = placeholderStyle ?? Style().foreground(AnsiColor(8)),
       _completionStyle = completionStyle ?? Style().foreground(AnsiColor(8));

  /// Prompt displayed before input.
  String prompt;

  /// Placeholder text when empty.
  String placeholder;

  /// Echo mode for displaying text.
  EchoMode echoMode;

  /// Character to show in password mode.
  String echoCharacter;

  /// Maximum characters allowed (0 = unlimited).
  int charLimit;

  /// Display width for horizontal scrolling (0 = unlimited).
  int width;

  /// Whether to show suggestions.
  bool showSuggestions;

  /// Key bindings.
  TextInputKeyMap keyMap;

  /// Cursor model.
  CursorModel cursor;

  /// Validation function.
  ValidateFunc? validate;

  /// Current validation error.
  String? error;

  /// Style for the prompt.
  final Style _promptStyle;

  /// Style for the text.
  final Style _textStyle;

  /// Style for placeholder text.
  final Style _placeholderStyle;

  /// Style for completion text.
  final Style _completionStyle;

  // Internal state
  List<String> _value = <String>[];
  bool _focused = false;
  int _pos = 0;
  int _offset = 0;
  int _offsetRight = 0;

  // Suggestions
  List<List<String>> _suggestions = <List<String>>[];
  List<List<String>> _matchedSuggestions = <List<String>>[];
  int _currentSuggestionIndex = 0;

  // Rune sanitizer
  RuneSanitizer? _sanitizer;

  /// Gets the current value as a string.
  String get value => _value.join();

  /// Sets the value of the text input.
  set value(String s) {
    final runes = _san(uni.codePoints(s));
    final graphemes = uni.graphemes(String.fromCharCodes(runes)).toList();
    final err = _validate(graphemes);
    _setValueInternal(graphemes, err);
  }

  /// Gets the cursor position.
  int get position => _pos;

  /// Sets the cursor position.
  set position(int pos) {
    _pos = pos.clamp(0, _value.length);
    _handleOverflow();
  }

  /// Whether the input is focused.
  bool get focused => _focused;

  /// Sets available suggestions for autocomplete.
  set suggestions(List<String> suggestions) {
    _suggestions = suggestions.map((s) => uni.graphemes(s).toList()).toList();
    _updateSuggestions();
  }

  /// Gets available suggestions.
  List<String> get availableSuggestions =>
      _suggestions.map((s) => s.join()).toList();

  /// Gets matched suggestions.
  List<String> get matchedSuggestions =>
      _matchedSuggestions.map((s) => s.join()).toList();

  /// Gets current suggestion index.
  int get currentSuggestionIndex => _currentSuggestionIndex;

  /// Gets current suggestion.
  String get currentSuggestion {
    if (_currentSuggestionIndex >= _matchedSuggestions.length) {
      return '';
    }
    return _matchedSuggestions[_currentSuggestionIndex].join();
  }

  /// Focus the input.
  Cmd? focus() {
    _focused = true;
    final (newCursor, cmd) = cursor.focus();
    cursor = newCursor;
    return cmd;
  }

  /// Blur (unfocus) the input.
  void blur() {
    _focused = false;
    cursor = cursor.blur();
  }

  /// Reset the input to empty.
  void reset() {
    _value = <String>[];
    position = 0;
  }

  /// Move cursor to start.
  void cursorStart() {
    position = 0;
  }

  /// Move cursor to end.
  void cursorEnd() {
    position = _value.length;
  }

  List<int> _san(List<int> runes) {
    _sanitizer ??= createSanitizer(
      SanitizerOptions(tabReplacement: ' ', newlineReplacement: ' '),
    );
    return _sanitizer!(runes);
  }

  String? _validate(List<String> graphemes) {
    if (validate != null) {
      return validate!(graphemes.join());
    }
    return null;
  }

  void _setValueInternal(List<String> graphemes, String? err) {
    error = err;
    final empty = _value.isEmpty;

    if (charLimit > 0 && graphemes.length > charLimit) {
      _value = graphemes.sublist(0, charLimit);
    } else {
      _value = graphemes;
    }

    if ((position == 0 && empty) || position > _value.length) {
      position = _value.length;
    }
    _handleOverflow();
  }

  void _insertRunes(List<int> v) {
    final pasteRunes = _san(v);
    final paste = uni.graphemes(String.fromCharCodes(pasteRunes)).toList();

    int availSpace;
    if (charLimit > 0) {
      availSpace = charLimit - _value.length;
      if (availSpace <= 0) return;

      if (availSpace < paste.length) {
        _insertLimited(paste.sublist(0, availSpace));
        return;
      }
    }

    _insertLimited(paste);
  }

  void _insertLimited(List<String> paste) {
    final head = _value.sublist(0, _pos);
    final tail = _value.sublist(_pos);

    final newValue = [...head, ...paste, ...tail];
    _pos += paste.length;

    final err = _validate(newValue);
    _setValueInternal(newValue, err);
  }

  void _handleOverflow() {
    if (width <= 0 || stringWidth(_value.join()) <= width) {
      _offset = 0;
      _offsetRight = _value.length;
      return;
    }

    _offsetRight = math.min(_offsetRight, _value.length);

    if (_pos < _offset) {
      _offset = _pos;
      var w = 0;
      var i = 0;
      final gs = _value.sublist(_offset);

      while (i < gs.length && w <= width) {
        w += runeWidth(uni.firstCodePoint(gs[i]));
        if (w <= width + 1) i++;
      }

      _offsetRight = _offset + i;
    } else if (_pos >= _offsetRight) {
      _offsetRight = _pos;
      var w = 0;
      final gs = _value.sublist(0, _offsetRight);
      var i = gs.length - 1;

      while (i > 0 && w < width) {
        w += runeWidth(uni.firstCodePoint(gs[i]));
        if (w <= width) i--;
      }

      _offset = _offsetRight - (gs.length - 1 - i);
    }
  }

  void _deleteBeforeCursor() {
    _value = _value.sublist(_pos);
    error = _validate(_value);
    _offset = 0;
    position = 0;
  }

  void _deleteAfterCursor() {
    _value = _value.sublist(0, _pos);
    error = _validate(_value);
    position = _value.length;
  }

  void _deleteWordBackward() {
    if (_pos == 0 || _value.isEmpty) return;

    if (echoMode != EchoMode.normal) {
      _deleteBeforeCursor();
      return;
    }

    var i = _pos - 1;
    while (i >= 0 && _isWhitespace(_value[i])) i--;
    while (i >= 0 && !_isWhitespace(_value[i])) i--;
    final start = (i + 1).clamp(0, _pos);

    _value = [..._value.sublist(0, start), ..._value.sublist(_pos)];
    error = _validate(_value);
    position = start;
  }

  void _deleteWordForward() {
    if (_pos >= _value.length || _value.isEmpty) return;

    if (echoMode != EchoMode.normal) {
      _deleteAfterCursor();
      return;
    }

    var i = _pos;
    while (i < _value.length && _isWhitespace(_value[i])) i++;
    while (i < _value.length && !_isWhitespace(_value[i])) i++;

    _value = [..._value.sublist(0, _pos), ..._value.sublist(i)];
    error = _validate(_value);
    _handleOverflow();
  }

  void _wordBackward() {
    if (_pos == 0 || _value.isEmpty) return;

    if (echoMode != EchoMode.normal) {
      cursorStart();
      return;
    }

    var i = _pos - 1;
    while (i >= 0 && _isWhitespace(_value[i])) i--;
    while (i >= 0 && !_isWhitespace(_value[i])) i--;
    position = (i + 1).clamp(0, _value.length);
  }

  void _wordForward() {
    if (_pos >= _value.length || _value.isEmpty) return;

    if (echoMode != EchoMode.normal) {
      cursorEnd();
      return;
    }

    var i = _pos;
    while (i < _value.length && _isWhitespace(_value[i])) i++;
    while (i < _value.length && !_isWhitespace(_value[i])) i++;
    position = i;
  }

  bool _isWhitespace(String grapheme) {
    final rune = uni.firstCodePoint(grapheme);
    return rune == 0x20 || // Space
        rune == 0x09 || // Tab
        rune == 0x0A || // LF
        rune == 0x0D; // CR
  }

  String _echoTransform(String v) {
    switch (echoMode) {
      case EchoMode.password:
        return echoCharacter * stringWidth(v);
      case EchoMode.none:
        return '';
      case EchoMode.normal:
        return v;
    }
  }

  bool _canAcceptSuggestion() => _matchedSuggestions.isNotEmpty;

  void _updateSuggestions() {
    if (!showSuggestions) return;

    if (_value.isEmpty || _suggestions.isEmpty) {
      _matchedSuggestions = <List<String>>[];
      return;
    }

    final valueStr = _value.join().toLowerCase();
    final matches = <List<String>>[];

    for (final s in _suggestions) {
      final suggestion = s.join().toLowerCase();
      if (suggestion.startsWith(valueStr)) {
        matches.add(s);
      }
    }

    if (!_listEquals(matches, _matchedSuggestions)) {
      _currentSuggestionIndex = 0;
    }

    _matchedSuggestions = matches;
  }

  bool _listEquals(List<List<String>> a, List<List<String>> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].length != b[i].length) return false;
      for (var j = 0; j < a[i].length; j++) {
        if (a[i][j] != b[i][j]) return false;
      }
    }
    return true;
  }

  void _nextSuggestion() {
    _currentSuggestionIndex = (_currentSuggestionIndex + 1);
    if (_currentSuggestionIndex >= _matchedSuggestions.length) {
      _currentSuggestionIndex = 0;
    }
  }

  void _previousSuggestion() {
    _currentSuggestionIndex = (_currentSuggestionIndex - 1);
    if (_currentSuggestionIndex < 0) {
      _currentSuggestionIndex = _matchedSuggestions.length - 1;
    }
  }

  @override
  Cmd? init() => null;

  @override
  (TextInputModel, Cmd?) update(Msg msg) {
    if (!_focused) {
      return (this, null);
    }

    // Check for suggestion acceptance first
    if (msg is KeyMsg && keyMatches(msg.key, [keyMap.acceptSuggestion])) {
      if (_canAcceptSuggestion()) {
        final suggestion = _matchedSuggestions[_currentSuggestionIndex];
        _value = [..._value, ...suggestion.sublist(_value.length)];
        cursorEnd();
      }
    }

    final oldPos = _pos;
    final cmds = <Cmd>[];

    if (msg is KeyMsg) {
      if (msg.key.type == KeyType.space) {
        _insertRunes([0x20]);
        return (this, null);
      }

      if (keyMatches(msg.key, [keyMap.deleteWordBackward])) {
        _deleteWordBackward();
      } else if (keyMatches(msg.key, [keyMap.deleteCharacterBackward])) {
        error = null;
        if (_value.isNotEmpty && _pos > 0) {
          _value = [
            ..._value.sublist(0, math.max(0, _pos - 1)),
            ..._value.sublist(_pos),
          ];
          error = _validate(_value);
          if (_pos > 0) position = _pos - 1;
        }
      } else if (keyMatches(msg.key, [keyMap.wordBackward])) {
        _wordBackward();
      } else if (keyMatches(msg.key, [keyMap.characterBackward])) {
        if (_pos > 0) position = _pos - 1;
      } else if (keyMatches(msg.key, [keyMap.wordForward])) {
        _wordForward();
      } else if (keyMatches(msg.key, [keyMap.characterForward])) {
        if (_pos < _value.length) position = _pos + 1;
      } else if (keyMatches(msg.key, [keyMap.lineStart])) {
        cursorStart();
      } else if (keyMatches(msg.key, [keyMap.deleteCharacterForward])) {
        if (_value.isNotEmpty && _pos < _value.length) {
          _value = [..._value.sublist(0, _pos), ..._value.sublist(_pos + 1)];
          error = _validate(_value);
        }
      } else if (keyMatches(msg.key, [keyMap.lineEnd])) {
        cursorEnd();
      } else if (keyMatches(msg.key, [keyMap.deleteAfterCursor])) {
        _deleteAfterCursor();
      } else if (keyMatches(msg.key, [keyMap.deleteBeforeCursor])) {
        _deleteBeforeCursor();
      } else if (keyMatches(msg.key, [keyMap.paste])) {
        // Return paste command - caller handles clipboard
        return (this, _pasteCmd());
      } else if (keyMatches(msg.key, [keyMap.deleteWordForward])) {
        _deleteWordForward();
      } else if (keyMatches(msg.key, [keyMap.nextSuggestion])) {
        _nextSuggestion();
      } else if (keyMatches(msg.key, [keyMap.prevSuggestion])) {
        _previousSuggestion();
      } else if (msg.key.runes.isNotEmpty) {
        // Regular character input
        _insertRunes(msg.key.runes);
      }

      _updateSuggestions();
    } else if (msg is PasteMsg) {
      _insertRunes(uni.codePoints(msg.content));
    } else if (msg is PasteErrorMsg) {
      error = msg.error.toString();
    }

    // Update cursor
    final (newCursor, cursorCmd) = cursor.update(msg);
    cursor = newCursor;
    if (cursorCmd != null) cmds.add(cursorCmd);

    // Reset blink if position changed - use focus() to restart blink
    if (oldPos != _pos && cursor.mode == CursorMode.blink) {
      final (refocusedCursor, blinkCmd) = cursor.focus();
      cursor = refocusedCursor;
      if (blinkCmd != null) cmds.add(blinkCmd);
    }

    _handleOverflow();
    return (this, cmds.isNotEmpty ? Cmd.batch(cmds) : null);
  }

  @override
  String view() {
    // Placeholder text
    if (_value.isEmpty && placeholder.isNotEmpty) {
      return _placeholderView();
    }

    String styleText(String s) => _textStyle.render(s);

    final visibleValue = _value.sublist(_offset, _offsetRight);
    final pos = math.max(0, _pos - _offset);

    var v = styleText(_echoTransform(visibleValue.sublist(0, pos).join()));

    if (pos < visibleValue.length) {
      final char = _echoTransform(visibleValue[pos]);
      cursor = cursor.setChar(char);
      v += cursor.view(); // Cursor and text under it
      v += styleText(
        _echoTransform(visibleValue.sublist(pos + 1).join()),
      ); // Text after cursor
      v += _completionView(0); // Suggested completion
    } else {
      if (_focused && _canAcceptSuggestion()) {
        final suggestion = _matchedSuggestions[_currentSuggestionIndex];
        if (_value.length < suggestion.length) {
          cursor = cursor.setChar(_echoTransform(suggestion[_value.length]));
          v += cursor.view();
          v += _completionView(1);
        } else {
          cursor = cursor.setChar(' ');
          v += cursor.view();
        }
      } else {
        cursor = cursor.setChar(' ');
        v += cursor.view();
      }
    }

    // Padding for fixed width
    final valWidth = stringWidth(visibleValue.join());
    if (width > 0 && valWidth <= width) {
      var padding = math.max(0, width - valWidth);
      if (valWidth + padding <= width && pos < visibleValue.length) {
        padding++;
      }
      v += styleText(' ' * padding);
    }

    final styledPrompt = _promptStyle.render(prompt);

    return '$styledPrompt$v';
  }

  String _placeholderView() {
    final result = firstGraphemeCluster(placeholder);
    cursor = cursor.setChar(result.first);
    var v = cursor.view();

    if (width < 1 && stringWidth(result.rest) <= 1) {
      final styledPrompt = _promptStyle.render(prompt);
      return '$styledPrompt$v';
    }

    if (width > 0) {
      final promptWidth = stringWidth(prompt);
      final cursorWidth = stringWidth(v);
      final availWidth = width - promptWidth - cursorWidth;
      final placeholderRest = truncate(result.rest, availWidth, '…');
      final restWidth = stringWidth(placeholderRest);
      final paddingWidth = math.max(0, availWidth - restWidth);
      v += _placeholderStyle.render(placeholderRest) + (' ' * paddingWidth);
    } else {
      v += _placeholderStyle.render(result.rest);
    }

    final styledPrompt = _promptStyle.render(prompt);

    return '$styledPrompt$v';
  }

  String _completionView(int offset) {
    if (_canAcceptSuggestion()) {
      final suggestion = _matchedSuggestions[_currentSuggestionIndex];
      if (_value.length < suggestion.length) {
        return _completionStyle.render(
          suggestion.sublist(_value.length + offset).join(),
        );
      }
    }
    return '';
  }

  Cmd? _pasteCmd() {
    // This is a placeholder - actual clipboard access would be platform-specific
    return null;
  }
}
