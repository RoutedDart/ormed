import 'dart:math' as math;

import '../../style/ranges.dart' as ranges;
import '../../style/style.dart';
import '../cmd.dart';
import '../component.dart';
import '../msg.dart';
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
    ViewportKeyMap? keyMap,
    List<String>? lines,
  }) : keyMap = keyMap ?? ViewportKeyMap(),
       _lines = lines ?? [];

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

  /// Key bindings for navigation.
  final ViewportKeyMap keyMap;

  final List<String> _lines;
  int _longestLineWidth = 0;

  /// The content lines.
  List<String> get lines => _lines;

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
  }) {
    final newModel = ViewportModel(
      width: width ?? this.width,
      height: height ?? this.height,
      gutter: gutter ?? this.gutter,
      yOffset: yOffset ?? this.yOffset,
      xOffset: xOffset ?? this.xOffset,
      mouseWheelEnabled: mouseWheelEnabled ?? this.mouseWheelEnabled,
      mouseWheelDelta: mouseWheelDelta ?? this.mouseWheelDelta,
      horizontalStep: horizontalStep ?? this.horizontalStep,
      keyMap: keyMap ?? this.keyMap,
      lines: lines ?? _lines,
    );
    newModel._longestLineWidth = lines != null
        ? _findLongestLineWidth(lines)
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
  int get _maxYOffset => math.max(0, _lines.length - height);

  /// Whether the viewport is at the top.
  bool get atTop => yOffset <= 0;

  /// Whether the viewport is at the bottom.
  bool get atBottom => yOffset >= _maxYOffset;

  /// Whether the viewport is scrolled past the bottom.
  bool get pastBottom => yOffset > _maxYOffset;

  /// Returns the scroll percentage (0.0 to 1.0).
  double get scrollPercent {
    if (height >= _lines.length) return 1.0;
    final y = yOffset.toDouble();
    final h = height.toDouble();
    final t = _lines.length.toDouble();
    final v = y / (t - h);
    return v.clamp(0.0, 1.0);
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
    if (_lines.isEmpty) return [];

    final top = math.max(0, yOffset);
    final bottom = (yOffset + height).clamp(top, _lines.length);
    var visible = _lines.sublist(top, bottom);

    final contentWidth = _contentWidth;
    if (contentWidth <= 0) {
      return visible;
    }

    // Apply horizontal scrolling
    if (xOffset > 0 || _longestLineWidth > contentWidth) {
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

    // Pad lines to width
    final contentWidth = math.max(0, width - gutter);
    final gutterPad = ' ' * gutter;
    final paddedLines = visible.map((line) {
      var working = line;
      final w = Style.visibleLength(working);
      if (w < contentWidth) {
        working = '$working${' ' * (contentWidth - w)}';
      } else if (w > contentWidth) {
        working = ranges.cutAnsiByCells(working, 0, contentWidth);
      }
      return '$gutterPad$working';
    }).toList();

    // Pad height if content is shorter
    while (paddedLines.length < height) {
      paddedLines.add(' ' * width);
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
