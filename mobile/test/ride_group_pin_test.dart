import 'package:aetherride_mobile/domain/community/ride_group.dart';
import 'package:aetherride_mobile/domain/community/ride_group_pin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Initialen und Chip', () {
    expect(friendPinInitials('Sam Rider'), 'SR');
    expect(friendPinInitials('@luka'), 'L');
    expect(friendPinInitials(''), '?');
    expect(
      friendPinChip(
        name: 'Sam',
        meters: 400,
        stale: false,
        staleLabel: 'eben noch',
      ),
      'Sam · 400 m',
    );
    expect(
      friendPinChip(
        name: 'Sam',
        meters: 400,
        stale: true,
        staleLabel: 'eben noch',
      ),
      'Sam · eben noch',
    );
  });

  test('Fenster-Rest', () {
    final end = DateTime.utc(2026, 8, 19, 14);
    expect(
      friendWindowLeft(
        end: end,
        now: DateTime.utc(2026, 8, 19, 13, 12),
        closed: 'zu',
        hours: (h) => 'noch $h h',
        mins: (m) => 'noch $m min',
      ),
      'noch 48 min',
    );
    expect(
      friendWindowLeft(
        end: end,
        now: DateTime.utc(2026, 8, 19, 12),
        closed: 'zu',
        hours: (h) => 'noch $h h',
        mins: (m) => 'noch $m min',
      ),
      'noch 2 h',
    );
    expect(
      friendWindowLeft(
        end: end,
        now: DateTime.utc(2026, 8, 19, 15),
        closed: 'zu',
        hours: (h) => 'noch $h h',
        mins: (m) => 'noch $m min',
      ),
      'zu',
    );
  });

  test('HUD-Snap zählt nur sichtbare Pins', () {
    const id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    final start = DateTime.utc(2026, 8, 19, 10);
    final group = RideGroup(
      id: id,
      hostUserId: 'host',
      savedRouteId: 'tour',
      title: 'Zoo',
      startWindowStart: start,
      startWindowEnd: start.add(const Duration(hours: 3)),
      joinCode: 'ABCDEF',
      status: RideGroupStatus.open,
      livePinsAllowed: true,
      createdAt: start,
    );
    final snap = buildRideGroupHudSnap(
      group: group,
      members: [
        RideGroupMember(
          groupId: id,
          userId: 'me',
          displayLabel: 'Du',
          joinedAt: start,
          liveOptIn: true,
        ),
        RideGroupMember(
          groupId: id,
          userId: 'friend',
          displayLabel: 'Sam',
          joinedAt: start,
          liveOptIn: true,
        ),
      ],
      pins: [
        RideGroupPresence(
          groupId: id,
          userId: 'friend',
          lat: 49.41,
          lng: 8.69,
          updatedAt: start,
          visibility: RideGroupPresenceVisibility.live,
        ),
      ],
      selfIds: {'me'},
      optIn: true,
      selfLat: 49.412,
      selfLng: 8.692,
    );
    expect(snap.sharing, 2);
    expect(snap.total, 2);
    expect(snap.mates.last.label, 'Sam');
    expect(snap.mates.last.meters, isNotNull);
    expect(friendHudLine(sharing: snap.sharing, total: snap.total, left: 'noch 48 min'),
        '2/2 · noch 48 min');
  });

  test('Richtung vor/hinter/links/rechts', () {
    expect(
      friendRelative(headingDeg: 0, bearingDeg: 10),
      FriendRel.ahead,
    );
    expect(
      friendRelative(headingDeg: 0, bearingDeg: 180),
      FriendRel.behind,
    );
    expect(
      friendRelative(headingDeg: 0, bearingDeg: 90),
      FriendRel.right,
    );
    expect(
      friendRelative(headingDeg: 0, bearingDeg: 270),
      FriendRel.left,
    );
    expect(friendRelative(headingDeg: null, bearingDeg: 90), isNull);
    expect(
      friendPinChip(
        name: 'Sam',
        meters: 800,
        stale: false,
        staleLabel: 'eben noch',
        relLabel: 'hinter dir',
      ),
      'Sam · 800 m hinter dir',
    );
  });

  test('Leere Namen werden Freund 1/2', () {
    const id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
    final start = DateTime.utc(2026, 8, 19, 10);
    final group = RideGroup(
      id: id,
      hostUserId: 'host',
      savedRouteId: 'tour',
      title: 'Zoo',
      startWindowStart: start,
      startWindowEnd: start.add(const Duration(hours: 3)),
      joinCode: 'ABCDEF',
      status: RideGroupStatus.open,
      livePinsAllowed: true,
      createdAt: start,
    );
    final snap = buildRideGroupHudSnap(
      group: group,
      members: [
        RideGroupMember(
          groupId: id,
          userId: 'host',
          displayLabel: 'Host',
          joinedAt: start,
        ),
        RideGroupMember(
          groupId: id,
          userId: 'bbb',
          displayLabel: '',
          joinedAt: start,
        ),
        RideGroupMember(
          groupId: id,
          userId: 'aaa',
          displayLabel: '',
          joinedAt: start,
        ),
      ],
      pins: const [],
      selfIds: {'host'},
      optIn: true,
      friendN: (n) => 'Freund $n',
    );
    expect(snap.selfIsHost, isTrue);
    expect(snap.mates[1].label, 'Freund 2');
    expect(snap.mates[2].label, 'Freund 1');
    expect(
      friendRosterName(
        displayLabel: '',
        self: false,
        friendN: 1,
        fallbackSelf: 'Du',
        fallbackOther: 'Gast',
        friendLabel: (n) => 'Freund $n',
      ),
      'Freund 1',
    );
    expect(
      friendMemberLine(
        displayLabel: 'Du',
        self: true,
        isHost: true,
        fallbackSelf: 'Du',
        fallbackOther: 'Gast',
        hostRole: 'Gastgeber',
        guestRole: 'Gast',
        friendLabel: (n) => 'Freund $n',
      ),
      'Du · Gastgeber',
    );
    expect(
      friendMemberLine(
        displayLabel: '',
        self: false,
        isHost: false,
        friendN: 1,
        fallbackSelf: 'Du',
        fallbackOther: 'Gast',
        hostRole: 'Gastgeber',
        guestRole: 'Gast',
        friendLabel: (n) => 'Freund $n',
      ),
      'Freund 1',
    );
  });

  test('HUD-Zeile allein ohne 1/1', () {
    final alone = RideGroupHudSnap(
      groupId: 'g',
      title: 'Zoo',
      optIn: true,
      sharing: 1,
      total: 1,
      windowEnd: DateTime.utc(2026, 8, 19, 17),
      mates: const [
        RideGroupHudMate(
          userId: 'me',
          label: 'Du',
          self: true,
          sharing: true,
        ),
      ],
    );
    expect(
      rideGroupHudStatusLine(
        snap: alone,
        left: 'noch 2 h',
        selfOn: (left) => 'Du teilst · $left',
        selfOff: (left) => 'stumm · $left',
        ratio: (s, t, left) => '$s/$t teilen · $left',
        withDetail: (d, left) => '$d · $left',
      ),
      'Du teilst · noch 2 h',
    );
    expect(
      rideGroupHudStatusLine(
        snap: RideGroupHudSnap(
          groupId: 'g',
          title: 'Zoo',
          optIn: false,
          sharing: 0,
          total: 1,
          windowEnd: DateTime.utc(2026, 8, 19, 17),
          mates: const [
            RideGroupHudMate(
              userId: 'me',
              label: 'Du',
              self: true,
              sharing: false,
            ),
          ],
        ),
        left: 'noch 2 h',
        selfOn: (left) => 'Du teilst · $left',
        selfOff: (left) => 'stumm · $left',
        ratio: (s, t, left) => '$s/$t teilen · $left',
        withDetail: (d, left) => '$d · $left',
      ),
      'stumm · noch 2 h',
    );
    expect(
      rideGroupHudStatusLine(
        snap: RideGroupHudSnap(
          groupId: 'g',
          title: 'Zoo',
          optIn: true,
          sharing: 2,
          total: 3,
          windowEnd: DateTime.utc(2026, 8, 19, 17),
          mates: const [
            RideGroupHudMate(
              userId: 'me',
              label: 'Du',
              self: true,
              sharing: true,
            ),
            RideGroupHudMate(
              userId: 'sam',
              label: 'Sam',
              self: false,
              sharing: true,
            ),
          ],
        ),
        left: 'noch 2 h',
        selfOn: (left) => 'Du teilst · $left',
        selfOff: (left) => 'stumm · $left',
        ratio: (s, t, left) => '$s/$t teilen · $left',
        withDetail: (d, left) => '$d · $left',
      ),
      '2/3 teilen · noch 2 h',
    );
  });

  test('HUD-Delta nur bei Wechsel', () {
    final end = DateTime.utc(2026, 8, 19, 17);
    final prev = RideGroupHudSnap(
      groupId: 'g',
      title: 'Zoo',
      optIn: true,
      sharing: 2,
      total: 2,
      windowEnd: end,
      mates: [
        RideGroupHudMate(
          userId: 'me',
          label: 'Du',
          self: true,
          sharing: true,
        ),
        RideGroupHudMate(
          userId: 'sam',
          label: 'Sam',
          self: false,
          sharing: true,
        ),
      ],
    );
    expect(
      friendHudDelta(
        prev: null,
        next: prev,
        now: DateTime.utc(2026, 8, 19, 16),
      ).note,
      RideGroupHudNote.none,
    );
    expect(
      friendHudDelta(
        prev: prev,
        next: prev,
        now: DateTime.utc(2026, 8, 19, 16),
      ).note,
      RideGroupHudNote.none,
    );
    expect(
      friendHudDelta(
        prev: prev,
        next: null,
        now: DateTime.utc(2026, 8, 19, 16),
      ).note,
      RideGroupHudNote.groupGone,
    );
    expect(
      friendHudDelta(
        prev: prev,
        next: null,
        now: DateTime.utc(2026, 8, 19, 18),
      ).note,
      RideGroupHudNote.windowClosed,
    );
    final withoutSam = RideGroupHudSnap(
      groupId: 'g',
      title: 'Zoo',
      optIn: true,
      sharing: 1,
      total: 1,
      windowEnd: end,
      mates: const [
        RideGroupHudMate(
          userId: 'me',
          label: 'Du',
          self: true,
          sharing: true,
        ),
      ],
    );
    final left = friendHudDelta(
      prev: prev,
      next: withoutSam,
      now: DateTime.utc(2026, 8, 19, 16),
    );
    expect(left.note, RideGroupHudNote.mateLeft);
    expect(left.name, 'Sam');
  });

  test('Teilen-Satz', () {
    expect(
      friendShareOnLine(
        otherNames: const ['Sam'],
        untilHm: '17:00',
        one: (n, t) => '$n sieht dich — nur bis $t.',
        many: (c, t) => '$c Freunde sehen dich — nur bis $t.',
        none: (t) => 'Noch niemand dabei — nur bis $t.',
      ),
      'Sam sieht dich — nur bis 17:00.',
    );
    expect(
      friendShareOnLine(
        otherNames: const ['Sam', 'Lea'],
        untilHm: '17:00',
        one: (n, t) => '$n sieht dich — nur bis $t.',
        many: (c, t) => '$c Freunde sehen dich — nur bis $t.',
        none: (t) => 'Noch niemand dabei — nur bis $t.',
      ),
      '2 Freunde sehen dich — nur bis 17:00.',
    );
  });
}
