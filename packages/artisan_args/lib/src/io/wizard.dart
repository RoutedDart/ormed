import 'dart:async';
import 'dart:io' as io;

import '../style/artisan_style.dart';
import 'prompts.dart';

/// Result of a wizard step.
class WizardStepResult {
  WizardStepResult({
    required this.key,
    required this.value,
    this.skipped = false,
  });

  final String key;
  final dynamic value;
  final bool skipped;
}

/// A step in a wizard flow.
abstract class WizardStep {
  WizardStep({required this.key, this.description});

  final String key;
  final String? description;

  /// Runs the step and returns the result.
  Future<WizardStepResult> run(WizardContext context);

  /// Whether this step should be skipped based on previous answers.
  bool shouldSkip(Map<String, dynamic> answers) => false;

  // ─────────────────────────────────────────────────────────────────────────────
  // Factory constructors for common step types
  // ─────────────────────────────────────────────────────────────────────────────

  /// Creates an ask step (text input).
  factory WizardStep.ask(
    String key,
    String question, {
    String? defaultValue,
    String? Function(String)? validator,
    String? description,
  }) = _AskStep;

  /// Creates a confirm step (yes/no).
  factory WizardStep.confirm(
    String key,
    String question, {
    bool defaultValue,
    String? description,
  }) = _ConfirmStep;

  /// Creates a choice step (single select).
  factory WizardStep.choice(
    String key,
    String question, {
    required List<String> choices,
    int? defaultIndex,
    String? description,
  }) = _ChoiceStep;

  /// Creates a multi-choice step.
  factory WizardStep.multiChoice(
    String key,
    String question, {
    required List<String> choices,
    List<int>? defaultSelected,
    String? description,
  }) = _MultiChoiceStep;

  /// Creates a secret step (password input).
  factory WizardStep.secret(
    String key,
    String question, {
    String? fallback,
    String? description,
  }) = _SecretStep;

  /// Creates an interactive single-select step with arrow-key navigation.
  factory WizardStep.select(
    String key,
    String question, {
    required List<String> choices,
    int defaultIndex,
    String? description,
  }) = _InteractiveSelectStep;

  /// Creates an interactive multi-select step with arrow-key navigation.
  factory WizardStep.multiSelect(
    String key,
    String question, {
    required List<String> choices,
    List<int>? defaultSelected,
    String? description,
  }) = _InteractiveMultiSelectStep;

  /// Creates a conditional step that only runs if condition is met.
  factory WizardStep.conditional(
    WizardStep step, {
    required bool Function(Map<String, dynamic> answers) condition,
  }) = _ConditionalStep;

  /// Creates a group of steps.
  factory WizardStep.group(
    String key,
    String title, {
    required List<WizardStep> steps,
    String? description,
  }) = _GroupStep;
}

/// Context passed to wizard steps.
class WizardContext {
  WizardContext({
    required this.style,
    required this.stdin,
    required this.stdout,
    required this.answers,
    this.noInteraction = false,
  });

  final ArtisanStyle style;
  final io.Stdin stdin;
  final io.Stdout stdout;
  final Map<String, dynamic> answers;
  final bool noInteraction;

  void write(String text) => stdout.write(text);
  void writeln([String text = '']) => stdout.writeln(text);
}

/// A multi-step wizard flow.
///
/// ```dart
/// final wizard = Wizard(
///   title: 'Create New Project',
///   steps: [
///     WizardStep.ask('name', 'Project name'),
///     WizardStep.choice('template', 'Template', choices: ['app', 'package']),
///     WizardStep.confirm('git', 'Initialize git?', defaultValue: true),
///   ],
///   style: style,
///   stdin: io.stdin,
///   stdout: io.stdout,
/// );
///
/// final results = await wizard.run();
/// // results = {'name': 'my_app', 'template': 'app', 'git': true}
/// ```
class Wizard {
  Wizard({
    required this.steps,
    required this.style,
    required io.Stdin stdin,
    required io.Stdout stdout,
    this.title,
    this.description,
    this.noInteraction = false,
  }) : _stdin = stdin,
       _stdout = stdout;

