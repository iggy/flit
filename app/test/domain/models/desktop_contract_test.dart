// docs/updates/gateway-0.18-to-0.20-optional.md §3: the desktop-contract
// version model. The interesting cases are all about UNKNOWN — an unreported
// contract must never read as an old one.

import 'package:flit/domain/models/desktop_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('unknown version', () {
    const contract = DesktopContract();

    test('is neither known nor behind', () {
      expect(contract.isKnown, isFalse);
      expect(contract.isBehind, isFalse);
    });

    test('imposes no attachment limit', () {
      expect(contract.attachmentLimitBytes, isNull);
      expect(contract.allowsAttachment(64 * 1024 * 1024), isTrue);
    });
  });

  group('current contract', () {
    const contract = DesktopContract(version: DesktopContract.minimum);

    test('is known and not behind', () {
      expect(contract.isKnown, isTrue);
      expect(contract.isBehind, isFalse);
    });

    test('imposes no attachment limit — the gateway raised its frame cap', () {
      expect(contract.attachmentLimitBytes, isNull);
      expect(contract.allowsAttachment(64 * 1024 * 1024), isTrue);
    });

    test('a NEWER contract than flit pins is not behind either', () {
      const newer = DesktopContract(version: DesktopContract.minimum + 3);

      expect(newer.isBehind, isFalse);
      expect(newer.attachmentLimitBytes, isNull);
    });
  });

  group('contract behind the pin', () {
    const contract = DesktopContract(
      version: DesktopContract.raisedFrameCap - 1,
    );

    test('is known and behind', () {
      expect(contract.isKnown, isTrue);
      expect(contract.isBehind, isTrue);
    });

    test('caps attachments under the 16 MiB uvicorn frame limit', () {
      final limit = contract.attachmentLimitBytes;

      expect(limit, isNotNull);
      // Strictly under the cap: the JSON-RPC envelope shares the frame.
      expect(limit, lessThan(DesktopContract.legacyFrameLimitBytes));
      expect(contract.allowsAttachment(limit!), isTrue);
      expect(contract.allowsAttachment(limit + 1), isFalse);
      expect(
        contract.allowsAttachment(DesktopContract.legacyFrameLimitBytes),
        isFalse,
      );
    });

    test('small attachments still go through', () {
      expect(contract.allowsAttachment(1024), isTrue);
    });

    test('the frame cap tracks raisedFrameCap, not the pin', () {
      // A gateway that lifted the cap but is behind a (hypothetically) raised
      // pin still gets no client-side attachment limit.
      const lifted = DesktopContract(version: DesktopContract.raisedFrameCap);

      expect(lifted.attachmentLimitBytes, isNull);
      expect(lifted.allowsAttachment(64 * 1024 * 1024), isTrue);
    });
  });

  test('value equality is by version', () {
    expect(
      const DesktopContract(version: 5),
      const DesktopContract(version: 5),
    );
    expect(
      const DesktopContract(version: 5).hashCode,
      const DesktopContract(version: 5).hashCode,
    );
    expect(
      const DesktopContract(version: 5),
      isNot(const DesktopContract(version: 4)),
    );
    expect(const DesktopContract(), isNot(const DesktopContract(version: 4)));
  });
}
