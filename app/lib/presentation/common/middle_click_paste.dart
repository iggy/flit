/// Middle-click paste, the X11 way, for every text field in the app: a
/// middle click on an editable field inserts the PRIMARY selection where
/// you clicked. Linux only (no PRIMARY selection elsewhere).
library;

import 'dart:async';

import 'package:flit/core/platform/primary_selection.dart';
import 'package:flit/presentation/common/editable_text_at.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

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
    final state = editableTextAt(context, event.position, event.viewId);
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
}
