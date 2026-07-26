/// App routing (go_router). Phase 0 wires /connect; Phase 1 lands the real
/// chat screen (P1-07) which bootstraps a session on arrival (P1-09).
/// Ticket P9-02 adds deep links (/session/:id, /plugins/kanban/:board) with
/// connection guards and a not-found screen.
library;

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/core/router/pending_deep_link_provider.dart';
import 'package:flit/presentation/chat/chat_screen.dart';
import 'package:flit/presentation/common/not_found_screen.dart';
import 'package:flit/presentation/connect/connect_screen.dart';
import 'package:flit/presentation/plugins/kanban/kanban_board_screen.dart';
import 'package:flit/presentation/plugins/kanban/kanban_deep_link_screen.dart';
import 'package:flit/presentation/plugins/plugins_screen.dart';
import 'package:flit/presentation/sessions/session_deep_link_screen.dart';
import 'package:flit/presentation/settings/about_screen.dart';
import 'package:flit/presentation/settings/agent_settings_screen.dart';
import 'package:flit/presentation/settings/appearance_screen.dart';
import 'package:flit/presentation/settings/background_screen.dart';
import 'package:flit/presentation/settings/billing_screen.dart';
import 'package:flit/presentation/settings/browser_screen.dart';
import 'package:flit/presentation/settings/checkpoints_screen.dart';
import 'package:flit/presentation/settings/config_editor_screen.dart';
import 'package:flit/presentation/settings/cron_screen.dart';
import 'package:flit/presentation/settings/health_screen.dart';
import 'package:flit/presentation/settings/insights_screen.dart';
import 'package:flit/presentation/settings/journey_screen.dart';
import 'package:flit/presentation/settings/kanban_boards_screen.dart';
import 'package:flit/presentation/settings/kanban_fleet_screen.dart';
import 'package:flit/presentation/settings/kanban_orchestration_screen.dart';
import 'package:flit/presentation/settings/mcp_screen.dart';
import 'package:flit/presentation/settings/notifications_screen.dart';
import 'package:flit/presentation/settings/processes_screen.dart';
import 'package:flit/presentation/settings/project_facts_screen.dart';
import 'package:flit/presentation/settings/projects_screen.dart';
import 'package:flit/presentation/settings/provider_keys_screen.dart';
import 'package:flit/presentation/settings/settings_screen.dart';
import 'package:flit/presentation/settings/skills_screen.dart';
import 'package:flit/presentation/settings/tools_screen.dart';
import 'package:flit/presentation/subagents/delegation_screen.dart';
import 'package:flit/presentation/subagents/spawn_tree_snapshots_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/connect',
    redirect: (context, state) => _guardConnection(ref, state),
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: <RouteBase>[
      GoRoute(
        path: '/connect',
        name: 'connect',
        builder: (context, state) => const ConnectScreen(),
      ),
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: '/session/:id',
        name: 'session-deep-link',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return SessionDeepLinkScreen(durableId: id);
        },
      ),
      GoRoute(
        path: '/plugins',
        name: 'plugins',
        builder: (context, state) => const PluginsScreen(),
      ),
      GoRoute(
        path: '/plugins/kanban',
        name: 'kanban',
        builder: (context, state) => const KanbanBoardScreen(),
      ),
      GoRoute(
        path: '/plugins/kanban/:board',
        name: 'kanban-board-deep-link',
        builder: (context, state) {
          final board = state.pathParameters['board'] ?? '';
          return KanbanDeepLinkScreen(boardSlug: board);
        },
      ),
      GoRoute(
        path: '/agents',
        name: 'agents',
        builder: (context, state) => const DelegationScreen(),
      ),
      GoRoute(
        path: '/agents/snapshots',
        name: 'snapshots',
        builder: (context, state) => const SpawnTreeSnapshotsScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/providers',
        name: 'settings-providers',
        builder: (context, state) => const ProviderKeysScreen(),
      ),
      GoRoute(
        path: '/settings/agent',
        name: 'settings-agent',
        builder: (context, state) => const AgentSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/tools',
        name: 'settings-tools',
        builder: (context, state) => const ToolsScreen(),
      ),
      GoRoute(
        path: '/settings/mcp',
        name: 'settings-mcp',
        builder: (context, state) => const McpScreen(),
      ),
      GoRoute(
        path: '/settings/config',
        name: 'settings-config',
        builder: (context, state) => const ConfigEditorScreen(),
      ),
      GoRoute(
        path: '/settings/health',
        name: 'settings-health',
        builder: (context, state) => const HealthScreen(),
      ),
      GoRoute(
        path: '/settings/projects',
        name: 'settings-projects',
        builder: (context, state) => const ProjectsScreen(),
      ),
      GoRoute(
        path: '/settings/cron',
        name: 'settings-cron',
        builder: (context, state) => const CronScreen(),
      ),
      GoRoute(
        path: '/settings/background',
        name: 'settings-background',
        builder: (context, state) => const BackgroundScreen(),
      ),
      GoRoute(
        path: '/settings/processes',
        name: 'settings-processes',
        builder: (context, state) => const ProcessesScreen(),
      ),
      GoRoute(
        path: '/settings/skills',
        name: 'settings-skills',
        builder: (context, state) => const SkillsScreen(),
      ),
      GoRoute(
        path: '/settings/boards',
        name: 'settings-boards',
        builder: (context, state) => const KanbanBoardsScreen(),
      ),
      GoRoute(
        path: '/settings/fleet',
        name: 'settings-fleet',
        builder: (context, state) => const KanbanFleetScreen(),
      ),
      GoRoute(
        path: '/settings/orchestration',
        name: 'settings-orchestration',
        builder: (context, state) => const KanbanOrchestrationScreen(),
      ),
      GoRoute(
        path: '/settings/journey',
        name: 'settings-journey',
        builder: (context, state) => const JourneyScreen(),
      ),
      GoRoute(
        path: '/settings/insights',
        name: 'settings-insights',
        builder: (context, state) => const InsightsScreen(),
      ),
      GoRoute(
        path: '/settings/facts',
        name: 'settings-facts',
        builder: (context, state) => const ProjectFactsScreen(),
      ),
      GoRoute(
        path: '/settings/checkpoints',
        name: 'settings-checkpoints',
        builder: (context, state) => const CheckpointsScreen(),
      ),
      GoRoute(
        path: '/settings/billing',
        name: 'settings-billing',
        builder: (context, state) => const BillingScreen(),
      ),
      GoRoute(
        path: '/settings/appearance',
        name: 'settings-appearance',
        builder: (context, state) => const AppearanceScreen(),
      ),
      GoRoute(
        path: '/settings/notifications',
        name: 'settings-notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings/browser',
        name: 'settings-browser',
        builder: (context, state) => const BrowserScreen(),
      ),
      GoRoute(
        path: '/settings/about',
        name: 'settings-about',
        builder: (context, state) => const AboutScreen(),
      ),
    ],
  );
});

