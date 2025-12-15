/// Fluent, chainable style builder for CLI output.
///
/// Inspired by Go's lipgloss library, this provides a composable way
/// to build text styles for terminal output.
///
/// ```dart
/// final style = Style()
///     .bold()
///     .foreground(Colors.green)
///     .padding(1, 2)
///     .border(Border.rounded)
///     .width(40);
///
/// print(style.render('Hello World'));
///
/// // Style inheritance
/// final derived = baseStyle.copy()..inherit(overrideStyle);
/// ```
library;

import 'package:chalkdart/chalk.dart';

import 'border.dart';
import 'color.dart';
import 'properties.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Property Bits
// ─────────────────────────────────────────────────────────────────────────────

/// Bitfield flags for tracking which properties have been explicitly set.
class _PropBits {
  static const int bold = 1 << 0;
  static const int italic = 1 << 1;
  static const int underline = 1 << 2;
  static const int strikethrough = 1 << 3;
  static const int dim = 1 << 4;
  static const int inverse = 1 << 5;
  static const int blink = 1 << 6;
  static const int foreground = 1 << 7;
  static const int background = 1 << 8;
  static const int width = 1 << 9;
  static const int height = 1 << 10;
  static const int padding = 1 << 11;
  static const int paddingTop = 1 << 12;
  static const int paddingRight = 1 << 13;
  static const int paddingBottom = 1 << 14;
  static const int paddingLeft = 1 << 15;
  static const int margin = 1 << 16;
  static const int marginTop = 1 << 17;
  static const int marginRight = 1 << 18;
  static const int marginBottom = 1 << 19;
  static const int marginLeft = 1 << 20;
  static const int align = 1 << 21;
  static const int border = 1 << 22;
  static const int borderSides = 1 << 23;
  static const int borderForeground = 1 << 24;
  static const int borderBackground = 1 << 25;
  static const int maxWidth = 1 << 26;
  static const int maxHeight = 1 << 27;
  static const int inline = 1 << 28;
  static const int transform = 1 << 29;
}

/// Fluent, chainable style builder for terminal output.
///
/// All setter methods return `this` for chaining. Use [render] to apply
/// the style to text and produce ANSI-escaped output.
///
/// ## Basic Usage
///
/// ```dart
/// final style = Style()
///     .bold()
///     .foreground(Colors.green)
///     .render('Success!');
/// ```
///
/// ## Style Composition
///
/// Styles can be composed using [inherit], which copies only the
/// explicitly-set properties from another style:
///
/// ```dart
/// final base = Style().foreground(Colors.white).padding(1);
/// final accent = Style().bold().foreground(Colors.cyan);
///
/// // Inherits bold and foreground from accent, keeps padding from base
/// final combined = base.copy()..inherit(accent);
/// ```
///
/// ## Property Tracking
///
/// The style tracks which properties have been explicitly set using a
/// bitfield. This enables smart inheritance where only set properties
/// are copied, and unset properties retain their previous values.
class Style {
  /// Creates a new empty style.
  Style();

  // ─────────────────────────────────────────────────────────────────────────────
  // Property Tracking
  // ─────────────────────────────────────────────────────────────────────────────

  /// Bitfield tracking which properties are explicitly set.
  int _props = 0;

  bool _hasFlag(int flag) => _props & flag != 0;
  void _setFlag(int flag) => _props |= flag;
  void _clearFlag(int flag) => _props &= ~flag;

  // ─────────────────────────────────────────────────────────────────────────────
  // Text Attribute Properties
  // ─────────────────────────────────────────────────────────────────────────────

  bool _bold = false;
  bool _italic = false;
  bool _underline = false;
  bool _strikethrough = false;
  bool _dim = false;
  bool _inverse = false;
  bool _blink = false;

  // ─────────────────────────────────────────────────────────────────────────────
  // Color Properties
  // ─────────────────────────────────────────────────────────────────────────────

  Color? _foreground;
  Color? _background;
  Color? _borderForeground;
  Color? _borderBackground;

  // ─────────────────────────────────────────────────────────────────────────────
  // Dimension Properties
  // ─────────────────────────────────────────────────────────────────────────────

  int _width = 0;
  int _height = 0;
  int _maxWidth = 0;
  int _maxHeight = 0;

  // ─────────────────────────────────────────────────────────────────────────────
  // Spacing Properties
  // ─────────────────────────────────────────────────────────────────────────────

  Padding _padding = Padding.zero;
  Margin _margin = Margin.zero;

  // ─────────────────────────────────────────────────────────────────────────────
  // Layout Properties
  // ─────────────────────────────────────────────────────────────────────────────

  HorizontalAlign _align = HorizontalAlign.left;
  Border? _border;
  BorderSides _borderSides = BorderSides.all;
  bool _inline = false;

  // ─────────────────────────────────────────────────────────────────────────────
  // Transform
  // ─────────────────────────────────────────────────────────────────────────────

  String Function(String)? _transform;

  // ─────────────────────────────────────────────────────────────────────────────
  // Pre-set String
  // ─────────────────────────────────────────────────────────────────────────────

  /// Pre-set string content for this style.
  String? _string;

  // ─────────────────────────────────────────────────────────────────────────────
  // Whitespace Options
  // ─────────────────────────────────────────────────────────────────────────────

  /// Custom character(s) for whitespace fill.
  String _whitespaceChar = ' ';

  /// Foreground color for whitespace fill.
  Color? _whitespaceForeground;

  // ─────────────────────────────────────────────────────────────────────────────
  // Rendering Context
  // ─────────────────────────────────────────────────────────────────────────────

