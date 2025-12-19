import 'dart:math' as math;

import '../../style/ranges.dart' as ranges;
import '../uv/wrap.dart' as uv_wrap;
import '../cmd.dart';
import '../msg.dart';
import 'viewport.dart';

/// A high-level text component that supports selection, scrolling, and wrapping.
/// It is built on top of [ViewportModel] but defaults to auto-height and soft-wrap.
class TextModel extends ViewportModel {
  TextModel.withOptions({
    super.width = 80,
    super.height,
    super.gutter = 0,
    super.yOffset = 0,
    super.xOffset = 0,
    super.mouseWheelEnabled = true,
    super.mouseWheelDelta = 3,
    super.horizontalStep = 0,
    super.softWrap = true,
    super.showLineNumbers = false,
    super.leftGutterFunc,
    super.highlights = const [],
    super.currentHighlightIndex = -1,
    super.selectionStart,
    super.selectionEnd,
    super.lastClickTime,
    super.lastClickPos,
    super.keyMap,
    super.lines,
    super.wrappedLines,
    super.originalLines,
  });

  factory TextModel(String content, {int width = 80}) {
    return TextModel.withOptions(width: width, softWrap: true, height: null)
        .setContent(content);
  }

  @override
  TextModel copyWith({
    int? width,
    int? height,
    int? gutter,
    int? yOffset,
    int? xOffset,
    bool? mouseWheelEnabled,
    int? mouseWheelDelta,
    int? horizontalStep,
    bool? softWrap,
    bool? showLineNumbers,
    String Function(int)? leftGutterFunc,
    List<ranges.StyleRange>? highlights,
    int? currentHighlightIndex,
    Object? selectionStart = undefined,
    Object? selectionEnd = undefined,
    DateTime? lastClickTime,
    (int, int)? lastClickPos,
    ViewportKeyMap? keyMap,
    List<String>? lines,
    List<String>? wrappedLines,
    List<String>? originalLines,
  }) {
    final newWidth = width ?? this.width;
    final newGutter = gutter ?? this.gutter;
    final newSoftWrap = softWrap ?? this.softWrap;
    final newOriginalLines = lines ?? originalLines ?? internalOriginalLines;
    final newHighlights = highlights ?? this.highlights;

    // Apply highlights to original lines
    var styledLines = lines ?? internalLines;
    if (lines != null || highlights != null) {
      styledLines = newOriginalLines;
      if (newHighlights.isNotEmpty) {
        final content = newOriginalLines.join('\n');
        final styled = ranges.styleRanges(content, newHighlights);
        styledLines = styled.split('\n');
      }
    }

    List<String>? newWrappedLines = wrappedLines ?? internalWrappedLines;
    if (newSoftWrap && (lines != null || width != null || gutter != null || softWrap != null || highlights != null)) {
      final contentWidth = math.max(0, newWidth - newGutter);
      final content = styledLines.join('\n');
      final wrapped = uv_wrap.wrapAnsiPreserving(content, contentWidth);
      newWrappedLines = wrapped.split('\n');
    }

    final newSelectionStart = selectionStart == undefined
        ? this.selectionStart
        : selectionStart as (int, int)?;
    final newSelectionEnd = selectionEnd == undefined
        ? this.selectionEnd
        : selectionEnd as (int, int)?;

    return TextModel.withOptions(
      width: newWidth,
      height: height ?? this.height,
      gutter: newGutter,
      yOffset: yOffset ?? this.yOffset,
      xOffset: xOffset ?? this.xOffset,
      mouseWheelEnabled: mouseWheelEnabled ?? this.mouseWheelEnabled,
      mouseWheelDelta: mouseWheelDelta ?? this.mouseWheelDelta,
      horizontalStep: horizontalStep ?? this.horizontalStep,
      softWrap: newSoftWrap,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      leftGutterFunc: leftGutterFunc ?? this.leftGutterFunc,
      highlights: newHighlights,
      currentHighlightIndex: currentHighlightIndex ?? this.currentHighlightIndex,
      selectionStart: newSelectionStart,
      selectionEnd: newSelectionEnd,
      lastClickTime: lastClickTime ?? this.lastClickTime,
      lastClickPos: lastClickPos ?? this.lastClickPos,
      keyMap: keyMap ?? this.keyMap,
      lines: styledLines,
      wrappedLines: newWrappedLines,
      originalLines: newOriginalLines,
    );
  }

  @override
  TextModel setContent(String content) {
    return super.setContent(content) as TextModel;
  }

  @override
  (TextModel, Cmd?) update(Msg msg) {
    final (newModel, cmd) = super.update(msg);
    return (newModel as TextModel, cmd);
  }
}
