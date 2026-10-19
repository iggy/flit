/// Bottom sheet for picking a session's model and reasoning effort, from the
/// models the server discovered.
library;

import 'package:flit/application/flit/flit_providers.dart';
import 'package:flit/core/errors/gateway_error.dart';
import 'package:flit/domain/models/flit_session.dart';
import 'package:flit/presentation/flit/flit_rating.dart';
import 'package:flit/presentation/flit/flit_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the user picked. [effort] '' means the model's default.
typedef FlitModelChoice = ({String provider, String model, String effort});

/// How many recently used models the picker lists.
const int flitRecentModels = 5;

/// The star and load/unload buttons of a model row.
Key flitStarKey(FlitModel m) => Key('flit_star_${m.provider}/${m.id}');
Key flitLoadKey(FlitModel m) => Key('flit_load_${m.provider}/${m.id}');

/// The picker's sections: Favorites, Recent (the latest used models that
/// aren't starred) and All models; just the matches while filtering.
/// Empty sections are left out.
List<({String title, List<FlitModel> models})> flitModelSections(
  List<FlitModel> all,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isNotEmpty) {
    return <({String title, List<FlitModel> models})>[
      (
        title: '',
        models: all
            .where(
              (m) =>
                  m.id.toLowerCase().contains(q) ||
                  m.label.toLowerCase().contains(q) ||
                  m.provider.toLowerCase().contains(q),
            )
            .toList(),
      ),
    ];
  }
  final favorites = all.where((m) => m.favorite).toList()
    ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  final recent = all.where((m) => !m.favorite && m.lastUsed != null).toList()
    ..sort((a, b) => b.lastUsed!.compareTo(a.lastUsed!));
  return <({String title, List<FlitModel> models})>[
    if (favorites.isNotEmpty) (title: 'Favorites', models: favorites),
    if (recent.isNotEmpty)
      (title: 'Recent', models: recent.take(flitRecentModels).toList()),
    if (all.isNotEmpty) (title: 'All models', models: all),
  ];
}

Future<FlitModelChoice?> showFlitModelPicker(
  BuildContext context, {
  required String provider,
  required String model,
  required String effort,
  Future<String?> Function(bool good)? onRateCurrent,
}) {
  return showModalBottomSheet<FlitModelChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.85,
      child: _Picker(
        provider: provider,
        model: model,
        effort: effort,
        onRateCurrent: onRateCurrent,
      ),
    ),
  );
}

class _Picker extends ConsumerStatefulWidget {
  const _Picker({
    required this.provider,
    required this.model,
    required this.effort,
    this.onRateCurrent,
  });

  final String provider;
  final String model;
  final String effort;
  final Future<String?> Function(bool good)? onRateCurrent;

  @override
  ConsumerState<_Picker> createState() => _PickerState();
}

class _PickerState extends ConsumerState<_Picker> {
  String _query = '';
  late String _provider = widget.provider;
  late String _model = widget.model;
  late String _effort = widget.effort;
  bool _refreshing = false;
  bool? _rated;

  /// Models being loaded or unloaded ("provider/id").
  final Set<String> _loading = <String>{};

