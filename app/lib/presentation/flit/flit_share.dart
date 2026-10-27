/// Text shared from another app ("Share via… flit") becomes a new flit
/// session with the text waiting in its composer, unsent, so the user can
/// add what they want done with it and pick the project first.
///
/// [ShareRouter] (app-wide) gets the user to the flit screens or explains
/// why it can't; [FlitShareHandler] (in the flit shell) opens the
/// new-session dialog.
library;

import 'dart:async';

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/application/share/share_providers.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/presentation/flit/flit_new_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Shown when a share arrives while connected to a Hermes gateway.
const String shareNeedsFlitMessage =
    'Shared text can only start a flit session. Connect to a flit server '
    'to use Share with flit.';

/// The connect screen's note while a share waits for a connection.
const String shareWaitingTitle = 'Shared text is waiting';
const String shareWaitingMessage =
    'Pair with a flit server and it opens in a new session.';

/// Watches for shares app-wide. Connected to flit: makes sure a flit screen
/// is showing (where [FlitShareHandler] takes over). Connected to Hermes:
/// says it isn't supported and drops the share. Not connected: leaves it
/// waiting (the connect screen says so) until a connection is made.
class ShareRouter extends ConsumerStatefulWidget {
  const ShareRouter({required this.router, required this.child, super.key});

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<ShareRouter> createState() => _ShareRouterState();
}

class _ShareRouterState extends ConsumerState<ShareRouter> {
  @override
  void initState() {
    super.initState();
    // Routing changes providers and navigates, so not from inside a
    // provider notification.
    ref
      ..listenManual(
        pendingShareProvider,
        (_, _) => scheduleMicrotask(_route),
        fireImmediately: true,
      )
      ..listenManual(
        connectionConfigProvider,
        (_, _) => scheduleMicrotask(_route),
      );
  }

  void _route() {
    if (!mounted) {
      return;
    }
    final route = shareRouteFor(
      ref.read(pendingShareProvider),
      ref.read(connectionConfigProvider),
    );
    switch (route) {
      case ShareRoute.none:
      case ShareRoute.wait:
        return;
      case ShareRoute.unsupported:
        ref.read(pendingShareProvider.notifier).consume();
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(const SnackBar(content: Text(shareNeedsFlitMessage)));
      case ShareRoute.flit:
        final location = widget.router.routerDelegate.currentConfiguration.uri
            .toString();
        if (!location.startsWith('/flit')) {
          widget.router.go('/flit');
        }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Inside the flit screens: turns a waiting share into the new-session
/// dialog, in the selected project, with the shared text as the draft.
class FlitShareHandler extends ConsumerStatefulWidget {
  const FlitShareHandler({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<FlitShareHandler> createState() => _FlitShareHandlerState();
}

class _FlitShareHandlerState extends ConsumerState<FlitShareHandler> {
  /// The dialog is up; a share arriving meanwhile waits for it to close.
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(pendingShareProvider, (_, next) {
      if (next != null) {
        // Not during a build: showing a dialog navigates.
        WidgetsBinding.instance.addPostFrameCallback((_) => _handle());
      }
    }, fireImmediately: true);
  }

  Future<void> _handle() async {
    if (_busy || !mounted || ref.read(flitRepositoryProvider) == null) {
      return;
    }
    final shared = ref.read(pendingShareProvider.notifier).consume();
    if (shared == null) {
      return;
    }
    _busy = true;
    try {
      await showFlitNewSession(
        context,
        ref,
        projectId: ref.read(flitSelectedProjectProvider),
        existing: ref.read(flitSessionsProvider).value ?? const <FlitSession>[],
        draft: shared.draft,
      );
    } finally {
      _busy = false;
    }
    // Another share came in while the dialog was up.
    if (mounted && ref.read(pendingShareProvider) != null) {
      unawaited(_handle());
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
