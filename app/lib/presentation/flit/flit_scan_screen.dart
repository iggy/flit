/// Full-screen camera view that scans a flit pairing QR code and returns
/// the [PairingInfo] in it.
library;

import 'package:flit/application/flit/flit_pair_controller.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class FlitScanScreen extends StatefulWidget {
  const FlitScanScreen({super.key});

  @override
  State<FlitScanScreen> createState() => _FlitScanScreenState();
}

class _FlitScanScreenState extends State<FlitScanScreen> {
  bool _done = false;
  String? _hint;

  void _onDetect(BarcodeCapture capture) {
    if (_done) {
      return;
    }
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) {
        continue;
      }
      final info = parsePairingUri(raw);
      if (info != null) {
        _done = true;
        Navigator.of(context).pop(info);
        return;
      }
      setState(() => _hint = 'That QR code is not from "flit pair".');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan pairing code')),
      body: Stack(
        children: <Widget>[
          MobileScanner(onDetect: _onDetect),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black54,
              padding: const EdgeInsets.all(16),
              child: Text(
                _hint ?? 'Point the camera at the QR code from "flit pair".',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
