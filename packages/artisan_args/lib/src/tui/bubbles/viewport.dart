import 'dart:math' as math;

import '../../style/ranges.dart' as ranges;
import '../../style/style.dart';
import '../cmd.dart';
import '../component.dart';
import '../msg.dart';
import '../uv/wrap.dart' as uv_wrap;
import 'key_binding.dart';

/// Key bindings for viewport navigation.
class ViewportKeyMap implements KeyMap {
  ViewportKeyMap({
    KeyBinding? pageDown,
    KeyBinding? pageUp,
    KeyBinding? halfPageUp,
    KeyBinding? halfPageDown,
    KeyBinding? down,
    KeyBinding? up,
    KeyBinding? left,
    KeyBinding? right,
  }) : pageDown =
           pageDown ??
           KeyBinding.withHelp(['pgdown', ' ', 'f'], 'f/pgdn', 'page down'),
       pageUp =
           pageUp ?? KeyBinding.withHelp(['pgup', 'b'], 'b/pgup', 'page up'),
       halfPageUp =
           halfPageUp ?? KeyBinding.withHelp(['u', 'ctrl+u'], 'u', '½ page up'),
       halfPageDown =
           halfPageDown ??
           KeyBinding.withHelp(['d', 'ctrl+d'], 'd', '½ page down'),
       down = down ?? KeyBinding.withHelp(['down', 'j'], '↓/j', 'down'),
       up = up ?? KeyBinding.withHelp(['up', 'k'], '↑/k', 'up'),
       left = left ?? KeyBinding.withHelp(['left', 'h'], '←/h', 'left'),
       right = right ?? KeyBinding.withHelp(['right', 'l'], '→/l', 'right');

  final KeyBinding pageDown;
  final KeyBinding pageUp;
  final KeyBinding halfPageUp;
  final KeyBinding halfPageDown;
  final KeyBinding down;
  final KeyBinding up;
  final KeyBinding left;
  final KeyBinding right;

  @override
  List<KeyBinding> shortHelp() => [up, down, pageUp, pageDown];

  @override
  List<List<KeyBinding>> fullHelp() => [
    [up, down, pageUp, pageDown],
    [halfPageUp, halfPageDown, left, right],
  ];
}

/// A viewport widget for scrollable content.
///
/// The viewport manages a scrollable view of content that may be larger
/// than the available display area. It supports vertical and horizontal
/// scrolling with keyboard and mouse input.
///
/// ## Example
///
/// ```dart
/// class DocViewerModel implements Model {
///   final ViewportModel viewport;
///   final String content;
///
///   DocViewerModel({ViewportModel? viewport, this.content = ''})
///       : viewport = (viewport ?? ViewportModel(width: 80, height: 24))
///           ..setContent(content);
///
///   @override
///   (Model, Cmd?) update(Msg msg) {
///     // Handle window resize
///     if (msg is WindowSizeMsg) {
///       return (
///         DocViewerModel(
///           viewport: viewport.copyWith(
///             width: msg.width,
///             height: msg.height - 2, // Leave room for status
///           ),
///           content: content,
///         ),
///         null,
///       );
///     }
///
///     final (newViewport, cmd) = viewport.update(msg);
///     return (
///       DocViewerModel(viewport: newViewport as ViewportModel, content: content),
///       cmd,
///     );
///   }
///
///   @override
///   String view() => '''
/// ${viewport.view()}
/// ${(viewport.scrollPercent * 100).toInt()}%
/// ''';
/// }
/// ```
class ViewportModel extends ViewComponent {
  /// Creates a new viewport model.
  ViewportModel({
    this.width = 80,
    this.height = 24,
    this.gutter = 0,
    this.yOffset = 0,
    this.xOffset = 0,
    this.mouseWheelEnabled = true,
    this.mouseWheelDelta = 3,
    this.horizontalStep = 0,
    this.softWrap = false,
    this.leftGutterFunc,
    this.highlights = const [],
    this.currentHighlightIndex = -1,
    ViewportKeyMap? keyMap,
    List<String>? lines,
    List<String>? wrappedLines,
    List<String>? originalLines,
  }) : keyMap = keyMap ?? ViewportKeyMap(),
       _lines = lines ?? [],
       _wrappedLines = wrappedLines ?? [],
       _originalLines = originalLines ?? lines ?? [];

  /// Width of the viewport in columns.
  final int width;

