import 'package:aetherride_mobile/data/community/ride_together_look.dart';
import 'package:aetherride_mobile/domain/community/ride_group.dart';
import 'package:aetherride_mobile/domain/community/ride_together.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detachSheet ruft stopLook nicht', () async {
    var stopped = 0;
    final look = RideTogetherLook(
      lookFn: ({required lat, required lng, String? label}) async =>
          const TogetherLookSnap(me: 'u', joinCode: 'ABCDEF'),
      stopLookFn: () async {
        stopped++;
        return const TogetherLookSnap(me: 'u', stopped: true);
      },
      labelFn: () async => '',
      sessionStateFn: () async => 'signedIn',
    );
    await look.ensureStarted(
      lat: 49.4,
      lng: 8.6,
      inPrivacyZone: false,
      needGpsNote: 'gps',
      inZoneNote: 'zone',
      needLoginNote: 'login',
    );
    expect(look.looking, isTrue);
    expect(look.joinCode, 'ABCDEF');
    look.attachSheet();
    look.detachSheet();
    expect(stopped, 0);
    expect(look.looking, isTrue);
    await look.stop();
    expect(stopped, 1);
    expect(look.looking, isFalse);
    expect(look.joinCode, isNull);
    look.dispose();
  });

  test('stop behält Code wenn schon zu zweit', () async {
    var stopped = 0;
    final look = RideTogetherLook(
      lookFn: ({required lat, required lng, String? label}) async =>
          TogetherLookSnap(
        me: 'u',
        joinCode: 'ABCDEF',
        members: [
          RideGroupMember(
            groupId: 'g',
            userId: 'u',
            displayLabel: 'A',
            joinedAt: DateTime.utc(2026, 8, 1),
          ),
          RideGroupMember(
            groupId: 'g',
            userId: 'v',
            displayLabel: 'B',
            joinedAt: DateTime.utc(2026, 8, 1),
          ),
        ],
      ),
      stopLookFn: () async {
        stopped++;
        return const TogetherLookSnap(me: 'u', stopped: true);
      },
      labelFn: () async => '',
      sessionStateFn: () async => 'signedIn',
    );
    await look.ensureStarted(
      lat: 49.4,
      lng: 8.6,
      inPrivacyZone: false,
      needGpsNote: 'gps',
      inZoneNote: 'zone',
      needLoginNote: 'login',
    );
    await look.stop();
    expect(stopped, 1);
    expect(look.joinCode, 'ABCDEF');
    look.dispose();
  });

  test('stop clearSession löscht Code, nicht die API-Session-Regel', () async {
    var stopped = 0;
    final look = RideTogetherLook(
      lookFn: ({required lat, required lng, String? label}) async =>
          const TogetherLookSnap(me: 'u', joinCode: 'ABCDEF'),
      stopLookFn: () async {
        stopped++;
        return const TogetherLookSnap(me: 'u', stopped: true);
      },
      labelFn: () async => '',
      sessionStateFn: () async => 'signedIn',
    );
    await look.ensureStarted(
      lat: 49.4,
      lng: 8.6,
      inPrivacyZone: false,
      needGpsNote: 'gps',
      inZoneNote: 'zone',
      needLoginNote: 'login',
    );
    await look.stop(clearSession: true);
    expect(stopped, 1);
    expect(look.joinCode, isNull);
    look.dispose();
  });
}
