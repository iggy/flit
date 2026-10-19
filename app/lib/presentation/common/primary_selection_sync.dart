/// Selecting text fills the PRIMARY selection, the X11 way, so middle-click
/// pastes it in other apps (X11 and Wayland). Linux only. Covers text
/// fields and selectable text (SelectableText and selectable markdown are
/// both EditableText underneath); password fields are never copied.
library;

import 'dart:async';

import 'package:flit/core/platform/primary_selection.dart';
import 'package:flit/presentation/common/editable_text_at.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Wraps the whole app (MaterialApp.builder). It follows the text the user
/// is selecting in (the field under a mouse press, or the focused one) and
/// writes each new non-empty selection to PRIMARY once it settles.
class PrimarySelectionSync extends StatefulWidget {
  const PrimarySelectionSync({
    required this.child,
    this.writeSelection = writePrimarySelection,
    this.enabled,
    super.key,
  });

  final Widget child;

  /// Writes the PRIMARY selection; injectable for tests.
  final Future<void> Function(String text) writeSelection;

  /// Overrides the platform check; for tests.
  final bool? enabled;

  /// How long a selection must hold still before it is written, so a drag
  /// doesn't write every intermediate range.
  static const Duration settle = Duration(milliseconds: 150);

  @override
  State<PrimarySelectionSync> createState() => _PrimarySelectionSyncState();
}

class _PrimarySelectionSyncState extends State<PrimarySelectionSync> {
  EditableTextState? _field;
  TextEditingController? _controller;
  Timer? _timer;

  bool get _enabled => widget.enabled ?? hasPrimarySelection;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_onFocus);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocus);
    _timer?.cancel();
    _controller?.removeListener(_onChanged);
    super.dispose();
  }

  void _onFocus() {
    final focused = FocusManager.instance.primaryFocus?.context;
    final field = focused?.findAncestorStateOfType<EditableTextState>();
    if (field != null) {
      _follow(field);
    }
  }

  /// Watches [field]'s selection instead of the previous field's.
  void _follow(EditableTextState field) {
    final controller = field.widget.controller;
    if (identical(controller, _controller)) {
      _field = field;
      return;
    }
    _controller?.removeListener(_onChanged);
    _field = field;
    _controller = controller..addListener(_onChanged);
  }

  void _onChanged() {
    _timer?.cancel();
    _timer = Timer(PrimarySelectionSync.settle, _write);
  }

  void _write() {
    final field = _field;
    final controller = _controller;
    if (field == null || controller == null || !field.mounted) {
      return;
    }
    if (field.widget.obscureText) {
      return;
    }
    final selection = controller.selection;
    if (!selection.isValid || selection.isCollapsed) {
      return;
    }
    final text = selection.textInside(controller.text);
    if (text.isEmpty) {
      return;
    }
    unawaited(widget.writeSelection(text));
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled) {
      return widget.child;
    }
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        // A press starts a mouse selection in whatever is under it, which
        // need not take focus (selectable text often doesn't).
        if (event.kind == PointerDeviceKind.mouse &&
            event.buttons & kPrimaryMouseButton != 0) {
          final field = editableTextAt(context, event.position, event.viewId);
          if (field != null) {
            _follow(field);
          }
        }
      },
      child: widget.child,
    );
  }
}
