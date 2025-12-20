import '../unicode/width.dart';

/// Upstream: `third_party/ultraviolet/cell.go` (`Link`).
final class Link {
  const Link({this.url = '', this.params = ''});

  final String url;
  final String params;

  bool get isZero => url.isEmpty && params.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is Link && other.url == url && other.params == params;

  @override
  int get hashCode => Object.hash(url, params);
}

/// Color representation sufficient for Ultraviolet parity tests.
///
/// Upstream: `third_party/ultraviolet/cell.go` stores `color.Color` values and
/// uses `x/ansi` helpers for named/indexed colors.
sealed class UvColor {
  const UvColor();

  const factory UvColor.basic16(int index, {bool bright}) = UvBasic16;
  const factory UvColor.indexed256(int index) = UvIndexed256;
  const factory UvColor.rgb(int r, int g, int b, {int a}) = UvRgb;
}

final class UvBasic16 extends UvColor {
  const UvBasic16(this.index, {this.bright = false});

  final int index; // 0..7
  final bool bright;

  @override
  bool operator ==(Object other) =>
      other is UvBasic16 && other.index == index && other.bright == bright;

  @override
  int get hashCode => Object.hash(index, bright);
}

final class UvIndexed256 extends UvColor {
  const UvIndexed256(this.index);

  final int index; // 0..255

  @override
  bool operator ==(Object other) =>
      other is UvIndexed256 && other.index == index;

  @override
  int get hashCode => index.hashCode;
}

final class UvRgb extends UvColor {
  const UvRgb(this.r, this.g, this.b, {this.a = 255});

  final int r;
  final int g;
  final int b;
  final int a;

  @override
  bool operator ==(Object other) =>
      other is UvRgb &&
      other.r == r &&
      other.g == g &&
      other.b == b &&
      other.a == a;

  @override
  int get hashCode => Object.hash(r, g, b, a);
}

/// Underline styles (subset).
///
/// Upstream: `third_party/ultraviolet/cell.go` uses `ansi.Underline`.
enum UnderlineStyle { none, single, double, curly, dotted, dashed }

/// Text attributes (bitmask).
///
/// Upstream: `third_party/ultraviolet/cell.go` (AttrBold, AttrFaint, ...).
abstract final class Attr {
  static const int bold = 1 << 0;
  static const int faint = 1 << 1;
  static const int italic = 1 << 2;
  static const int blink = 1 << 3;
  static const int rapidBlink = 1 << 4;
  static const int reverse = 1 << 5;
  static const int conceal = 1 << 6;
  static const int strikethrough = 1 << 7;
}

/// Upstream: `third_party/ultraviolet/cell.go` (`UvStyle`).
final class UvStyle {
  const UvStyle({
    this.fg,
    this.bg,
    this.underlineColor,
    this.underline = UnderlineStyle.none,
    this.attrs = 0,
  });

  final UvColor? fg;
  final UvColor? bg;
  final UvColor? underlineColor;
  final UnderlineStyle underline;
  final int attrs;

  bool get isZero =>
      fg == null &&
      bg == null &&
      underlineColor == null &&
      underline == UnderlineStyle.none &&
      attrs == 0;

  UvStyle copyWith({
    UvColor? fg,
    bool clearFg = false,
    UvColor? bg,
    bool clearBg = false,
    UvColor? underlineColor,
    bool clearUnderlineColor = false,
    UnderlineStyle? underline,
    int? attrs,
  }) {
    return UvStyle(
      fg: clearFg ? null : (fg ?? this.fg),
      bg: clearBg ? null : (bg ?? this.bg),
      underlineColor: clearUnderlineColor
          ? null
          : (underlineColor ?? this.underlineColor),
      underline: underline ?? this.underline,
      attrs: attrs ?? this.attrs,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UvStyle &&
      other.fg == fg &&
      other.bg == bg &&
      other.underlineColor == underlineColor &&
      other.underline == underline &&
      other.attrs == attrs;

  @override
  int get hashCode => Object.hash(fg, bg, underlineColor, underline, attrs);
}

/// A single cell in a terminal [Buffer].
///
/// A cell contains a character (or string for multi-byte characters), a [UvStyle],
/// an optional [Link], and its display width. It can also hold a [drawable]
/// for rendering images or complex graphics.
///
/// Upstream: `third_party/ultraviolet/cell.go` (`Cell`, `EmptyCell`).
final class Cell {
  Cell({
    this.content = '',
    this.style = const UvStyle(),
    this.link = const Link(),
    this.drawable,
    int? width,
  }) : width = width ?? (content.isEmpty ? 0 : 1);

  String content;
  UvStyle style;
  Link link;
  int width;
  Object? drawable;

  bool get isZero =>
      content.isEmpty && width == 0 && style.isZero && link.isZero && drawable == null;

  bool get isEmpty =>
      content == ' ' && width == 1 && style.isZero && link.isZero && drawable == null;

  Cell clone() =>
      Cell(content: content, style: style, link: link, width: width, drawable: drawable);

  void empty() {
    content = ' ';
    width = 1;
  }

  static Cell emptyCell() => Cell(content: ' ', width: 1);

  static Cell newCell(WidthMethod method, String grapheme) {
    if (grapheme.isEmpty) return Cell();
    if (grapheme == ' ') return Cell.emptyCell();
    return Cell(content: grapheme, width: method.stringWidth(grapheme));
  }

  @override
  bool operator ==(Object other) =>
      other is Cell &&
      other.content == content &&
      other.width == width &&
      other.style == style &&
      other.link == link;

  @override
  int get hashCode => Object.hash(content, width, style, link);
}
