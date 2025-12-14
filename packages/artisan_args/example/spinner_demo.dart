#!/usr/bin/env dart

import 'dart:io';
import 'package:artisan_args/artisan_args.dart';

/// Run this directly: dart run example/spinner_demo.dart
void main() async {
  final style = ArtisanStyle(ansi: stdout.supportsAnsiEscapes);
  final context = ComponentContext(
    style: style,
    stdout: stdout,
    stdin: stdin,
    terminalWidth: stdout.hasTerminal ? stdout.terminalColumns : 80,
  );

  print('Testing animated spinner...\n');

  // Test 1: Basic spinner with dots
  print('1. Dots spinner (default):');
  await withSpinner(
    message: 'Loading data...',
    context: context,
    task: () async {
      await Future<void>.delayed(const Duration(seconds: 3));
      return 'Done!';
    },
  );

  print('\n2. Line spinner:');
  await withSpinner(
    message: 'Processing...',
    context: context,
    frames: SpinnerFrames.line,
    task: () async {
      await Future<void>.delayed(const Duration(seconds: 2));
      return null;
    },
  );

  print('\n3. Circle spinner:');
  await withSpinner(
    message: 'Compiling...',
    context: context,
    frames: SpinnerFrames.circle,
    task: () async {
      await Future<void>.delayed(const Duration(seconds: 2));
      return null;
    },
  );

  print('\n4. Arc spinner:');
  await withSpinner(
    message: 'Uploading...',
    context: context,
    frames: SpinnerFrames.arc,
    task: () async {
      await Future<void>.delayed(const Duration(seconds: 2));
      return null;
    },
  );

  print('\n5. Arrows spinner:');
  await withSpinner(
    message: 'Syncing...',
    context: context,
    frames: SpinnerFrames.arrows,
    task: () async {
      await Future<void>.delayed(const Duration(seconds: 2));
      return null;
    },
  );

  print('\n6. Manual spinner control:');
  final spinner = StatefulSpinner(message: 'Doing work step by step...');

  spinner.start(context);
  await Future<void>.delayed(const Duration(seconds: 1));
  spinner.update(context, 'Step 1 of 3...');
  await Future<void>.delayed(const Duration(seconds: 1));
  spinner.update(context, 'Step 2 of 3...');
  await Future<void>.delayed(const Duration(seconds: 1));
  spinner.update(context, 'Step 3 of 3...');
  await Future<void>.delayed(const Duration(seconds: 1));
  spinner.success(context, 'All steps complete!');

  print('\n7. Error spinner:');
  try {
    await withSpinner(
      message: 'This will fail...',
      context: context,
      task: () async {
        await Future<void>.delayed(const Duration(seconds: 2));
        throw Exception('Simulated error');
      },
    );
  } catch (e) {
    // Error was already displayed by spinner
  }

  print('\n8. SpinnerComponent (interactive component):');
  await SpinnerComponent(
    message: 'Using SpinnerComponent...',
    task: () async {
      await Future<void>.delayed(const Duration(seconds: 2));
    },
  ).interact(context);

  print('\nAll spinners tested!');
}
