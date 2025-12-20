import 'package:artisanal/src/tui/bubbles/bubbles.dart' show RenderConfig;
import 'package:artisanal/style.dart' show Colors, Style;
import 'package:artisanal/tui.dart' show Cmd;
import 'package:artisanal/uv.dart' as uv;

import '../msg.dart';
import 'components/panel.dart';

/// Draggable render-metrics overlay for debugging TUI performance.
///
/// Intended to be composed by parent models:
/// - feed it `RenderMetricsMsg` + `WindowSizeMsg`
/// - call [compose] to overlay it above your main view
/// - use [toggle] to show/hide (the caller decides which key)
final class DebugOverlayModel {
  const DebugOverlayModel({
    required this.enabled,
    required this.terminalWidth,
    required this.terminalHeight,
    required this.metrics,
    required this.panelX,
    required this.panelY,
    required this.dragging,
    required this.dragOffsetX,
    required this.dragOffsetY,
    this.panelWidth = 40,
    this.marginRight = 2,
    this.marginTop = 0,
    this.marginBottom = 2,
    this.title = 'Render Metrics',
    this.rendererLabel = 'UV',
  });

  factory DebugOverlayModel.initial({
    bool enabled = false,
    int terminalWidth = 0,
    int terminalHeight = 0,
    String title = 'Render Metrics',
    String rendererLabel = 'UV',
    int panelWidth = 40,
    int marginRight = 2,
    int marginTop = 0,
    int marginBottom = 2,
  }) {
    return DebugOverlayModel(
      enabled: enabled,
      terminalWidth: terminalWidth,
      terminalHeight: terminalHeight,
      metrics: null,
      panelX: null,
      panelY: null,
      dragging: false,
      dragOffsetX: 0,
      dragOffsetY: 0,
      panelWidth: panelWidth,
      marginRight: marginRight,
      marginTop: marginTop,
      marginBottom: marginBottom,
      title: title,
      rendererLabel: rendererLabel,
    );
  }

  final bool enabled;
  final int terminalWidth;
  final int terminalHeight;
  final uv.RenderMetrics? metrics;

  /// Stored top-left position. When null, uses default placement.
  final int? panelX;
  final int? panelY;

  // Drag state.
  final bool dragging;
  final int dragOffsetX;
  final int dragOffsetY;

  // Layout config.
  final int panelWidth;
  final int marginRight;
  final int marginTop;
  final int marginBottom;
  final String title;
  final String rendererLabel;

  DebugOverlayModel copyWith({
    bool? enabled,
    int? terminalWidth,
    int? terminalHeight,
    uv.RenderMetrics? metrics,
    Object? panelX = _unset,
    Object? panelY = _unset,
    bool? dragging,
    int? dragOffsetX,
    int? dragOffsetY,
    int? panelWidth,
    int? marginRight,
    int? marginTop,
    int? marginBottom,
    String? title,
    String? rendererLabel,
  }) {
    return DebugOverlayModel(
      enabled: enabled ?? this.enabled,
      terminalWidth: terminalWidth ?? this.terminalWidth,
      terminalHeight: terminalHeight ?? this.terminalHeight,
      metrics: metrics ?? this.metrics,
      panelX: panelX == _unset ? this.panelX : panelX as int?,
      panelY: panelY == _unset ? this.panelY : panelY as int?,
      dragging: dragging ?? this.dragging,
      dragOffsetX: dragOffsetX ?? this.dragOffsetX,
      dragOffsetY: dragOffsetY ?? this.dragOffsetY,
      panelWidth: panelWidth ?? this.panelWidth,
      marginRight: marginRight ?? this.marginRight,
      marginTop: marginTop ?? this.marginTop,
      marginBottom: marginBottom ?? this.marginBottom,
      title: title ?? this.title,
      rendererLabel: rendererLabel ?? this.rendererLabel,
    );
  }

  DebugOverlayModel toggle() => copyWith(
    enabled: !enabled,
    panelX: null,
    panelY: null,
    dragging: false,
  );

  DebugOverlayModel setEnabled(bool v) => v == enabled ? this : copyWith(enabled: v);

