/// The session drawer (ticket P1-10): manage more than one conversation.
///
/// - Header: 'Sessions' + a 'New session' action (`session.create`).
/// - Live section: `session.active_list` rows with a status badge
///   (idle/starting/waiting/working) and a 'current' highlight; the
///   current row carries an interrupt affordance while the session is
///   working (`session.interrupt`, wire §12).
/// - History section: `session.list` rows (durable ids); tapping switches —
///   reusing the live id for still-live sessions, `session.resume` for
///   durable-only ones (protocol §9).
///
/// Failures surface as a dismissible in-drawer message — nothing throws;
/// the providers already yield empty lists while disconnected. After a
/// successful new/switch the drawer closes.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hermes/application/sessions/active_session.dart';
import 'package:hermes/application/sessions/session_list.dart';
import 'package:hermes/domain/models/active_session.dart';
import 'package:hermes/domain/models/session_summary.dart';

/// Key of the 'New session' button.
const Key sessionDrawerNewKey = Key('session_drawer_new');

/// Key of the interrupt button on the current live row.
const Key sessionDrawerInterruptKey = Key('session_drawer_interrupt');

/// Key of a Live-section row.
Key sessionDrawerLiveKey(String liveId) => Key('session_drawer_live_$liveId');

/// Key of a History-section row.
Key sessionDrawerHistoryKey(String durableId) {
  return Key('session_drawer_history_$durableId');
}

class SessionDrawer extends ConsumerStatefulWidget {
  const SessionDrawer({super.key});

  @override
  ConsumerState<SessionDrawer> createState() => _SessionDrawerState();
}

class _SessionDrawerState extends ConsumerState<SessionDrawer> {
  /// The last failed action's message, shown in a dismissible banner.
  String? _actionError;

  /// Bumped with every new error so the banner reappears even for a
  /// repeated message (it is keyed by this).
  int _errorSeq = 0;

