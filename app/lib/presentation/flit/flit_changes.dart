/// A flit session's git changes: the header chip (branch, changed files,
/// ahead/behind) and the Changes screen (file list and per-file diffs).
library;

import 'dart:async';

import 'package:flit/application/flit/flit_git.dart';
import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/flit_git.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The session header's git chip.
const Key flitGitChipKey = Key('flit_git_chip');

/// The Changes screen's "Remove worktree" button, and its confirm button.
const Key flitRemoveWorktreeKey = Key('flit_remove_worktree');
const Key flitRemoveWorktreeConfirmKey = Key('flit_remove_worktree_confirm');

/// Width from which the Changes screen shows the list and a diff side by
/// side.
const double flitChangesWideWidth = 840;

/// Branch, changed-file count and ahead/behind of the session's repository;
/// nothing when the session isn't in one. Opens the Changes screen.
class FlitGitChip extends ConsumerWidget {
  const FlitGitChip({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(flitGitStatusProvider(sessionId)).value;
    if (status == null || !status.isRepo) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final n = status.files.length;
    final parts = <String>[
      status.branchLabel.isEmpty ? 'no commits' : status.branchLabel,
      if (n > 0)
        '$n ${n == 1 ? 'file' : 'files'}${status.filesTruncated ? '+' : ''}',
      if (status.upstream.isNotEmpty && (status.ahead > 0 || status.behind > 0))
        <String>[
          if (status.ahead > 0) '↑${status.ahead}',
          if (status.behind > 0) '↓${status.behind}',
        ].join(' '),
    ];
    return Tooltip(
      message: n == 0 ? 'No changes this session' : 'Show changes',
      child: InkWell(
        key: flitGitChipKey,
        borderRadius: BorderRadius.circular(8),
        onTap: () =>
            unawaited(context.push('/flit/session/$sessionId/changes')),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                status.detached ? Icons.commit : Icons.call_split,
                size: 14,
                color: style?.color,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  parts.join(' · '),
                  style: style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The files changed since the session's base, and their diffs.
class FlitChangesScreen extends ConsumerStatefulWidget {
  const FlitChangesScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  ConsumerState<FlitChangesScreen> createState() => _FlitChangesScreenState();
}

class _FlitChangesScreenState extends ConsumerState<FlitChangesScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(flitGitStatusProvider(widget.sessionId));
    final session = ref.watch(flitSessionProvider(widget.sessionId)).value;
    final wide = MediaQuery.sizeOf(context).width >= flitChangesWideWidth;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Changes'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => unawaited(
              ref
                  .read(flitGitStatusProvider(widget.sessionId).notifier)
                  .refresh(),
            ),
            icon: const Icon(Icons.refresh),
          ),
          if (session != null &&
              session.hasWorktree &&
              !session.worktreeRemoved)
            IconButton(
              key: flitRemoveWorktreeKey,
              tooltip: 'Remove worktree',
              onPressed: () => unawaited(_removeWorktree(session)),
              icon: const Icon(Icons.folder_delete_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: switch (async) {
          AsyncValue(:final value?)
              when !value.isRepo && (session?.worktreeRemoved ?? false) =>
            Center(
              child: Text(
                "This session's worktree was removed. Its commits are on "
                'branch ${session?.worktreeBranch} if it had any of its own.',
                textAlign: TextAlign.center,
              ),
            ),
          AsyncValue(:final value?) when !value.isRepo => const Center(
            child: Text("This session's directory isn't in a git repository."),
          ),
          AsyncValue(:final value?) => _body(value, wide: wide),
          AsyncValue(:final error?) => Center(
            child: Text('Could not read the repository: $error'),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }

  Future<void> _removeWorktree(FlitSession session) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove the worktree?'),
        content: Text(
          'Deletes ${session.worktreePath}. No history is lost: the branch '
          '${session.worktreeBranch} stays if it has commits found nowhere '
          'else. flit refuses while there are uncommitted changes. The '
          "session can't run turns afterwards.",
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: flitRemoveWorktreeConfirmKey,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    final repository = ref.read(flitRepositoryProvider);
    if (ok != true || repository == null) {
      return;
    }
    String message;
    try {
      final r = await repository.removeWorktree(widget.sessionId);
      message = r.branchKept
          ? 'Worktree removed. Branch ${r.branch} keeps '
                '${r.commits} ${r.commits == 1 ? 'commit' : 'commits'}.'
          : 'Worktree and branch ${r.branch} removed; nothing was only there.';
      ref.invalidate(flitSessionProvider(widget.sessionId));
      await ref
          .read(flitGitStatusProvider(widget.sessionId).notifier)
          .refresh();
    } on GatewayException catch (error) {
      message = 'Could not remove it: ${error.message}';
    }
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Widget _body(FlitGitStatus status, {required bool wide}) {
    final selected = status.files.any((f) => f.path == _selected)
        ? _selected
        : (wide && status.files.isNotEmpty ? status.files.first.path : null);
    final list = _FileList(
      status: status,
      selected: wide ? selected : null,
      onTap: (f) {
        if (wide) {
          setState(() => _selected = f.path);
          return;
        }
        unawaited(
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                appBar: AppBar(
                  title: Text(
                    f.path,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                body: SafeArea(
                  child: FlitDiffView(
                    sessionId: widget.sessionId,
                    path: f.path,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    if (!wide) {
      return list;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(width: 340, child: list),
        const VerticalDivider(width: 1),
        Expanded(
          child: selected == null
              ? const Center(child: Text('No changes.'))
              : FlitDiffView(
                  key: ValueKey<String>(selected),
                  sessionId: widget.sessionId,
                  path: selected,
                ),
        ),
      ],
    );
  }
}

/// What the diff compares against, in words.
String flitDiffBaseLabel(FlitDiffBase kind, String rev) {
  final short = rev.length > 7 ? rev.substring(0, 7) : rev;
  return switch (kind) {
    FlitDiffBase.sessionStart => 'Since the session started ($short)',
    FlitDiffBase.headNoBase =>
      'Since the last commit ($short): the session has no starting commit',
    FlitDiffBase.headBaseMissing =>
      "Since the last commit ($short): the session's starting commit is gone",
    FlitDiffBase.emptyTree => 'Everything: the repository has no commits yet',
    FlitDiffBase.unknown => '',
  };
}

class _FileList extends StatelessWidget {
  const _FileList({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final FlitGitStatus status;
  final String? selected;
  final void Function(FlitGitFile) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = flitDiffBaseLabel(status.diffBaseKind, status.diffBase);
    final upstream = status.upstream.isEmpty
        ? ''
        : ' · ${status.upstream} ↑${status.ahead} ↓${status.behind}';
    return ListView(
      children: <Widget>[
        ListTile(
          dense: true,
          leading: Icon(status.detached ? Icons.commit : Icons.call_split),
          title: Text(
            '${status.detached ? 'Detached at ' : ''}'
            '${status.branchLabel.isEmpty ? 'No commits yet' : status.branchLabel}'
            '$upstream',
          ),
          subtitle: base.isEmpty ? null : Text(base),
        ),
        const Divider(height: 1),
        if (status.files.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No changes.')),
          ),
        for (final f in status.files)
          ListTile(
            dense: true,
            selected: f.path == selected,
            onTap: () => onTap(f),
            leading: FlitFileStatusBadge(file: f),
            title: Text(f.path, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: f.oldPath.isEmpty && _where(f).isEmpty
                ? null
                : Text(
                    <String>[
                      if (f.oldPath.isNotEmpty) 'from ${f.oldPath}',
                      if (_where(f).isNotEmpty) _where(f),
                    ].join(' · '),
                  ),
            trailing: f.binary
                ? const Text('binary')
                : Text.rich(
                    TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: '+${f.additions}',
                          style: TextStyle(color: flitAddedColor(theme)),
                        ),
                        const TextSpan(text: ' '),
                        TextSpan(
                          text: '−${f.deletions}',
                          style: TextStyle(color: flitRemovedColor(theme)),
                        ),
                      ],
                    ),
                  ),
          ),
        if (status.filesTruncated)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('More files changed than can be listed.'),
          ),
      ],
    );
  }

  static String _where(FlitGitFile f) {
    if (f.untracked) {
      return 'untracked';
    }
    return <String>[
      if (f.staged) 'staged',
      if (f.unstaged) 'unstaged',
      if (!f.staged && !f.unstaged) 'committed',
    ].join(', ');
  }
}

Color flitAddedColor(ThemeData theme) => theme.brightness == Brightness.dark
    ? Colors.green.shade300
    : Colors.green.shade800;

Color flitRemovedColor(ThemeData theme) => theme.brightness == Brightness.dark
    ? Colors.red.shade300
    : Colors.red.shade800;

/// A one-letter badge for how a file changed (M, A, D, R, …).
class FlitFileStatusBadge extends StatelessWidget {
  const FlitFileStatusBadge({required this.file, super.key});

  final FlitGitFile file;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (letter, color, label) = switch (file.status) {
      FlitFileStatus.added => ('A', flitAddedColor(theme), 'added'),
      FlitFileStatus.deleted => ('D', flitRemovedColor(theme), 'deleted'),
      FlitFileStatus.renamed => ('R', theme.colorScheme.primary, 'renamed'),
      FlitFileStatus.copied => ('C', theme.colorScheme.primary, 'copied'),
      FlitFileStatus.typeChanged => (
        'T',
        theme.colorScheme.tertiary,
        'type changed',
      ),
      FlitFileStatus.unmerged => ('U', theme.colorScheme.error, 'conflicted'),
      FlitFileStatus.modified => ('M', theme.colorScheme.tertiary, 'modified'),
      FlitFileStatus.unknown => ('?', theme.colorScheme.outline, 'changed'),
    };
    return Tooltip(
      message: label,
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          letter,
          style: theme.textTheme.labelMedium?.copyWith(color: color),
        ),
      ),
    );
  }
}

const TextStyle _mono = TextStyle(
  fontFamily: 'monospace',
  fontFamilyFallback: <String>['Courier New', 'Courier', 'monospace'],
  fontSize: 12.5,
  height: 1.35,
);

/// One file's diff (or all of them, with an empty [path]) with added and
/// removed lines coloured. Long lines wrap, so it reads on a phone too.
class FlitDiffView extends ConsumerWidget {
  const FlitDiffView({required this.sessionId, required this.path, super.key});

  final String sessionId;
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(flitGitDiffProvider((sessionId, path)));
    return switch (async) {
      AsyncValue(:final value?) => _lines(context, value),
      AsyncValue(:final error?) => Center(
        child: Text('Could not load the diff: $error'),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  Widget _lines(BuildContext context, FlitGitDiff diff) {
    final lines = parseUnifiedDiff(diff.text);
    if (lines.isEmpty) {
      return const Center(child: Text('No differences.'));
    }
    final theme = Theme.of(context);
    final added = flitAddedColor(theme).withValues(alpha: 0.14);
    final removed = flitRemovedColor(theme).withValues(alpha: 0.14);
    final gutter = _mono.copyWith(color: theme.colorScheme.outline);
    final count = lines.length + (diff.truncated ? 1 : 0);
    return SelectionArea(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: count,
        itemBuilder: (context, i) {
          if (i == lines.length) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'The diff is too large to show in full.',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            );
          }
          final line = lines[i];
          final (bg, sign, fg) = switch (line.kind) {
            FlitDiffLineKind.added => (added, '+', null),
            FlitDiffLineKind.removed => (removed, '-', null),
            FlitDiffLineKind.context => (null, ' ', null),
            FlitDiffLineKind.hunk => (
              theme.colorScheme.surfaceContainerHighest,
              '',
              theme.colorScheme.primary,
            ),
            FlitDiffLineKind.header => (
              null,
              '',
              theme.colorScheme.onSurfaceVariant,
            ),
            FlitDiffLineKind.note => (null, '', theme.colorScheme.outline),
          };
          final numbered =
              line.kind == FlitDiffLineKind.added ||
              line.kind == FlitDiffLineKind.removed ||
              line.kind == FlitDiffLineKind.context;
          return ColoredBox(
            color: bg ?? Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (numbered) ...<Widget>[
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${line.oldLine ?? ''}',
                        style: gutter,
                        textAlign: TextAlign.right,
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${line.newLine ?? ''}',
                        style: gutter,
                        textAlign: TextAlign.right,
                      ),
                    ),
                    SizedBox(width: 16, child: Text(' $sign', style: _mono)),
                  ],
                  Expanded(
                    child: Text(
                      line.text,
                      style: fg == null ? _mono : _mono.copyWith(color: fg),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