  /// Color profile for rendering (defaults to trueColor).
  ColorProfile colorProfile = ColorProfile.trueColor;

  /// Whether the terminal has a dark background.
  bool hasDarkBackground = true;

  // ═══════════════════════════════════════════════════════════════════════════
  // FLUENT SETTERS
  // ═══════════════════════════════════════════════════════════════════════════

  // ─────────────────────────────────────────────────────────────────────────────
  // Text Attributes
  // ─────────────────────────────────────────────────────────────────────────────

  /// Sets bold text.
  Style bold([bool value = true]) {
    _bold = value;
    _setFlag(_PropBits.bold);
    return this;
  }

  /// Sets italic text.
  Style italic([bool value = true]) {
    _italic = value;
    _setFlag(_PropBits.italic);
    return this;
  }

  /// Sets underlined text.
  Style underline([bool value = true]) {
    _underline = value;
    _setFlag(_PropBits.underline);
    return this;
  }

  /// Sets strikethrough text.
  Style strikethrough([bool value = true]) {
    _strikethrough = value;
    _setFlag(_PropBits.strikethrough);
    return this;
  }

  /// Sets dimmed/faint text.
  Style dim([bool value = true]) {
    _dim = value;
    _setFlag(_PropBits.dim);
    return this;
  }

  /// Sets inverse/reverse video.
  Style inverse([bool value = true]) {
    _inverse = value;
    _setFlag(_PropBits.inverse);
    return this;
  }

