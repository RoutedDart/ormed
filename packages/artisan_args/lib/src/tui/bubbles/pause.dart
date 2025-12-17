import '../cmd.dart';
import '../key.dart';
import '../model.dart';
import '../msg.dart';
import 'timer.dart';

/// A simple "press any key" pause model.
///
/// This is a small convenience bubble that mirrors the legacy "pause"
/// behavior (previously exposed as `PauseComponent`).
class PauseModel implements Model {
  PauseModel({this.message = 'Press any key to continue...'});

  final String message;

  @override
  Cmd? init() => null;

  @override
  (Model, Cmd?) update(Msg msg) {
    if (msg is KeyMsg) {
      return (this, Cmd.quit());
    }
    return (this, null);
  }

  @override
  String view() => message;
}

/// A countdown model built on top of [TimerModel].
///
/// This is a convenience bubble for the legacy countdown behavior (previously
/// exposed as `CountdownComponent`).
class CountdownModel implements Model {
  CountdownModel({
    required Duration duration,
    this.message = 'Continuing in',
    Duration interval = const Duration(seconds: 1),
  }) : _timer = TimerModel(timeout: duration, interval: interval);

  final String message;
  TimerModel _timer;

  @override
  Cmd? init() => _timer.start();

  @override
  (Model, Cmd?) update(Msg msg) {
    if (msg is KeyMsg &&
        (msg.key.type == KeyType.escape ||
            (msg.key.ctrl &&
                msg.key.runes.isNotEmpty &&
                msg.key.runes.first == 0x63))) {
      return (this, Cmd.quit());
    }

    final (newTimer, cmd) = _timer.update(msg);
    _timer = newTimer as TimerModel;

    if (_timer.timedOut) {
      return (this, Cmd.quit());
    }

    return (this, cmd);
  }

  @override
  String view() => '$message ${_timer.view()}';
}
