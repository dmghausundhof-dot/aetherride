import 'package:aetherride_mobile/data/community/ride_group_cloud.dart';
import 'package:aetherride_mobile/domain/community/ride_group.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseBundle: Roster ohne erfundene Namen', () {
    final bundle = RideGroupCloud.parseBundle({
      'me': 'auth-1',
      'group': {
        'id': '11111111-1111-1111-1111-111111111111',
        'hostUserId': 'auth-1',
        'savedRouteId': 'r-bodensee-road',
        'title': 'Bodensee',
        'startWindowStart': '2026-08-15T08:00:00.000Z',
        'startWindowEnd': '2026-08-15T12:00:00.000Z',
        'joinCode': 'K7M2NP',
        'status': 'open',
        'livePinsAllowed': true,
        'createdAt': '2026-08-15T08:00:00.000Z',
      },
      'members': [
        {
          'groupId': '11111111-1111-1111-1111-111111111111',
          'userId': 'auth-1',
          'displayLabel': '',
          'joinedAt': '2026-08-15T08:00:00.000Z',
          'liveOptIn': false,
        },
      ],
    });
    expect(bundle.me, 'auth-1');
    expect(bundle.groups.single.onServer, isTrue);
    expect(bundle.groups.single.joinCode, 'K7M2NP');
    expect(bundle.members.single.displayLabel, isEmpty);
  });

  test('parseResponse 401 bleibt ehrlich', () {
    final fail = RideGroupCloud.parseResponse(
      401,
      '{"error":"unauthorized"}',
    );
    expect(fail.ok, isFalse);
    expect(fail.status, 401);
    expect(fail.error, 'unauthorized');
  });

  test('parseBundle: Presence ohne Fake-Koordinaten', () {
    final bundle = RideGroupCloud.parseBundle({
      'me': 'auth-1',
      'presence': [
        {
          'groupId': '11111111-1111-1111-1111-111111111111',
          'userId': 'auth-2',
          'lat': 49.41,
          'lng': 8.69,
          'updatedAt': '2026-08-16T08:00:00.000Z',
          'visibility': 'hidden_opt_out',
        },
        {
          'groupId': '11111111-1111-1111-1111-111111111111',
          'userId': 'auth-3',
          'lat': 49.41,
          'lng': 8.69,
          'updatedAt': '2026-08-16T08:00:00.000Z',
          'visibility': 'live',
        },
      ],
    });
    expect(bundle.presence.length, 2);
    expect(bundle.presence.first.visibility,
        RideGroupPresenceVisibility.hiddenOptOut);
    expect(bundle.presence.last.visibility, RideGroupPresenceVisibility.live);
    expect(bundle.presence.last.lat, 49.41);
  });

  test('parseResponse 501 stub', () {
    final fail = RideGroupCloud.parseResponse(
      501,
      '{"error":"not_implemented","stub":true,"note":"Server-Tabelle fehlt — nur lokal."}',
    );
    expect(fail.stub, isTrue);
    expect(fail.note, contains('Server-Tabelle'));
  });
}
