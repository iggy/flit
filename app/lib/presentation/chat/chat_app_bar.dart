/// The chat screen app bar, laid out for the width it actually has.
///
/// The bar carries a lot: connection state, model picker, profiles, session
/// info, command palette, slash commands, plugins, agents, settings and sign
/// out. On a phone in portrait that is far more than fits, and Material
/// silently clips the overflowing actions — they become untappable.
///
/// So the bar has two layouts:
/// - WIDE (tablet/desktop): every action inline, as before.
/// - COMPACT (phone portrait): the model picker becomes the title (it is the
///   one control that needs room for text), the connection chip stays, and
///   everything else moves into a single overflow menu.
///
/// The decision uses width divided by the user's text scale, so a large
/// accessibility font also gets the compact layout.
library;

import 'dart:async';

import 'package:flit/application/chat/composer_prefill.dart';
import 'package:flit/application/connection/connect_controller.dart';
import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/profiles/profile_providers.dart';
import 'package:flit/presentation/chat/slash_launcher.dart';
import 'package:flit/presentation/common/command_palette.dart';
import 'package:flit/presentation/common/connection_chip.dart';
import 'package:flit/presentation/models/model_picker_sheet.dart';
import 'package:flit/presentation/profiles/profile_menu.dart';
import 'package:flit/presentation/sessions/session_info_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Below this logical width (text-scale adjusted) the actions collapse into
/// an overflow menu. Measured against the widest inline layout: leading +
/// chip + model picker + eight icon buttons + a title.
const double kChatAppBarCompactWidth = 800;

/// Everything the compact overflow menu can do.
enum ChatMenuAction {
  sessionInfo,
  profiles,
  commandPalette,
  slashCommands,
  plugins,
  agents,
  settings,
  signOut,
}

class ChatAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ChatAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = MediaQuery.of(context);
    // A 2x accessibility font makes every label twice as wide, so treat the
    // bar as half as wide when deciding whether the inline layout fits.
    final textScale = media.textScaler.scale(16) / 16;
    final effectiveWidth = media.size.width / (textScale < 1 ? 1 : textScale);
    final compact = effectiveWidth < kChatAppBarCompactWidth;

    final connectionState = ref.watch(connectionStateProvider);
    final chip = Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Center(child: ConnectionChip(state: connectionState.value)),
    );

    if (compact) {
      // The model name is the useful title here; 'Hermes' is not. Leave room
      // for the drawer button, the chip and the overflow button.
      final labelWidth = (media.size.width - 220).clamp(96.0, 220.0);
      return AppBar(
        titleSpacing: 0,
        title: Align(
          alignment: Alignment.centerLeft,
          child: ModelPickerButton(maxLabelWidth: labelWidth),
        ),
        actions: <Widget>[chip, const ChatOverflowMenu()],
      );
    }

    return AppBar(
      title: const Text('Hermes'),
      actions: <Widget>[
        // Connection state first (P1-16): a dropped socket shows
        // 'Reconnecting' here while the client backs off and resumes.
        chip,
        const ModelPickerButton(),
        const ProfileMenuButton(),
        const SessionInfoButton(),
        IconButton(
          tooltip: 'Command Palette (Ctrl/Cmd+K)',
          icon: const Icon(Icons.search),
          onPressed: () async {
            await showCommandPalette(context);
          },
        ),
        IconButton(
          tooltip: 'Commands',
          icon: const Icon(Icons.terminal),
          onPressed: () => _openSlashLauncher(context, ref),
        ),
        IconButton(
          tooltip: 'Plugins',
          icon: const Icon(Icons.extension_outlined),
          onPressed: () => context.push('/plugins'),
        ),
        IconButton(
          tooltip: 'Agents',
          icon: const Icon(Icons.account_tree_outlined),
          onPressed: () => context.push('/agents'),
        ),
        IconButton(
          tooltip: 'Settings',
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.push('/settings'),
        ),
        IconButton(
          tooltip: 'Sign out',
          icon: const Icon(Icons.logout),
          onPressed: () => _signOut(context, ref),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

/// The compact-layout overflow menu: everything that does not fit inline.
class ChatOverflowMenu extends ConsumerWidget {
  const ChatOverflowMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Profiles degrade to a disabled row on gateways that do not serve them,
    // exactly like the inline button does (P1-13).
    final profilesUnavailable = ref.watch(profilesUnavailableProvider);
    return PopupMenuButton<ChatMenuAction>(
      tooltip: 'More',
      icon: const Icon(Icons.more_vert),
      onSelected: (action) => _onSelected(context, ref, action),
      itemBuilder: (context) => <PopupMenuEntry<ChatMenuAction>>[
        const PopupMenuItem<ChatMenuAction>(
          value: ChatMenuAction.sessionInfo,
          child: _MenuRow(icon: Icons.info_outline, label: 'Session info'),
        ),
        PopupMenuItem<ChatMenuAction>(
          value: ChatMenuAction.profiles,
          enabled: !profilesUnavailable,
          child: _MenuRow(
            icon: Icons.person_outline,
            label: profilesUnavailable
                ? 'Profiles unavailable on this gateway'
                : 'Profiles',
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<ChatMenuAction>(
          value: ChatMenuAction.commandPalette,
          child: _MenuRow(icon: Icons.search, label: 'Command palette'),
        ),
        const PopupMenuItem<ChatMenuAction>(
          value: ChatMenuAction.slashCommands,
          child: _MenuRow(icon: Icons.terminal, label: 'Commands'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<ChatMenuAction>(
          value: ChatMenuAction.plugins,
          child: _MenuRow(icon: Icons.extension_outlined, label: 'Plugins'),
        ),
        const PopupMenuItem<ChatMenuAction>(
          value: ChatMenuAction.agents,
          child: _MenuRow(icon: Icons.account_tree_outlined, label: 'Agents'),
        ),
        const PopupMenuItem<ChatMenuAction>(
          value: ChatMenuAction.settings,
          child: _MenuRow(icon: Icons.settings_outlined, label: 'Settings'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<ChatMenuAction>(
          value: ChatMenuAction.signOut,
          child: _MenuRow(icon: Icons.logout, label: 'Sign out'),
        ),
      ],
    );
  }

  Future<void> _onSelected(
    BuildContext context,
    WidgetRef ref,
    ChatMenuAction action,
  ) async {
    switch (action) {
      case ChatMenuAction.sessionInfo:
        await showSessionInfoSheet(context);
      case ChatMenuAction.profiles:
        await showProfileSheet(context);
      case ChatMenuAction.commandPalette:
        await showCommandPalette(context);
      case ChatMenuAction.slashCommands:
        await _openSlashLauncher(context, ref);
      case ChatMenuAction.plugins:
        unawaited(context.push('/plugins'));
      case ChatMenuAction.agents:
        unawaited(context.push('/agents'));
      case ChatMenuAction.settings:
        unawaited(context.push('/settings'));
      case ChatMenuAction.signOut:
        await _signOut(context, ref);
    }
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

Future<void> _openSlashLauncher(BuildContext context, WidgetRef ref) async {
  final command = await showSlashLauncher(context);
  if (command != null) {
    ref.read(composerPrefillProvider.notifier).prefill('${command.command} ');
  }
}

Future<void> _signOut(BuildContext context, WidgetRef ref) async {
  await ref.read(connectControllerProvider.notifier).signOut();
  if (context.mounted) {
    context.go('/connect');
  }
}
