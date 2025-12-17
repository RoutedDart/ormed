/// Files tree example - ported from lipgloss/examples/tree/files
///
/// Demonstrates building a tree from filesystem directories.
import 'dart:io';

import 'package:artisan_args/artisan_args.dart';

void addBranches(Tree root, String path) {
  final dir = Directory(path);
  final items = dir.listSync();

  for (final item in items) {
    final name = item.path.split(Platform.pathSeparator).last;

    // Skip hidden files/directories
    if (name.startsWith('.')) continue;

    if (item is Directory) {
      final treeBranch = Tree().root(name);
      root.child(treeBranch);

      // Recurse
      addBranches(treeBranch, item.path);
    } else {
      root.child(name);
    }
  }
}

void main() {
  final enumeratorStyle = Style().foreground(AnsiColor(240)).paddingRight(1);
  final itemStyle = Style().foreground(AnsiColor(99)).bold().paddingRight(1);

  final pwd = Directory.current.path;

  final t = Tree()
      .root(pwd)
      .branchStyle(enumeratorStyle)
      .rootStyle(itemStyle)
      .fileStyle(itemStyle);

  addBranches(t, '.');

  print(t);
}
