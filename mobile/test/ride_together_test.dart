import 'package:aetherride_mobile/data/community/ride_together_cloud.dart';
import 'package:aetherride_mobile/domain/community/ride_group.dart';
import 'package:aetherride_mobile/domain/community/ride_group_policy.dart';
import 'package:aetherride_mobile/domain/community/ride_together.dart';
import 'package:flutter_test/flutter_test.dart';

RideGroup _g({
  required String id,
  required String route,
  required DateTime created,
  bool onServer = true,
}) {
  return RideGroup(
    id: id,
    hostUserId: 'h',
    savedRouteId: route,
    title: id,
    startWindowStart: created,
    startWindowEnd: created.add(const Duration(hours: 8)),
    joinCode: 'ABCDEF',
    status: RideGroupStatus.riding,
    livePinsAllowed: true,
    createdAt: created,
    onServer: onServer,
  );
}

void main() {
  test('Session-Route und Label', () {
    expect(RideTogetherPolicy.isSessionRouteId('freeride'), isTrue);
    expect(RideTogetherPolicy.isFreerideRide(null), isTrue);
    expect(RideTogetherPolicy.canJoinSessionByCode('freeride'), isTrue);
    expect(RideGroupPolicy.normalizeJoinCode('ab c2-d3'), 'ABC2D3');
    expect(RideTogetherPolicy.sanitizeLabel('  Luka   Flow  '), 'Luka Flow');
    expect(RideTogetherPolicy.sanitizeLabel('x' * 40).length, 24);
    expect(RideTogetherPolicy.matePair('b', 'a')?.lo, 'a');
    expect(RideTogetherPolicy.matePair('a', 'a'), isNull);
    expect(RideTogetherPolicy.canAddMember(19), isTrue);
    expect(RideTogetherPolicy.canAddMember(20), isFalse);
    expect(RideTogetherPolicy.sessionClosesAfterLeave(1), isFalse);
    expect(RideTogetherPolicy.sessionClosesAfterLeave(0), isTrue);
    expect(RideTogetherPolicy.stopLookClosesSession(), isFalse);
    expect(RideTogetherPolicy.stopLookClosesSoloSession(), isTrue);
    expect(
      RideTogetherPolicy.pickRequestSession(fromCount: 1, toCount: 1),
      'from',
    );
    expect(
      RideTogetherPolicy.pickRequestSession(fromCount: 8, toCount: 1),
      'from',
    );
    expect(
      RideTogetherPolicy.pickRequestSession(fromCount: 1, toCount: 8),
      'to',
    );
    expect(
      RideTogetherPolicy.pickRequestSession(fromCount: 5, toCount: 12),
      'none',
    );
  });

  test('Zelle: neben dir, nicht die Stadt', () {
    expect(
      RideTogetherPolicy.bucket(
        selfLat: 49.4094,
        selfLng: 8.6948,
        otherLat: 49.4094,
        otherLng: 8.6948,
      ),
      'beside',
    );
    expect(
      RideTogetherPolicy.bucket(
        selfLat: 49.4094,
        selfLng: 8.6948,
        otherLat: 49.5,
        otherLng: 8.8,
      ),
      isNull,
    );
  });

  test('pickGroupForRide: Freeride nur Session mit zwei Leuten', () {
    final session = _g(
      id: 's1',
      route: RideTogetherPolicy.routeId,
      created: DateTime.utc(2026, 8, 19, 10),
    );
    final planned = _g(
      id: 'p1',
      route: 'r-bodensee-road',
      created: DateTime.utc(2026, 8, 19, 9),
    );
    expect(
      RideTogetherPolicy.pickGroupForRide(
        rideRouteId: null,
        groups: [session, planned],
        memberCounts: {'s1': 1, 'p1': 2},
      ),
      isNull,
    );
    expect(
      RideTogetherPolicy.pickGroupForRide(
        rideRouteId: null,
        groups: [session, planned],
        memberCounts: {'s1': 2, 'p1': 2},
      )?.id,
      's1',
    );
    expect(
      RideTogetherPolicy.pickGroupForRide(
        rideRouteId: null,
        groups: [session],
        memberCounts: {'s1': 20},
      )?.id,
      's1',
    );
    expect(
      RideTogetherPolicy.pickGroupForRide(
        rideRouteId: 'r-bodensee-road',
        groups: [session, planned],
        memberCounts: {'s1': 2, 'p1': 2},
      )?.id,
      'p1',
    );
    expect(
      RideTogetherPolicy.pickGroupForRide(
        rideRouteId: 'saved-hd',
        catalogTourId: 'r-bodensee-road',
        groups: [session, planned],
        memberCounts: {'s1': 2, 'p1': 2},
      )?.id,
      'p1',
    );
  });

  test('Session-Gruppe nie als Treffen-Pin', () {
    final g = _g(
      id: 's1',
      route: RideTogetherPolicy.routeId,
      created: DateTime.utc(2026, 8, 19, 10),
    );
    expect(
      RideGroupPolicy.canShowMeetingOnExplore(
        g,
        isMember: true,
        now: DateTime.utc(2026, 8, 19, 11),
      ),
      isFalse,
    );
  });

  test('Look-JSON: Nähe ohne Koordinaten', () {
    final snap = RideTogetherCloud.parseLook(
      200,
      '{"me":"u1","joinCode":"AB12CD","nearby":[{"userId":"u2","label":"Sam","bucket":"beside"}],"inbound":[]}',
    );
    expect(snap.joinCode, 'AB12CD');
    expect(snap.nearby.single.userId, 'u2');
    expect(snap.nearby.single.bucket, 'beside');
  });

  test('Look-JSON: Outbound-Status', () {
    final snap = RideTogetherCloud.parseLook(
      200,
      '{"me":"u1","joinCode":"AB12CD","nearby":[],"inbound":[],'
      '"outbound":[{"id":"r1","toUserId":"u2","label":"Sam","status":"pending"}]}',
    );
    expect(snap.outbound.single.status, 'pending');
    expect(snap.activeOutbound?.toUserId, 'u2');
  });

  test('Chip-Kind: Code, Solo, Anfrage', () {
    expect(
      togetherChipKind(looking: true, joinCode: 'ABCDEF'),
      TogetherChipKind.code,
    );
    expect(
      togetherChipKind(looking: true),
      TogetherChipKind.soloWait,
    );
    expect(
      togetherChipKind(looking: true, outboundStatus: 'pending'),
      TogetherChipKind.wait,
    );
    expect(
      togetherChipKind(looking: false, inboundCount: 1),
      TogetherChipKind.inbound,
    );
    expect(togetherChipKind(looking: false), TogetherChipKind.idle);
  });
}
