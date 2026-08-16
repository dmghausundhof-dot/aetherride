import 'package:aetherride_mobile/domain/community/ride_group.dart';
import 'package:aetherride_mobile/domain/community/ride_group_policy.dart';
import 'package:aetherride_mobile/domain/privacy/consents.dart';
import 'package:aetherride_mobile/domain/saved_route_note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Join-Code Länge und Alphabet', () {
    expect(RideGroupPolicy.generateJoinCode(() => 0).length, 6);
    expect(RideGroupPolicy.generateJoinCode(() => 0), 'AAAAAA');
    expect(RideGroupPolicy.groupListedOnExplore(), isFalse);
  });

  test('canAttachCourse: privat nein, shared/Katalog ja', () {
    expect(
      RideGroupPolicy.canAttachCourse('gpx-neckar', SavedRouteMeta.empty),
      isFalse,
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
}