  /// Updates overlay state and reports whether the message was consumed.
  ({DebugOverlayModel model, Cmd? cmd, bool consumed}) update(Msg msg) {
    switch (msg) {
      case RenderMetricsMsg(:final metrics):
        return (model: copyWith(metrics: metrics), cmd: null, consumed: false);

      case WindowSizeMsg(:final width, :final height):
        final next = copyWith(terminalWidth: width, terminalHeight: height);
        // Clamp stored position if set.
        if (next.panelX != null || next.panelY != null) {
          final (:x, :y, :w, :h) = next._panelRect();
          final clampedX = x.clamp(0, (width - w).clamp(0, width));
          final clampedY = y.clamp(0, (height - h).clamp(0, height));
          return (
            model: next.copyWith(panelX: clampedX, panelY: clampedY),
            cmd: null,
            consumed: false,
          );
        }
        return (model: next, cmd: null, consumed: false);

      case MouseMsg(:final x, :final y, :final button, :final action):
        if (!enabled) return (model: this, cmd: null, consumed: false);

        // When dragging, consume ALL mouse events to prevent selection bleed.
        if (dragging) {
          if (action == MouseAction.release) {
            return (
              model: copyWith(dragging: false),
              cmd: null,
              consumed: true,
            );
          }
          if (action == MouseAction.motion) {
            // Use fixed panel dimensions to avoid expensive re-render during drag
            const panelHeight = 8; // 6 content lines + 2 border lines
            final maxX = (terminalWidth - panelWidth).clamp(0, terminalWidth);
            final maxY = (terminalHeight - panelHeight).clamp(0, terminalHeight);
            final nx = (x - dragOffsetX).clamp(0, maxX);
            final ny = (y - dragOffsetY).clamp(0, maxY);
            return (
              model: copyWith(panelX: nx, panelY: ny),
              cmd: null,
              consumed: true,
            );
          }
          return (model: this, cmd: null, consumed: true);
        }

        // Start dragging when clicking inside the panel.
        if (action == MouseAction.press && button == MouseButton.left) {
          // Use approximate bounds for hit testing (avoids rendering panel)
          const panelHeight = 8;
          final px = panelX ?? (terminalWidth - panelWidth - marginRight);
          final py = panelY ?? (terminalHeight - panelHeight - marginBottom);
          final inPanel =
              x >= px &&
              x < px + panelWidth &&
              y >= py &&
              y < py + panelHeight;
          if (inPanel) {
            return (
              model: copyWith(
                dragging: true,
                dragOffsetX: x - px,
                dragOffsetY: y - py,
              ),
              cmd: null,
              consumed: true,
            );
          }
        }

        return (model: this, cmd: null, consumed: false);

      default:
        return (model: this, cmd: null, consumed: false);
    }
  }

  /// Renders just the debug panel.
  String panel({int? terminalWidthOverride}) {
    final label = Style().foreground(Colors.yellow).bold();
    final m = metrics;
    final avgFps = m?.averageFps ?? 0.0;
    final avgFrameTimeUs = m?.averageFrameTime.inMicroseconds ?? 0;
    final avgRenderTimeUs = m?.averageRenderDuration.inMicroseconds ?? 0;
    final frameCount = m?.frameCount ?? 0;
    final skippedFrames = m?.skippedFrames ?? 0;
    final renderPct = m?.renderTimePercentage ?? 0.0;

    final content =
        '${label.render('FPS:')} ${avgFps.toStringAsFixed(1)} (${m?.minFps.toStringAsFixed(0) ?? 0}-${m?.maxFps.toStringAsFixed(0) ?? 0})\n'
        '${label.render('Frame Time:')} ${(avgFrameTimeUs / 1000).toStringAsFixed(2)}ms\n'
        '${label.render('Render Time:')} ${avgRenderTimeUs}µs (${renderPct.toStringAsFixed(1)}%)\n'
        '${label.render('Frames:')} $frameCount (skipped: $skippedFrames)\n'
        '${label.render('Cells:')} ${terminalWidth * terminalHeight}\n'
        '${label.render('Renderer:')} $rendererLabel';

    return PanelComponent(
      title: title,
      content: content,
      width: panelWidth,
      renderConfig: RenderConfig(terminalWidth: terminalWidthOverride ?? terminalWidth),
    ).render();
  }

  /// Overlays the debug panel above [base] using the UV compositor.
  ///
  /// If not enabled, returns [base] unchanged.
  String compose(String base) {
    if (!enabled) return base;
    final p = panel();
    // Compute size from the already-rendered panel (avoids double render)
    final lines = p.split('\n');
    final h = lines.length;
    final w = lines.fold<int>(0, (m, l) => mathMax(m, Style.visibleLength(l)));
    final x = panelX ?? (terminalWidth - w - marginRight);
    final y = panelY ?? (terminalHeight - h - marginBottom);
    
    final mainLayer = uv.newLayer(base)..setId('main')..setZ(0);
    final debugLayer =
        uv.newLayer(p)..setId('debug')..setX(x)..setY(y)..setZ(10);
    return uv.Compositor([mainLayer, debugLayer]).render();
  }

  ({int w, int h}) _panelSize() {
    final p = panel();
    final lines = p.split('\n');
    final h = lines.length;
    final w = lines.fold<int>(
      0,
      (m, l) => mathMax(m, Style.visibleLength(l)),
    );
    return (w: w, h: h);
  }

  ({int x, int y, int w, int h}) _panelRect() {
    final (:w, :h) = _panelSize();
    final x = panelX ?? (terminalWidth - w - marginRight);
    final y = panelY ?? (terminalHeight - h - marginBottom);
    return (x: x, y: y, w: w, h: h);
  }
}

const _unset = Object();

int mathMax(int a, int b) => a > b ? a : b;
