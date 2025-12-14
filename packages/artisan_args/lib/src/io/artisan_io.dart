import 'dart:async';
import 'dart:io' as io;

import '../output/progress_bar.dart';
import '../output/table.dart';
import '../style/artisan_style.dart';
import '../style/verbosity.dart';
import 'components.dart';
import 'prompts.dart';

/// Callback for writing a complete line to output.
typedef ArtisanWriteLine = void Function(String line);

/// Callback for writing raw text (without newline) to output.
typedef ArtisanWriteRaw = void Function(String text);

/// Callback for reading a line of input.
typedef ArtisanReadLine = String? Function();

/// Callback for reading secret/password input without echo.
typedef ArtisanSecretReader =
    String Function(String prompt, {String? fallback});

/// Result of a task operation.
enum ArtisanTaskResult {
  /// Task completed successfully.
  success,

  /// Task failed.
  failure,

  /// Task was skipped.
  skipped,
}

/// The main I/O helper for Artisan-style console output.
///
/// Provides methods for:
/// - Formatted output (titles, sections, messages)
/// - Tables and progress bars
/// - Interactive prompts (confirm, ask, choice, secret)
/// - Task status display
///
/// ```dart
/// io.title('My Application');
/// io.info('Starting...');
/// await io.task('Processing', run: () async => ArtisanTaskResult.success);
/// io.success('Done!');
/// ```
class ArtisanIO {
  /// Creates a new I/O helper.
  ArtisanIO({
    required this.style,
    required ArtisanWriteLine out,
    required ArtisanWriteLine err,
    ArtisanWriteRaw? outRaw,
    ArtisanWriteRaw? errRaw,
    ArtisanReadLine? readLine,
    ArtisanSecretReader? secretReader,
    io.Stdin? stdin,
    io.Stdout? stdout,
    this.interactive = true,
    this.verbosity = ArtisanVerbosity.normal,
    int? terminalWidth,
  }) : _out = out,
       _err = err,
       _outRaw = outRaw ?? ((text) => out(text)),
       _errRaw = errRaw ?? ((text) => err(text)),
       _readLine = readLine,
       _secretReader = secretReader,
       _stdin = stdin,
       _stdout = stdout,
       terminalWidth = terminalWidth ?? 120;

  /// The ANSI style configuration.
  final ArtisanStyle style;

  /// Whether interactive prompts are enabled.
  final bool interactive;

  /// The current verbosity level.
  final ArtisanVerbosity verbosity;

  /// The terminal width for formatting.
  final int terminalWidth;

  final ArtisanWriteLine _out;
  final ArtisanWriteLine _err;
  final ArtisanWriteRaw _outRaw;
  final ArtisanWriteRaw _errRaw;
  final ArtisanReadLine? _readLine;
  final ArtisanSecretReader? _secretReader;
  final io.Stdin? _stdin;
  final io.Stdout? _stdout;

  ArtisanComponents? _components;

  /// Whether output is suppressed (quiet mode).
  bool get quiet => verbosity == ArtisanVerbosity.quiet;

  /// Access to higher-level console components (Laravel-style).
  ///
  /// ```dart
  /// io.components.task('Processing', run: () async => ArtisanTaskResult.success);
  /// io.components.twoColumnDetail('Name', 'Value');
  /// io.components.bulletList(['Item 1', 'Item 2']);
  /// ```
  ArtisanComponents get components =>
      _components ??= ArtisanComponents(io: this);

  // ─────────────────────────────────────────────────────────────────────────────
  // Basic Output
  // ─────────────────────────────────────────────────────────────────────────────

  /// Writes a line to stdout.
  void writeln([String line = '']) {
    if (quiet) return;
    _out(line);
  }

  /// Writes raw text to stdout (no newline).
  void write(String text) {
    if (quiet) return;
    _outRaw(text);
  }

  /// Writes raw text to stderr.
  void writeErr(String text) {
    _errRaw(text);
  }

  /// Writes a line to stderr.
  void writelnErr([String line = '']) {
    _err(line);
  }