  /// Sets blinking text (limited terminal support).
  Style blink([bool value = true]) {
    _blink = value;
    _setFlag(_PropBits.blink);
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Colors
  // ─────────────────────────────────────────────────────────────────────────────

  /// Sets the foreground (text) color.
  Style foreground(Color color) {
    _foreground = color;
    _setFlag(_PropBits.foreground);
    return this;
  }

  /// Sets the background color.
  Style background(Color color) {
    _background = color;
    _setFlag(_PropBits.background);
    return this;
  }

  /// Sets the border foreground color.
  Style borderForeground(Color color) {
    _borderForeground = color;
    _setFlag(_PropBits.borderForeground);
    return this;
  }

  /// Sets the border background color.
  Style borderBackground(Color color) {
    _borderBackground = color;
    _setFlag(_PropBits.borderBackground);
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Dimensions
  // ─────────────────────────────────────────────────────────────────────────────

  /// Sets the fixed width of the styled content.
  Style width(int value) {
    _width = value;
    _setFlag(_PropBits.width);
    return this;
  }

  /// Sets the fixed height of the styled content.
  Style height(int value) {
    _height = value;
    _setFlag(_PropBits.height);
    return this;
  }

  /// Sets the maximum width of the styled content.
  Style maxWidth(int value) {
    _maxWidth = value;
    _setFlag(_PropBits.maxWidth);
    return this;
  }

  /// Sets the maximum height of the styled content.
  Style maxHeight(int value) {
    _maxHeight = value;
    _setFlag(_PropBits.maxHeight);
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Padding
  // ─────────────────────────────────────────────────────────────────────────────

  /// Sets padding on all sides or vertical/horizontal.
  ///
  /// - `padding(1)` - 1 on all sides
  /// - `padding(1, 2)` - 1 vertical, 2 horizontal
  /// - `padding(1, 2, 3, 4)` - top, right, bottom, left
  Style padding(int topOrAll, [int? right, int? bottom, int? left]) {
    if (right == null && bottom == null && left == null) {
      // All sides
      _padding = Padding.all(topOrAll);
    } else if (bottom == null && left == null) {
      // Vertical, horizontal
      _padding = Padding.symmetric(vertical: topOrAll, horizontal: right!);
    } else {
      // Individual sides
      _padding = Padding(
        top: topOrAll,
        right: right ?? 0,
        bottom: bottom ?? 0,
        left: left ?? 0,
      );
    }
    _setFlag(_PropBits.padding);
    return this;
  }

  /// Sets top padding.
  Style paddingTop(int value) {
    _padding = _padding.copyWith(top: value);
    _setFlag(_PropBits.paddingTop);
    return this;
  }

  /// Sets right padding.
  Style paddingRight(int value) {
    _padding = _padding.copyWith(right: value);
    _setFlag(_PropBits.paddingRight);
    return this;
  }

  /// Sets bottom padding.
  Style paddingBottom(int value) {
    _padding = _padding.copyWith(bottom: value);
    _setFlag(_PropBits.paddingBottom);
    return this;
  }

  /// Sets left padding.
  Style paddingLeft(int value) {
    _padding = _padding.copyWith(left: value);
    _setFlag(_PropBits.paddingLeft);
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Margin
  // ─────────────────────────────────────────────────────────────────────────────

  /// Sets margin on all sides or vertical/horizontal.
  ///
  /// - `margin(1)` - 1 on all sides
  /// - `margin(1, 2)` - 1 vertical, 2 horizontal
  /// - `margin(1, 2, 3, 4)` - top, right, bottom, left
  Style margin(int topOrAll, [int? right, int? bottom, int? left]) {
    if (right == null && bottom == null && left == null) {
      // All sides
      _margin = Margin.all(topOrAll);
    } else if (bottom == null && left == null) {
      // Vertical, horizontal
      _margin = Margin.symmetric(vertical: topOrAll, horizontal: right!);
    } else {
      // Individual sides
      _margin = Margin(
        top: topOrAll,
        right: right ?? 0,
        bottom: bottom ?? 0,
        left: left ?? 0,
      );
    }
    _setFlag(_PropBits.margin);
    return this;
  }

  /// Sets top margin.
  Style marginTop(int value) {
    _margin = _margin.copyWith(top: value);
    _setFlag(_PropBits.marginTop);
    return this;
  }

  /// Sets right margin.
  Style marginRight(int value) {
    _margin = _margin.copyWith(right: value);
    _setFlag(_PropBits.marginRight);
    return this;
  }

  /// Sets bottom margin.
  Style marginBottom(int value) {
    _margin = _margin.copyWith(bottom: value);
    _setFlag(_PropBits.marginBottom);
    return this;
  }

  /// Sets left margin.
  Style marginLeft(int value) {
    _margin = _margin.copyWith(left: value);
    _setFlag(_PropBits.marginLeft);
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Alignment
  // ─────────────────────────────────────────────────────────────────────────────

  /// Sets horizontal text alignment within the width.
  Style align(HorizontalAlign value) {
    _align = value;
    _setFlag(_PropBits.align);
    return this;
  }

  /// Aligns text to the left.
  Style alignLeft() => align(HorizontalAlign.left);

  /// Aligns text to the center.
  Style alignCenter() => align(HorizontalAlign.center);

  /// Aligns text to the right.
  Style alignRight() => align(HorizontalAlign.right);

  // ─────────────────────────────────────────────────────────────────────────────
  // Border
  // ─────────────────────────────────────────────────────────────────────────────

  /// Sets the border style.
  Style border(Border value) {
    _border = value;
    _setFlag(_PropBits.border);
    return this;
  }

  /// Alias for [border] - sets the border style.
  ///
  /// This matches the lipgloss API where `BorderStyle()` sets the border type.
  Style borderStyle(Border value) => border(value);

  /// Sets which border sides are visible.
  Style borderSides(BorderSides value) {
    _borderSides = value;
    _setFlag(_PropBits.borderSides);
    return this;
  }

  /// Shows or hides the top border.
  Style borderTop(bool visible) {
    _borderSides = _borderSides.copyWith(top: visible);
    _setFlag(_PropBits.borderSides);
    return this;
  }

  /// Shows or hides the bottom border.
  Style borderBottom(bool visible) {
    _borderSides = _borderSides.copyWith(bottom: visible);
    _setFlag(_PropBits.borderSides);
    return this;
  }

  /// Shows or hides the left border.
  Style borderLeft(bool visible) {
    _borderSides = _borderSides.copyWith(left: visible);
    _setFlag(_PropBits.borderSides);
    return this;
  }

  /// Shows or hides the right border.
  Style borderRight(bool visible) {
    _borderSides = _borderSides.copyWith(right: visible);
    _setFlag(_PropBits.borderSides);
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Pre-set String
  // ─────────────────────────────────────────────────────────────────────────────

  /// Sets a pre-defined string content for this style.
  ///
  /// When set, calling [toString] will render this string with the style,
  /// allowing the style to be used directly as a string.
  ///
  /// ```dart
  /// final divider = Style()
  ///     .foreground(Colors.muted)
  ///     .padding(0, 1)
  ///     .setString('•');
  ///
  /// print('Item 1${divider}Item 2${divider}Item 3');
  /// // Output: Item 1 • Item 2 • Item 3
  /// ```
  Style setString(String value) {
    _string = value;
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Whitespace Options
  // ─────────────────────────────────────────────────────────────────────────────

  /// Sets custom character(s) for whitespace fill.
  ///
  /// Used when filling space in aligned content or padding.
  ///
  /// ```dart
  /// final style = Style()
  ///     .width(20)
  ///     .align(HorizontalAlign.center)
  ///     .whitespaceChars('·');
  /// ```
  Style whitespaceChars(String chars) {
    _whitespaceChar = chars;
    return this;
  }

  /// Sets the foreground color for whitespace fill.
  Style whitespaceForeground(Color color) {
    _whitespaceForeground = color;
    return this;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Other
  // ─────────────────────────────────────────────────────────────────────────────

  /// Sets inline mode (ignores padding, margin, border).
  Style inline([bool value = true]) {
    _inline = value;
    _setFlag(_PropBits.inline);
    return this;
  }

  /// Sets a text transformation function.
  Style transform(String Function(String) fn) {
    _transform = fn;
    _setFlag(_PropBits.transform);
    return this;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UNSET METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Unsets bold.
  Style unsetBold() {
    _bold = false;
    _clearFlag(_PropBits.bold);
    return this;
  }

  /// Unsets italic.
  Style unsetItalic() {
    _italic = false;
    _clearFlag(_PropBits.italic);
    return this;
  }

  /// Unsets underline.
  Style unsetUnderline() {
    _underline = false;
    _clearFlag(_PropBits.underline);
    return this;
  }

  /// Unsets strikethrough.
  Style unsetStrikethrough() {
    _strikethrough = false;
    _clearFlag(_PropBits.strikethrough);
    return this;
  }

  /// Unsets foreground color.
  Style unsetForeground() {
    _foreground = null;
    _clearFlag(_PropBits.foreground);
    return this;
  }

  /// Unsets background color.
  Style unsetBackground() {
    _background = null;
    _clearFlag(_PropBits.background);
    return this;
  }

  /// Unsets width.
  Style unsetWidth() {
    _width = 0;
    _clearFlag(_PropBits.width);
    return this;
  }

  /// Unsets height.
  Style unsetHeight() {
    _height = 0;
    _clearFlag(_PropBits.height);
    return this;
  }

  /// Unsets padding.
  Style unsetPadding() {
    _padding = Padding.zero;
    _clearFlag(_PropBits.padding);
    _clearFlag(_PropBits.paddingTop);
    _clearFlag(_PropBits.paddingRight);
    _clearFlag(_PropBits.paddingBottom);
    _clearFlag(_PropBits.paddingLeft);
    return this;
  }

  /// Unsets margin.
  Style unsetMargin() {
    _margin = Margin.zero;
    _clearFlag(_PropBits.margin);
    _clearFlag(_PropBits.marginTop);
    _clearFlag(_PropBits.marginRight);
    _clearFlag(_PropBits.marginBottom);
    _clearFlag(_PropBits.marginLeft);
    return this;
  }

  /// Unsets border.
  Style unsetBorder() {
    _border = null;
    _clearFlag(_PropBits.border);
    return this;
  }

  /// Unsets transform.
  Style unsetTransform() {
    _transform = null;
    _clearFlag(_PropBits.transform);
    return this;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Whether bold is explicitly set.
  bool get isBold => _hasFlag(_PropBits.bold) && _bold;

  /// Whether italic is explicitly set.
  bool get isItalic => _hasFlag(_PropBits.italic) && _italic;

  /// Whether underline is explicitly set.
  bool get isUnderline => _hasFlag(_PropBits.underline) && _underline;

  /// Whether strikethrough is explicitly set.
  bool get isStrikethrough =>
      _hasFlag(_PropBits.strikethrough) && _strikethrough;

  /// Whether dim is explicitly set.
  bool get isDim => _hasFlag(_PropBits.dim) && _dim;

  /// Whether inverse is explicitly set.
  bool get isInverse => _hasFlag(_PropBits.inverse) && _inverse;

  /// Whether blink is explicitly set.
  bool get isBlink => _hasFlag(_PropBits.blink) && _blink;

  /// Whether inline mode is set.
  bool get isInline => _hasFlag(_PropBits.inline) && _inline;

  /// Gets the foreground color if set.
  Color? get getForeground =>
      _hasFlag(_PropBits.foreground) ? _foreground : null;

  /// Gets the background color if set.
  Color? get getBackground =>
      _hasFlag(_PropBits.background) ? _background : null;

  /// Gets the width if set.
  int get getWidth => _hasFlag(_PropBits.width) ? _width : 0;

  /// Gets the height if set.
  int get getHeight => _hasFlag(_PropBits.height) ? _height : 0;

  /// Gets the max width if set.
  int get getMaxWidth => _hasFlag(_PropBits.maxWidth) ? _maxWidth : 0;

  /// Gets the max height if set.
  int get getMaxHeight => _hasFlag(_PropBits.maxHeight) ? _maxHeight : 0;

  /// Gets the padding.
  Padding get getPadding => _padding;

  /// Gets the margin.
  Margin get getMargin => _margin;

  /// Gets the alignment.
  HorizontalAlign get getAlign => _align;

  /// Gets the border if set.
  Border? get getBorder => _hasFlag(_PropBits.border) ? _border : null;

  /// Gets the border sides.
  BorderSides get getBorderSides => _borderSides;

  /// Gets the transform function if set.
  String Function(String)? get getTransform =>
      _hasFlag(_PropBits.transform) ? _transform : null;

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPERTY CHECKING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Whether a specific property flag is set.
  bool hasProperty(int flag) => _hasFlag(flag);

  /// Whether any text attribute is set.
  bool get hasTextAttributes =>
      _hasFlag(_PropBits.bold) ||
      _hasFlag(_PropBits.italic) ||
      _hasFlag(_PropBits.underline) ||
      _hasFlag(_PropBits.strikethrough) ||
      _hasFlag(_PropBits.dim) ||
      _hasFlag(_PropBits.inverse) ||
      _hasFlag(_PropBits.blink);

  /// Whether any color is set.
  bool get hasColors =>
      _hasFlag(_PropBits.foreground) || _hasFlag(_PropBits.background);

  /// Whether any spacing (padding or margin) is set.
  bool get hasSpacing =>
      _hasFlag(_PropBits.padding) ||
      _hasFlag(_PropBits.paddingTop) ||
      _hasFlag(_PropBits.paddingRight) ||
      _hasFlag(_PropBits.paddingBottom) ||
      _hasFlag(_PropBits.paddingLeft) ||
      _hasFlag(_PropBits.margin) ||
      _hasFlag(_PropBits.marginTop) ||
      _hasFlag(_PropBits.marginRight) ||
      _hasFlag(_PropBits.marginBottom) ||
      _hasFlag(_PropBits.marginLeft);

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPOSITION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates a copy of this style.
  Style copy() {
    final s = Style();
    s._props = _props;
    s._bold = _bold;
    s._italic = _italic;
    s._underline = _underline;
    s._strikethrough = _strikethrough;
    s._dim = _dim;
    s._inverse = _inverse;
    s._blink = _blink;
    s._foreground = _foreground;
    s._background = _background;
    s._borderForeground = _borderForeground;
    s._borderBackground = _borderBackground;
    s._width = _width;
    s._height = _height;
    s._maxWidth = _maxWidth;
    s._maxHeight = _maxHeight;
    s._padding = _padding;
    s._margin = _margin;
    s._align = _align;
    s._border = _border;
    s._borderSides = _borderSides;
    s._inline = _inline;
    s._transform = _transform;
    s.colorProfile = colorProfile;
    s.hasDarkBackground = hasDarkBackground;
    return s;
  }

  /// Inherits explicitly-set properties from another style.
  ///
  /// Only properties that are explicitly set on [other] will be copied
  /// to this style, leaving other properties unchanged.
  Style inherit(Style other) {
    if (other._hasFlag(_PropBits.bold)) {
      _bold = other._bold;
      _setFlag(_PropBits.bold);
    }
    if (other._hasFlag(_PropBits.italic)) {
      _italic = other._italic;
      _setFlag(_PropBits.italic);
    }
    if (other._hasFlag(_PropBits.underline)) {
      _underline = other._underline;
      _setFlag(_PropBits.underline);
    }
    if (other._hasFlag(_PropBits.strikethrough)) {
      _strikethrough = other._strikethrough;
      _setFlag(_PropBits.strikethrough);
    }
    if (other._hasFlag(_PropBits.dim)) {
      _dim = other._dim;
      _setFlag(_PropBits.dim);
    }
    if (other._hasFlag(_PropBits.inverse)) {
      _inverse = other._inverse;
      _setFlag(_PropBits.inverse);
    }
    if (other._hasFlag(_PropBits.blink)) {
      _blink = other._blink;
      _setFlag(_PropBits.blink);
    }
    if (other._hasFlag(_PropBits.foreground)) {
      _foreground = other._foreground;
      _setFlag(_PropBits.foreground);
    }
    if (other._hasFlag(_PropBits.background)) {
      _background = other._background;
      _setFlag(_PropBits.background);
    }
    if (other._hasFlag(_PropBits.borderForeground)) {
      _borderForeground = other._borderForeground;
      _setFlag(_PropBits.borderForeground);
    }
    if (other._hasFlag(_PropBits.borderBackground)) {
      _borderBackground = other._borderBackground;
      _setFlag(_PropBits.borderBackground);
    }
    if (other._hasFlag(_PropBits.width)) {
      _width = other._width;
      _setFlag(_PropBits.width);
    }
    if (other._hasFlag(_PropBits.height)) {
      _height = other._height;
      _setFlag(_PropBits.height);
    }
    if (other._hasFlag(_PropBits.maxWidth)) {
      _maxWidth = other._maxWidth;
      _setFlag(_PropBits.maxWidth);
    }
    if (other._hasFlag(_PropBits.maxHeight)) {
      _maxHeight = other._maxHeight;
      _setFlag(_PropBits.maxHeight);
    }
    if (other._hasFlag(_PropBits.padding)) {
      _padding = other._padding;
      _setFlag(_PropBits.padding);
    }
    if (other._hasFlag(_PropBits.paddingTop)) {
      _padding = _padding.copyWith(top: other._padding.top);
      _setFlag(_PropBits.paddingTop);
    }
    if (other._hasFlag(_PropBits.paddingRight)) {
      _padding = _padding.copyWith(right: other._padding.right);
      _setFlag(_PropBits.paddingRight);
    }
    if (other._hasFlag(_PropBits.paddingBottom)) {
      _padding = _padding.copyWith(bottom: other._padding.bottom);
      _setFlag(_PropBits.paddingBottom);
    }
    if (other._hasFlag(_PropBits.paddingLeft)) {
      _padding = _padding.copyWith(left: other._padding.left);
      _setFlag(_PropBits.paddingLeft);
    }
    if (other._hasFlag(_PropBits.margin)) {
      _margin = other._margin;
      _setFlag(_PropBits.margin);
    }
    if (other._hasFlag(_PropBits.marginTop)) {
      _margin = _margin.copyWith(top: other._margin.top);
      _setFlag(_PropBits.marginTop);
    }
    if (other._hasFlag(_PropBits.marginRight)) {
      _margin = _margin.copyWith(right: other._margin.right);
      _setFlag(_PropBits.marginRight);
    }
    if (other._hasFlag(_PropBits.marginBottom)) {
      _margin = _margin.copyWith(bottom: other._margin.bottom);
      _setFlag(_PropBits.marginBottom);
    }
    if (other._hasFlag(_PropBits.marginLeft)) {
      _margin = _margin.copyWith(left: other._margin.left);
      _setFlag(_PropBits.marginLeft);
    }
    if (other._hasFlag(_PropBits.align)) {
      _align = other._align;
      _setFlag(_PropBits.align);
    }
    if (other._hasFlag(_PropBits.border)) {
      _border = other._border;
      _setFlag(_PropBits.border);
    }
    if (other._hasFlag(_PropBits.borderSides)) {
      _borderSides = other._borderSides;
      _setFlag(_PropBits.borderSides);
    }
    if (other._hasFlag(_PropBits.inline)) {
      _inline = other._inline;
      _setFlag(_PropBits.inline);
    }
    if (other._hasFlag(_PropBits.transform)) {
      _transform = other._transform;
      _setFlag(_PropBits.transform);
    }
    return this;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RENDERING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Renders the given text with this style applied.
  ///
  /// This produces an ANSI-escaped string ready for terminal output.
  String render(String text) {
    // Check if any styling or layout is needed
    final hasLayout =
        _hasFlag(_PropBits.width) ||
        _hasFlag(_PropBits.height) ||
        _hasFlag(_PropBits.maxWidth) ||
        _hasFlag(_PropBits.maxHeight) ||
        _hasFlag(_PropBits.border) ||
        _hasFlag(_PropBits.align) ||
        _hasFlag(_PropBits.transform) ||
        hasSpacing;

    if (colorProfile == ColorProfile.ascii &&
        !hasTextAttributes &&
        !hasLayout) {
      return text;
    }

    var result = text;

    // Apply transform first
    if (_hasFlag(_PropBits.transform) && _transform != null) {
      result = _transform!(result);
    }

    // If inline, skip layout processing
    if (_inline) {
      return _applyTextStyles(result);
    }

    // Process lines for layout
    var lines = result.split('\n');

    // Apply max width (truncate)
    if (_hasFlag(_PropBits.maxWidth) && _maxWidth > 0) {
      lines = _truncateLines(lines, _maxWidth);
    }

    // Calculate content width
    var contentWidth = _getMaxLineWidth(lines);

    // Apply fixed width - wrap text to fit
    // Like lipgloss, wrap at (width - horizontal padding) so content + padding = width
    if (_hasFlag(_PropBits.width) && _width > 0) {
      final wrapAt = _width - _padding.horizontal;
      lines = _wrapText(lines, wrapAt > 0 ? wrapAt : _width);
      contentWidth = wrapAt > 0 ? wrapAt : _width;
    }

    // Apply padding
    if (!_padding.isZero) {
      lines = _applyPadding(lines, contentWidth);
      contentWidth += _padding.horizontal;
    }

    // Apply alignment/padding to width
    // Like lipgloss, this runs when there are multiple lines OR when width is set
    // to ensure content is padded to the specified width
    if ((lines.length > 1 || _hasFlag(_PropBits.width)) && contentWidth > 0) {
      lines = _alignLines(lines, contentWidth);
    }

    // Apply border
    if (_hasFlag(_PropBits.border) && _border != null && _border!.isVisible) {
      lines = _applyBorder(lines, contentWidth);
    }

    // Apply text styles to content lines BEFORE margin
    // (margin is outside the styled area)
    lines = lines.map(_applyTextStyles).toList();

    // Apply fixed height (affects the styled box, margin is applied after)
    if (_hasFlag(_PropBits.height) && _height > 0) {
      lines = _applyHeight(lines, _height);
    }

    // Apply max height
    if (_hasFlag(_PropBits.maxHeight) &&
        _maxHeight > 0 &&
        lines.length > _maxHeight) {
      lines = lines.take(_maxHeight).toList();
    }

    // Apply margin (after sizing the box; margin lines are unstyled)
    if (!_margin.isZero) {
      // Use the actual rendered line width to keep margin rows aligned with
      // the styled box (padding/border may have changed width).
      final renderedWidth = lines.isEmpty
          ? contentWidth
          : lines.map(visibleLength).reduce((a, b) => a > b ? a : b);
      lines = _applyMargin(lines, renderedWidth);
    }

    result = lines.join('\n');

    return result;
  }

  /// Applies ANSI text styling to a string.
  String _applyTextStyles(String text) {
    if (colorProfile == ColorProfile.ascii) {
      return text;
    }

    final chalk = Chalk();
    var styled = text;

    // Apply colors
    if (_hasFlag(_PropBits.background) && _background != null) {
      final ansi = _background!.toAnsi(
        colorProfile,
        background: true,
        hasDarkBackground: hasDarkBackground,
      );
      if (ansi.isNotEmpty) {
        styled = '$ansi$styled\x1B[49m';
      }
    }

    if (_hasFlag(_PropBits.foreground) && _foreground != null) {
      final ansi = _foreground!.toAnsi(
        colorProfile,
        background: false,
        hasDarkBackground: hasDarkBackground,
      );
      if (ansi.isNotEmpty) {
        styled = '$ansi$styled\x1B[39m';
      }
    }

    // Apply text attributes
    if (_hasFlag(_PropBits.bold) && _bold) {
      styled = chalk.bold(styled);
    }
    if (_hasFlag(_PropBits.italic) && _italic) {
      styled = chalk.italic(styled);
    }
    if (_hasFlag(_PropBits.underline) && _underline) {
      styled = chalk.underline(styled);
    }
    if (_hasFlag(_PropBits.strikethrough) && _strikethrough) {
      styled = chalk.strikethrough(styled);
    }
    if (_hasFlag(_PropBits.dim) && _dim) {
      styled = chalk.dim(styled);
    }
    if (_hasFlag(_PropBits.inverse) && _inverse) {
      styled = chalk.inverse(styled);
    }

    return styled;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Layout Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  /// Strips ANSI escape sequences from a string.
  static String stripAnsi(String text) {
    return text.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');
  }

  /// Gets the visible length of a string (ignoring ANSI codes).
  static int visibleLength(String text) {
    final stripped = stripAnsi(text);
    return _displayWidth(stripped);
  }

  /// Calculates the display width of a string, accounting for double-width characters.
  ///
  /// CJK characters, emoji, and other full-width characters take 2 columns in a terminal.
  static int _displayWidth(String text) {
    var width = 0;
    for (final rune in text.runes) {
      width += _charWidth(rune);
    }
    return width;
  }

  /// Returns the display width of a single Unicode code point.
  ///
  /// Returns 2 for full-width characters (CJK, emoji, etc.), 0 for combining
  /// characters and control codes, and 1 for everything else.
  static int _charWidth(int codePoint) {
    // Control characters and null
    if (codePoint < 32 || (codePoint >= 0x7F && codePoint < 0xA0)) {
      return 0;
    }

    // Combining characters (zero width)
    if (_isCombining(codePoint)) {
      return 0;
    }

    // Full-width characters (CJK and others)
    if (_isFullWidth(codePoint)) {
      return 2;
    }

    return 1;
  }

  /// Checks if a code point is a combining character (zero width).
  static bool _isCombining(int cp) {
    return (cp >= 0x0300 && cp <= 0x036F) || // Combining Diacritical Marks
        (cp >= 0x1AB0 && cp <= 0x1AFF) || // Combining Diacritical Marks Extended
        (cp >= 0x1DC0 && cp <= 0x1DFF) || // Combining Diacritical Marks Supplement
        (cp >= 0x20D0 && cp <= 0x20FF) || // Combining Diacritical Marks for Symbols
        (cp >= 0xFE20 && cp <= 0xFE2F); // Combining Half Marks
  }

  /// Checks if a code point is a full-width character (displays as 2 columns).
  static bool _isFullWidth(int cp) {
    // CJK Unified Ideographs and related blocks
    return (cp >= 0x1100 && cp <= 0x115F) || // Hangul Jamo
        (cp >= 0x2E80 && cp <= 0x9FFF) || // CJK Radicals through CJK Unified Ideographs
        (cp >= 0xAC00 && cp <= 0xD7A3) || // Hangul Syllables
        (cp >= 0xF900 && cp <= 0xFAFF) || // CJK Compatibility Ideographs
        (cp >= 0xFE10 && cp <= 0xFE1F) || // Vertical Forms
        (cp >= 0xFE30 && cp <= 0xFE6F) || // CJK Compatibility Forms
        (cp >= 0xFF00 && cp <= 0xFF60) || // Fullwidth ASCII variants
        (cp >= 0xFFE0 && cp <= 0xFFE6) || // Fullwidth symbol variants
        (cp >= 0x20000 && cp <= 0x2FFFF) || // CJK Unified Ideographs Extension B-F
        (cp >= 0x30000 && cp <= 0x3FFFF) || // CJK Unified Ideographs Extension G-H
        // Common emoji ranges (simplified - many emoji are double-width)
        (cp >= 0x1F300 && cp <= 0x1F9FF) || // Miscellaneous Symbols and Pictographs, Emoticons, etc.
        (cp >= 0x1FA00 && cp <= 0x1FAFF); // Chess, symbols, extended-A
  }

  int _getMaxLineWidth(List<String> lines) {
    if (lines.isEmpty) return 0;
    return lines.map(visibleLength).reduce((a, b) => a > b ? a : b);
  }

  List<String> _truncateLines(List<String> lines, int maxWidth) {
    return lines.map((line) => _truncateLine(line, maxWidth)).toList();
  }

  /// Truncates a single line while preserving ANSI codes.
  String _truncateLine(String line, int maxWidth) {
    final visible = visibleLength(line);
    if (visible <= maxWidth) return line;

    final targetLen = maxWidth - 1; // Leave room for ellipsis
    if (targetLen <= 0) return '…';

    final buffer = StringBuffer();
    final ansiPattern = RegExp(r'\x1B\[[0-9;]*m');
    var currentLen = 0;
    var i = 0;

    while (i < line.length && currentLen < targetLen) {
      // Check for ANSI escape sequence
      final match = ansiPattern.matchAsPrefix(line, i);
      if (match != null) {
        // Include the ANSI code but don't count its length
        buffer.write(match.group(0));
        i += match.group(0)!.length;
        continue;
      }

      // Regular character
      buffer.write(line[i]);
      currentLen++;
      i++;
    }

    // Add reset and ellipsis
    buffer.write('\x1B[0m…');
    return buffer.toString();
  }

  /// Wraps text to fit within a specified width.
  ///
  /// Breaks lines at word boundaries when possible, preserving ANSI codes.
  List<String> _wrapText(List<String> lines, int maxWidth) {
    final result = <String>[];

    for (final line in lines) {
      if (visibleLength(line) <= maxWidth) {
        result.add(line);
        continue;
      }

      // Need to wrap this line
      result.addAll(_wrapLine(line, maxWidth));
    }

    return result;
  }

  /// Wraps a single line to fit within maxWidth.
  List<String> _wrapLine(String line, int maxWidth) {
    final result = <String>[];
    final words = _splitIntoWords(line);
    var currentLine = StringBuffer();
    var currentLen = 0;

    for (final word in words) {
      final wordLen = visibleLength(word);

      // If adding this word would exceed maxWidth
      if (currentLen + wordLen > maxWidth) {
        // If we have content, save it and start new line
        if (currentLen > 0) {
          result.add(currentLine.toString());
          currentLine = StringBuffer();
          currentLen = 0;
        }

        // If the word itself is longer than maxWidth, break it
        if (wordLen > maxWidth) {
          final broken = _breakLongWord(word, maxWidth);
          // Add all but last piece as complete lines
          for (var i = 0; i < broken.length - 1; i++) {
            result.add(broken[i]);
          }
          // Continue with last piece
          if (broken.isNotEmpty) {
            currentLine.write(broken.last);
            currentLen = visibleLength(broken.last);
          }
          continue;
        }
      }

      currentLine.write(word);
      currentLen += wordLen;
    }

    // Don't forget the last line
    if (currentLen > 0) {
      result.add(currentLine.toString());
    }

    return result.isEmpty ? [''] : result;
  }

  /// Splits text into words, preserving spaces and ANSI codes.
  List<String> _splitIntoWords(String text) {
    final words = <String>[];
    final buffer = StringBuffer();
    final ansiPattern = RegExp(r'\x1B\[[0-9;]*m');
    var i = 0;

    while (i < text.length) {
      // Check for ANSI escape sequence
      final match = ansiPattern.matchAsPrefix(text, i);
      if (match != null) {
        buffer.write(match.group(0));
        i += match.group(0)!.length;
        continue;
      }

      final char = text[i];
      if (char == ' ') {
        // Include space with current word
        buffer.write(char);
        words.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
      i++;
    }

    // Don't forget the last word
    if (buffer.isNotEmpty) {
      words.add(buffer.toString());
    }

    return words;
  }

  /// Breaks a long word into pieces that fit within maxWidth.
  List<String> _breakLongWord(String word, int maxWidth) {
    final result = <String>[];
    final ansiPattern = RegExp(r'\x1B\[[0-9;]*m');
    var buffer = StringBuffer();
    var currentLen = 0;
    var i = 0;

    while (i < word.length) {
      // Check for ANSI escape sequence
      final match = ansiPattern.matchAsPrefix(word, i);
      if (match != null) {
        buffer.write(match.group(0));
        i += match.group(0)!.length;
        continue;
      }

      if (currentLen >= maxWidth) {
        result.add(buffer.toString());
        buffer = StringBuffer();
        currentLen = 0;
      }

      buffer.write(word[i]);
      currentLen++;
      i++;
    }

    if (buffer.isNotEmpty) {
      result.add(buffer.toString());
    }

    return result;
  }

  List<String> _alignLines(List<String> lines, int width) {
    return lines.map((line) {
      final visible = visibleLength(line);
      if (visible >= width) return line;

      final diff = width - visible;
      switch (_align) {
        case HorizontalAlign.left:
          return '$line${' ' * diff}';
        case HorizontalAlign.center:
          final left = diff ~/ 2;
          final right = diff - left;
          return '${' ' * left}$line${' ' * right}';
        case HorizontalAlign.right:
          return '${' ' * diff}$line';
      }
    }).toList();
  }

  List<String> _applyPadding(List<String> lines, int contentWidth) {
    final result = <String>[];
    final horizontalPad = ' ' * _padding.left;
    final horizontalPadRight = ' ' * _padding.right;
    final totalWidth = contentWidth + _padding.horizontal;

    // Top padding
    for (var i = 0; i < _padding.top; i++) {
      result.add(' ' * totalWidth);
    }

    // Content with horizontal padding
    for (final line in lines) {
      final visible = visibleLength(line);
      final rightFill = ' ' * (contentWidth - visible);
      result.add('$horizontalPad$line$rightFill$horizontalPadRight');
    }

    // Bottom padding
    for (var i = 0; i < _padding.bottom; i++) {
      result.add(' ' * totalWidth);
    }

    return result;
  }

  List<String> _applyBorder(List<String> lines, int contentWidth) {
    final result = <String>[];
    final b = _border!;
    final sides = _borderSides;

    // Compute border styling
    String styleBorder(String text) {
      if (!_hasFlag(_PropBits.borderForeground) &&
          !_hasFlag(_PropBits.borderBackground)) {
        return text;
      }

      var styled = text;
      if (_hasFlag(_PropBits.borderBackground) && _borderBackground != null) {
        final ansi = _borderBackground!.toAnsi(
          colorProfile,
          background: true,
          hasDarkBackground: hasDarkBackground,
        );
        if (ansi.isNotEmpty) {
          styled = '$ansi$styled\x1B[49m';
        }
      }
      if (_hasFlag(_PropBits.borderForeground) && _borderForeground != null) {
        final ansi = _borderForeground!.toAnsi(
          colorProfile,
          background: false,
          hasDarkBackground: hasDarkBackground,
        );
        if (ansi.isNotEmpty) {
          styled = '$ansi$styled\x1B[39m';
        }
      }
      return styled;
    }

    // Top border
    if (sides.top) {
      final left = sides.left ? b.topLeft : '';
      final right = sides.right ? b.topRight : '';
      result.add(styleBorder('$left${b.top * contentWidth}$right'));
    }

    // Content lines with side borders
    for (final line in lines) {
      final left = sides.left ? styleBorder(b.left) : '';
      final right = sides.right ? styleBorder(b.right) : '';
      result.add('$left$line$right');
    }

    // Bottom border
    if (sides.bottom) {
      final left = sides.left ? b.bottomLeft : '';
      final right = sides.right ? b.bottomRight : '';
      result.add(styleBorder('$left${b.bottom * contentWidth}$right'));
    }

    return result;
  }

  List<String> _applyMargin(List<String> lines, int contentWidth) {
    final result = <String>[];
    final leftMargin = ' ' * _margin.left;
    final rightMargin = ' ' * _margin.right;
    final horizontalFill = ' ' * contentWidth;

    // Top margin
    for (var i = 0; i < _margin.top; i++) {
      result.add('$leftMargin$horizontalFill$rightMargin');
    }

    // Content with horizontal margin
    for (final line in lines) {
      result.add('$leftMargin$line$rightMargin');
    }

    // Bottom margin
    for (var i = 0; i < _margin.bottom; i++) {
      result.add('$leftMargin$horizontalFill$rightMargin');
    }

    return result;
  }

  List<String> _applyHeight(List<String> lines, int targetHeight) {
    if (lines.length >= targetHeight) {
      return lines.take(targetHeight).toList();
    }

    final result = List<String>.from(lines);
    final width = lines.isNotEmpty ? visibleLength(lines.first) : 0;
    while (result.length < targetHeight) {
      result.add(' ' * width);
    }
    return result;
  }

  @override
  String toString() {
    // If a string was pre-set, render it
    if (_string != null) {
      return render(_string!);
    }
    // Otherwise, return a debug representation
    final parts = <String>[];
    if (isBold) parts.add('bold');
    if (isItalic) parts.add('italic');
    if (isUnderline) parts.add('underline');
    if (_hasFlag(_PropBits.foreground)) parts.add('fg:$_foreground');
    if (_hasFlag(_PropBits.background)) parts.add('bg:$_background');
    if (_hasFlag(_PropBits.width)) parts.add('width:$_width');
    if (_hasFlag(_PropBits.height)) parts.add('height:$_height');
    if (!_padding.isZero) parts.add('padding:$_padding');
    if (!_margin.isZero) parts.add('margin:$_margin');
    if (_hasFlag(_PropBits.border)) parts.add('border:$_border');
    return 'Style(${parts.join(', ')})';
  }
}