  final List<WizardStep> steps;
  final ArtisanStyle style;
  final String? title;
  final String? description;
  final bool noInteraction;

  final io.Stdin _stdin;
  final io.Stdout _stdout;

  /// Runs the wizard and returns all collected answers.
  Future<Map<String, dynamic>> run() async {
    final answers = <String, dynamic>{};

    // Show title
    if (title != null) {
      _stdout.writeln();
      _stdout.writeln(style.heading(' $title '));
      if (description != null) {
        _stdout.writeln(style.muted(description!));
      }
      _stdout.writeln();
    }

    // Progress tracking
    final totalSteps = _countSteps(steps);
    var currentStep = 0;

    // Run each step
    for (final step in steps) {
      if (step.shouldSkip(answers)) {
        continue;
      }

      currentStep++;
      _showProgress(currentStep, totalSteps);

      final context = WizardContext(
        style: style,
        stdin: _stdin,
        stdout: _stdout,
        answers: answers,
        noInteraction: noInteraction,
      );

      final result = await step.run(context);
      if (!result.skipped) {
        answers[result.key] = result.value;
      }
    }

    // Show completion
    _stdout.writeln();
    _stdout.writeln(style.success('✓ Wizard completed'));
    _stdout.writeln();

    return answers;
  }

  void _showProgress(int current, int total) {
    final progress = style.muted('[$current/$total]');
    _stdout.write('$progress ');
  }

