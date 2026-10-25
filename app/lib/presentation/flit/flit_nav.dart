/// Getting between projects and sessions without backing out of a session.
/// Wide windows get [FlitShell]'s persistent side pane listing projects and
/// their sessions; narrow ones get [FlitBreadcrumb] (Project › Session) in
/// the session's app bar, whose project part goes back to that project.
library;

import 'package:flit/application/flit/flit_cron.dart';
import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/presentation/flit/flit_crons.dart';
import 'package:flit/presentation/flit/flit_projects.dart';
import 'package:flit/presentation/flit/flit_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Windows at least this wide show the side pane instead of the breadcrumb.
const double flitWideLayoutWidth = 840;

/// Whether this window is wide enough for the side pane.
bool flitIsWide(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= flitWideLayoutWidth;

/// The breadcrumb's project part.
const Key flitBreadcrumbProjectKey = Key('flit_breadcrumb_project');

/// Wraps the flit screens: on wide windows puts the side pane to the left
/// of [child]; on narrow ones it is just [child].
class FlitShell extends StatelessWidget {
  const FlitShell({required this.child, this.sessionId, super.key});

  final Widget child;

  /// The open session, highlighted in the pane.
  final String? sessionId;

  @override
  Widget build(BuildContext context) {
    if (!flitIsWide(context)) {
      return child;
    }
    return Row(
      children: <Widget>[
        SizedBox(width: 300, child: FlitNavPane(sessionId: sessionId)),
        const VerticalDivider(width: 1),
        Expanded(child: child),
      ],
    );
  }
}

/// Projects, each with its sessions, newest first. Tapping a project shows
/// its session list; tapping a session opens it.
class FlitNavPane extends ConsumerWidget {
  const FlitNavPane({this.sessionId, super.key});

  final String? sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects =
        ref.watch(flitProjectsProvider).value ?? const <FlitProject>[];
    final sessions =
        ref.watch(flitAllSessionsProvider).value ?? const <FlitSession>[];
    final selectedProject = ref.watch(flitSelectedProjectProvider);
    final byProject = <String, List<FlitSession>>{};
    String? openProject;
    for (final s in sessions) {
      (byProject[s.projectId] ??= <FlitSession>[]).add(s);
      if (s.id == sessionId) {
        openProject = s.projectId;
      }
    }
    final scheme = Theme.of(context).colorScheme;

    void openProjectList(String projectId) {
      ref.read(flitSelectedProjectProvider.notifier).select(projectId);
      context.go('/flit');
    }

    return Material(
      color: scheme.surfaceContainerLow,
      child: SafeArea(
        right: false,
        child: ListView(
          children: <Widget>[
            ListTile(
              title: Text(
                'Projects',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              trailing: IconButton(
                tooltip: 'Refresh',
                onPressed: () => ref
                  ..invalidate(flitProjectsProvider)
                  ..invalidate(flitAllSessionsProvider)
                  ..invalidate(flitCronJobsProvider),
                icon: const Icon(Icons.refresh),
              ),
            ),
            for (final p in projects)
              ExpansionTile(
                // Re-key on the open session so its project opens when
                // another one is picked.
                key: PageStorageKey<String>('flit_nav_${p.id}_$openProject'),
                initiallyExpanded:
                    p.id == openProject ||
                    (sessionId == null && p.id == selectedProject),
                leading: const Icon(Icons.folder_outlined),
                // Right-click or long-press anywhere on the title row opens
                // the project's context menu; tapping the name opens its
                // session list (elsewhere on the row expands it).
                title: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onSecondaryTapUp: (d) => showFlitProjectMenu(
                    context,
                    ref,
                    p,
                    position: d.globalPosition,
                    sessions: byProject[p.id] ?? const <FlitSession>[],
                  ),
                  onLongPressStart: (d) => showFlitProjectMenu(
                    context,
                    ref,
                    p,
                    position: d.globalPosition,
                    sessions: byProject[p.id] ?? const <FlitSession>[],
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: GestureDetector(
                      onTap: () => openProjectList(p.id),
                      child: Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight:
                              sessionId == null && p.id == selectedProject
                              ? FontWeight.bold
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                children: <Widget>[
                  for (final s in byProject[p.id] ?? const <FlitSession>[])
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.only(
                        left: 32,
                        right: 12,
                      ),
                      selected: s.id == sessionId,
                      title: Text(
                        s.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (s.isCronRun) ...<Widget>[
                            FlitCronBadge(job: s.cronJob),
                            const SizedBox(width: 4),
                          ],
                          FlitTaskStateChip(state: s.state, compact: true),
                        ],
                      ),
                      onTap: () => context.go('/flit/session/${s.id}'),
                    ),
                  if ((byProject[p.id] ?? const <FlitSession>[]).isEmpty)
                    const ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.only(left: 32),
                      title: Text('No sessions'),
                    ),
                ],
              ),
            const FlitCronSection(),
          ],
        ),
      ),
    );
  }
}

/// "Project › Session" for a session's app bar on narrow windows. The
/// project part goes back to that project's session list.
class FlitBreadcrumb extends ConsumerWidget {
  const FlitBreadcrumb({required this.session, super.key});

  final FlitSession? session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = session;
    final title = Text(
      s?.displayTitle ?? 'Session',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (s == null || s.projectId.isEmpty) {
      return title;
    }
    String? projectName;
    for (final p
        in ref.watch(flitProjectsProvider).value ?? const <FlitProject>[]) {
      if (p.id == s.projectId) {
        projectName = p.name;
      }
    }
    if (projectName == null) {
      return title;
    }
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Flexible(
          child: InkWell(
            key: flitBreadcrumbProjectKey,
            borderRadius: BorderRadius.circular(4),
            onTap: () {
              ref
                  .read(flitSelectedProjectProvider.notifier)
                  .select(s.projectId);
              final router = GoRouter.maybeOf(context);
              if (router == null) {
                Navigator.of(context).maybePop();
              } else if (router.canPop()) {
                router.pop();
              } else {
                router.go('/flit');
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                projectName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.chevron_right, size: 20),
        ),
        Flexible(flex: 2, child: title),
      ],
    );
  }
}
