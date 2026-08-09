/// The connected gateway's desktop-contract version
/// (docs/updates/gateway-0.18-to-0.20-optional.md §3).
///
/// `info.desktop_contract` rides along on every `session.create` /
/// `session.resume` result and every `session.info` event, so the version is
/// learned from whichever arrives first and refreshed after each turn. It is
/// NOT queryable on its own — until a session is bootstrapped the version is
/// unknown, and unknown is treated as "not told" rather than "old".
library;

import 'package:flit/application/connection/connection_providers.dart';
import 'package:flit/data/dto/events/gateway_event_parser.dart';
import 'package:flit/domain/models/desktop_contract.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The contract version the gateway reports, or an unknown-version
/// [DesktopContract] before any session bootstrap has landed.
final desktopContractProvider =
    NotifierProvider<DesktopContractNotifier, DesktopContract>(
      DesktopContractNotifier.new,
    );

class DesktopContractNotifier extends Notifier<DesktopContract> {
  @override
  DesktopContract build() {
    ref.listen(gatewayEventsProvider, (previous, next) {
      final raw = next.value;
      if (raw == null) {
        return;
      }
      final event = parseGatewayEvent(raw);
      if (event is SessionInfo) {
        recordInfo(event.info);
      }
    });
    return const DesktopContract();
  }

  /// Read the version out of a session `info` dict (`session.create` /
  /// `session.resume` result, or a `session.info` event payload).
  ///
  /// A dict WITHOUT the key leaves the state alone: the gateway sends a
  /// minimal info for a lazy session, and forgetting a version we already
  /// learned would flip a warning off mid-connection.
  void recordInfo(Map<String, dynamic>? info) {
    final version = info?['desktop_contract'];
    if (version is int) {
      set(version);
    }
  }

  /// Record a version directly.
  void set(int version) {
    if (state.version == version) {
      return;
    }
    state = DesktopContract(version: version);
  }

  /// Forget the version (disconnect — the next gateway may be a different
  /// one).
  void clear() {
    state = const DesktopContract();
  }
}
