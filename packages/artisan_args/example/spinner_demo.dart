#!/usr/bin/env dart

import 'dart:io';
import 'package:artisan_args/artisan_args.dart';

/// Run this directly: dart run example/spinner_demo.dart
void main() async {
  final style = ArtisanStyle(ansi: stdout.supportsAnsiEscapes);

  print('Testing animated spinner...\n');

  // Test 1: Basic spinner with dots
  print('1. Dots spinner (default):');
  await withSpinner(
    message: 'Loading data...',
    style: style,
    stdout: stdout,
    run: () async {
      await Future<void>.delayed(const Duration(seconds: 3));
      return 'Done!';
    },
  );

  print('\n2. Line spinner:');
  await withSpinner(
    message: 'Processing...',
    style: style,
    stdout: stdout,
    config: const SpinnerConfig(frames: SpinnerFrames.line),
    run: () async {
      await Future<void>.delayed(const Duration(seconds: 2));
      return null;
    },
  );

  print('\n3. Circle spinner:');
  await withSpinner(
    message: 'Compiling...',
    style: style,
    stdout: stdout,
    config: const SpinnerConfig(frames: SpinnerFrames.circle),
    run: () async {
      await Future<void>.delayed(const Duration(seconds: 2));
      return null;
    },
  );

  print('\n4. Arc spinner:');
  await withSpinner(
    message: 'Uploading...',
    style: style,
    stdout: stdout,
    config: const SpinnerConfig(frames: SpinnerFrames.arc),
    run: () async {
      await Future<void>.delayed(const Duration(seconds: 2));
      return null;
    },
  );

  print('\n5. Arrows spinner:');
  await withSpinner(
    message: 'Syncing...',
    style: style,
    stdout: stdout,
    config: const SpinnerConfig(frames: SpinnerFrames.arrows),
    run: () async {
      await Future<void>.delayed(const Duration(seconds: 2));
      return null;
    },
  );

  print('\n6. Manual spinner control:');
  final spinner = Spinner(
    message: 'Doing work step by step...',
    style: style,
    stdout: stdout,
  );

  spinner.start();
  await Future<void>.delayed(const Duration(seconds: 1));
  spinner.update('Step 1 of 3...');
  await Future<void>.delayed(const Duration(seconds: 1));
  spinner.update('Step 2 of 3...');
  await Future<void>.delayed(const Duration(seconds: 1));
  spinner.update('Step 3 of 3...');
  await Future<void>.delayed(const Duration(seconds: 1));
  spinner.success('All steps complete!');

  print('\n7. Error spinner:');
  try {
    await withSpinner(
      message: 'This will fail...',
      style: style,
      stdout: stdout,
      run: () async {
        await Future<void>.delayed(const Duration(seconds: 2));
        throw Exception('Simulated error');
      },
    );
  } catch (e) {
    // Error was already displayed by spinner
  }

  print('\nDone testing spinners!');
}
