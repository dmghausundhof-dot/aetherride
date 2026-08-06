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
}
