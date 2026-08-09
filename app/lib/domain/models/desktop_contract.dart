/// The gateway's `info.desktop_contract` — the version of the desktop-client
/// backend contract the connected gateway speaks
/// (docs/reference/07-session-depth-wire-shapes.md §session.info,
/// `DESKTOP_BACKEND_CONTRACT`).
///
/// History of the versions, since the pin below has to be justified against
/// them: v1 baseline, v2 `file.attach`, v3 `approvals.mode` + `session.info`
/// reconciliation, v4 `session.create` `fast: false` meaning "pin the normal
/// tier" (rather than "inherit"), v5 the raised uvicorn WS frame cap that lets
/// base64 attachment frames exceed 16 MiB.
final class DesktopContract {
  const DesktopContract({this.version});

  /// The lowest contract flit is written against.
  ///
  /// v5: flit sends an explicit `fast: false` to pin the normal tier (v4, see
  /// `SessionOverrides`) and puts whole attachments on the wire as base64 in a
  /// single frame with no size negotiation (v5). Raise this only when flit
  /// actually starts requiring a newer contract.
  static const int minimum = 5;

  /// The contract that raised the WS frame cap. Tracked separately from
  /// [minimum] so raising the pin later doesn't start applying the legacy cap
  /// to gateways that already lifted it.
  static const int raisedFrameCap = 5;

  /// uvicorn's WS frame cap below [raisedFrameCap] (16 MiB). How far v5 raised
  /// it is not on the wire, so the cap is only ever applied to a gateway known
  /// to be older than that.
  static const int legacyFrameLimitBytes = 16 * 1024 * 1024;

  /// Room left for the JSON-RPC envelope around a base64 payload inside one
  /// frame (method name, session id, filename, quoting). Generous on purpose:
  /// a refusal names a real limit, whereas a frame over the cap kills the
  /// socket with no error at all.
  static const int _envelopeAllowanceBytes = 64 * 1024;

  /// Wire `info.desktop_contract`, or null when the gateway has not reported
  /// it yet — a minimal info dict omits the key, and it is absent entirely
  /// before the first session bootstrap. Null is "not told", never "old".
  final int? version;

  /// The gateway has reported its contract version.
  bool get isKnown => version != null;

  /// The gateway reported a contract OLDER than flit needs. False while the
  /// version is unknown: an unreported contract must not provoke a warning.
  bool get isBehind => version != null && version! < minimum;

  /// Largest base64 attachment payload that fits in one WS frame, or null when
  /// no client-side limit applies (the gateway raised its cap, or has not said
  /// what it speaks).
  int? get attachmentLimitBytes {
    final reported = version;
    if (reported == null || reported >= raisedFrameCap) {
      return null;
    }
    return legacyFrameLimitBytes - _envelopeAllowanceBytes;
  }

  /// Whether a base64 payload of [base64Length] bytes can be sent as an
  /// attachment. Permissive when the contract is unknown — the point is to
  /// explain a certain failure, not to pre-emptively block attachments against
  /// a gateway that simply hasn't said.
  bool allowsAttachment(int base64Length) {
    final limit = attachmentLimitBytes;
    return limit == null || base64Length <= limit;
  }

  @override
  bool operator ==(Object other) {
    return other is DesktopContract && other.version == version;
  }

  @override
  int get hashCode => version.hashCode;

  @override
  String toString() => 'DesktopContract(version: $version)';
}
