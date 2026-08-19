import 'package:aetherride_mobile/domain/community/ride_group.dart';
import 'package:aetherride_mobile/domain/community/ride_group_policy.dart';
import 'package:aetherride_mobile/domain/privacy/consents.dart';
import 'package:aetherride_mobile/domain/saved_route_note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Join-Code Länge und Alphabet', () {
    expect(RideGroupPolicy.generateJoinCode(() => 0).length, 6);
    expect(RideGroupPolicy.generateJoinCode(() => 0), 'AAAAAA');
    expect(RideGroupPolicy.normalizeJoinCode(' k7-m2 np '), 'K7M2NP');
    expect(RideGroupPolicy.normalizeJoinCode('io01ab'), 'AB');
    expect(RideGroupPolicy.joinAlphabet.contains('1'), isFalse);
    expect(RideGroupPolicy.joinAlphabet.contains('I'), isFalse);
    expect(RideGroupPolicy.isTypedJoinCode('k7-m2 np'), isTrue);
    expect(RideGroupPolicy.isTypedJoinCode('AB'), isFalse);
    expect(
      RideGroupPolicy.canJoinByTypedCode(RideGroupVisibility.public),
      isTrue,
    );
    expect(
      RideGroupPolicy.canJoinByTypedCode(RideGroupVisibility.private),
      isFalse,
    );
    expect(RideGroupPolicy.groupListedOnExplore(), isFalse);
    expect(
      RideGroupPolicy.canShowMeetingOnExplore(
        RideGroup(
          id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          hostUserId: 'h',
          savedRouteId: 'tour',
          title: 'Zoo',
          startWindowStart: DateTime.utc(2026, 8, 18, 8),
          startWindowEnd: DateTime.utc(2026, 8, 18, 16),
          joinCode: 'ABCDEF',
          status: RideGroupStatus.open,
          livePinsAllowed: true,
          createdAt: DateTime.utc(2026, 8, 18, 8),
          visibility: RideGroupVisibility.public,
        ),
        isMember: false,
        now: DateTime.utc(2026, 8, 18, 10),
      ),
      isTrue,
    );
  });

  test('canAttachCourse: privat und Katalog ja, freeride nein', () {
    expect(
      RideGroupPolicy.canAttachCourse('gpx-neckar', SavedRouteMeta.empty),
      isTrue,
    );
    expect(
      RideGroupPolicy.canAttachCourse(
        'gpx-neckar',
        const SavedRouteMeta(visibility: 'shared'),
      ),
      isTrue,
    );
    expect(
      RideGroupPolicy.canAttachCourse(
        'local-copy',
        const SavedRouteMeta(catalogTourId: 'idea-koenigstuhl'),
      ),
      isTrue,
    );
    expect(
      RideGroupPolicy.canAttachCourse('freeride', SavedRouteMeta.empty),
      isFalse,
    );
    expect(RideGroupPolicy.canAttachCourse('', SavedRouteMeta.empty), isFalse);
  });

  test('Event-Fenster', () {
    final start = DateTime.utc(2026, 8, 15, 9);
    final end = DateTime.utc(2026, 8, 15, 13);
    expect(
      RideGroupPolicy.isEventWindowOpen(
        now: DateTime.utc(2026, 8, 15, 9, 10),
        start: start,
        end: end,
        status: RideGroupStatus.open,
      ),
      isTrue,
    );
    expect(
      RideGroupPolicy.isEventWindowOpen(
        now: DateTime.utc(2026, 8, 15, 8),
        start: start,
        end: end,
        status: RideGroupStatus.open,
      ),
      isFalse,
    );
    expect(
      RideGroupPolicy.isEventWindowOpen(
        now: DateTime.utc(2026, 8, 15, 9, 10),
        start: start,
        end: end,
        status: RideGroupStatus.closed,
      ),
      isFalse,
    );
    expect(
      RideGroupPolicy.canJoin(
        now: DateTime.utc(2026, 8, 15, 8),
        end: end,
        status: RideGroupStatus.scheduled,
      ),
      isTrue,
    );
    expect(
      RideGroupPolicy.canJoin(
        now: DateTime.utc(2026, 8, 15, 14),
        end: end,
        status: RideGroupStatus.open,
      ),
      isFalse,
    );
    expect(
      RideGroupPolicy.formatWhen(
        DateTime(2026, 8, 16, 10),
        DateTime(2026, 8, 16, 13),
        now: DateTime(2026, 8, 14, 12),
      ),
      'So 10:00 · 3 h',
    );
    expect(
      RideGroupPolicy.formatWhen(
        DateTime(2026, 8, 16, 10),
        DateTime(2026, 8, 16, 11, 30),
        now: DateTime(2026, 8, 14, 12),
      ),
      'So 10:00 · 1,5 h',
    );
    expect(
      RideGroupPolicy.platzPrimaryIsInvite(
        selfIsHost: true,
        otherMemberCount: 0,
      ),
      isTrue,
    );
    expect(
      RideGroupPolicy.platzPrimaryIsInvite(
        selfIsHost: true,
        otherMemberCount: 1,
      ),
      isFalse,
    );
    expect(
      RideGroupPolicy.platzPrimaryIsInvite(
        selfIsHost: false,
        otherMemberCount: 0,
      ),
      isFalse,
    );
    expect(RideGroupPolicy.formatDurationHours(3.5, decimalSep: ','), '3,5 h');
  });

  test('Quantisierung und Zonen', () {
    final q = RideGroupPolicy.quantize(49.4094, 8.6948);
    expect(q.lat, (49.4094 / 0.0005).round() * 0.0005);
    expect(q.lat, isNot(49.4094));
    expect(
      RideGroupPolicy.pointInPrivacyZones(47.448, 12.148, [
        const PrivacyZone(
          id: 'z',
          label: 'Hof',
          lat: 47.448,
          lng: 12.148,
          radiusM: 200,
        ),
      ]),
      isTrue,
    );
    expect(
      RideGroupPolicy.pointInPrivacyZones(47.46, 12.16, [
        const PrivacyZone(
          id: 'z',
          label: 'Hof',
          lat: 47.448,
          lng: 12.148,
          radiusM: 200,
        ),
      ]),
      isFalse,
    );
  });

  test('Presence-Sichtbarkeit', () {
    RideGroupPresenceVisibility vis({
      bool member = true,
      bool opt = true,
      bool window = true,
      bool zone = false,
      bool fix = true,
      int? age = 4000,
    }) =>
        RideGroupPolicy.resolvePresence(
          isMember: member,
          livePinsAllowed: true,
          liveOptIn: opt,
          inEventWindow: window,
          inPrivacyZone: zone,
          hasFix: fix,
          ageMs: age,
        );

    expect(vis(), RideGroupPresenceVisibility.live);
    expect(vis(member: false), RideGroupPresenceVisibility.hiddenNotMember);
    expect(vis(opt: false), RideGroupPresenceVisibility.hiddenOptOut);
    expect(vis(window: false), RideGroupPresenceVisibility.hiddenWindow);
    expect(vis(zone: true), RideGroupPresenceVisibility.hiddenZone);
    expect(vis(age: 120000), RideGroupPresenceVisibility.stale);
    expect(vis(age: 400000), RideGroupPresenceVisibility.hiddenOffline);
    expect(vis(fix: false, age: null), RideGroupPresenceVisibility.hiddenOffline);
    expect(RideGroupPolicy.pinVisible(RideGroupPresenceVisibility.live), isTrue);
    expect(
      RideGroupPolicy.pinVisible(RideGroupPresenceVisibility.hiddenOptOut),
      isFalse,
    );
  });

  test('keepLocalAfterCloud: Host offline ja, Gast/Server-Rest nein', () {
    expect(
      RideGroupPolicy.keepLocalAfterCloud(onServer: false, selfIsHost: true),
      isTrue,
    );
    expect(
      RideGroupPolicy.keepLocalAfterCloud(onServer: false, selfIsHost: false),
      isFalse,
    );
    expect(
      RideGroupPolicy.keepLocalAfterCloud(onServer: true, selfIsHost: true),
      isFalse,
    );
    expect(
      RideGroupPolicy.keepLocalAfterCloud(onServer: true, selfIsHost: false),
      isFalse,
    );
  });

  test('extendWindowEnd +1 h, Deckel 12 h', () {
    final now = DateTime.utc(2026, 8, 19, 12);
    expect(
      RideGroupPolicy.extendWindowEnd(
        now: now,
        end: DateTime.utc(2026, 8, 19, 13),
      ),
      DateTime.utc(2026, 8, 19, 14),
    );
    expect(
      RideGroupPolicy.extendWindowEnd(
        now: now,
        end: DateTime.utc(2026, 8, 19, 11),
      ),
      DateTime.utc(2026, 8, 19, 13),
    );
    expect(
      RideGroupPolicy.extendWindowEnd(
        now: now,
        end: DateTime.utc(2026, 8, 19, 23),
      ),
      DateTime.utc(2026, 8, 20),
    );
  });

  test('parseWindow und Verlängerung individuell', () {
    final now = DateTime.utc(2026, 8, 16, 6);
    final half = RideGroupPolicy.parseWindow(
      startsAt: DateTime.utc(2026, 8, 16, 8),
      durationHours: 1.5,
      now: now,
    );
    expect(half, isNotNull);
    expect(half!.durationHours, 1.5);
    expect(half.end, DateTime.utc(2026, 8, 16, 9, 30));
    final five = RideGroupPolicy.parseWindow(
      startsAt: DateTime.utc(2026, 8, 16, 8),
      durationHours: 5,
      now: now,
    );
    expect(five!.end, DateTime.utc(2026, 8, 16, 13));
    final byEnd = RideGroupPolicy.parseWindow(
      startsAt: DateTime.utc(2026, 8, 16, 8),
      endsAt: DateTime.utc(2026, 8, 16, 9, 15),
      now: now,
    );
    expect(byEnd!.durationHours, 1.25);
    expect(
      RideGroupPolicy.parseWindow(durationHours: 0.1, now: now),
      isNull,
    );
    expect(
      RideGroupPolicy.parseWindow(durationHours: 13, now: now),
      isNull,
    );
    expect(RideGroupPolicy.parseDurationHours('1,5'), 1.5);
    expect(
      RideGroupPolicy.extendWindowEnd(
        now: DateTime.utc(2026, 8, 19, 12),
        end: DateTime.utc(2026, 8, 19, 13),
        hours: 0.5,
      ),
      DateTime.utc(2026, 8, 19, 13, 30),
    );
    expect(
      RideGroupPolicy.extendWindowEnd(
        now: DateTime.utc(2026, 8, 19, 12),
        end: DateTime.utc(2026, 8, 19, 13),
        newEnd: DateTime.utc(2026, 8, 19, 16),
      ),
      DateTime.utc(2026, 8, 19, 16),
    );
    expect(
      RideGroupPolicy.extendWindowEnd(
        now: DateTime.utc(2026, 8, 19, 12),
        end: DateTime.utc(2026, 8, 19, 13),
        newEnd: DateTime.utc(2026, 8, 20, 8),
      ),
      DateTime.utc(2026, 8, 20),
    );
    expect(RideGroupPolicy.groupListedOnExplore(), isFalse);
  });
}
