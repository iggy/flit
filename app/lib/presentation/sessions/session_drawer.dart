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
///
/// Footer (ticket P1-16): the connected gateway's version, small and muted.
library;

import 'dart:async';

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/sessions/active_session.dart';
import 'package:flit/application/sessions/session_list.dart';
import 'package:flit/domain/models/active_session.dart';
import 'package:flit/domain/models/session_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Key of the popup menu for a session row.
Key sessionDrawerMenuKey(String id) => Key('session_drawer_menu_$id');

/// Key of the rename confirm button.
const Key sessionDrawerRenameConfirmKey = Key('session_drawer_rename_confirm');

/// Key of the delete confirm button.
const Key sessionDrawerDeleteConfirmKey = Key('session_drawer_delete_confirm');

/// Key of the branch confirm button.
const Key sessionDrawerBranchConfirmKey = Key('session_drawer_branch_confirm');

class SessionDrawer extends ConsumerStatefulWidget {
  const SessionDrawer({super.key});

  @override
  ConsumerState<SessionDrawer> createState() => _SessionDrawerState();
}

class _SessionDrawerState extends ConsumerState<SessionDrawer> {
  String? _actionError;
  int _errorSeq = 0;
  String _searchQuery = '';

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

  Widget _rowMenu({
    String? liveId,
    String? durableId,
    required String currentTitle,
  }) {
    return PopupMenuButton<String>(
      key: sessionDrawerMenuKey(durableId ?? liveId ?? 'unknown'),
      icon: const Icon(Icons.more_vert),
      itemBuilder: (context) => <PopupMenuEntry<String>>[
        if (liveId != null)
          const PopupMenuItem<String>(value: 'rename', child: Text('Rename')),
        if (liveId != null)
          const PopupMenuItem<String>(value: 'branch', child: Text('Branch')),
        if (durableId != null)
          const PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
      ],
      onSelected: (value) async {
        switch (value) {
          case 'rename':
            if (liveId != null) {
              await _promptRename(liveId, currentTitle);
            }
          case 'branch':
            if (liveId != null) {
              await _confirmBranch(liveId);
            }
          case 'delete':
            if (durableId != null) {
              await _confirmDelete(durableId);
            }
        }
      },
    );
  }

  Future<void> _promptRename(String liveId, String currentTitle) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: currentTitle);
        return AlertDialog(
          title: const Text('Rename session'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Title'),
            autofocus: true,
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              key: sessionDrawerRenameConfirmKey,
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
    if (!mounted || result == null || result.trim().isEmpty) {
      return;
    }
    unawaited(
      _run(
        () => ref.read(sessionActionsProvider).rename(liveId, result.trim()),
        closeOnSuccess: false,
      ),
    );
  }

  Future<void> _confirmBranch(String liveId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Branch session?'),
          content: const Text('Create a new branch from this conversation.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              key: sessionDrawerBranchConfirmKey,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Branch'),
            ),
          ],
        );
      },
    );
    if (!mounted || confirmed != true) {
      return;
    }
    unawaited(
      _run(() => ref.read(sessionActionsProvider).branchSession(liveId)),
    );
  }

  Future<void> _confirmDelete(String durableId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete session?'),
          content: const Text(
            'This permanently deletes the stored conversation.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              key: sessionDrawerDeleteConfirmKey,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (!mounted || confirmed != true) {
      return;
    }
    unawaited(
      _run(
        () => ref.read(sessionActionsProvider).deleteSession(durableId),
        closeOnSuccess: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(sessionListProvider);
    final live = ref.watch(activeSessionListProvider);
    final active = ref.watch(activeSessionProvider);
    final actionError = _actionError;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Sessions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    key: sessionDrawerNewKey,
                    tooltip: 'New session',
                    icon: const Icon(Icons.add),
                    onPressed: () => unawaited(
                      _run(() => ref.read(sessionActionsProvider).newSession()),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search sessions...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            if (actionError != null)
              _ErrorBanner(
                key: ValueKey<String>('action_$_errorSeq'),
                message: actionError,
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(sessionListProvider);
                  ref.invalidate(activeSessionListProvider);
                  // Await the refreshed futures so the spinner persists until both settle.
                  // Swallow errors (providers already surface them via AsyncValue in the UI).
                  try {
                    await Future.wait<void>(<Future<void>>[
                      ref.read(sessionListProvider.future),
                      ref.read(activeSessionListProvider.future),
                    ]);
                  } on Object {
                    // Ignore: the lists handle errors in their AsyncValue.
                  }
                },
                child: ListView(
                  // RefreshIndicator needs an always-scrollable child to trigger on short lists.
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: <Widget>[
                    const _SectionHeader(title: 'Live'),
                    ..._liveTiles(live, active),
                    const _SectionHeader(title: 'History'),
                    ..._historyTiles(history, active),
                  ],
                ),
              ),
            ),
            const _GatewayVersionFooter(),
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
      AsyncData(:final value) => () {
        final query = _searchQuery.toLowerCase();
        final filtered = query.isEmpty
            ? value
            : value.where((s) {
                final title = s.title?.toLowerCase() ?? '';
                final preview = s.preview?.toLowerCase() ?? '';
                return title.contains(query) || preview.contains(query);
              }).toList();
        if (filtered.isEmpty) {
          return <Widget>[const _EmptyHint('No matching sessions')];
        }
        return <Widget>[
          for (final session in filtered) _liveTile(session, active),
        ];
      }(),
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
          : _rowMenu(
              liveId: session.liveId,
              durableId: null,
              currentTitle: title ?? '',
            ),
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
      AsyncData(:final value) => () {
        final query = _searchQuery.toLowerCase();
        final filtered = query.isEmpty
            ? value
            : value.where((s) {
                final title = s.title.toLowerCase();
                final preview = s.preview.toLowerCase();
                return title.contains(query) || preview.contains(query);
              }).toList();
        if (filtered.isEmpty) {
          return <Widget>[const _EmptyHint('No matching sessions')];
        }
        return <Widget>[
          for (final summary in filtered)
            () {
              final isActive =
                  summary.durableId == active.durableId &&
                  active.durableId != null;
              return ListTile(
                key: sessionDrawerHistoryKey(summary.durableId),
                selected: isActive,
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
                trailing: _rowMenu(
                  liveId: isActive ? active.liveId : null,
                  durableId: summary.durableId,
                  currentTitle: summary.title,
                ),
                onTap: () => unawaited(
                  _run(
                    () => ref
                        .read(sessionActionsProvider)
                        .switchToSummary(summary),
                  ),
                ),
              );
            }(),
        ];
      }(),
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

/// Muted 'Gateway vX.Y.Z' footer (ticket P1-16): the gateway status is
/// recorded on a successful connect; nothing renders while it is unknown.
class _GatewayVersionFooter extends ConsumerWidget {
  const _GatewayVersionFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(gatewayStatusProvider)?.version;
    if (version == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        'Gateway v$version',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
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
