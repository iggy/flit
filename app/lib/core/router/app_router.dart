/// App routing (go_router). Phase 0 wires /connect; Phase 1 lands the real
/// chat screen (P1-07) which bootstraps a session on arrival (P1-09).
library;

import 'package:flit/presentation/chat/chat_screen.dart';
import 'package:flit/presentation/connect/connect_screen.dart';
import 'package:flit/presentation/plugins/kanban/kanban_board_screen.dart';
import 'package:flit/presentation/plugins/plugins_screen.dart';
import 'package:flit/presentation/settings/agent_settings_screen.dart';
import 'package:flit/presentation/settings/background_screen.dart';
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
    ],
  );
});
