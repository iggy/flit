/// The flit half of the connect screen: pair this device with a flit server
/// by scanning the QR code from `flit pair` (phones) or typing the server
/// URL and code (desktop).
library;

import 'package:flit/application/flit/flit_pair_controller.dart';
import 'package:flit/presentation/flit/flit_scan_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether this platform can scan QR codes with the camera.
bool get canScanQr =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

class FlitPairForm extends ConsumerStatefulWidget {
  const FlitPairForm({super.key});

  @override
  ConsumerState<FlitPairForm> createState() => _FlitPairFormState();
}

class _FlitPairFormState extends ConsumerState<FlitPairForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _url = TextEditingController();
  final TextEditingController _code = TextEditingController();
  late final TextEditingController _name = TextEditingController(
    text: ref.read(flitDefaultDeviceNameProvider),
  );

  @override
  void dispose() {
    _url.dispose();
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _pair() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    await ref
        .read(flitPairControllerProvider.notifier)
        .pair(serverUrl: _url.text, code: _code.text, deviceName: _name.text);
  }

  Future<void> _scan() async {
    final info = await Navigator.of(context).push<PairingInfo>(
      MaterialPageRoute<PairingInfo>(builder: (_) => const FlitScanScreen()),
    );
    if (info == null || !mounted) {
      return;
    }
    _url.text = info.serverUrl;
    _code.text = info.code;
    await _pair();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(flitPairControllerProvider);
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Run "flit pair" on the machine running flit, then scan the QR '
            'code it shows or type the server address and code.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (canScanQr) ...<Widget>[
            FilledButton.icon(
              onPressed: state.busy ? null : _scan,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR code'),
            ),
            const SizedBox(height: 16),
            Text('Or enter them by hand:', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
          ],
          TextFormField(
            controller: _url,
            enabled: !state.busy,
            decoration: const InputDecoration(
              labelText: 'Server URL',
              hintText: 'https://flit.example.com',
              prefixIcon: Icon(Icons.link),
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter the server URL' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _code,
            enabled: !state.busy,
            decoration: const InputDecoration(
              labelText: 'Pairing code',
              hintText: 'ABCD-EFGH',
              prefixIcon: Icon(Icons.pin_outlined),
            ),
            autocorrect: false,
            textCapitalization: TextCapitalization.characters,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Enter the code from "flit pair"'
                : null,
            onFieldSubmitted: (_) => _pair(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _name,
            enabled: !state.busy,
            decoration: const InputDecoration(
              labelText: 'Name for this device',
              helperText: 'Shown on the server and to your other devices',
              prefixIcon: Icon(Icons.devices_outlined),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: state.busy ? null : _pair,
            icon: state.busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.link),
            label: Text(state.busy ? 'Pairing…' : 'Pair'),
          ),
          if (state.error != null) ...<Widget>[
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  state.error!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