  /// Run a drawer action: on success close the drawer (unless
  /// [closeOnSuccess] is false — interrupt keeps it open); on failure show
  /// the returned message in a dismissible banner.
  Future<void> _run(
    FutureOr<String?> Function() action, {
    bool closeOnSuccess = true,
  }) async {
    final error = await action();
    if (!mounted) {
      return;
    }
    if (error == null) {
      if (closeOnSuccess) {
        Navigator.of(context).pop();
      }
    } else {
      setState(() {
        _errorSeq++;
        _actionError = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(sessionListProvider);
    final live = ref.watch(activeSessionListProvider);
    final active = ref.watch(activeSessionProvider);
    final scheme = Theme.of(context).colorScheme;
    final actionError = _actionError;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: scheme.primaryContainer),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text(
                    'Sessions',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: sessionDrawerNewKey,
                    onPressed: () => unawaited(
                      _run(() => ref.read(sessionActionsProvider).newSession()),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('New session'),
                  ),
                ],
              ),
            ),
            if (actionError != null)
              _ErrorBanner(
                key: ValueKey<String>('action_$_errorSeq'),
                message: actionError,
              ),
            const _SectionHeader(title: 'Live'),
            ..._liveTiles(live, active),
            const _SectionHeader(title: 'History'),
            ..._historyTiles(history, active),
          ],
        ),
      ),
    );
  }

  List<Widget> _liveTiles(
    AsyncValue<List<ActiveSession>> live,
    ActiveSessionState active,
  ) {
    return switch (live) {
      AsyncData(:final value) when value.isEmpty => <Widget>[
        const _EmptyHint('No live sessions'),
      ],
      AsyncData(:final value) => <Widget>[
        for (final session in value) _liveTile(session, active),
      ],
      AsyncError(:final error) => <Widget>[
        _ErrorBanner(message: 'Could not load live sessions: $error'),
      ],
      _ => const <Widget>[_SectionLoading()],
    };
  }

  Widget _liveTile(ActiveSession session, ActiveSessionState active) {
    final isCurrent = session.liveId == active.liveId && active.liveId != null;
    final title = session.title;
    final preview = session.preview;
    return ListTile(
      key: sessionDrawerLiveKey(session.liveId),
      selected: isCurrent,
      leading: Tooltip(
        message: session.status.name,
        child: _StatusDot(status: session.status),
      ),
      title: Text(
        title == null || title.isEmpty ? 'Untitled' : title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        <String>[
          session.status.name,
          if (preview != null && preview.isNotEmpty) preview,
        ].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isCurrent && session.status == SessionStatus.working
          ? IconButton(
              key: sessionDrawerInterruptKey,
              tooltip: 'Interrupt',
              icon: const Icon(Icons.stop_circle_outlined),
              onPressed: () => unawaited(
                _run(
                  () => ref.read(sessionActionsProvider).interruptActive(),
                  closeOnSuccess: false,
                ),
              ),
            )
          : null,
      onTap: () => unawaited(
        _run(() {
          ref.read(sessionActionsProvider).switchToLive(session);
          return null;
        }),
      ),
    );
  }

  List<Widget> _historyTiles(
    AsyncValue<List<SessionSummary>> history,
    ActiveSessionState active,
  ) {
    return switch (history) {
      AsyncData(:final value) when value.isEmpty => <Widget>[
        const _EmptyHint('No past sessions'),
      ],
      AsyncData(:final value) => <Widget>[
        for (final summary in value)
          ListTile(
            key: sessionDrawerHistoryKey(summary.durableId),
            selected:
                summary.durableId == active.durableId &&
                active.durableId != null,
            leading: const Icon(Icons.history),
            title: Text(
              summary.title.isEmpty ? 'Untitled' : summary.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              _historySubtitle(summary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => unawaited(
              _run(
                () => ref.read(sessionActionsProvider).switchToSummary(summary),
              ),
            ),
          ),
      ],
      AsyncError(:final error) => <Widget>[
        _ErrorBanner(message: 'Could not load sessions: $error'),
      ],
      _ => const <Widget>[_SectionLoading()],
    };
  }

  static String _historySubtitle(SessionSummary summary) {
    final date = _relativeDate(summary.startedAt);
    return <String>[
      if (summary.preview.isNotEmpty) summary.preview,
      '${summary.messageCount} message${summary.messageCount == 1 ? '' : 's'}',
      if (date.isNotEmpty) date,
    ].join(' · ');
  }
}

/// A relative-ish timestamp for history rows: minutes/hours/days ago, then
/// a bare ISO date.
String _relativeDate(DateTime? time) {
  if (time == null) {
    return '';
  }
  final difference = DateTime.now().difference(time);
  if (difference.isNegative || difference.inMinutes < 1) {
    return 'just now';
  }
  if (difference.inHours < 1) {
    return '${difference.inMinutes}m ago';
  }
  if (difference.inDays < 1) {
    return '${difference.inHours}h ago';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  }
  final month = time.month.toString().padLeft(2, '0');
  final day = time.day.toString().padLeft(2, '0');
  return '${time.year}-$month-$day';
}

/// A colored status badge dot (idle/starting/waiting/working).
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final SessionStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      SessionStatus.idle => Colors.green,
      SessionStatus.starting => Colors.blue,
      SessionStatus.waiting => Colors.grey,
      SessionStatus.working => Colors.orange,
    };
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

/// An in-drawer error message with a dismiss affordance (ticket P1-10:
/// errors never throw; they land here). Dismissal is local — the banner
/// hides until it is rebuilt with a new key.
class _ErrorBanner extends StatefulWidget {
  const _ErrorBanner({super.key, required this.message});

  final String message;

  @override
  State<_ErrorBanner> createState() => _ErrorBannerState();
}

class _ErrorBannerState extends State<_ErrorBanner> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    if (!_visible) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      child: ListTile(
        dense: true,
        leading: Icon(Icons.error_outline, color: scheme.onErrorContainer),
        title: Text(
          widget.message,
          style: TextStyle(color: scheme.onErrorContainer),
        ),
        trailing: IconButton(
          tooltip: 'Dismiss',
          icon: Icon(Icons.close, color: scheme.onErrorContainer),
          onPressed: () => setState(() => _visible = false),
        ),
      ),
    );
  }
}