  /// Height of the viewport in rows.
  final int height;

  /// Left gutter (spaces) applied to each rendered line. Also reduces
  /// available content width.
  final int gutter;

  /// Vertical scroll offset (0 = top).
  final int yOffset;

  /// Horizontal scroll offset (0 = left).
  final int xOffset;

  /// Whether mouse wheel scrolling is enabled.
  final bool mouseWheelEnabled;

  /// Number of lines to scroll per mouse wheel tick.
  final int mouseWheelDelta;

  /// Number of columns to scroll left/right. 0 disables horizontal scrolling.
  final int horizontalStep;

  /// Whether to wrap lines that exceed the viewport width.
  final bool softWrap;

  /// A function that returns the gutter for a given line index.
  /// If provided, [gutter] is ignored for rendering but still used
  /// for width calculations.
  final String Function(int lineIndex)? leftGutterFunc;

  /// Style ranges to highlight in the viewport.
  final List<ranges.StyleRange> highlights;

  /// The index of the currently focused highlight.
  final int currentHighlightIndex;

  /// Key bindings for navigation.
  final ViewportKeyMap keyMap;

  final List<String> _lines;
  final List<String> _wrappedLines;
  final List<String> _originalLines;
  int _longestLineWidth = 0;

  /// The content lines.
  List<String> get lines => softWrap ? _wrappedLines : _lines;

  int get _contentWidth => math.max(0, width - gutter);

  /// Creates a copy with the given fields replaced.
  ViewportModel copyWith({
    int? width,
    int? height,
    int? yOffset,
    int? xOffset,
    bool? mouseWheelEnabled,
    int? mouseWheelDelta,
    int? horizontalStep,
    ViewportKeyMap? keyMap,
    List<String>? lines,
    int? gutter,
    bool? softWrap,
    String Function(int lineIndex)? leftGutterFunc,
    List<ranges.StyleRange>? highlights,
    int? currentHighlightIndex,
  }) {
    final newWidth = width ?? this.width;
    final newGutter = gutter ?? this.gutter;
    final newSoftWrap = softWrap ?? this.softWrap;
    final newOriginalLines = lines ?? _originalLines;
    final newHighlights = highlights ?? this.highlights;

    // Apply highlights to original lines
    var styledLines = newOriginalLines;
    if (newHighlights.isNotEmpty) {
      final content = newOriginalLines.join('\n');
      final styled = ranges.styleRanges(content, newHighlights);
      styledLines = styled.split('\n');
    }

    List<String>? newWrappedLines;
    if (newSoftWrap) {
      final contentWidth = math.max(0, newWidth - newGutter);
      final content = styledLines.join('\n');
      final wrapped = uv_wrap.wrapAnsiPreserving(content, contentWidth);
      newWrappedLines = wrapped.split('\n');
    }

    final newModel = ViewportModel(
      width: newWidth,
      height: height ?? this.height,
      gutter: newGutter,
      yOffset: yOffset ?? this.yOffset,
      xOffset: xOffset ?? this.xOffset,
      mouseWheelEnabled: mouseWheelEnabled ?? this.mouseWheelEnabled,
      mouseWheelDelta: mouseWheelDelta ?? this.mouseWheelDelta,
      horizontalStep: horizontalStep ?? this.horizontalStep,
      keyMap: keyMap ?? this.keyMap,
      lines: styledLines,
      wrappedLines: newWrappedLines,
      originalLines: newOriginalLines,
      softWrap: newSoftWrap,
      leftGutterFunc: leftGutterFunc ?? this.leftGutterFunc,
      highlights: newHighlights,
      currentHighlightIndex: currentHighlightIndex ?? this.currentHighlightIndex,
    );
    newModel._longestLineWidth = styledLines != null
        ? _findLongestLineWidth(styledLines)
        : _longestLineWidth;
    return newModel;
  }

  /// Sets the content of the viewport.
  ViewportModel setContent(String content) {
    final normalized = content.replaceAll('\r\n', '\n');
    final newLines = normalized.split('\n');
    final newModel = copyWith(lines: newLines);
    newModel._longestLineWidth = _findLongestLineWidth(newLines);

    // Adjust offset if content is shorter
    if (newModel.yOffset > newLines.length - 1) {
      return newModel.gotoBottom();
    }
    return newModel;
  }

  /// Maximum Y offset based on content and height.
  int get _maxYOffset => math.max(0, lines.length - height);

