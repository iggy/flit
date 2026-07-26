import 'package:flit/application/projects/project_facts_providers.dart';
import 'package:flit/application/projects/projects_providers.dart';
import 'package:flit/domain/models/project_facts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Project facts screen (ticket P6-04): detected manifests, package managers,
/// verify commands, and context files for the active project's primary path.
class ProjectFactsScreen extends ConsumerWidget {
  const ProjectFactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsList = ref.watch(projectsListProvider);
    final cwd = projectsList.whenOrNull(
      data: (data) {
        final activeId = data.activeId;
        if (activeId == null) {
          return null;
        }
        final project = data.projects
            .where((p) => p.id == activeId)
            .firstOrNull;
        return project?.primaryPath;
      },
    );
    final facts = ref.watch(projectFactsProvider(cwd));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project facts'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(projectFactsProvider(cwd)),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: facts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ProjectFactsError(
          message: error.toString(),
          onRetry: () => ref.invalidate(projectFactsProvider(cwd)),
        ),
        data: (data) {
          if (data == null) {
            return const _ProjectFactsEmpty();
          }
          return _ProjectFactsContent(facts: data);
        },
      ),
    );
  }
}

class _ProjectFactsContent extends StatelessWidget {
  const _ProjectFactsContent({required this.facts});

  final ProjectFacts facts;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _SectionHeader(title: 'Root'),
        SelectableText(
          facts.root,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
        ),
        const SizedBox(height: 16),
        if (facts.manifests.isNotEmpty) ...<Widget>[
          _SectionHeader(title: 'Manifests'),
          _ChipList(items: facts.manifests),
          const SizedBox(height: 16),
        ],
        if (facts.packageManagers.isNotEmpty) ...<Widget>[
          _SectionHeader(title: 'Package managers'),
          _ChipList(items: facts.packageManagers),
          const SizedBox(height: 16),
        ],
        if (facts.verifyCommands.isNotEmpty) ...<Widget>[
          _SectionHeader(title: 'Verify commands'),
          _CommandList(commands: facts.verifyCommands),
          const SizedBox(height: 16),
        ],
        if (facts.contextFiles.isNotEmpty) ...<Widget>[
          _SectionHeader(title: 'Context files'),
          _ChipList(items: facts.contextFiles),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _ChipList extends StatelessWidget {
  const _ChipList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) => Chip(label: Text(item))).toList(),
    );
  }
}

class _CommandList extends StatelessWidget {
  const _CommandList({required this.commands});

  final List<String> commands;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: commands
          .map(
            (cmd) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    cmd,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ProjectFactsEmpty extends StatelessWidget {
  const _ProjectFactsEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('No project facts (not a code workspace).'),
    );
  }
}

class _ProjectFactsError extends StatelessWidget {
  const _ProjectFactsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.error_outline),
          const SizedBox(height: 8),
          Text(
            'Could not load project facts',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(message, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
