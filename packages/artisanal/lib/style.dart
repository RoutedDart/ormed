/// Fluent styling system for terminal text (Lip Gloss for Dart).
///
/// This library provides a powerful, declarative styling system for terminal
/// applications. It allows you to define styles for text, borders, padding,
/// margins, and alignment using a fluent API.
///
/// ## Key Concepts
///
/// - **[Style]**: The primary entry point for defining text formatting.
/// - **[Color]**: Support for ANSI 16, ANSI 256, and TrueColor (RGB).
/// - **[Layout]**: Utilities for joining styled blocks horizontally or vertically.
/// - **[Border]**: Predefined and custom border styles for boxes.
/// - **[List]**: Support for styled bulleted or numbered lists.
/// - **[Table]**: Support for rendering data in styled grids.
///
/// ## Usage
///
/// ```dart
/// import 'package:artisanal/style.dart';
///
/// final style = Style()
///   .bold()
///   .foreground(Colors.purple)
///   .padding(1, 2)
///   .border(Border.rounded);
///
/// print(style.render('Hello, Artisanal!'));
/// ```
library artisanal.style;

export 'src/style/style.dart' show Style, styleRunes;
export 'src/layout/layout.dart' show Layout;
export 'src/style/properties.dart'
    show
        UnderlineStyle,
        VerticalAlign,
        HorizontalAlign,
        Padding,
        Margin,
        Align,
        HorizontalAlignPosition,
        VerticalAlignPosition;
export 'src/style/color.dart'
    show
        Color,
        AnsiColor,
        BasicColor,
        AdaptiveColor,
        CompleteColor,
        CompleteAdaptiveColor,
        NoColor,
        Colors,
        ColorProfile;
export 'src/style/border.dart' show Border, BorderSides;
export 'src/style/list.dart'
    show
        LipList,
        ListEnumerators,
        ListIndenters,
        ListItem,
        ListItems,
        ListStyleFunc,
        ListEnumeratorFunc,
        ListIndenterFunc;
export 'src/layout/layout.dart' show Layout, WhitespaceOptions;
export 'src/style/ranges.dart' show StyleRange, styleRanges, Ranges;
export 'src/style/blending.dart' show blend1D, blend2D;
export 'src/style/writer.dart'
    show
        Writer,
        resetWriter,
        Print,
        PrintAll,
        Println,
        PrintlnAll,
        Printf,
        Sprint,
        SprintAll,
        Sprintln,
        SprintlnAll,
        Sprintf,
        SprintfAll,
        Fprint,
        Fprintln,
        Fprintf,
        stringForProfile;