  int _countSteps(List<WizardStep> steps) {
    var count = 0;
    for (final step in steps) {
      if (step is _GroupStep) {
        count += _countSteps(step.steps);
      } else {
        count++;
      }
    }
    return count;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step implementations
// ─────────────────────────────────────────────────────────────────────────────

class _AskStep extends WizardStep {
  _AskStep(
    String key,
    this.question, {
    this.defaultValue,
    this.validator,
    String? description,
  }) : super(key: key, description: description);

  final String question;
  final String? defaultValue;
  final String? Function(String)? validator;

  @override
  Future<WizardStepResult> run(WizardContext context) async {
    final defaultDisplay = defaultValue != null
        ? context.style.muted(' [$defaultValue]')
        : '';
    context.write('${context.style.emphasize(question)}$defaultDisplay: ');

    if (context.noInteraction) {
      final value = defaultValue ?? '';
      context.writeln(value);
      return WizardStepResult(key: key, value: value);
    }

    while (true) {
      final input = context.stdin.readLineSync() ?? '';
      final value = input.isEmpty ? (defaultValue ?? '') : input;

      if (validator != null) {
        final error = validator!(value);
        if (error != null) {
          context.writeln(context.style.error('  $error'));
          context.write(
            '${context.style.emphasize(question)}$defaultDisplay: ',
          );
          continue;
        }
      }

      return WizardStepResult(key: key, value: value);
    }
  }
}

class _ConfirmStep extends WizardStep {
  _ConfirmStep(
    String key,
    this.question, {
    this.defaultValue = false,
    String? description,
  }) : super(key: key, description: description);

  final String question;
  final bool defaultValue;

  @override
  Future<WizardStepResult> run(WizardContext context) async {
    final hint = defaultValue ? '[Y/n]' : '[y/N]';
    context.write(
      '${context.style.emphasize(question)} ${context.style.muted(hint)}: ',
    );

    if (context.noInteraction) {
      context.writeln(defaultValue ? 'yes' : 'no');
      return WizardStepResult(key: key, value: defaultValue);
    }

    final input = context.stdin.readLineSync()?.toLowerCase() ?? '';
    final value = input.isEmpty
        ? defaultValue
        : input == 'y' || input == 'yes' || input == 'true' || input == '1';

    return WizardStepResult(key: key, value: value);
  }
}

class _ChoiceStep extends WizardStep {
  _ChoiceStep(
    String key,
    this.question, {
    required this.choices,
    this.defaultIndex,
    String? description,
  }) : super(key: key, description: description);

  final String question;
  final List<String> choices;
  final int? defaultIndex;

  @override
  Future<WizardStepResult> run(WizardContext context) async {
    context.writeln(context.style.emphasize(question));

    for (var i = 0; i < choices.length; i++) {
      final isDefault = i == defaultIndex;
      final marker = isDefault ? context.style.info('*') : ' ';
      context.writeln('  $marker [${i + 1}] ${choices[i]}');
    }

    final defaultDisplay = defaultIndex != null
        ? context.style.muted(' [${defaultIndex! + 1}]')
        : '';
    context.write('  Choice$defaultDisplay: ');

    if (context.noInteraction) {
      final index = defaultIndex ?? 0;
      context.writeln('${index + 1}');
      return WizardStepResult(key: key, value: choices[index]);
    }

    while (true) {
      final input = context.stdin.readLineSync() ?? '';
      int index;

      if (input.isEmpty && defaultIndex != null) {
        index = defaultIndex!;
      } else {
        final parsed = int.tryParse(input);
        if (parsed == null || parsed < 1 || parsed > choices.length) {
          context.writeln(
            context.style.error(
              '  Please enter a number between 1 and ${choices.length}',
            ),
          );
          context.write('  Choice$defaultDisplay: ');
          continue;
        }
        index = parsed - 1;
      }

      return WizardStepResult(key: key, value: choices[index]);
    }
  }
}

class _MultiChoiceStep extends WizardStep {
  _MultiChoiceStep(
    String key,
    this.question, {
    required this.choices,
    this.defaultSelected,
    String? description,
  }) : super(key: key, description: description);

  final String question;
  final List<String> choices;
  final List<int>? defaultSelected;

  @override
  Future<WizardStepResult> run(WizardContext context) async {
    context.writeln(context.style.emphasize(question));
    context.writeln(
      context.style.muted('  (Enter comma-separated numbers, e.g., 1,3,4)'),
    );

    for (var i = 0; i < choices.length; i++) {
      final isDefault = defaultSelected?.contains(i) ?? false;
      final marker = isDefault ? context.style.info('*') : ' ';
      context.writeln('  $marker [${i + 1}] ${choices[i]}');
    }

    final defaultDisplay =
        defaultSelected != null && defaultSelected!.isNotEmpty
        ? context.style.muted(
            ' [${defaultSelected!.map((i) => i + 1).join(',')}]',
          )
        : '';
    context.write('  Choices$defaultDisplay: ');

    if (context.noInteraction) {
      final indices = defaultSelected ?? [];
      context.writeln(indices.map((i) => i + 1).join(','));
      return WizardStepResult(
        key: key,
        value: indices.map((i) => choices[i]).toList(),
      );
    }

    while (true) {
      final input = context.stdin.readLineSync() ?? '';

      if (input.isEmpty && defaultSelected != null) {
        return WizardStepResult(
          key: key,
          value: defaultSelected!.map((i) => choices[i]).toList(),
        );
      }

      final parts = input
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty);
      final indices = <int>[];
      var valid = true;

      for (final part in parts) {
        final parsed = int.tryParse(part);
        if (parsed == null || parsed < 1 || parsed > choices.length) {
          context.writeln(context.style.error('  Invalid selection: $part'));
          valid = false;
          break;
        }
        indices.add(parsed - 1);
      }

      if (!valid) {
        context.write('  Choices$defaultDisplay: ');
        continue;
      }

      return WizardStepResult(
        key: key,
        value: indices.map((i) => choices[i]).toList(),
      );
    }
  }
}

class _SecretStep extends WizardStep {
  _SecretStep(String key, this.question, {this.fallback, String? description})
    : super(key: key, description: description);

  final String question;
  final String? fallback;

