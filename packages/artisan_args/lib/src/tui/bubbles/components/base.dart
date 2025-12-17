import '../../../renderer/renderer.dart' show Renderer;
import '../../../style/color.dart';
import '../../../style/style.dart';

/// Rendering configuration for display-only UI building blocks.
///
/// Bubble models render plain strings from `view()`. These components follow the
/// same convention by rendering to strings and letting the caller decide how to
/// print them (or compose them into a parent model's view).
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
abstract class ViewComponent {
  const ViewComponent();

  /// Renders the component as a string.
  String render();

  /// Number of lines in [render].
  int get lineCount => render().split('\n').length;
}

/// Abstract base for fluent component builders.
///
/// Provides shared style configuration (color profile and background) for
/// components that use the fluent [Style] system.
abstract class FluentComponent<T extends FluentComponent<T>>
    implements ViewComponent {
  ColorProfile _colorProfile = ColorProfile.trueColor;
  bool _hasDarkBackground = true;

  /// Gets the current color profile.
  ColorProfile get currentColorProfile => _colorProfile;

  /// Gets whether the terminal has a dark background.
  bool get currentHasDarkBackground => _hasDarkBackground;

  /// Sets the color profile for rendering.
  T colorProfile(ColorProfile profile) {
    _colorProfile = profile;
    return this as T;
  }

  /// Sets whether the terminal has a dark background.
  T darkBackground(bool value) {
    _hasDarkBackground = value;
    return this as T;
  }

  /// Configures this component from a [Renderer].
  T fromRenderer(Renderer renderer) {
    _colorProfile = renderer.colorProfile;
    _hasDarkBackground = renderer.hasDarkBackground;
    return this as T;
  }

  /// Configures this component from a [RenderConfig].
  T fromRenderConfig(RenderConfig config) {
    _colorProfile = config.colorProfile;
    _hasDarkBackground = config.hasDarkBackground;
    return this as T;
  }

  /// Applies the current color profile to a style.
  Style configureStyle(Style style) {
    return style
      ..colorProfile = _colorProfile
      ..hasDarkBackground = _hasDarkBackground;
  }

  @override
  String render();

  @override
  int get lineCount;

  @override
  String toString() => render();
}
