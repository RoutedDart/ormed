import '../../../renderer/renderer.dart' show Renderer;
import '../../../style/color.dart';
import '../../../style/style.dart';
import '../../component.dart' as tui;

/// Rendering configuration for display-only UI building blocks.
///
/// Bubble models render plain strings from `view()`. These components follow the
/// same convention by rendering to strings and letting the caller decide how to
/// print them (or compose them into a parent model's view).
///
/// {@category TUI}
///
/// {@macro artisanal_bubbles_display_components}
class RenderConfig {
  const RenderConfig({
    this.terminalWidth = 80,
    this.colorProfile = ColorProfile.trueColor,
    this.hasDarkBackground = true,
  });

  factory RenderConfig.fromRenderer(
    Renderer renderer, {
    int terminalWidth = 80,
  }) => RenderConfig(
    terminalWidth: terminalWidth,
    colorProfile: renderer.colorProfile,
    hasDarkBackground: renderer.hasDarkBackground,
  );

  final int terminalWidth;
  final ColorProfile colorProfile;
  final bool hasDarkBackground;

  Style configureStyle(Style style) {
    style
      ..colorProfile = colorProfile
      ..hasDarkBackground = hasDarkBackground;
    return style;
  }
}

/// Base type for display-only UI building blocks.
abstract class DisplayComponent extends tui.StaticComponent {
  const DisplayComponent();

  /// Renders the component as a string.
  String render();

  @override
  String view() => render();

  /// Number of lines in [render].
  int get lineCount => render().split('\n').length;

  @override
  String toString() => render();
}