/// Connection guard (ticket P9-02): deep links that need a gateway connection
/// redirect to `/connect` when [connectionConfigProvider] has no config, and
/// the original location is stored in [pendingDeepLinkProvider] so the connect
/// flow can resume it after a successful connection.
///
/// Returns the redirect location (non-null) or null when no redirect is needed.
String? _guardConnection(Ref ref, GoRouterState state) {
  final location = state.uri.toString();
  if (!deepLinkNeedsConnection(location)) {
    return null;
  }

  // Null config = not connected.
  if (ref.read(connectionConfigProvider) != null) {
    return null;
  }

  // No connection — store the pending location and redirect to /connect.
  ref.read(pendingDeepLinkProvider.notifier).setPending(location);
  return '/connect';
}

/// Whether [location] may only be shown with a live gateway connection —
/// the pure half of [_guardConnection], split out so it is unit-testable
/// without a router or a provider container (ticket P9-02).
///
/// `/connect` itself always passes: guarding it would loop.
bool deepLinkNeedsConnection(String location) {
  if (location.startsWith('/connect')) {
    return false;
  }
  return location.startsWith('/session/') ||
      location.startsWith('/chat') ||
      location.startsWith('/plugins') ||
      location.startsWith('/agents') ||
      location.startsWith('/settings');
}