  /// Whether the viewport is at the top.
  bool get atTop => yOffset <= 0;

  /// Whether the viewport is at the bottom.
  bool get atBottom => yOffset >= _maxYOffset;

  /// Whether the viewport is scrolled past the bottom.
  bool get pastBottom => yOffset > _maxYOffset;

  /// Returns the scroll percentage (0.0 to 1.0).
  double get scrollPercent {
    if (height >= lines.length) return 1.0;
    final y = yOffset.toDouble();
    final h = height.toDouble();
    final t = lines.length.toDouble();
    final v = y / (t - h);
    return v.clamp(0.0, 1.0);
  }

  /// Moves the viewport to the next highlight.
  ViewportModel highlightNext() {
    if (highlights.isEmpty) return this;
    final nextIndex = (currentHighlightIndex + 1) % highlights.length;
    return copyWith(currentHighlightIndex: nextIndex)._scrollToHighlight(nextIndex);
  }

  /// Moves the viewport to the previous highlight.
  ViewportModel highlightPrev() {
    if (highlights.isEmpty) return this;
    final prevIndex =
        (currentHighlightIndex - 1 + highlights.length) % highlights.length;
    return copyWith(currentHighlightIndex: prevIndex)._scrollToHighlight(prevIndex);
  }

  ViewportModel _scrollToHighlight(int index) {
    final h = highlights[index];
    final targetLines = softWrap ? _wrappedLines : _lines;
    var currentCell = 0;
    for (var i = 0; i < targetLines.length; i++) {
      final w = Style.visibleLength(targetLines[i]);
      if (currentCell + w > h.start) {
        return setYOffset(i);
      }
      currentCell += w;
    }
    return this;
  }

  /// Returns the horizontal scroll percentage (0.0 to 1.0).
  double get horizontalScrollPercent {
    final contentWidth = _contentWidth;
    if (contentWidth <= 0 || _longestLineWidth <= contentWidth) return 1.0;
    if (xOffset >= _longestLineWidth - contentWidth) return 1.0;
    final x = xOffset.toDouble();
    final w = contentWidth.toDouble();
    final t = _longestLineWidth.toDouble();
    final v = x / (t - w);
    return v.clamp(0.0, 1.0);
  }

  /// Total number of lines in the content.
  int get totalLineCount => _lines.length;

  /// Number of visible lines.
  int get visibleLineCount => _visibleLines().length;

  /// Returns the visible lines based on current scroll position.
  List<String> _visibleLines() {
    final lines = softWrap ? _wrappedLines : _lines;
    if (lines.isEmpty) return [];

    final top = math.max(0, yOffset);
    final bottom = (yOffset + height).clamp(top, lines.length);
    var visible = lines.sublist(top, bottom);

    final contentWidth = _contentWidth;
    if (contentWidth <= 0) {
      return visible;
    }

    // Apply horizontal scrolling (only if not soft wrapping)
    if (!softWrap && (xOffset > 0 || _longestLineWidth > contentWidth)) {
      visible = visible.map((line) {
        final lineWidth = Style.visibleLength(line);
        if (lineWidth <= xOffset) return '';
        return ranges.cutAnsiByCells(line, xOffset, xOffset + contentWidth);
      }).toList();
    }

    return visible;
  }

  /// Sets the Y offset (clamped to valid range).
  ViewportModel setYOffset(int n) {
    return copyWith(yOffset: n.clamp(0, _maxYOffset));
  }

  /// Sets the X offset (clamped to valid range).
  ViewportModel setXOffset(int n) {
    final maxXOffset = _longestLineWidth - _contentWidth;
    return copyWith(xOffset: n.clamp(0, maxXOffset > 0 ? maxXOffset : 0));
  }

  /// Scrolls down by the given number of lines.
  ViewportModel scrollDown(int n) {
    if (atBottom || n == 0 || _lines.isEmpty) return this;
    return setYOffset(yOffset + n);
  }

  /// Scrolls up by the given number of lines.
  ViewportModel scrollUp(int n) {
    if (atTop || n == 0 || _lines.isEmpty) return this;
    return setYOffset(yOffset - n);
  }

  /// Scrolls left by the given number of columns.
  ViewportModel scrollLeft(int n) {
    return setXOffset(xOffset - n);
  }

