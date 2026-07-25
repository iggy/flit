import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flit/application/profiles/profile_providers.dart';
import 'package:flit/domain/models/profile.dart';

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

    return PopupMenuButton<String>(
      tooltip: 'Profiles',
      icon: const Icon(Icons.person_outline),
      onSelected: (name) => _onProfileSelected(context, ref, name),
      itemBuilder: (context) => _buildItems(context, profiles, activeName),
    );
  }

  List<PopupMenuEntry<String>> _buildItems(
    BuildContext context,
    AsyncValue<List<Profile>> profiles,
    String? activeName,
  ) {
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
          ),
        ),
      );
    }
    return items;
  }

  Future<void> _onProfileSelected(
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
}

/// One profile row: a check mark on the active profile, the name with a
/// '(default)' tag when [Profile.isDefault], and the model when known.
class _ProfileMenuEntry extends StatelessWidget {
  const _ProfileMenuEntry({required this.profile, required this.isActive});

  final Profile profile;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
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