  void _snack(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _star(FlitModel m) async {
    final repository = ref.read(flitRepositoryProvider);
    if (repository == null) {
      return;
    }
    try {
      await repository.setFavorite(m.provider, m.id, favorite: !m.favorite);
      ref.invalidate(flitModelsProvider);
    } on GatewayException catch (error) {
      _snack('Could not change favorites: ${error.message}');
    }
  }

  Future<void> _setLoaded(FlitModel m, {required bool load}) async {
    final repository = ref.read(flitRepositoryProvider);
    if (repository == null) {
      return;
    }
    final key = '${m.provider}/${m.id}';
    setState(() => _loading.add(key));
    try {
      final now = await repository.setModelLoaded(m.provider, m.id, load: load);
      if (now.state == FlitModelState.failed) {
        _snack('${m.label} failed to load; see the llama.cpp server log.');
      }
      ref.invalidate(flitModelsProvider);
    } on GatewayException catch (error) {
      _snack(
        'Could not ${load ? 'load' : 'unload'} ${m.label}: ${error.message}',
      );
    } finally {
      if (mounted) {
        setState(() => _loading.remove(key));
      }
    }
  }

  Widget _row(FlitModel m) {
    final isSelected = m.provider == _provider && m.id == _model;
    final busy =
        _loading.contains('${m.provider}/${m.id}') ||
        m.state == FlitModelState.loading;
    final up =
        m.state == FlitModelState.loaded || m.state == FlitModelState.sleeping;
    return ListTile(
      dense: true,
      selected: isSelected,
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
      ),
      title: Text(m.label),
      subtitle: Text(_describe(m)),
      onTap: () => setState(() {
        _provider = m.provider;
        _model = m.id;
        if (!m.efforts.contains(_effort)) {
          _effort = '';
        }
      }),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (m.canLoad)
            busy
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    key: flitLoadKey(m),
                    tooltip: up ? 'Unload from llama.cpp' : 'Load in llama.cpp',
                    onPressed: () => _setLoaded(m, load: !up),
                    icon: Icon(up ? Icons.eject : Icons.play_arrow_outlined),
                  ),
          IconButton(
            key: flitStarKey(m),
            tooltip: m.favorite ? 'Remove from favorites' : 'Add to favorites',
            onPressed: () => _star(m),
            icon: Icon(m.favorite ? Icons.star : Icons.star_border),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh() async {
    final repository = ref.read(flitRepositoryProvider);
    if (repository == null) {
      return;
    }
    setState(() => _refreshing = true);
    try {
      await repository.refreshModels();
      ref.invalidate(flitModelsProvider);
    } on GatewayException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Refresh failed: ${error.message}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final models = ref.watch(flitModelsProvider);
    final theme = Theme.of(context);
    final all = models.value ?? const <FlitModel>[];
    FlitModel? selected;
    for (final m in all) {
      if (m.provider == _provider && m.id == _model) {
        selected = m;
      }
    }
    final efforts = selected?.efforts ?? const <String>[];
    final sections = flitModelSections(all, _query);
    final shown = sections.expand((s) => s.models).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text('Model', style: theme.textTheme.titleLarge)),
              IconButton(
                tooltip: 'Discover models again',
                onPressed: _refreshing ? null : _refresh,
                icon: _refreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
            ],
          ),
          if (widget.onRateCurrent != null && widget.model.isNotEmpty)
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Is ${widget.model} a good choice for this work?',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                FlitRatingButtons(
                  rating: _rated,
                  onRate: (good) async {
                    final error = await widget.onRateCurrent!(good);
                    if (!context.mounted) {
                      return;
                    }
                    if (error == null) {
                      setState(() => _rated = good);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not rate: $error')),
                      );
                    }
                  },
                ),
              ],
            ),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Filter models',
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: models.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Could not list models: '
                  '${e is GatewayException ? e.message : e}',
                ),
              ),
              data: (_) => shown.isEmpty
                  ? const Center(
                      child: Text(
                        'No models. Check the providers in the server config.',
                      ),
                    )
                  : ListView(
                      children: <Widget>[
                        for (final section in sections) ...<Widget>[
                          if (section.title.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                              child: Text(
                                section.title,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          for (final m in section.models) _row(m),
                        ],
                      ],
                    ),
            ),
          ),
          const Divider(height: 1),
          // The footer is set apart from the list so the action is easy to
          // find and hit, on phones especially.
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (efforts.isNotEmpty) ...<Widget>[
                    Text('Reasoning effort', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 6),
                    SegmentedButton<String>(
                      segments: <ButtonSegment<String>>[
                        const ButtonSegment<String>(
                          value: '',
                          label: Text('Default'),
                        ),
                        for (final e in efforts)
                          ButtonSegment<String>(value: e, label: Text(e)),
                      ],
                      selected: <String>{_effort},
                      onSelectionChanged: (s) =>
                          setState(() => _effort = s.first),
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      textStyle: theme.textTheme.titleMedium,
                    ),
                    onPressed: _model.isEmpty
                        ? null
                        : () => Navigator.pop<FlitModelChoice>(context, (
                            provider: _provider,
                            model: _model,
                            effort: _effort,
                          )),
                    icon: const Icon(Icons.check),
                    label: const Text('Use this model'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _describe(FlitModel m) {
    return <String?>[
      m.provider,
      if (m.contextLength > 0) '${formatTokens(m.contextLength)} context',
      if (m.supportsTools) 'tools',
      if (m.supportsReasoning) 'reasoning',
      if (m.supportsVision) 'vision',
      switch (m.state) {
        FlitModelState.none => m.loaded ? 'loaded' : null,
        FlitModelState.loaded => 'loaded',
        FlitModelState.loading => 'loading…',
        FlitModelState.sleeping => 'sleeping',
        FlitModelState.failed => 'failed to load',
        FlitModelState.unloaded => null,
      },
    ].nonNulls.join(' · ');
  }
}