  /// Scrolls right by the given number of columns.
  ViewportModel scrollRight(int n) {
    return setXOffset(xOffset + n);
  }

  /// Moves down by one page.
  ViewportModel pageDown() {
    if (atBottom) return this;
    return scrollDown(height);
  }

  /// Moves up by one page.
  ViewportModel pageUp() {
    if (atTop) return this;
    return scrollUp(height);
  }

  /// Moves down by half a page.
  ViewportModel halfPageDown() {
    if (atBottom) return this;
    return scrollDown(height ~/ 2);
  }

  /// Moves up by half a page.
  ViewportModel halfPageUp() {
    if (atTop) return this;
    return scrollUp(height ~/ 2);
  }

  /// Goes to the top of the content.
  ViewportModel gotoTop() {
    if (atTop) return this;
    return setYOffset(0);
  }

  /// Goes to the bottom of the content.
  ViewportModel gotoBottom() {
    return setYOffset(_maxYOffset);
  }

  @override
  Cmd? init() => null;

  @override
  (ViewportModel, Cmd?) update(Msg msg) {
    switch (msg) {
      case KeyMsg(:final key):
        if (key.matchesSingle(keyMap.pageDown)) {
          return (pageDown(), null);
        }
        if (key.matchesSingle(keyMap.pageUp)) {
          return (pageUp(), null);
        }
        if (key.matchesSingle(keyMap.halfPageDown)) {
          return (halfPageDown(), null);
        }
        if (key.matchesSingle(keyMap.halfPageUp)) {
          return (halfPageUp(), null);
        }
        if (key.matchesSingle(keyMap.down)) {
          return (scrollDown(1), null);
        }
        if (key.matchesSingle(keyMap.up)) {
          return (scrollUp(1), null);
        }
        if (horizontalStep > 0) {
          if (key.matchesSingle(keyMap.left)) {
            return (scrollLeft(horizontalStep), null);
          }
          if (key.matchesSingle(keyMap.right)) {
            return (scrollRight(horizontalStep), null);
          }
        }
        return (this, null);

      case MouseMsg(:final button, :final action, :final shift):
        if (!mouseWheelEnabled || action != MouseAction.press) {
          return (this, null);
        }

        switch (button) {
          case MouseButton.wheelUp:
            if (shift && horizontalStep > 0) {
              return (scrollLeft(horizontalStep), null);
            }
            return (scrollUp(mouseWheelDelta), null);

          case MouseButton.wheelDown:
            if (shift && horizontalStep > 0) {
              return (scrollRight(horizontalStep), null);
            }
            return (scrollDown(mouseWheelDelta), null);

          case MouseButton.wheelLeft:
            if (horizontalStep > 0) {
              return (scrollLeft(horizontalStep), null);
            }
            return (this, null);

          case MouseButton.wheelRight:
            if (horizontalStep > 0) {
              return (scrollRight(horizontalStep), null);
            }
            return (this, null);

          default:
            return (this, null);
        }

      default:
        return (this, null);
    }
  }

  @override
  String view() {
    if (width <= 0) {
      return _visibleLines().join('\n');
    }

    final visible = _visibleLines();
    final top = math.max(0, yOffset);

    // Pad lines to width
    final contentWidth = _contentWidth;
    final paddedLines = <String>[];

    for (var i = 0; i < visible.length; i++) {
      var line = visible[i];
      final lineIndex = top + i;
      final gutterStr = leftGutterFunc?.call(lineIndex) ?? (' ' * gutter);

      final w = Style.visibleLength(line);
      if (w < contentWidth) {
        line = '$line${' ' * (contentWidth - w)}';
      } else if (w > contentWidth && !softWrap) {
        line = ranges.cutAnsiByCells(line, xOffset, xOffset + contentWidth);
      }
      paddedLines.add('$gutterStr$line');
    }

    // Pad height if content is shorter
    while (paddedLines.length < height) {
      final lineIndex = top + paddedLines.length;
      final gutterStr = leftGutterFunc?.call(lineIndex) ?? (' ' * gutter);
      paddedLines.add('$gutterStr${' ' * contentWidth}');
    }

    return paddedLines.join('\n');
  }

  static int _findLongestLineWidth(List<String> lines) {
    var maxWidth = 0;
    for (final line in lines) {
      final w = Style.visibleLength(line);
      if (w > maxWidth) {
        maxWidth = w;
      }
    }
    return maxWidth;
  }
}
