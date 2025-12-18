import 'dart:math' as math;

import 'package:artisan_args/src/style/style.dart';
import 'package:artisan_args/src/style/color.dart';
import 'package:artisan_args/src/tui/harmonica.dart' as hz;

import '../cmd.dart';
import '../model.dart';
import '../msg.dart';

/// Message indicating a progress bar animation frame should advance.
class ProgressFrameMsg extends Msg {
  const ProgressFrameMsg({required this.id, required this.tag});

  /// The ID of the progress bar this message belongs to.
  final int id;

  /// Tag to prevent duplicate frame messages.
  final int tag;
}

/// Global ID counter for progress bar instances.
int _lastProgressId = 0;

int _nextProgressId() => ++_lastProgressId;

const _fps = 60;
const _defaultWidth = 40;
const _defaultFrequency = 18.0;
const _defaultDamping = 1.0;

/// A stable damped spring integrator matching charmbracelet/harmonica.
class _Spring {
  _Spring({this.frequency = _defaultFrequency, this.damping = _defaultDamping})
    : _inner = hz.Spring(1 / _fps, frequency * 2 * math.pi, damping);

  final double frequency;
  final double damping;
  final hz.Spring _inner;

  /// Updates the spring state and returns (newValue, newVelocity).
  (double, double) update(double current, double velocity, double target) {
    return _inner.update(current, velocity, target);
  }
}

/// A progress bar widget with optional animation support.
///
/// The progress bar can be rendered statically using [viewAs] or
/// animated using the [update] loop and [setPercent] commands.
///
/// ## Example (Static)
///
/// ```dart
/// // Simple static progress bar
/// final progress = ProgressModel(width: 40);
/// print(progress.viewAs(0.5)); // 50% complete
/// ```
///
/// ## Example (Animated)
///
/// ```dart
/// class DownloadModel implements Model {
///   final ProgressModel progress;
///   final double downloaded;
///
///   DownloadModel({ProgressModel? progress, this.downloaded = 0})
///       : progress = progress ?? ProgressModel();
///
///   @override
///   (Model, Cmd?) update(Msg msg) {
///     // Handle progress animation frames
///     final (newProgress, cmd) = progress.update(msg);
///     if (newProgress != progress) {
///       return (
///         DownloadModel(progress: newProgress as ProgressModel, downloaded: downloaded),
///         cmd,
///       );
///     }
///
///     // Handle download progress updates
///     if (msg is DownloadProgressMsg) {
///       final newPercent = msg.bytes / msg.total;
///       final (updatedProgress, animCmd) = progress.setPercent(newPercent);
///       return (
///         DownloadModel(progress: updatedProgress, downloaded: newPercent),
///         animCmd,
///       );
///     }
///
///     return (this, null);
///   }
///
///   @override
///   String view() => progress.view();
/// }
/// ```
class ProgressModel implements Model {
  /// Creates a new progress bar model.
  ProgressModel({
    this.width = _defaultWidth,
    this.full = '█',
    this.fullColor = '#7571F9',
    this.empty = '░',
    this.emptyColor = '#606060',
    this.showPercentage = true,
    this.percentFormat = ' %3.0f%%',
    double frequency = _defaultFrequency,
    double damping = _defaultDamping,
    this.useGradient = false,
    this.gradientColorA = '#5A56E0',
    this.gradientColorB = '#EE6FF8',
    this.scaleGradient = false,
    double percentShown = 0,
    double targetPercent = 0,
    double velocity = 0,
    int? id,
    int tag = 0,
  }) : _spring = _Spring(frequency: frequency, damping: damping),
       _percentShown = percentShown,
       _targetPercent = targetPercent,
       _velocity = velocity,
       _id = id ?? _nextProgressId(),
       _tag = tag;

  /// Total width of the progress bar, including percentage.
  final int width;

  /// Character for filled sections.
  final String full;

  /// Color for filled sections.
  final String fullColor;

  /// Character for empty sections.
  final String empty;

  /// Color for empty sections.
  final String emptyColor;

  /// Whether to show the percentage text.
  final bool showPercentage;

  /// Format string for the percentage (e.g., " %3.0f%%").
  final String percentFormat;

  /// Whether to use a gradient fill.
  final bool useGradient;

  /// First color of the gradient.
  final String gradientColorA;

  /// Second color of the gradient.
  final String gradientColorB;

  /// Whether to scale the gradient to the filled portion.
  final bool scaleGradient;

  final _Spring _spring;
  final double _percentShown;
  final double _targetPercent;
  final double _velocity;
  final int _id;
  final int _tag;

  /// The current visible percentage (for animation).
  double get percentShown => _percentShown;

  /// The target percentage.
  double get percent => _targetPercent;

  /// The progress bar's unique ID.
  int get id => _id;

  /// Current frame tag (exposed for testing/inspection).
  int get tag => _tag;

  /// Whether the progress bar is currently animating.
  bool get isAnimating {
    final dist = (_percentShown - _targetPercent).abs();
    return !(dist < 0.001 && _velocity < 0.01);
  }

