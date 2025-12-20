/// Terminal progress bar primitives (Windows Terminal sequences).
///
/// Upstream: `third_party/ultraviolet/uv.go` (ProgressBarState/ProgressBar).
library;

/// Progress bar states.
enum ProgressBarState { none, normal, error, indeterminate, warning }

/// A progress bar state + value.
///
/// The [value] is clamped to 0..100 and is ignored when [state] is
/// [ProgressBarState.none] or [ProgressBarState.indeterminate].
final class ProgressBar {
  ProgressBar(this.state, int value)
    : value = switch (state) {
        ProgressBarState.none || ProgressBarState.indeterminate => 0,
        _ => value.clamp(0, 100),
      };

  final ProgressBarState state;
  final int value;

  @override
  String toString() => switch (state) {
    ProgressBarState.none => 'None',
    ProgressBarState.normal => 'Default',
    ProgressBarState.error => 'Error',
    ProgressBarState.indeterminate => 'Indeterminate',
    ProgressBarState.warning => 'Warning',
  };
}