  /// Outputs one or more blank lines.
  void newLine([int count = 1]) {
    for (var i = 0; i < count; i++) {
      writeln();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Formatted Output
  // ─────────────────────────────────────────────────────────────────────────────

  /// Outputs a title with underline.
  void title(String message) {
    final trimmed = message.trimRight();
    writeln(style.heading(trimmed));
    writeln(style.heading('=' * ArtisanStyle.visibleLength(trimmed)));
    newLine();
  }

  /// Outputs a section header with underline.
  void section(String message) {
    final trimmed = message.trimRight();
    writeln(style.heading(trimmed));
    writeln(style.heading('-' * ArtisanStyle.visibleLength(trimmed)));
    newLine();
  }

  /// Outputs indented text.
  void text(Object message) {
    final lines = _normalizeLines(message);
    for (final line in lines) {
      writeln(' $line');
    }
  }

  /// Outputs a bulleted list.
  void listing(Iterable<Object> items) {
    for (final item in items) {
      writeln(' * $item');
    }
    newLine();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Message Blocks
  // ─────────────────────────────────────────────────────────────────────────────

  /// Outputs an info message.
  void info(Object message) => _labeledBlock('INFO', message, style.info);

  /// Outputs a success message.
  void success(Object message) => _labeledBlock('OK', message, style.success);

  /// Outputs a warning message.
  void warning(Object message) =>
      _labeledBlock('WARNING', message, style.warning);

  /// Outputs an error message.
  void error(Object message) => _labeledBlock('ERROR', message, style.error);

  /// Outputs a note message.
  void note(Object message) => _labeledBlock('NOTE', message, style.heading);

  /// Outputs a caution message.
  void caution(Object message) =>
      _labeledBlock('CAUTION', message, style.error);

  /// Outputs an alert box.
  void alert(Object message) {
    final lines = _normalizeLines(message);
    final contentWidth = lines
        .map((line) => ArtisanStyle.visibleLength(line))
        .fold<int>(0, (m, v) => v > m ? v : m);
    final width = (contentWidth + 4).clamp(0, terminalWidth);

    final top = '+${'-' * (width - 2)}+';
    writeln(style.warning(top));
    for (final line in lines) {
      final visible = ArtisanStyle.visibleLength(line);
      final fill = width - 4 - visible;
      writeln(
        style.warning('| ') +
            line +
            (' ' * (fill > 0 ? fill : 0)) +
            style.warning(' |'),
      );
    }
    writeln(style.warning(top));
    newLine();
  }

  /// Outputs a two-column detail line.
  void twoColumnDetail(String first, [String? second]) {
    final left = first;
    final right = second ?? '';
    final maxLeft = (terminalWidth / 2).floor().clamp(16, 60);
    final leftLen = ArtisanStyle.visibleLength(left);
    final pad = maxLeft - leftLen;
    final gap = pad > 0 ? ' ' * pad : ' ';
    writeln('  $left$gap$right');
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Tasks
  // ─────────────────────────────────────────────────────────────────────────────

  /// Displays a task with status indicator (DONE/FAIL/SKIPPED).
  Future<ArtisanTaskResult> task(
    String description, {
    FutureOr<ArtisanTaskResult> Function()? run,
  }) async {
    final desc = description.trimRight();
    write('  $desc ');

    final watch = Stopwatch()..start();
    ArtisanTaskResult result = ArtisanTaskResult.success;
    try {
      final value = await (run?.call() ?? ArtisanTaskResult.success);
      result = value;
      return result;
    } catch (_) {
      result = ArtisanTaskResult.failure;
      rethrow;
    } finally {
      watch.stop();
      final runtime = run == null ? '' : ' ${_formatDuration(watch.elapsed)}';
      final statusLabel = switch (result) {
        ArtisanTaskResult.success => style.success('DONE'),
        ArtisanTaskResult.skipped => style.warning('SKIPPED'),
        ArtisanTaskResult.failure => style.error('FAIL'),
      };

      final used =
          2 +
          ArtisanStyle.visibleLength(desc) +
          1 +
          ArtisanStyle.visibleLength(runtime) +
          1 +
          4;
      final dots = (terminalWidth - used).clamp(0, terminalWidth);
      write(style.muted('.' * dots));
      if (runtime.isNotEmpty) {
        write(style.muted(runtime));
      }
      writeln(' $statusLabel');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Tables
  // ─────────────────────────────────────────────────────────────────────────────

  /// Outputs a formatted table.
  void table({
    required List<String> headers,
    required List<List<Object?>> rows,
  }) {
    final rendered = ArtisanTable(
      style: style,
    ).render(headers: headers, rows: rows);
    for (final line in rendered.split('\n')) {
      writeln(line);
    }
    newLine();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Progress
  // ─────────────────────────────────────────────────────────────────────────────

  /// Creates a new progress bar.
  ArtisanProgressBar createProgressBar({int max = 0}) {
    return ArtisanProgressBar(
      style: style,
      outRaw: _outRaw,
      terminalWidth: terminalWidth,
      max: max,
    );
  }

  /// Iterates over items with a progress bar.
  Iterable<T> progressIterate<T>(Iterable<T> iterable, {int? max}) sync* {
    final total = max ?? (iterable is List<T> ? iterable.length : 0);
    final bar = createProgressBar(max: total);
    bar.start();
    var i = 0;
    for (final item in iterable) {
      yield item;
      i++;
      bar.advance();
    }
    if (total == 0) {
      bar.setMax(i);
    }
    bar.finish();
    newLine();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Prompts
  // ─────────────────────────────────────────────────────────────────────────────

  /// Prompts for a yes/no confirmation.
  bool confirm(String question, {bool defaultValue = true}) {
    if (!interactive) return defaultValue;

    final suffix = defaultValue ? '[Y/n]' : '[y/N]';
    write('${style.emphasize(question)} $suffix ');
    final input = (_readLine?.call() ?? '').trim().toLowerCase();
    if (input.isEmpty) return defaultValue;
    if (input == 'y' || input == 'yes') return true;
    if (input == 'n' || input == 'no') return false;
    return defaultValue;
  }

  /// Prompts for text input.
  String ask(
    String question, {
    String? defaultValue,
    String? Function(String value)? validator,
    int attempts = 3,
  }) {
    if (!interactive) {
      if (defaultValue != null) return defaultValue;
      throw StateError('Cannot prompt in non-interactive mode.');
    }

    for (var i = 0; i < attempts; i++) {
      final suffix = defaultValue == null ? '' : ' [$defaultValue]';
      write('${style.emphasize(question)}$suffix: ');
      final raw = _readLine?.call();
      final value = (raw == null || raw.isEmpty) ? (defaultValue ?? '') : raw;
      final error = validator?.call(value);
      if (error == null) return value;
      writelnErr(style.error('Error: $error'));
    }

    throw StateError('Too many invalid attempts.');
  }

  /// Prompts for secret/password input (no echo).
  String secret(String question, {String? fallback}) {
    if (!interactive) {
      if (fallback != null) return fallback;
      throw StateError('Cannot prompt in non-interactive mode.');
    }

    if (_secretReader != null) {
      return _secretReader(question, fallback: fallback);
    }

    final secretInput = SecretInput(
      style: style,
      write: write,
      writeln: writeln,
      stdin: _stdin,
      stdout: _stdout,
    );
    return secretInput.read(question, fallback: fallback);
  }

  /// Prompts for a choice from a list (basic numbered selection).
  Object choice(
    String question, {
    required List<String> choices,
    int? defaultIndex,
    bool multiSelect = false,
  }) {
    if (!interactive) {
      if (defaultIndex != null &&
          defaultIndex >= 0 &&
          defaultIndex < choices.length) {
        return multiSelect
            ? <String>[choices[defaultIndex]]
            : choices[defaultIndex];
      }
      throw StateError('Cannot prompt in non-interactive mode.');
    }

    writeln(style.emphasize(question));
    for (var i = 0; i < choices.length; i++) {
      writeln('  [$i] ${choices[i]}');
    }

    if (!multiSelect) {
      final prompt = defaultIndex == null
          ? 'Select an option'
          : 'Select an option [$defaultIndex]';
      final raw = ask(prompt, defaultValue: defaultIndex?.toString());
      final parsed = int.tryParse(raw);
      if (parsed == null || parsed < 0 || parsed >= choices.length) {
        throw StateError('Invalid selection: $raw');
      }
      return choices[parsed];
    }

    final prompt = defaultIndex == null
        ? 'Select options (comma separated)'
        : 'Select options (comma separated) [$defaultIndex]';
    final raw = ask(prompt, defaultValue: defaultIndex?.toString());
    final parts = raw
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList(growable: false);
    final selected = <String>[];
    for (final part in parts) {
      final parsed = int.tryParse(part);
      if (parsed == null || parsed < 0 || parsed >= choices.length) {
        throw StateError('Invalid selection: $part');
      }
      selected.add(choices[parsed]);
    }
    return selected;
  }

  /// Interactive single-select with arrow-key navigation.
  Future<T?> selectChoice<T>(
    String question, {
    required List<T> choices,
    int? defaultIndex,
    String Function(T)? display,
  }) async {
    if (!interactive) {
      if (defaultIndex != null &&
          defaultIndex >= 0 &&
          defaultIndex < choices.length) {
        return choices[defaultIndex];
      }
      throw StateError('Cannot prompt in non-interactive mode.');
    }

    try {
      final ic = InteractiveChoice(
        style: style,
        write: write,
        writeln: writeln,
        stdin: _stdin,
        stdout: _stdout,
      );
      return await ic.select(
        question,
        choices: choices,
        defaultIndex: defaultIndex,
        display: display,
      );
    } catch (e) {
      final displayFn = display ?? (v) => v.toString();
      final items = choices.map(displayFn).toList();
      final result =
          choice(
                question,
                choices: items,
                defaultIndex: defaultIndex,
                multiSelect: false,
              )
              as String;
      final index = items.indexOf(result);
      return index >= 0 ? choices[index] : null;
    }
  }

  /// Interactive multi-select with arrow-key navigation.
  Future<List<T>> multiSelectChoice<T>(
    String question, {
    required List<T> choices,
    List<int> defaultSelected = const [],
    String Function(T)? display,
  }) async {
    if (!interactive) {
      return defaultSelected.map((i) => choices[i]).toList();
    }

    try {
      final ic = InteractiveChoice(
        style: style,
        write: write,
        writeln: writeln,
        stdin: _stdin,
        stdout: _stdout,
      );
      return await ic.multiSelect(
        question,
        choices: choices,
        defaultSelected: defaultSelected,
        display: display,
      );
    } catch (e) {
      final displayFn = display ?? (v) => v.toString();
      final items = choices.map(displayFn).toList();
      final result =
          choice(
                question,
                choices: items,
                defaultIndex: defaultSelected.isEmpty
                    ? null
                    : defaultSelected.first,
                multiSelect: true,
              )
              as List<String>;
      return result
          .map((r) {
            final index = items.indexOf(r);
            return index >= 0 ? choices[index] : null;
          })
          .whereType<T>()
          .toList();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Private Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  List<String> _normalizeLines(Object message) {
    if (message is Iterable) {
      return message.map((e) => e.toString()).toList();
    }
    return message.toString().split('\n');
  }

  void _labeledBlock(
    String label,
    Object message,
    String Function(String text) labelStyle,
  ) {
    final lines = _normalizeLines(message);
    for (final line in lines) {
      writeln('${labelStyle('[$label]')} $line');
    }
    newLine();
  }
}

String _formatDuration(Duration duration) {
  final ms = duration.inMilliseconds;
  if (ms < 1000) return '${ms}ms';
  final seconds = ms / 1000;
  return '${seconds.toStringAsFixed(seconds < 10 ? 1 : 0)}s';
}
