/// Slash command launcher modal (ticket P3-01).
library;

import 'package:flit/application/slash/slash_providers.dart';
import 'package:flit/domain/models/slash_command.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows a searchable command launcher modal; returns the selected command
/// or null if dismissed.
///
/// Catalog is grouped by category (when not searching) or filtered flat
/// (when searching). Selection prefills the composer with the command text
/// (P3-03 integration).
Future<SlashCommand?> showSlashLauncher(BuildContext context) {
  return showModalBottomSheet<SlashCommand>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _SlashLauncher(),
  );
}

class _SlashLauncher extends ConsumerStatefulWidget {
  const _SlashLauncher();

  @override
  ConsumerState<_SlashLauncher> createState() => _SlashLauncherState();
}

class _SlashLauncherState extends ConsumerState<_SlashLauncher> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _query = value.toLowerCase();
    });
  }

  void _onCommandSelected(SlashCommand command) {
    Navigator.pop(context, command);
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(slashCatalogProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                key: const Key('slash_launcher_search'),
                controller: _searchController,
                onChanged: _onSearchChanged,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search commands...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: catalogAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Text('Error loading catalog: $err'),
                ),
                data: (catalog) {
                  if (catalog == null) {
                    return const Center(
                      child: Text('Disconnected — no commands available.'),
                    );
                  }
                  return _buildCommandList(catalog, scrollController);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommandList(SlashCatalog catalog, ScrollController controller) {
    if (_query.isEmpty) {
      // Show categorized list.
      return ListView.builder(
        controller: controller,
        itemCount: catalog.categories.length,
        itemBuilder: (context, index) {
          final category = catalog.categories[index];
          return _buildCategory(category);
        },
      );
    } else {
      // Filter all commands by query (command text OR description).
      final filtered = catalog.allCommands.where((cmd) {
        return cmd.command.toLowerCase().contains(_query) ||
            cmd.description.toLowerCase().contains(_query);
      }).toList();

      if (filtered.isEmpty) {
        return Center(
          child: Text(
            'No commands match "$_query"',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        );
      }

      return ListView.builder(
        controller: controller,
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          return _buildCommandTile(filtered[index]);
        },
      );
    }
  }

  Widget _buildCategory(SlashCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            category.name,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...category.commands.map(_buildCommandTile),
      ],
    );
  }

  Widget _buildCommandTile(SlashCommand command) {
    return ListTile(
      leading: const Icon(Icons.terminal),
      title: Text(
        command.command,
        style: const TextStyle(fontFamily: 'monospace'),
      ),
      subtitle: Text(command.description),
      onTap: () => _onCommandSelected(command),
    );
  }
}
