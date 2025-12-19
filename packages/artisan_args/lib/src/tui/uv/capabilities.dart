import 'event.dart';

/// Terminal capabilities discovered via ANSI queries.
final class TerminalCapabilities {
  TerminalCapabilities();

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
    } else if (event is SecondaryDeviceAttributesEvent) {
      // iTerm2 often identifies itself in secondary DA or via environment.
      // We also check environment in Terminal.
    }
    return false;
  }
}
