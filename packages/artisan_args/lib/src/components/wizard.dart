import 'dart:async';

import 'base.dart';
import 'input.dart';
import 'password.dart';
import 'select.dart';

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
  Future<WizardStepResult> run(
    ComponentContext context,
    Map<String, dynamic> answers,
  );

  /// Whether this step should be skipped based on previous answers.
  bool shouldSkip(Map<String, dynamic> answers) => false;

  // Factory constructors
  factory WizardStep.ask(
    String key,
    String question, {
    String? defaultValue,
    String? Function(String)? validator,
    String? description,
  }) = _AskStep;

  factory WizardStep.confirm(
    String key,
    String question, {
    bool defaultValue,
    String? description,
  }) = _ConfirmStep;

  factory WizardStep.choice(
    String key,
    String question, {
    required List<String> choices,
    int? defaultIndex,
    String? description,
  }) = _ChoiceStep;

  factory WizardStep.multiChoice(
    String key,
    String question, {
    required List<String> choices,
    List<int>? defaultSelected,
    String? description,
  }) = _MultiChoiceStep;

  factory WizardStep.secret(
    String key,
    String question, {
    String? fallback,
    String? description,
  }) = _SecretStep;

  factory WizardStep.select(
    String key,
    String question, {
    required List<String> choices,
    int defaultIndex,
    String? description,
  }) = _InteractiveSelectStep;

  factory WizardStep.multiSelect(
    String key,
    String question, {
    required List<String> choices,
    List<int>? defaultSelected,
    String? description,
  }) = _InteractiveMultiSelectStep;

  factory WizardStep.conditional(
    WizardStep step, {
    required bool Function(Map<String, dynamic> answers) condition,
  }) = _ConditionalStep;

  factory WizardStep.group(
    String key,
    String title, {
    required List<WizardStep> steps,
    String? description,
  }) = _GroupStep;
}

/// A multi-step wizard component.
///
/// ```dart
/// final results = await WizardComponent(
///   title: 'Create New Project',
///   steps: [
///     WizardStep.ask('name', 'Project name'),
///     WizardStep.choice('template', 'Template', choices: ['app', 'package']),
///     WizardStep.confirm('git', 'Initialize git?', defaultValue: true),
///   ],
/// ).interact(context);
/// ```
class WizardComponent extends InteractiveComponent<Map<String, dynamic>> {
  WizardComponent({
    required this.steps,
    this.title,
    this.description,
    this.noInteraction = false,
  });

  final List<WizardStep> steps;
  final String? title;
  final String? description;
  final bool noInteraction;

  @override
  RenderResult build(ComponentContext context) {
    if (title != null) {
      return RenderResult(
        output: context.style.heading(' $title '),
        lineCount: 1,
      );
    }
    return RenderResult.empty;
  }

  @override
  Future<Map<String, dynamic>> interact(ComponentContext context) async {
    final answers = <String, dynamic>{};

    if (title != null) {
      context.writeln();
      context.writeln(context.style.heading(' $title '));
      if (description != null) {
        context.writeln(context.style.muted(description!));
      }
      context.writeln();
    }

    final totalSteps = _countSteps(steps);
    var currentStep = 0;

    for (final step in steps) {
      if (step.shouldSkip(answers)) {
        continue;
      }

      currentStep++;
      _showProgress(context, currentStep, totalSteps);

      final result = await step.run(context, answers);
      if (!result.skipped) {
        answers[result.key] = result.value;
      }
    }

    context.writeln();
    context.writeln(context.style.success('✓ Wizard completed'));
    context.writeln();

    return answers;
  }

  void _showProgress(ComponentContext context, int current, int total) {
    final progress = context.style.muted('[$current/$total]');
    context.write('$progress ');
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

// Step implementations

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
  Future<WizardStepResult> run(
    ComponentContext context,
    Map<String, dynamic> answers,
  ) async {
    final result = await TextInput(
      prompt: question,
      defaultValue: defaultValue,
      validator: validator,
    ).interact(context);

    return WizardStepResult(key: key, value: result);
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
  Future<WizardStepResult> run(
    ComponentContext context,
    Map<String, dynamic> answers,
  ) async {
    final result = await Confirm(
      prompt: question,
      defaultValue: defaultValue,
    ).interact(context);

    return WizardStepResult(key: key, value: result);
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
  Future<WizardStepResult> run(
    ComponentContext context,
    Map<String, dynamic> answers,
  ) async {
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
  Future<WizardStepResult> run(
    ComponentContext context,
    Map<String, dynamic> answers,
  ) async {
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
  Future<WizardStepResult> run(
    ComponentContext context,
    Map<String, dynamic> answers,
  ) async {
    final result = await PasswordComponent(
      prompt: question,
      fallback: fallback ?? '',
    ).interact(context);

    return WizardStepResult(key: key, value: result);
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
  Future<WizardStepResult> run(
    ComponentContext context,
    Map<String, dynamic> answers,
  ) async {
    final result = await Select<String>(
      prompt: question,
      options: choices,
      defaultIndex: defaultIndex,
    ).interact(context);

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
  Future<WizardStepResult> run(
    ComponentContext context,
    Map<String, dynamic> answers,
  ) async {
    final result = await MultiSelect<String>(
      prompt: question,
      options: choices,
      defaultSelected: defaultSelected ?? [],
    ).interact(context);

    return WizardStepResult(key: key, value: result);
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
  Future<WizardStepResult> run(
    ComponentContext context,
    Map<String, dynamic> answers,
  ) => step.run(context, answers);
}

class _GroupStep extends WizardStep {
  _GroupStep(String key, this.title, {required this.steps, String? description})
    : super(key: key, description: description);

  final String title;
  final List<WizardStep> steps;

  @override
  Future<WizardStepResult> run(
    ComponentContext context,
    Map<String, dynamic> answers,
  ) async {
    context.writeln();
    context.writeln(context.style.info('── $title ──'));
    context.writeln();

    final groupAnswers = <String, dynamic>{};

    for (final step in steps) {
      if (step.shouldSkip(answers)) {
        continue;
      }

      final result = await step.run(context, answers);
      if (!result.skipped) {
        groupAnswers[result.key] = result.value;
        answers[result.key] = result.value;
      }
    }

    return WizardStepResult(key: key, value: groupAnswers);
  }
}
