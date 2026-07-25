/// Settings hub (Phase 4): a single entry point linking to the config,
/// tools, and workspace surfaces. Each row navigates to a sub-page owned by
/// its feature ticket (P4-01…08). Reached from the chat app bar.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The Settings landing screen: a grouped list of the Phase 4 surfaces.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          children: const <Widget>[
            _SectionHeader('Models & providers'),
            _SettingsTile(
              icon: Icons.key_outlined,
              title: 'Provider keys',
              subtitle: 'Add or remove provider API keys',
              route: '/settings/providers',
            ),
            _SettingsTile(
              icon: Icons.tune_outlined,
              title: 'Agent',
              subtitle: 'Reasoning effort, fast mode, persona & prompt',
              route: '/settings/agent',
            ),
            _SectionHeader('Tools & MCP'),
            _SettingsTile(
              icon: Icons.build_outlined,
              title: 'Tools',
              subtitle: 'Browse and enable tools & toolsets',
              route: '/settings/tools',
            ),
            _SettingsTile(
              icon: Icons.cable_outlined,
              title: 'MCP & environment',
              subtitle: 'Reload MCP servers and environment',
              route: '/settings/mcp',
            ),
            _SettingsTile(
              icon: Icons.auto_awesome_outlined,
              title: 'Skills',
              subtitle: 'Browse and manage installed skills',
              route: '/settings/skills',
            ),
            _SectionHeader('Automation'),
            _SettingsTile(
              icon: Icons.schedule_outlined,
              title: 'Scheduled jobs',
              subtitle: 'Cron jobs: add, pause & remove',
              route: '/settings/cron',
            ),
            _SettingsTile(
              icon: Icons.play_circle_outline,
              title: 'Background tasks',
              subtitle: 'Fire detached runs and watch completions',
              route: '/settings/background',
            ),
            _SettingsTile(
              icon: Icons.memory_outlined,
              title: 'Processes',
              subtitle: 'Background processes and shell exec',
              route: '/settings/processes',
            ),
            _SectionHeader('Kanban & fleet'),
            _SettingsTile(
              icon: Icons.dashboard_outlined,
              title: 'Boards',
              subtitle: 'Kanban boards and stats',
              route: '/settings/boards',
            ),
            _SettingsTile(
              icon: Icons.groups_outlined,
              title: 'Fleet',
              subtitle: 'Workers, diagnostics & dispatch',
              route: '/settings/fleet',
            ),
            _SettingsTile(
              icon: Icons.account_tree_outlined,
              title: 'Orchestration',
              subtitle: 'Assignees, profiles & orchestration',
              route: '/settings/orchestration',
            ),
            _SectionHeader('Configuration'),
            _SettingsTile(
              icon: Icons.settings_outlined,
              title: 'Config editor',
              subtitle: 'View and edit gateway config keys',
              route: '/settings/config',
            ),
            _SettingsTile(
              icon: Icons.health_and_safety_outlined,
              title: 'Health',
              subtitle: 'Setup, runtime & verification status',
              route: '/settings/health',
            ),
            _SectionHeader('Workspaces'),
            _SettingsTile(
              icon: Icons.folder_outlined,
              title: 'Projects',
              subtitle: 'Switch and manage project workspaces',
              route: '/settings/projects',
            ),
            _SettingsTile(
              icon: Icons.fact_check_outlined,
              title: 'Project facts',
              subtitle: 'Manifests, package manager & verify commands',
              route: '/settings/facts',
            ),
            _SectionHeader('Memory & learning'),
            _SettingsTile(
              icon: Icons.timeline_outlined,
              title: 'Learning journey',
              subtitle: 'Skills learned & memories curated over time',
              route: '/settings/journey',
            ),
            _SettingsTile(
              icon: Icons.insights_outlined,
              title: 'Insights',
              subtitle: 'Session & message activity over a window',
              route: '/settings/insights',
            ),
            _SectionHeader('History'),
            _SettingsTile(
              icon: Icons.history_outlined,
              title: 'Checkpoints',
              subtitle: 'Diff & restore git checkpoints for this session',
              route: '/settings/checkpoints',
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(route),
    );
  }
}