  @override
  Future<WizardStepResult> run(WizardContext context) async {
    context.write('${context.style.emphasize(question)}: ');

    if (context.noInteraction) {
      context.writeln('********');
      return WizardStepResult(key: key, value: fallback ?? '');
    }

    String value;
    try {
      final oldEchoMode = context.stdin.echoMode;
      try {
        context.stdin.echoMode = false;
        value = context.stdin.readLineSync() ?? '';
        context.writeln();
      } finally {
        context.stdin.echoMode = oldEchoMode;
      }
    } catch (_) {
      value = context.stdin.readLineSync() ?? '';
    }

    return WizardStepResult(
      key: key,
      value: value.isEmpty ? (fallback ?? '') : value,
    );
  }
}

class _ConditionalStep extends WizardStep {
  _ConditionalStep(this.step, {required this.condition})
    : super(key: step.key, description: step.description);

  final WizardStep step;
  final bool Function(Map<String, dynamic> answers) condition;

  @override
  bool shouldSkip(Map<String, dynamic> answers) => !condition(answers);

  @override
  Future<WizardStepResult> run(WizardContext context) => step.run(context);
}

class _GroupStep extends WizardStep {
  _GroupStep(String key, this.title, {required this.steps, String? description})
    : super(key: key, description: description);

  final String title;
  final List<WizardStep> steps;

  @override
  Future<WizardStepResult> run(WizardContext context) async {
    context.writeln();
    context.writeln(context.style.info('── $title ──'));
    context.writeln();

    final groupAnswers = <String, dynamic>{};

    for (final step in steps) {
      if (step.shouldSkip(context.answers)) {
        continue;
      }

      final result = await step.run(context);
      if (!result.skipped) {
        groupAnswers[result.key] = result.value;
        context.answers[result.key] = result.value;
      }
    }

    return WizardStepResult(key: key, value: groupAnswers);
  }
}

class _InteractiveSelectStep extends WizardStep {
  _InteractiveSelectStep(
    String key,
    this.question, {
    required this.choices,
    this.defaultIndex = 0,
    String? description,
  }) : super(key: key, description: description);

  final String question;
  final List<String> choices;
  final int defaultIndex;

  @override
  Future<WizardStepResult> run(WizardContext context) async {
    if (context.noInteraction) {
      final value = choices[defaultIndex];
      context.writeln('${context.style.emphasize(question)}: $value');
      return WizardStepResult(key: key, value: value);
    }

    // Reuse InteractiveChoice component
    final interactive = InteractiveChoice(
      style: context.style,
      write: context.write,
      writeln: context.writeln,
      stdin: context.stdin,
      stdout: context.stdout,
    );

    final result = await interactive.select<String>(
      question,
      choices: choices,
      defaultIndex: defaultIndex,
    );

    if (result == null) {
      throw StateError('Selection cancelled');
    }

    return WizardStepResult(key: key, value: result);
  }
}

class _InteractiveMultiSelectStep extends WizardStep {
  _InteractiveMultiSelectStep(
    String key,
    this.question, {
    required this.choices,
    this.defaultSelected,
    String? description,
  }) : super(key: key, description: description);

  final String question;
  final List<String> choices;
  final List<int>? defaultSelected;

  @override
  Future<WizardStepResult> run(WizardContext context) async {
    if (context.noInteraction) {
      final indices = defaultSelected ?? [];
      final values = indices.map((i) => choices[i]).toList();
      context.writeln(
        '${context.style.emphasize(question)}: ${values.join(', ')}',
      );
      return WizardStepResult(key: key, value: values);
    }

    // Reuse InteractiveChoice component
    final interactive = InteractiveChoice(
      style: context.style,
      write: context.write,
      writeln: context.writeln,
      stdin: context.stdin,
      stdout: context.stdout,
    );

    final result = await interactive.multiSelect<String>(
      question,
      choices: choices,
      defaultSelected: defaultSelected ?? [],
    );

    return WizardStepResult(key: key, value: result);
  }
}
