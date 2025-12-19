import 'environ.dart';
import 'event.dart';
import 'cell.dart';

/// Terminal capabilities discovered via ANSI queries.
final class TerminalCapabilities {
  TerminalCapabilities({List<String>? env}) {
    if (env != null) {
      final environ = Environ(env);
      final term = environ.getenv('TERM');
      final termProg = environ.getenv('TERM_PROGRAM');
      final lcTerm = environ.getenv('LC_TERMINAL');

      // iTerm2 Image Protocol is specific to iTerm2-compatible terminals.
      if (termProg.contains('iTerm') || lcTerm.contains('iTerm')) {
        hasITerm2 = true;
      }

      // Kitty graphics is supported by Kitty itself and some other terminals
      // (e.g. WezTerm). Treat TERM hints as "best effort" (queries are the
      // source of truth).
      if (term.contains('kitty') ||
          environ.getenv('KITTY_WINDOW_ID').isNotEmpty ||
          termProg.contains('WezTerm')) {
        hasKittyGraphics = true;
      }
    }
  }

  /// Whether the terminal supports Kitty Graphics Protocol.
  bool hasKittyGraphics = false;

  /// Whether the terminal supports Sixel Graphics.
  bool hasSixel = false;

  /// Whether the terminal supports iTerm2 Image Protocol.
  bool hasITerm2 = false;

  /// Whether the terminal supports Kitty Keyboard Protocol enhancements.
  bool hasKeyboardEnhancements = false;

  /// The primary device attributes reported by the terminal.
  List<int> primaryAttributes = [];

  /// The terminal background color.
  UvRgb? backgroundColor;

  /// The terminal color palette.
  final Map<int, UvRgb> palette = {};

  /// Whether the terminal has reported its background color.
  bool get hasBackgroundColor => backgroundColor != null;

  /// Whether the terminal has reported any color palette entries.
  bool get hasColorPalette => palette.isNotEmpty;

  /// Updates capabilities based on an event.
  /// 
  /// Returns true if any capability changed.
  bool updateFromEvent(Event event) {
    if (event is KittyGraphicsEvent) {
      if (!hasKittyGraphics) {
        hasKittyGraphics = true;
        return true;
      }
    } else if (event is KeyboardEnhancementsEvent) {
      if (!hasKeyboardEnhancements) {
        hasKeyboardEnhancements = true;
        return true;
      }
    } else if (event is PrimaryDeviceAttributesEvent) {
      primaryAttributes = event.attrs;
      // Attribute 4 is Sixel.
      final oldSixel = hasSixel;
      hasSixel = event.attrs.contains(4);
      return oldSixel != hasSixel;
    } else if (event is BackgroundColorEvent) {
      backgroundColor = event.color;
      return true;
    } else if (event is ColorPaletteEvent) {
      if (event.color != null) {
        palette[event.index] = event.color!;
        return true;
      }
    } else if (event is SecondaryDeviceAttributesEvent) {
      // iTerm2 often identifies itself in secondary DA or via environment.
      // We also check environment in Terminal.
    }
    return false;
  }
}
