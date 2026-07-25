/// App routing (go_router). Phase 0 wires /connect; Phase 1 lands the real
/// chat screen (P1-07) which bootstraps a session on arrival (P1-09).
library;

import 'package:flit/presentation/chat/chat_screen.dart';
import 'package:flit/presentation/connect/connect_screen.dart';
import 'package:flit/presentation/plugins/kanban/kanban_board_screen.dart';
import 'package:flit/presentation/plugins/plugins_screen.dart';
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
    ],
  );
});
