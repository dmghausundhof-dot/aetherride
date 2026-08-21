import 'package:aetherride_mobile/data/sync/epoch_ms.dart';
import 'package:aetherride_mobile/data/sync/sync_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SyncPayload roundtrip includes payloadVersion', () {
    final p = SyncPayload(
      bikes: [
        {'id': '1', 'name': 'Trail'},
      ],
      updatedAt: '2026-08-06T00:00:00.000Z',
      payloadVersion: 1,
    );
    final json = p.toJson();
    final back = SyncPayload.fromJson(json);
    expect(back.payloadVersion, 1);
    expect(back.updatedAt, p.updatedAt);
    expect((back.bikes as List).length, 1);
  });

  test('epochMsFromUpdatedAt accepts ISO, ns, and junk', () {
    expect(
      epochMsFromUpdatedAt('2026-08-21T08:14:23.752Z'),
      DateTime.parse('2026-08-21T08:14:23.752Z').millisecondsSinceEpoch,
    );
    expect(
      epochMsFromUpdatedAt('1787298863752470000'),
      1787298863752,
    );
    expect(epochMsFromUpdatedAt('nope'), 0);
    expect(epochMsFromUpdatedAt(null), 0);
    expect(
      dateTimeFromLooseEpoch(1787298863752470000)?.year,
      2026,
    );
  });
}
