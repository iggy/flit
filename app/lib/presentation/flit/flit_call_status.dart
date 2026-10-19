/// What the chat shows while a model call waits: elapsed time (or how far
/// the server has got reading the prompt), and once nothing has arrived
/// for a while, "the model hasn't responded" with Retry and Stop instead
/// of an endless spinner.
library;

import 'dart:async';

import 'package:flit/application/flit/flit_fold.dart';
import 'package:flit/domain/models/flit_event.dart';
import 'package:flutter/material.dart';

/// After this long with nothing from the model, offer Retry and Stop.
const Duration flitNoResponseAfter = Duration(seconds: 60);

const Key flitCallStatusKey = Key('flit_call_status');
const Key flitCallRetryKey = Key('flit_call_retry');
const Key flitCallStopKey = Key('flit_call_stop');

/// m:ss, or h:mm:ss.
String flitClock(Duration d) {
  if (d.isNegative) {
    d = Duration.zero;
  }
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  if (d.inHours > 0) {
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    return '${d.inHours}:$m:$s';
  }
  return '${d.inMinutes}:$s';
}

class FlitCallStatus extends StatefulWidget {
  const FlitCallStatus({
    required this.call,
    required this.onRetry,
    required this.onStop,
    this.now = DateTime.now,
    super.key,
  });

  final FlitPendingCall call;
  final VoidCallback onRetry;
  final VoidCallback onStop;

  /// The clock; injectable for tests.
  final DateTime Function() now;

  @override
  State<FlitCallStatus> createState() => _FlitCallStatusState();
}

class _FlitCallStatusState extends State<FlitCallStatus> {
  Timer? _tick;

  /// When this widget first saw the call, for events without a time.
  late DateTime _seen = widget.now();

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(FlitCallStatus old) {
    super.didUpdateWidget(old);
    if (old.call.messageId != widget.call.messageId ||
        old.call.attempt != widget.call.attempt) {
      _seen = widget.now();
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final call = widget.call;
    final now = widget.now();
    final started = call.startedAt ?? _seen;
    final elapsed = now.difference(started);
    final idle = now.difference(call.lastActivity ?? started);
    final quiet = idle >= flitNoResponseAfter;
    if (call.hasOutput && !quiet) {
      return const SizedBox.shrink(); // the reply is streaming
    }
    final attempt = call.attempt > 1 ? ' (attempt ${call.attempt})' : '';
    final waiting = switch (call.waitReason) {
      FlitWaitReason.slotsBusy =>
        call.totalSlots > 0
            ? 'Waiting for a free llama.cpp slot (all ${call.totalSlots} busy)'
            : 'Waiting for a free llama.cpp slot',
      FlitWaitReason.sleeping => 'Waking the model up',
      FlitWaitReason.loading => 'Loading the model',
      FlitWaitReason.unknown || null => null,
    };
    final String text;
    if (waiting != null && !call.hasOutput) {
      text = '$waiting · ${flitClock(elapsed)}$attempt';
    } else if (quiet) {
      text = call.hasOutput
          ? 'No new output from the model for ${flitClock(idle)}$attempt'
          : "The model hasn't responded for ${flitClock(idle)}$attempt";
    } else if (call.total > 0 && call.processed < call.total) {
      text =
          'Reading the prompt: ${call.processed} of ${call.total} tokens · '
          '${flitClock(elapsed)}$attempt';
    } else {
      text = 'Waiting for the model · ${flitClock(elapsed)}$attempt';
    }
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: quiet ? scheme.onErrorContainer : scheme.onSurfaceVariant,
    );
    return Container(
      key: flitCallStatusKey,
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: quiet ? scheme.errorContainer : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          if (quiet)
            Icon(Icons.hourglass_bottom, size: 16, color: style?.color)
          else
            const SizedBox.square(
              dimension: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: style)),
          if (quiet && !call.hasOutput)
            TextButton(
              key: flitCallRetryKey,
              onPressed: widget.onRetry,
              child: const Text('Retry'),
            ),
          if (quiet)
            TextButton(
              key: flitCallStopKey,
              onPressed: widget.onStop,
              child: const Text('Stop'),
            ),
        ],
      ),
    );
  }
}
