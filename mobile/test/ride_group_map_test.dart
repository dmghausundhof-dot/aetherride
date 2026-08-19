import 'package:aetherride_mobile/domain/community/ride_group.dart';
import 'package:aetherride_mobile/domain/community/ride_group_map.dart';
import 'package:aetherride_mobile/domain/community/ride_group_policy.dart';
import 'package:flutter_test/flutter_test.dart';

RideGroup _g({
  String id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  RideGroupVisibility visibility = RideGroupVisibility.public,
  RideGroupStatus status = RideGroupStatus.open,
  String? meetingPoint,
  DateTime? end,
}) {
  final start = DateTime.utc(2026, 8, 18, 8);
  return RideGroup(
    id: id,
    hostUserId: 'host',
    savedRouteId: 'tour-1',
    title: 'Zoo',
    startWindowStart: start,
    startWindowEnd: end ?? DateTime.utc(2026, 8, 18, 16),
    joinCode: 'ABCDEF',
    status: status,
    livePinsAllowed: true,
    createdAt: start,
    visibility: visibility,
    meetingPoint: meetingPoint,
  );
}

void main() {
  final now = DateTime.utc(2026, 8, 18, 10);

  test('Live-GPS bleibt von Explore fern, Treffen-Pin ist erlaubt', () {
    expect(RideGroupPolicy.groupListedOnExplore(), isFalse);
    expect(
      RideGroupPolicy.canShowMeetingOnExplore(
        _g(),
        isMember: false,
        now: now,
      ),
      isTrue,
    );
    expect(
      RideGroupPolicy.canShowMeetingOnExplore(
        _g(visibility: RideGroupVisibility.private),
        isMember: false,
        now: now,
      ),
      isFalse,
    );
    expect(
      RideGroupPolicy.canShowMeetingOnExplore(
        _g(visibility: RideGroupVisibility.private),
        isMember: true,
        now: now,
      ),
      isTrue,
    );
    expect(
      RideGroupPolicy.canShowMeetingOnExplore(
        _g(status: RideGroupStatus.closed),
        isMember: true,
        now: now,
      ),
      isFalse,
    );
    expect(
      RideGroupPolicy.canShowMeetingOnExplore(
        _g(end: DateTime.utc(2026, 8, 18, 9)),
        isMember: false,
        now: now,
      ),
      isFalse,
    );
  });

  test('groupMeetPinsOnExplore: Koordinaten oder Tour-Mitte, nie Live-GPS', () {
    final pins = groupMeetPinsOnExplore(
      groups: [
        _g(
          id: '11111111-1111-1111-1111-111111111111',
          meetingPoint: 'Parkplatz Zoo 49.4076, 8.6908',
        ),
        _g(
          id: '22222222-2222-2222-2222-222222222222',
          visibility: RideGroupVisibility.private,
          meetingPoint: 'Heim 49.41, 8.70',
        ),
        _g(
          id: '33333333-3333-3333-3333-333333333333',
          meetingPoint: 'Nur Text ohne Koordinaten',
        ),
        _g(
          id: '44444444-4444-4444-4444-444444444444',
          status: RideGroupStatus.closed,
          meetingPoint: 'Zu 49.40, 8.69',
        ),
      ],
      memberGroupIds: const {},
      now: now,
      centerFor: (g) =>
          g.id.startsWith('3333') ? (lat: 49.5, lng: 8.6) : null,
    );

    expect(pins, hasLength(2));
    expect(pins.first.placeId, 'meet-11111111-1111-1111-1111-111111111111');
    expect(pins.first.lat, 49.4076);
    expect(pins.first.lng, 8.6908);
    expect(pins.first.label, 'Parkplatz Zoo');
    expect(pins.last.lat, 49.5);
    expect(pins.last.label, 'Nur Text ohne Koordinaten');
  });

  test('eigene private Gruppe erscheint als Treffen-Pin', () {
    const id = '22222222-2222-2222-2222-222222222222';
    final pins = groupMeetPinsOnExplore(
      groups: [
        _g(
          id: id,
          visibility: RideGroupVisibility.private,
          meetingPoint: 'Heim 49.41, 8.70',
        ),
      ],
      memberGroupIds: {id},
      now: now,
    );
    expect(pins, hasLength(1));
    expect(pins.single.label, 'Heim');
  });
}
