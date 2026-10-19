/// Finding the text field (or selectable text) under a pointer.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// The [EditableTextState] whose text is under [position] in view [viewId],
/// searched for below [context]; null if there is none.
EditableTextState? editableTextAt(
  BuildContext context,
  Offset position,
  int viewId,
) {
  final result = HitTestResult();
  WidgetsBinding.instance.hitTestInView(result, position, viewId);
  RenderEditable? target;
  for (final entry in result.path) {
    if (entry.target is RenderEditable) {
      target = entry.target as RenderEditable;
      break;
    }
  }
  if (target == null) {
    return null;
  }
  EditableTextState? found;
  void visit(Element element) {
    if (found != null) {
      return;
    }
    if (element is StatefulElement &&
        element.state is EditableTextState &&
        (element.state as EditableTextState).renderEditable == target) {
      found = element.state as EditableTextState;
      return;
    }
    element.visitChildren(visit);
  }

  context.visitChildElements(visit);
  return found;
}
