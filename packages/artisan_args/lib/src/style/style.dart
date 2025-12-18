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
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;

import 'border.dart';
import 'color.dart';
import 'properties.dart';
import '../unicode/grapheme.dart' as uni;
import '../tui/uv/wrap.dart' as uv_wrap;

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
  static const int alignVertical = 1 << 30;
  // Per-side border colors use a separate bitfield (_borderProps)

  // Additional properties (using a second bitfield _props2)
  static const int tabWidth = 1 << 0;
  static const int underlineSpaces = 1 << 1;
  static const int strikethroughSpaces = 1 << 2;
  static const int marginBackground = 1 << 3;
  static const int stringValue = 1 << 4;
  static const int borderTop = 1 << 5;
  static const int borderRight = 1 << 6;
  static const int borderBottom = 1 << 7;
  static const int borderLeft = 1 << 8;
  static const int wrapAnsi = 1 << 9;
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

  /// Second bitfield for additional properties.
  int _props2 = 0;

  bool _hasFlag(int flag) => _props & flag != 0;
  void _setFlag(int flag) => _props |= flag;
  void _clearFlag(int flag) => _props &= ~flag;

  bool _hasFlag2(int flag) => _props2 & flag != 0;
  void _setFlag2(int flag) => _props2 |= flag;
  void _clearFlag2(int flag) => _props2 &= ~flag;

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

  // Per-side border colors
  Color? _borderTopForeground;
  Color? _borderRightForeground;
  Color? _borderBottomForeground;
  Color? _borderLeftForeground;
  Color? _borderTopBackground;
  Color? _borderRightBackground;
  Color? _borderBottomBackground;
  Color? _borderLeftBackground;

  /// Bitfield for per-side border color properties.
  int _borderProps = 0;
  static const int _borderTopFg = 1 << 0;
  static const int _borderRightFg = 1 << 1;
  static const int _borderBottomFg = 1 << 2;
  static const int _borderLeftFg = 1 << 3;
  static const int _borderTopBg = 1 << 4;
  static const int _borderRightBg = 1 << 5;
  static const int _borderBottomBg = 1 << 6;
  static const int _borderLeftBg = 1 << 7;

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
  VerticalAlign _alignVertical = VerticalAlign.top;
  Border? _border;
  BorderSides _borderSides = BorderSides.all;
  bool _inline = false;
  bool _wrapAnsi = false;

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
  // Additional Style Properties
  // ─────────────────────────────────────────────────────────────────────────────

  /// Tab width for tab character handling.
  int _tabWidth = 4;

  /// Whether to underline spaces.
  bool _underlineSpaces = false;

  /// Whether to strikethrough spaces.
  bool _strikethroughSpaces = false;

  /// Background color for margin areas.
  Color? _marginBackground;

  /// Individual border side visibility.
  bool _borderTopVisible = true;
  bool _borderRightVisible = true;
  bool _borderBottomVisible = true;
  bool _borderLeftVisible = true;

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

  /// Sets the top border foreground color.
  Style borderTopForeground(Color color) {
    _borderTopForeground = color;
    _borderProps |= _borderTopFg;
    return this;
  }

  /// Sets the right border foreground color.
  Style borderRightForeground(Color color) {
    _borderRightForeground = color;
    _borderProps |= _borderRightFg;
    return this;
  }

  /// Sets the bottom border foreground color.
  Style borderBottomForeground(Color color) {
    _borderBottomForeground = color;
    _borderProps |= _borderBottomFg;
    return this;
  }

  /// Sets the left border foreground color.
  Style borderLeftForeground(Color color) {
    _borderLeftForeground = color;
    _borderProps |= _borderLeftFg;
    return this;
  }

  /// Sets the top border background color.
  Style borderTopBackground(Color color) {
    _borderTopBackground = color;
    _borderProps |= _borderTopBg;
    return this;
  }

  /// Sets the right border background color.
  Style borderRightBackground(Color color) {
    _borderRightBackground = color;
    _borderProps |= _borderRightBg;
    return this;
  }

  /// Sets the bottom border background color.
  Style borderBottomBackground(Color color) {
    _borderBottomBackground = color;
    _borderProps |= _borderBottomBg;
    return this;
  }

  /// Sets the left border background color.
  Style borderLeftBackground(Color color) {
    _borderLeftBackground = color;
    _borderProps |= _borderLeftBg;
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

  /// Sets horizontal text alignment, optionally with vertical alignment.
  ///
  /// With one argument, sets horizontal alignment only.
  /// With two arguments, sets both horizontal and vertical alignment.
  ///
  /// ```dart
  /// style.align(HorizontalAlign.center); // horizontal only
  /// style.align(HorizontalAlign.center, VerticalAlign.middle); // both
  /// ```
  Style align(HorizontalAlign horizontal, [VerticalAlign? vertical]) {
    _align = horizontal;
    _setFlag(_PropBits.align);
    if (vertical != null) {
      _alignVertical = vertical;
      _setFlag(_PropBits.alignVertical);
    }
    return this;
  }

  /// Sets horizontal text alignment (alias for [align]).
  Style alignHorizontal(HorizontalAlign value) => align(value);

  /// Sets vertical text alignment within the height.
  Style alignVertical(VerticalAlign value) {
    _alignVertical = value;
    _setFlag(_PropBits.alignVertical);
    return this;
  }

  /// Aligns text to the left.
  Style alignLeft() => align(HorizontalAlign.left);

  /// Aligns text to the center horizontally.
  Style alignCenter() => align(HorizontalAlign.center);

  /// Aligns text to the right.
  Style alignRight() => align(HorizontalAlign.right);

  /// Aligns text to the top.
  Style alignTop() => alignVertical(VerticalAlign.top);

  /// Aligns text to the center vertically.
  Style alignMiddle() => alignVertical(VerticalAlign.center);

  /// Aligns text to the bottom.
  Style alignBottom() => alignVertical(VerticalAlign.bottom);

  // ─────────────────────────────────────────────────────────────────────────────
  // Border
  // ─────────────────────────────────────────────────────────────────────────────

  /// Sets the border style, optionally specifying which sides are visible.
  ///
  /// With one argument, sets the border style and enables all sides.
  /// With additional arguments, sets visibility for top, right, bottom, left.
  ///
  /// ```dart
  /// // Enable border on all sides
  /// style.border(Border.rounded());
  ///
  /// // Enable border on top and bottom only
  /// style.border(Border.rounded(), top: true, bottom: true);
  ///
  /// // Explicitly set all sides
  /// style.border(Border.rounded(), top: true, right: false, bottom: true, left: false);
  /// ```
  Style border(
    Border value, {
    bool? top,
    bool? right,
    bool? bottom,
    bool? left,
  }) {
    _border = value;
    _setFlag(_PropBits.border);

    // If any side is specified, apply the border sides
    if (top != null || right != null || bottom != null || left != null) {
      _borderSides = BorderSides(
        top: top ?? false,
        right: right ?? false,
        bottom: bottom ?? false,
        left: left ?? false,
      );
      _setFlag(_PropBits.borderSides);
    }
    return this;
  }

  /// Alias for setting border style only (without changing sides).
  ///
  /// This matches the lipgloss API where `BorderStyle()` sets the border type
  /// without affecting which sides are visible.
  Style borderStyle(Border value) {
    _border = value;
    _setFlag(_PropBits.border);
    return this;
  }

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
    _setFlag2(_PropBits.stringValue);
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

  /// Sets whether to use ANSI-preserving wrapping.
  ///
  /// When enabled, ANSI pen state (SGR + OSC 8) is preserved across
  /// wrapped lines.
  Style wrapAnsi([bool value = true]) {
    _wrapAnsi = value;
    _setFlag2(_PropBits.wrapAnsi);
    return this;
  }

  /// Sets a text transformation function.
  Style transform(String Function(String) fn) {
    _transform = fn;
    _setFlag(_PropBits.transform);
    return this;
  }

  /// Sets the tab width for tab character handling.
  Style tabWidth(int width) {
    _tabWidth = width;
    _setFlag2(_PropBits.tabWidth);
    return this;
  }

  /// Sets whether to underline spaces.
  Style underlineSpaces([bool value = true]) {
    _underlineSpaces = value;
    _setFlag2(_PropBits.underlineSpaces);
    return this;
  }

  /// Sets whether to strikethrough spaces.
  Style strikethroughSpaces([bool value = true]) {
    _strikethroughSpaces = value;
    _setFlag2(_PropBits.strikethroughSpaces);
    return this;
  }

  /// Sets the background color for margin areas.
  Style marginBackground(Color color) {
    _marginBackground = color;
    _setFlag2(_PropBits.marginBackground);
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

  /// Unsets dim.
  Style unsetDim() {
    _dim = false;
    _clearFlag(_PropBits.dim);
    return this;
  }

  /// Unsets blink.
  Style unsetBlink() {
    _blink = false;
    _clearFlag(_PropBits.blink);
    return this;
  }

  /// Unsets reverse (inverse colors).
  Style unsetReverse() {
    _inverse = false;
    _clearFlag(_PropBits.inverse);
    return this;
  }

  /// Unsets max width.
  Style unsetMaxWidth() {
    _maxWidth = 0;
    _clearFlag(_PropBits.maxWidth);
    return this;
  }

  /// Unsets max height.
  Style unsetMaxHeight() {
    _maxHeight = 0;
    _clearFlag(_PropBits.maxHeight);
    return this;
  }

  /// Unsets horizontal alignment.
  Style unsetAlignHorizontal() {
    _align = HorizontalAlign.left;
    _clearFlag(_PropBits.align);
    return this;
  }

  /// Unsets vertical alignment.
  Style unsetAlignVertical() {
    _alignVertical = VerticalAlign.top;
    _clearFlag(_PropBits.alignVertical);
    return this;
  }

  /// Unsets inline mode.
  Style unsetInline() {
    _inline = false;
    _clearFlag(_PropBits.inline);
    return this;
  }

  /// Unsets tab width.
  Style unsetTabWidth() {
    _tabWidth = 4;
    _clearFlag2(_PropBits.tabWidth);
    return this;
  }

  /// Unsets underline spaces.
  Style unsetUnderlineSpaces() {
    _underlineSpaces = false;
    _clearFlag2(_PropBits.underlineSpaces);
    return this;
  }

  /// Unsets strikethrough spaces.
  Style unsetStrikethroughSpaces() {
    _strikethroughSpaces = false;
    _clearFlag2(_PropBits.strikethroughSpaces);
    return this;
  }

  /// Unsets margin background color.
  Style unsetMarginBackground() {
    _marginBackground = null;
    _clearFlag2(_PropBits.marginBackground);
    return this;
  }

  /// Unsets top border visibility.
  Style unsetBorderTop() {
    _borderTopVisible = true;
    _clearFlag2(_PropBits.borderTop);
    return this;
  }

  /// Unsets right border visibility.
  Style unsetBorderRight() {
    _borderRightVisible = true;
    _clearFlag2(_PropBits.borderRight);
    return this;
  }

  /// Unsets bottom border visibility.
  Style unsetBorderBottom() {
    _borderBottomVisible = true;
    _clearFlag2(_PropBits.borderBottom);
    return this;
  }

  /// Unsets left border visibility.
  Style unsetBorderLeft() {
    _borderLeftVisible = true;
    _clearFlag2(_PropBits.borderLeft);
    return this;
  }

  /// Unsets the pre-set string value.
  Style unsetString() {
    _string = null;
    _clearFlag2(_PropBits.stringValue);
    return this;
  }

  /// Unsets border foreground color.
  Style unsetBorderForeground() {
    _borderForeground = null;
    _borderTopForeground = null;
    _borderRightForeground = null;
    _borderBottomForeground = null;
    _borderLeftForeground = null;
    _clearFlag(_PropBits.borderForeground);
    _borderProps &=
        ~(_borderTopFg | _borderRightFg | _borderBottomFg | _borderLeftFg);
    return this;
  }

  /// Unsets border background color.
  Style unsetBorderBackground() {
    _borderBackground = null;
    _borderTopBackground = null;
    _borderRightBackground = null;
    _borderBottomBackground = null;
    _borderLeftBackground = null;
    _clearFlag(_PropBits.borderBackground);
    _borderProps &=
        ~(_borderTopBg | _borderRightBg | _borderBottomBg | _borderLeftBg);
    return this;
  }

  /// Unsets padding top.
  Style unsetPaddingTop() {
    _padding = _padding.copyWith(top: 0);
    _clearFlag(_PropBits.paddingTop);
    return this;
  }

  /// Unsets padding right.
  Style unsetPaddingRight() {
    _padding = _padding.copyWith(right: 0);
    _clearFlag(_PropBits.paddingRight);
    return this;
  }

  /// Unsets padding bottom.
  Style unsetPaddingBottom() {
    _padding = _padding.copyWith(bottom: 0);
    _clearFlag(_PropBits.paddingBottom);
    return this;
  }

  /// Unsets padding left.
  Style unsetPaddingLeft() {
    _padding = _padding.copyWith(left: 0);
    _clearFlag(_PropBits.paddingLeft);
    return this;
  }

  /// Unsets margin top.
  Style unsetMarginTop() {
    _margin = _margin.copyWith(top: 0);
    _clearFlag(_PropBits.marginTop);
    return this;
  }

  /// Unsets margin right.
  Style unsetMarginRight() {
    _margin = _margin.copyWith(right: 0);
    _clearFlag(_PropBits.marginRight);
    return this;
  }

  /// Unsets margin bottom.
  Style unsetMarginBottom() {
    _margin = _margin.copyWith(bottom: 0);
    _clearFlag(_PropBits.marginBottom);
    return this;
  }

  /// Unsets margin left.
  Style unsetMarginLeft() {
    _margin = _margin.copyWith(left: 0);
    _clearFlag(_PropBits.marginLeft);
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

  /// Gets the tab width.
  int get getTabWidth => _hasFlag2(_PropBits.tabWidth) ? _tabWidth : 4;

  /// Whether underline spaces is set.
  bool get isUnderlineSpaces =>
      _hasFlag2(_PropBits.underlineSpaces) && _underlineSpaces;

  /// Whether strikethrough spaces is set.
  bool get isStrikethroughSpaces =>
      _hasFlag2(_PropBits.strikethroughSpaces) && _strikethroughSpaces;

  /// Gets the margin background color if set.
  Color? get getMarginBackground =>
      _hasFlag2(_PropBits.marginBackground) ? _marginBackground : null;

  /// Gets whether top border is visible.
  bool get getBorderTop =>
      _hasFlag2(_PropBits.borderTop) ? _borderTopVisible : true;

  /// Gets whether right border is visible.
  bool get getBorderRight =>
      _hasFlag2(_PropBits.borderRight) ? _borderRightVisible : true;

  /// Gets whether bottom border is visible.
  bool get getBorderBottom =>
      _hasFlag2(_PropBits.borderBottom) ? _borderBottomVisible : true;

  /// Gets whether left border is visible.
  bool get getBorderLeft =>
      _hasFlag2(_PropBits.borderLeft) ? _borderLeftVisible : true;

  /// Gets the pre-set string value.
  String? get value => _hasFlag2(_PropBits.stringValue) ? _string : _string;

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

  /// Gets the top padding.
  int get getPaddingTop => _padding.top;

  /// Gets the right padding.
  int get getPaddingRight => _padding.right;

  /// Gets the bottom padding.
  int get getPaddingBottom => _padding.bottom;

  /// Gets the left padding.
  int get getPaddingLeft => _padding.left;

  /// Gets the horizontal padding (left + right).
  int get getHorizontalPadding => _padding.horizontal;

  /// Gets the vertical padding (top + bottom).
  int get getVerticalPadding => _padding.vertical;

  /// Gets the margin.
  Margin get getMargin => _margin;

  /// Gets the top margin.
  int get getMarginTop => _margin.top;

  /// Gets the right margin.
  int get getMarginRight => _margin.right;

  /// Gets the bottom margin.
  int get getMarginBottom => _margin.bottom;

  /// Gets the left margin.
  int get getMarginLeft => _margin.left;

  /// Gets the horizontal margin (left + right).
  int get getHorizontalMargins => _margin.horizontal;

  /// Gets the vertical margin (top + bottom).
  int get getVerticalMargins => _margin.vertical;

  /// Gets the horizontal alignment.
  HorizontalAlign get getAlign => _align;

  /// Gets the horizontal alignment (alias).
  HorizontalAlign get getAlignHorizontal => _align;

  /// Gets the vertical alignment.
  VerticalAlign get getAlignVertical => _alignVertical;

  /// Gets the border if set.
  Border? get getBorder => _hasFlag(_PropBits.border) ? _border : null;

  /// Gets the border style (alias for getBorder).
  Border? get getBorderStyle => getBorder;

  /// Gets the border sides.
  BorderSides get getBorderSides => _borderSides;

  /// Gets the border foreground color if set.
  Color? get getBorderForeground =>
      _hasFlag(_PropBits.borderForeground) ? _borderForeground : null;

  /// Gets the border background color if set.
  Color? get getBorderBackground =>
      _hasFlag(_PropBits.borderBackground) ? _borderBackground : null;

  /// Gets the top border foreground color if set.
  Color? get getBorderTopForeground =>
      (_borderProps & _borderTopFg) != 0 ? _borderTopForeground : null;

  /// Gets the right border foreground color if set.
  Color? get getBorderRightForeground =>
      (_borderProps & _borderRightFg) != 0 ? _borderRightForeground : null;

  /// Gets the bottom border foreground color if set.
  Color? get getBorderBottomForeground =>
      (_borderProps & _borderBottomFg) != 0 ? _borderBottomForeground : null;

  /// Gets the left border foreground color if set.
  Color? get getBorderLeftForeground =>
      (_borderProps & _borderLeftFg) != 0 ? _borderLeftForeground : null;

  /// Gets the top border background color if set.
  Color? get getBorderTopBackground =>
      (_borderProps & _borderTopBg) != 0 ? _borderTopBackground : null;

  /// Gets the right border background color if set.
  Color? get getBorderRightBackground =>
      (_borderProps & _borderRightBg) != 0 ? _borderRightBackground : null;

  /// Gets the bottom border background color if set.
  Color? get getBorderBottomBackground =>
      (_borderProps & _borderBottomBg) != 0 ? _borderBottomBackground : null;

  /// Gets the left border background color if set.
  Color? get getBorderLeftBackground =>
      (_borderProps & _borderLeftBg) != 0 ? _borderLeftBackground : null;

  /// Gets the horizontal frame size (border + padding).
  int get getHorizontalFrameSize {
    var size = _padding.horizontal;
    if (_hasFlag(_PropBits.border) && _border != null && _border!.isVisible) {
      if (_borderSides.left) size += 1;
      if (_borderSides.right) size += 1;
    }
    return size;
  }

  /// Gets the vertical frame size (border + padding).
  int get getVerticalFrameSize {
    var size = _padding.vertical;
    if (_hasFlag(_PropBits.border) && _border != null && _border!.isVisible) {
      if (_borderSides.top) size += 1;
      if (_borderSides.bottom) size += 1;
    }
    return size;
  }

  /// Gets the frame size (border + padding) as (width, height).
  ({int width, int height}) get getFrameSize =>
      (width: getHorizontalFrameSize, height: getVerticalFrameSize);

  /// Gets the transform function if set.
  String Function(String)? get getTransform =>
      _hasFlag(_PropBits.transform) ? _transform : null;

  /// Gets the pre-set string value if set.
  String? get getValue => _string;

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
    s._props2 = _props2;
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
    s._borderTopForeground = _borderTopForeground;
    s._borderTopBackground = _borderTopBackground;
    s._borderRightForeground = _borderRightForeground;
    s._borderRightBackground = _borderRightBackground;
    s._borderBottomForeground = _borderBottomForeground;
    s._borderBottomBackground = _borderBottomBackground;
    s._borderLeftForeground = _borderLeftForeground;
    s._borderLeftBackground = _borderLeftBackground;
    s._borderProps = _borderProps;
    s._width = _width;
    s._height = _height;
    s._maxWidth = _maxWidth;
    s._maxHeight = _maxHeight;
    s._padding = _padding;
    s._margin = _margin;
    s._align = _align;
    s._alignVertical = _alignVertical;
    s._border = _border;
    s._borderSides = _borderSides;
    s._inline = _inline;
    s._wrapAnsi = _wrapAnsi;
    s._transform = _transform;
    s._whitespaceChar = _whitespaceChar;
    s._whitespaceForeground = _whitespaceForeground;
    s._string = _string;
    s._tabWidth = _tabWidth;
    s._underlineSpaces = _underlineSpaces;
    s._strikethroughSpaces = _strikethroughSpaces;
    s._marginBackground = _marginBackground;
    s._borderTopVisible = _borderTopVisible;
    s._borderRightVisible = _borderRightVisible;
    s._borderBottomVisible = _borderBottomVisible;
    s._borderLeftVisible = _borderLeftVisible;
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
    if (other._hasFlag2(_PropBits.wrapAnsi)) {
      _wrapAnsi = other._wrapAnsi;
      _setFlag2(_PropBits.wrapAnsi);
    }
    if (other._hasFlag(_PropBits.transform)) {
      _transform = other._transform;
      _setFlag(_PropBits.transform);
    }
    if (other._hasFlag(_PropBits.alignVertical)) {
      _alignVertical = other._alignVertical;
      _setFlag(_PropBits.alignVertical);
    }
    // Per-side border colors use _borderProps bitfield
    if ((other._borderProps & _borderTopFg) != 0) {
      _borderTopForeground = other._borderTopForeground;
      _borderProps |= _borderTopFg;
    }
    if ((other._borderProps & _borderTopBg) != 0) {
      _borderTopBackground = other._borderTopBackground;
      _borderProps |= _borderTopBg;
    }
    if ((other._borderProps & _borderRightFg) != 0) {
      _borderRightForeground = other._borderRightForeground;
      _borderProps |= _borderRightFg;
    }
    if ((other._borderProps & _borderRightBg) != 0) {
      _borderRightBackground = other._borderRightBackground;
      _borderProps |= _borderRightBg;
    }
    if ((other._borderProps & _borderBottomFg) != 0) {
      _borderBottomForeground = other._borderBottomForeground;
      _borderProps |= _borderBottomFg;
    }
    if ((other._borderProps & _borderBottomBg) != 0) {
      _borderBottomBackground = other._borderBottomBackground;
      _borderProps |= _borderBottomBg;
    }
    if ((other._borderProps & _borderLeftFg) != 0) {
      _borderLeftForeground = other._borderLeftForeground;
      _borderProps |= _borderLeftFg;
    }
    if ((other._borderProps & _borderLeftBg) != 0) {
      _borderLeftBackground = other._borderLeftBackground;
      _borderProps |= _borderLeftBg;
    }
    // Properties from _props2
    if (other._hasFlag2(_PropBits.tabWidth)) {
      _tabWidth = other._tabWidth;
      _setFlag2(_PropBits.tabWidth);
    }
    if (other._hasFlag2(_PropBits.underlineSpaces)) {
      _underlineSpaces = other._underlineSpaces;
      _setFlag2(_PropBits.underlineSpaces);
    }
    if (other._hasFlag2(_PropBits.strikethroughSpaces)) {
      _strikethroughSpaces = other._strikethroughSpaces;
      _setFlag2(_PropBits.strikethroughSpaces);
    }
    if (other._hasFlag2(_PropBits.marginBackground)) {
      _marginBackground = other._marginBackground;
      _setFlag2(_PropBits.marginBackground);
    }
    if (other._hasFlag2(_PropBits.stringValue)) {
      _string = other._string;
      _setFlag2(_PropBits.stringValue);
    }
    if (other._hasFlag2(_PropBits.borderTop)) {
      _borderTopVisible = other._borderTopVisible;
      _setFlag2(_PropBits.borderTop);
    }
    if (other._hasFlag2(_PropBits.borderRight)) {
      _borderRightVisible = other._borderRightVisible;
      _setFlag2(_PropBits.borderRight);
    }
    if (other._hasFlag2(_PropBits.borderBottom)) {
      _borderBottomVisible = other._borderBottomVisible;
      _setFlag2(_PropBits.borderBottom);
    }
    if (other._hasFlag2(_PropBits.borderLeft)) {
      _borderLeftVisible = other._borderLeftVisible;
      _setFlag2(_PropBits.borderLeft);
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
    text = _applyConsoleTags(text);
    text = _applyConsoleTags(text);

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

    // Apply padding (fixed spaces, alignment fills to width later)
    if (!_padding.isZero) {
      lines = _applyPadding(lines);
    }

    // Apply alignment to reach target width
    // Like lipgloss, this runs when there are multiple lines OR when width is set
    // The target width is the full _width (including padding), or the widest line if no width set
    final alignWidth = _hasFlag(_PropBits.width) && _width > 0
        ? _width
        : _getMaxLineWidth(lines);
    if ((lines.length > 1 || _hasFlag(_PropBits.width)) && alignWidth > 0) {
      lines = _alignLines(lines, alignWidth);
    }

    // Update contentWidth after alignment for border
    contentWidth = alignWidth;

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
    return text.replaceAll(RegExp(r'\x1B\[[0-9;:]*m'), '');
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
    for (final g in uni.graphemes(text)) {
      width += _charWidth(uni.firstCodePoint(g));
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
        (cp >= 0x1AB0 &&
            cp <= 0x1AFF) || // Combining Diacritical Marks Extended
        (cp >= 0x1DC0 &&
            cp <= 0x1DFF) || // Combining Diacritical Marks Supplement
        (cp >= 0x20D0 &&
            cp <= 0x20FF) || // Combining Diacritical Marks for Symbols
        (cp >= 0xFE20 && cp <= 0xFE2F); // Combining Half Marks
  }

  /// Checks if a code point is a full-width character (displays as 2 columns).
  static bool _isFullWidth(int cp) {
    // CJK Unified Ideographs and related blocks
    return (cp >= 0x1100 && cp <= 0x115F) || // Hangul Jamo
        (cp >= 0x2E80 &&
            cp <= 0x9FFF) || // CJK Radicals through CJK Unified Ideographs
        (cp >= 0xAC00 && cp <= 0xD7A3) || // Hangul Syllables
        (cp >= 0xF900 && cp <= 0xFAFF) || // CJK Compatibility Ideographs
        (cp >= 0xFE10 && cp <= 0xFE1F) || // Vertical Forms
        (cp >= 0xFE30 && cp <= 0xFE6F) || // CJK Compatibility Forms
        (cp >= 0xFF00 && cp <= 0xFF60) || // Fullwidth ASCII variants
        (cp >= 0xFFE0 && cp <= 0xFFE6) || // Fullwidth symbol variants
        (cp >= 0x20000 &&
            cp <= 0x2FFFF) || // CJK Unified Ideographs Extension B-F
        (cp >= 0x30000 &&
            cp <= 0x3FFFF) || // CJK Unified Ideographs Extension G-H
        // Common emoji ranges (simplified - many emoji are double-width)
        (cp >= 0x1F300 &&
            cp <=
                0x1F9FF) || // Miscellaneous Symbols and Pictographs, Emoticons, etc.
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
    if (_wrapAnsi) {
      final joined = lines.join('\n');
      final wrapped = uv_wrap.wrapAnsiPreserving(joined, maxWidth);
      return wrapped.split('\n');
    }

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

  /// Aligns lines horizontally, like lipgloss's alignTextHorizontal.
  ///
  /// For each line:
  /// 1. Calculate shortAmount = widestLine - lineWidth (to match widest line)
  /// 2. Add additional space if width > (shortAmount + lineWidth)
  /// This ensures all lines become the same width, and reach the target width if set.
  List<String> _alignLines(List<String> lines, int targetWidth) {
    if (lines.isEmpty) return lines;

    // Find the widest line
    final widestLine = lines.map(visibleLength).reduce((a, b) => a > b ? a : b);

    return lines.map((line) {
      final lineWidth = visibleLength(line);
      var shortAmount = widestLine - lineWidth; // difference from widest line

      // Add more if we need to reach target width
      final neededForWidth = targetWidth - (shortAmount + lineWidth);
      if (neededForWidth > 0) {
        shortAmount += neededForWidth;
      }

      if (shortAmount <= 0) return line;

      switch (_align) {
        case HorizontalAlign.left:
          return '$line${' ' * shortAmount}';
        case HorizontalAlign.center:
          final left = shortAmount ~/ 2;
          final right = shortAmount - left;
          return '${' ' * left}$line${' ' * right}';
        case HorizontalAlign.right:
          return '${' ' * shortAmount}$line';
      }
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Console-style tag parsing (Symfony/Laravel)
  // ─────────────────────────────────────────────────────────────────────────

  static const _resetAnsi = '\x1B[0m';

  String _applyConsoleTags(String text) {
    // Quick exit if no tags
    if (!text.contains('<')) return text;

    final wrapped = _wrapConsoleTags(text);
    if (wrapped == null) return text;

    final normalized = wrapped.replaceAll('</>', '</span>');
    final fragment = html.parseFragment(normalized);
    final buf = StringBuffer();
    final stack = <String>[];

    void walk(dom.Node node) {
      if (node.nodeType == dom.Node.TEXT_NODE) {
        buf.write(node.text);
        return;
      }
      if (node is dom.Element) {
        String? applied;
        if (node.localName == 'span') {
          final data = node.attributes['data-console'];
          if (data != null) {
            applied = _consoleToAnsi(data);
            if (applied.isNotEmpty) {
              buf.write(applied);
              stack.add(applied);
            }
          }
        }
        for (final child in node.nodes) {
          walk(child);
        }
        if (applied != null && stack.isNotEmpty) {
          // restore previous style or reset
          stack.removeLast();
          final prev = stack.isNotEmpty ? stack.last : null;
          buf.write(prev ?? _resetAnsi);
        }
      }
    }

    for (final node in fragment.nodes) {
      walk(node);
    }

    buf.write(_resetAnsi);
    return buf.toString();
  }

  String _consoleToAnsi(String tag) {
    var fg = '';
    var bg = '';
    var opts = '';
    var href = '';

    for (final part in tag.split(';')) {
      final kv = part.split('=');
      if (kv.length != 2) continue;
      switch (kv[0].toLowerCase()) {
        case 'fg':
          fg = kv[1];
          break;
        case 'bg':
          bg = kv[1];
          break;
        case 'options':
          opts = kv[1];
          break;
        case 'href':
          href = kv[1];
          break;
      }
    }

    final buf = StringBuffer();
    if (fg.isNotEmpty) buf.write(_colorAnsi(fg, true));
    if (bg.isNotEmpty) buf.write(_colorAnsi(bg, false));
    if (opts.isNotEmpty) buf.write(_optionsAnsi(opts));
    if (href.isNotEmpty) {
      buf.write('\u001b]8;;$href\u0007');
    }

    return buf.toString();
  }

  String _colorAnsi(String color, bool foreground) {
    final map = <String, int>{
      'black': 0,
      'red': 1,
      'green': 2,
      'yellow': 3,
      'blue': 4,
      'magenta': 5,
      'cyan': 6,
      'white': 7,
      'default': 9,
      'gray': 7,
      'grey': 7,
    };
    final lower = color.toLowerCase();
    final bright = lower.startsWith('bright-');
    final name = bright ? lower.substring(7) : lower;
    final code = map[name];
    if (code == null) return '';
    final base = foreground ? 30 : 40;
    final value = bright ? base + 60 + code : base + code;
    return '\x1B[${value}m';
  }

  String _optionsAnsi(String opts) {
    final parts = opts.split(',').map((s) => s.trim().toLowerCase());
    final codes = <int>[];
    for (final p in parts) {
      switch (p) {
        case 'bold':
          codes.add(1);
          break;
        case 'underscore':
        case 'underline':
          codes.add(4);
          break;
        case 'blink':
          codes.add(5);
          break;
        case 'reverse':
          codes.add(7);
          break;
        case 'conceal':
          codes.add(8);
          break;
      }
    }
    if (codes.isEmpty) return '';
    return '\x1B[${codes.join(';')}m';
  }

  /// Wrap console tags into spans for HTML parsing without regex usage.
  /// Returns null if no wrapping was needed.
  String? _wrapConsoleTags(String text) {
    final buf = StringBuffer();
    var i = 0;
    var changed = false;
    var appliedAny = false;

    while (i < text.length) {
      final ch = text[i];
      if (ch != '<') {
        buf.write(ch);
        i++;
        continue;
      }

      final end = text.indexOf('>', i + 1);
      if (end == -1) {
        buf.write(text.substring(i));
        break;
      }

      final token = text.substring(i + 1, end);

      // Handle reset </>
      if (token == '/') {
        if (appliedAny) {
          buf.write('</span>');
          changed = true;
        } else {
          buf.write('</>');
        }
        i = end + 1;
        continue;
      }

      // Closing tags pass through
      if (token.startsWith('/')) {
        buf.write('<$token>');
        i = end + 1;
        continue;
      }

      final lower = token.toLowerCase();
      final hasSupported =
          lower.contains('fg=') ||
          lower.contains('bg=') ||
          lower.contains('options=') ||
          lower.contains('href=');

      if (hasSupported) {
        buf.write('<span data-console="$token">');
        appliedAny = true;
        changed = true;
      } else {
        buf.write('<$token>');
      }
      i = end + 1;
    }

    return changed ? buf.toString() : null;
  }

  /// Applies padding (fixed spaces, not filling to width).
  /// Like lipgloss, padding adds fixed space characters - alignment fills to width later.
  List<String> _applyPadding(List<String> lines) {
    final result = <String>[];
    final leftPad = ' ' * _padding.left;
    final rightPad = ' ' * _padding.right;

    // Top padding - empty lines (will be filled by alignment)
    for (var i = 0; i < _padding.top; i++) {
      result.add('');
    }

    // Content with horizontal padding (fixed spaces, not filling)
    for (final line in lines) {
      result.add('$leftPad$line$rightPad');
    }

    // Bottom padding - empty lines (will be filled by alignment)
    for (var i = 0; i < _padding.bottom; i++) {
      result.add('');
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
