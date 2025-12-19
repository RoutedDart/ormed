/// Kitchen-sink TUI (implementation entry).
///
/// Keep this file small so newcomers can navigate the app via the `part` list.
library kitchen_sink;

import 'dart:io' as io;
import 'dart:math' as math;

import 'package:artisan_args/artisan_args.dart'
    show
        AdaptiveColor,
        AnsiColor,
        BasicColor,
        Border,
        Color,
        ColorProfile,
        Colors,
        Compositor,
        Layer,
        Layout,
        LipList,
        ListEnumerators,
        Style,
        StyledString,
        Table,
        Tree,
        TreeEnumerator,
        UnderlineStyle,
        VerticalAlign,
        blend1D,
        blend2D,
        stringForProfile;
import 'package:artisan_args/src/tui/uv/capabilities.dart';
import 'package:artisan_args/src/tui/uv/event.dart' as uvev;
import 'package:artisan_args/src/tui/uv/terminal.dart' as uvt;
import 'package:artisan_args/src/unicode/grapheme.dart' as uni;
import 'package:artisan_args/tui.dart' as tui;
import 'package:image/image.dart' as img;

part 'kitchen_sink_core.dart';
part 'kitchen_sink_pages_basic.dart';
part 'kitchen_sink_pages_showcase.dart';
part 'kitchen_sink_pages_widgets.dart';
