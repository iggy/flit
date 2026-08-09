import 'dart:async';

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/application/profiles/profile_providers.dart';
import 'package:flit/domain/models/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Profiles dropdown for the chat app bar (ticket P1-13).
///
/// HONEST CAVEAT (P1-13 acceptance / docs/roadmap.md "profiles caveat"):
/// there is NO in-session profile-switch RPC. A profile is a whole
/// HERMES_HOME; `POST /api/profiles/active` sets the sticky pointer FUTURE
/// gateway launches read — it does NOT retarget the running gateway. The
/// menu says this plainly ('Active profile for new gateway launches') and
/// picking a profile shows a snackbar repeating it. Never imply a
/// hot-swap.
///
/// Degrade rule: when [profilesUnavailableProvider] is true (disconnected,
/// or `/api/profiles` failed — older gateways 404 it) the button renders
/// DISABLED with a tooltip; it never crashes and never spins forever.
///
/// The gateway-topology annotations ('live' tags, the multiplex note) come
/// from `/api/status` and are purely additive: the fields behind them are null
/// on pre-0.20 gateways and `gateways` is withheld in gated mode, so an
/// un-annotated row means "not told", never "not running".
class ProfileMenuButton extends ConsumerWidget {
  const ProfileMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(profilesUnavailableProvider)) {
      return const IconButton(
        tooltip: 'Profiles unavailable on this gateway',
        icon: Icon(Icons.person_outline),
        onPressed: null,
      );
    }

    final profiles = ref.watch(profilesProvider);
    final activeName = ref.watch(activeProfileProvider).value;
    // Gateway topology (0.20): which profiles a gateway is actually serving,
    // and whether one gateway multiplexes them. Both stay null on older
    // gateways, and `gateways` is withheld in gated mode — so this only ever
    // ADDS a note, never gates the menu.
    final status = ref.watch(gatewayStatusProvider);

    return PopupMenuButton<String>(
      tooltip: 'Profiles',
      icon: const Icon(Icons.person_outline),
      onSelected: (name) => _setActiveProfile(context, ref, name),
      itemBuilder: (context) => _buildItems(
        context,
        profiles,
        activeName,
        liveProfiles: status?.liveGatewayProfiles ?? const <String>{},
        multiplexed: status?.gatewayMode == 'multiplex',
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildItems(
    BuildContext context,
    AsyncValue<List<Profile>> profiles,
    String? activeName, {
    required Set<String> liveProfiles,
    required bool multiplexed,
  }) {
    final captionStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic);
    final items = <PopupMenuEntry<String>>[
      // The honest caveat, stated where the choice is made.
      PopupMenuItem<String>(
        enabled: false,
        child: Text(
          'Active profile for new gateway launches',
          style: captionStyle,
        ),
      ),
      if (multiplexed)
        PopupMenuItem<String>(
          enabled: false,
          child: Text(
            'One gateway is serving several profiles',
            style: captionStyle,
          ),
        ),
      const PopupMenuDivider(),
    ];

    final list = profiles.value;
    if (profiles.isLoading || list == null) {
      // Loading (or refetching): a subtle spinner in the menu — never a
      // forever-spinner at the button level (errors degrade to disabled).
      items.add(
        const PopupMenuItem<String>(
          enabled: false,
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Loading profiles…'),
            ],
          ),
        ),
      );
      return items;
    }

    for (final profile in list) {
      items.add(
        PopupMenuItem<String>(
          value: profile.name,
          child: _ProfileMenuEntry(
            profile: profile,
            isActive: profile.name == activeName,
            isLive: liveProfiles.contains(profile.name),
          ),
        ),
      );
    }
    return items;
  }
}

Future<void> _setActiveProfile(
  BuildContext context,
  WidgetRef ref,
  String name,
) async {
  // Capture before the async gap — the menu has popped by the time the
  // POST completes.
  final messenger = ScaffoldMessenger.of(context);
  final ok = await ref.read(profileActionsProvider).setActive(name);
  if (ok) {
    // The honest note (P1-13 acceptance): NEW launches only — the
    // running gateway is unchanged.
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Profile "$name" will be used for NEW gateway launches — '
          'the running gateway is unchanged.',
        ),
      ),
    );
  } else {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Could not update the active profile on this gateway.'),
      ),
    );
  }
}

/// The same profile choice as [ProfileMenuButton], as a bottom sheet — used
/// by narrow layouts where the app bar has no room for a dropdown of its own.
Future<void> showProfileSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => const _ProfileSheet(),
  );
}

class _ProfileSheet extends ConsumerWidget {
  const _ProfileSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profilesProvider);
    final activeName = ref.watch(activeProfileProvider).value;
    final status = ref.watch(gatewayStatusProvider);
    final liveProfiles = status?.liveGatewayProfiles ?? const <String>{};
    final theme = Theme.of(context).textTheme;
    final list = profiles.value;

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 12),
        children: <Widget>[
          ListTile(
            title: const Text('Profiles'),
            subtitle: Text(
              'Active profile for new gateway launches',
              style: theme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
          if (status?.gatewayMode == 'multiplex')
            ListTile(
              dense: true,
              title: Text(
                'One gateway is serving several profiles',
                style: theme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          const Divider(height: 1),
          if (profiles.isLoading || list == null)
            const ListTile(
              leading: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text('Loading profiles…'),
            )
          else
            for (final profile in list)
              ListTile(
                title: _ProfileMenuEntry(
                  profile: profile,
                  isActive: profile.name == activeName,
                  isLive: liveProfiles.contains(profile.name),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  unawaited(_setActiveProfile(context, ref, profile.name));
                },
              ),
        ],
      ),
    );
  }
}

/// One profile row: a check mark on the active profile, the name with a
/// '(default)' tag when [Profile.isDefault], the model when known, and a
/// 'live' tag when a gateway is currently serving the profile.
class _ProfileMenuEntry extends StatelessWidget {
  const _ProfileMenuEntry({
    required this.profile,
    required this.isActive,
    this.isLive = false,
  });

  final Profile profile;
  final bool isActive;

  /// Whether `/api/status` reported a live gateway serving this profile. Only
  /// ever true when the gateway told us (loopback mode, 0.20+): absence is
  /// "not told", so a false NEVER renders as 'not running'.
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context).textTheme;
    return Row(
      children: <Widget>[
        SizedBox(
          width: 24,
          child: isActive ? const Icon(Icons.check, size: 18) : null,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Flexible(child: Text(profile.name)),
                  if (profile.isDefault)
                    Text(' (default)', style: theme.bodySmall),
                  if (isLive)
                    Text(
                      ' · live',
                      style: theme.bodySmall?.copyWith(color: scheme.primary),
                    ),
                ],
              ),
              if (profile.model != null)
                Text(profile.model!, style: theme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
