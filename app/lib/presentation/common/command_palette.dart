/// Command palette overlay (P9-04): fuzzy-filtered launcher for navigation,
/// sessions, models, and slash commands.
library;

import 'package:flit/application/chat/composer_prefill.dart';
import 'package:flit/application/models/model_providers.dart';
import 'package:flit/application/palette/palette_providers.dart';
import 'package:flit/application/sessions/session_list.dart';
import 'package:flit/domain/models/model_option.dart';
import 'package:flit/domain/models/session_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Show the command palette as a dialog overlay.
Future<void> showCommandPalette(BuildContext context) async {
  if (!context.mounted) {
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (context) => const _CommandPaletteDialog(),
  );
}

class _CommandPaletteDialog extends ConsumerStatefulWidget {
  const _CommandPaletteDialog();

  @override
  ConsumerState<_CommandPaletteDialog> createState() =>
      _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends ConsumerState<_CommandPaletteDialog> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    // Request focus after the dialog renders.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    ref.read(paletteQueryProvider.notifier).setQuery(_textController.text);
    setState(() {
      _selectedIndex = 0; // Reset selection on query change.
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return;
    }
    final commands = ref.read(filteredPaletteCommandsProvider);
    if (commands.isEmpty) {
      return;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % commands.length;
      });
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedIndex =
            (_selectedIndex - 1 + commands.length) % commands.length;
      });
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      _activateCommand(commands[_selectedIndex]);
    }
  }

  Future<void> _activateCommand(PaletteCommand command) async {
    // Close the palette FIRST.
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();

    // THEN dispatch the intent.
    switch (command) {
      case PaletteNavigate(:final route):
        if (mounted) {
          context.go(route);
        }
      case PaletteSwitchSession(:final durableId):
        final sessions = ref.read(sessionListProvider).value;
        if (sessions != null) {
          final summary = sessions.firstWhere(
            (s) => s.durableId == durableId,
            orElse: () => SessionSummary(
              durableId: durableId,
              title: '',
              preview: '',
              messageCount: 0,
            ),
          );
          await ref.read(sessionActionsProvider).switchToSummary(summary);
        }
      case PaletteSelectModel(:final providerSlug, :final model):
        await ref
            .read(modelPickerControllerProvider.notifier)
            .select(ModelOption(providerSlug: providerSlug, model: model));
      case PalettePrefillSlash(:final command):
        if (mounted) {
          ref.read(composerPrefillProvider.notifier).prefill('$command ');
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final commands = ref.watch(filteredPaletteCommandsProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
        child: KeyboardListener(
          focusNode: _focusNode,
          onKeyEvent: _handleKeyEvent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Search field
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Search commands...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  autofocus: true,
                ),
              ),
              const Divider(height: 1),
              // Command list
              Expanded(
                child: commands.isEmpty
                    ? Center(
                        child: Text(
                          'No commands match',
                          style: textTheme.bodyMedium?.copyWith(
                            color: scheme.outline,
                          ),
                        ),
                      )
                    : _buildCommandList(commands, scheme, textTheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommandList(
    List<PaletteCommand> commands,
    ColorScheme scheme,
    TextTheme textTheme,
  ) {
    // Group by section.
    final sections = <String, List<PaletteCommand>>{};
    for (final command in commands) {
      sections
          .putIfAbsent(command.section, () => <PaletteCommand>[])
          .add(command);
    }

    return ListView.builder(
      itemCount: commands.length + sections.length,
      itemBuilder: (context, index) {
        var flatIndex = 0;
        for (final section in sections.keys) {
          if (index == flatIndex) {
            // Section header
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                section,
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }
          flatIndex++;
          final sectionCommands = sections[section]!;
          if (index < flatIndex + sectionCommands.length) {
            final commandIndex = index - flatIndex;
            final command = sectionCommands[commandIndex];
            final globalIndex = commands.indexOf(command);
            final isSelected = globalIndex == _selectedIndex;
            return _CommandTile(
              command: command,
              isSelected: isSelected,
              onTap: () => _activateCommand(command),
              onHover: () => setState(() {
                _selectedIndex = globalIndex;
              }),
            );
          }
          flatIndex += sectionCommands.length;
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _CommandTile extends StatelessWidget {
  const _CommandTile({
    required this.command,
    required this.isSelected,
    required this.onTap,
    required this.onHover,
  });

  final PaletteCommand command;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onHover;

  IconData _iconForCommand(PaletteCommand cmd) {
    return switch (cmd) {
      PaletteNavigate(:final route) => switch (route) {
        '/chat' => Icons.chat,
        '/plugins' => Icons.extension,
        '/plugins/kanban' => Icons.view_kanban,
        '/agents' => Icons.account_tree,
        '/agents/snapshots' => Icons.camera_alt,
        '/settings' => Icons.settings,
        _ => Icons.arrow_forward,
      },
      PaletteSwitchSession() => Icons.history,
      PaletteSelectModel() => Icons.model_training,
      PalettePrefillSlash() => Icons.terminal,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => onHover(),
      child: Material(
        color: isSelected ? scheme.surfaceContainerHighest : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: <Widget>[
                Icon(
                  _iconForCommand(command),
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        command.label,
                        style: textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (command.subtitle != null)
                        Text(
                          command.subtitle!,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
