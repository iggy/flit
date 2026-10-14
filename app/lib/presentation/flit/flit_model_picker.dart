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
    final q = _query.toLowerCase();
    final shown = all
        .where(
          (m) =>
              q.isEmpty ||
              m.id.toLowerCase().contains(q) ||
              m.label.toLowerCase().contains(q) ||
              m.provider.toLowerCase().contains(q),
        )
        .toList();

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
                  : ListView.builder(
                      itemCount: shown.length,
                      itemBuilder: (context, i) {
                        final m = shown[i];
                        final isSelected =
                            m.provider == _provider && m.id == _model;
                        return ListTile(
                          dense: true,
                          selected: isSelected,
                          leading: Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
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
                        );
                      },
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
    return <String>[
      m.provider,
      if (m.contextLength > 0) '${formatTokens(m.contextLength)} context',
      if (m.supportsTools) 'tools',
      if (m.supportsReasoning) 'reasoning',
      if (m.supportsVision) 'vision',
      if (m.loaded) 'loaded',
    ].join(' · ');
  }
}
