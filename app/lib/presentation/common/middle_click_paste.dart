/// Middle-click paste, the X11 way, for every text field in the app: a
/// middle click on an editable field inserts the PRIMARY selection where
/// you clicked. Linux only (no PRIMARY selection elsewhere).
library;

import 'dart:async';

import 'package:flit/core/platform/primary_selection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Wraps the whole app (MaterialApp.builder) so dialogs and sheets are
/// covered too.
class MiddleClickPaste extends StatelessWidget {
  const MiddleClickPaste({
    required this.child,
    this.readSelection = readPrimarySelection,
    this.enabled,
    super.key,
  });

  final Widget child;

  /// Reads the PRIMARY selection; injectable for tests.
  final Future<String?> Function() readSelection;

  /// Overrides the platform check; for tests.
  final bool? enabled;

  @override
  Widget build(BuildContext context) {
    if (!(enabled ?? hasPrimarySelection)) {
      return child;
    }
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        if (event.kind == PointerDeviceKind.mouse &&
            event.buttons & kMiddleMouseButton != 0) {
          unawaited(_paste(context, event));
        }
      },
      child: child,
    );
  }

  Future<void> _paste(BuildContext context, PointerDownEvent event) async {
    final state = _editableAt(context, event);
    if (state == null || state.widget.readOnly) {
      return;
    }
    // Where the click landed, before the await (layout may change).
    final position = state.renderEditable.getPositionForPoint(event.position);
    final text = await readSelection();
    if (text == null || text.isEmpty || !state.mounted) {
      return;
    }
    final value = state.textEditingValue;
    final offset = position.offset.clamp(0, value.text.length);
    state.widget.focusNode.requestFocus();
    state.userUpdateTextEditingValue(
      TextEditingValue(
        text: value.text.replaceRange(offset, offset, text),
        selection: TextSelection.collapsed(offset: offset + text.length),
      ),
      SelectionChangedCause.tap,
    );
  }

  /// The editable text field under the pointer, if any.
  static EditableTextState? _editableAt(
    BuildContext context,
    PointerDownEvent event,
  ) {
    final result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, event.position, event.viewId);
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
}