  /// Creates a copy with the given fields replaced.
  ProgressModel copyWith({
    int? width,
    String? full,
    String? fullColor,
    String? empty,
    String? emptyColor,
    bool? showPercentage,
    String? percentFormat,
    bool? useGradient,
    String? gradientColorA,
    String? gradientColorB,
    bool? scaleGradient,
    double? percentShown,
    double? targetPercent,
    double? velocity,
    int? tag,
    double? frequency,
    double? damping,
  }) {
    return ProgressModel(
      width: width ?? this.width,
      full: full ?? this.full,
      fullColor: fullColor ?? this.fullColor,
      empty: empty ?? this.empty,
      emptyColor: emptyColor ?? this.emptyColor,
      showPercentage: showPercentage ?? this.showPercentage,
      percentFormat: percentFormat ?? this.percentFormat,
      useGradient: useGradient ?? this.useGradient,
      gradientColorA: gradientColorA ?? this.gradientColorA,
      gradientColorB: gradientColorB ?? this.gradientColorB,
      scaleGradient: scaleGradient ?? this.scaleGradient,
      percentShown: percentShown ?? _percentShown,
      targetPercent: targetPercent ?? _targetPercent,
      velocity: velocity ?? _velocity,
      id: _id,
      tag: tag ?? _tag,
      frequency: frequency ?? _spring.frequency,
      damping: damping ?? _spring.damping,
    );
  }

  /// Sets the target percentage and returns a command for animation.
  (ProgressModel, Cmd?) setPercent(double p, {bool animate = true}) {
    final clamped = p.clamp(0.0, 1.0);
    final newModel = copyWith(targetPercent: clamped, tag: _tag + 1);
    if (!animate) {
      return (newModel.copyWith(percentShown: clamped, velocity: 0), null);
    }
    return (newModel, newModel._nextFrame());
  }

  /// Increments the percentage by the given amount.
  (ProgressModel, Cmd?) incrPercent(double v) {
    return setPercent(_targetPercent + v);
  }

  /// Decrements the percentage by the given amount.
  (ProgressModel, Cmd?) decrPercent(double v) {
    return setPercent(_targetPercent - v);
  }

  Cmd _nextFrame() {
    final id = _id;
    final tag = _tag;
    return Cmd.tick(
      Duration(milliseconds: 1000 ~/ _fps),
      (_) => ProgressFrameMsg(id: id, tag: tag),
    );
  }

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    if (msg is! ProgressFrameMsg) {
      return (this, null);
    }

    if (msg.id != _id || msg.tag != _tag) {
      return (this, null);
    }

    // Stop animating if we've reached equilibrium
    if (!isAnimating) {
      return (this, null);
    }

    // Update spring animation
    final (newPercent, newVelocity) = _spring.update(
      _percentShown,
      _velocity,
      _targetPercent,
    );

    final newModel = copyWith(percentShown: newPercent, velocity: newVelocity);

    return (newModel, newModel._nextFrame());
  }

  @override
  String view() => viewAs(_percentShown);

  /// Renders the progress bar at the given percentage (static rendering).
  String viewAs(double percent) {
    final percentView = _percentageView(percent);
    final barView = _barView(percent, percentView.length);
    return '$barView$percentView';
  }

  String _barView(double percent, int textWidth) {
    final tw = math.max(0, width - textWidth); // total bar width
    var fw = (tw * percent).round(); // filled width
    fw = fw.clamp(0, tw);

    final buffer = StringBuffer();

    if (useGradient) {
      // Gradient fill
      for (var i = 0; i < fw; i++) {
        double p;
        if (fw == 1) {
          p = 0.5;
        } else if (scaleGradient) {
          p = i / (fw - 1);
        } else {
          p = i / (tw - 1);
        }
        final color = _interpolateColor(gradientColorA, gradientColorB, p);
        buffer.write(_colorize(full, color));
      }
    } else {
      // Solid fill
      final colored = _colorize(full, fullColor);
      for (var i = 0; i < fw; i++) {
        buffer.write(colored);
      }
    }

    // Empty fill
    final emptyColored = _colorize(empty, emptyColor);
    final emptyCount = math.max(0, tw - fw);
    for (var i = 0; i < emptyCount; i++) {
      buffer.write(emptyColored);
    }

    return buffer.toString();
  }

  String _percentageView(double percent) {
    if (!showPercentage) return '';
    final clamped = percent.clamp(0.0, 1.0);
    // Simple format replacement
    var result = percentFormat;
    final value = (clamped * 100).toStringAsFixed(0);
    result = result.replaceFirst('%3.0f', value.padLeft(3));
    return result;
  }

  /// Applies color to text using the Style class.
  String _colorize(String text, String hexColor) {
    return Style().foreground(BasicColor(hexColor)).render(text);
  }

  /// Parses a hex color to RGB.
  (int, int, int)? _hexToRgb(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length != 6) return null;
    final r = int.tryParse(hex.substring(0, 2), radix: 16);
    final g = int.tryParse(hex.substring(2, 4), radix: 16);
    final b = int.tryParse(hex.substring(4, 6), radix: 16);
    if (r == null || g == null || b == null) return null;
    return (r, g, b);
  }

  /// Interpolates between two hex colors.
  String _interpolateColor(String colorA, String colorB, double t) {
    final rgbA = _hexToRgb(colorA);
    final rgbB = _hexToRgb(colorB);
    if (rgbA == null || rgbB == null) return colorA;

    final r = (rgbA.$1 + (rgbB.$1 - rgbA.$1) * t).round().clamp(0, 255);
    final g = (rgbA.$2 + (rgbB.$2 - rgbA.$2) * t).round().clamp(0, 255);
    final b = (rgbA.$3 + (rgbB.$3 - rgbA.$3) * t).round().clamp(0, 255);

    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }
}
