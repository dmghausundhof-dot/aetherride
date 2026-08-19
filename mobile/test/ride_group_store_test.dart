import 'dart:io';

import 'package:aetherride_mobile/data/community/ride_group_cloud.dart';
import 'package:aetherride_mobile/data/community/ride_group_store.dart';
import 'package:aetherride_mobile/domain/community/ride_group.dart';
import 'package:aetherride_mobile/domain/saved_route_note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late RideGroupStore store;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('rg-');
    store = RideGroupStore(dirProvider: () async => dir);
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('createGroup legt private GPX an, nicht freeride', () async {
    final g = await store.createGroup(
      savedRouteId: 'gpx-neckar',
      title: 'Privat',
      meta: SavedRouteMeta.empty,
    );
    expect(g.savedRouteId, 'gpx-neckar');
    expect(g.visibility, RideGroupVisibility.private);
    expect(
      () => store.createGroup(
        savedRouteId: 'freeride',
        title: 'Zusammen',
        meta: SavedRouteMeta.empty,
      ),
      throwsStateError,
    );
  });

  test('create + join + opt-in + presence ohne Fake', () async {
    final g = await store.createGroup(
      savedRouteId: 'r-bodensee-road',
      title: 'Bodensee',
      catalogTourId: 'r-bodensee-road',
      meta: const SavedRouteMeta(catalogTourId: 'r-bodensee-road'),
    );
    expect(g.joinCode.length, 6);
    expect(g.status, RideGroupStatus.open);

    final again = await store.joinByCode(g.joinCode);
    expect(again?.id, g.id);

    expect(await store.joinByCode('XXXXXX'), isNull);

    await store.setLiveOptIn(g.id, true);
    final me = await store.localMember(g.id);
    expect(me?.liveOptIn, isTrue);

    await store.publishPresence(
      groupId: g.id,
      lat: 47.67123,
      lng: 9.17321,
      zones: const [],
    );
    final pins = await store.visiblePins(groupId: g.id, zones: const []);
    final uid = await store.localUserId();
    expect(pins.length, 1);
    expect(pins.first.userId, uid);
    expect(pins.first.lat, isNot(47.67123));
  });

  test('Presence-Bundle vom Server bringt den Freund auf die Karte', () async {
    final g = await store.createGroup(
      savedRouteId: 'r-bodensee-road',
      title: 'Bodensee',
      catalogTourId: 'r-bodensee-road',
      meta: const SavedRouteMeta(catalogTourId: 'r-bodensee-road'),
    );
    await store.setLiveOptIn(g.id, true);
    final me = await store.localUserId();
    final now = DateTime.now().toUtc();
    await store.applyPresenceFromCloud(
      g.id,
      RideGroupCloudBundle(
        me: me,
        groups: const [],
        members: [
          RideGroupMember(
            groupId: g.id,
            userId: me,
            displayLabel: 'Du',
            joinedAt: now,
            liveOptIn: true,
          ),
          RideGroupMember(
            groupId: g.id,
            userId: 'friend-auth',
            displayLabel: 'Sam',
            joinedAt: now,
            liveOptIn: true,
          ),
        ],
        presence: [
          RideGroupPresence(
            groupId: g.id,
            userId: 'friend-auth',
            lat: 49.41,
            lng: 8.69,
            updatedAt: now,
            visibility: RideGroupPresenceVisibility.live,
          ),
        ],
      ),
    );

    final roster = await store.membersOf(g.id);
    expect(roster.any((m) => m.userId == 'friend-auth' && m.liveOptIn), isTrue);

    final pins = await store.visiblePins(groupId: g.id, zones: const []);
    expect(pins.any((p) => p.userId == 'friend-auth'), isTrue);
    expect(pins.where((p) => p.userId == 'friend-auth').single.lat, 49.41);
  });

  test('Presence-Bundle zieht Fenster nach, andere Gruppe bleibt', () async {
    final a = await store.createGroup(
      savedRouteId: 'r-bodensee-road',
      title: 'Bodensee',
      catalogTourId: 'r-bodensee-road',
      meta: const SavedRouteMeta(catalogTourId: 'r-bodensee-road'),
    );
    final other = await store.createGroup(
      savedRouteId: 'r-heidelberg-city',
      title: 'Heidelberg',
      catalogTourId: 'r-heidelberg-city',
      meta: const SavedRouteMeta(catalogTourId: 'r-heidelberg-city'),
    );
    final me = await store.localUserId();
    final now = DateTime.now().toUtc();
    final nextEnd = now.add(const Duration(hours: 6));
    await store.applyPresenceFromCloud(
      a.id,
      RideGroupCloudBundle(
        me: me,
        groups: [
          RideGroup(
            id: a.id,
            hostUserId: me,
            savedRouteId: a.savedRouteId,
            catalogTourId: a.catalogTourId,
            title: a.title,
            startWindowStart: a.startWindowStart,
            startWindowEnd: nextEnd,
            joinCode: a.joinCode,
            status: RideGroupStatus.open,
            livePinsAllowed: true,
            createdAt: a.createdAt,
            onServer: true,
          ),
        ],
        members: [
          RideGroupMember(
            groupId: a.id,
            userId: me,
            displayLabel: 'Du',
            joinedAt: now,
            liveOptIn: true,
          ),
        ],
      ),
    );
    final updated = await store.groupForRide(
      'saved-copy',
      preferGroupId: a.id,
      catalogTourId: 'r-bodensee-road',
    );
    expect(updated?.id, a.id);
    expect(updated!.startWindowEnd.difference(nextEnd).inSeconds.abs() < 2, isTrue);
    expect(
      (await store.activeGroups()).any((g) => g.id == other.id),
      isTrue,
    );
  });

  test('Host verlängert Fenster lokal um 1 h', () async {
    final g = await store.createGroup(
      savedRouteId: 'r-bodensee-road',
      title: 'Bodensee',
      catalogTourId: 'r-bodensee-road',
      meta: const SavedRouteMeta(catalogTourId: 'r-bodensee-road'),
    );
    final before = g.startWindowEnd;
    expect(await store.extendWindow(g.id), isTrue);
    final after = await store.groupForRide('r-bodensee-road');
    expect(after, isNotNull);
    expect(
      after!.startWindowEnd.difference(before).inMinutes,
      60,
    );
  });

  test('create + extend mit individueller Dauer', () async {
    final start = DateTime.now().toUtc().add(const Duration(hours: 1));
    final g = await store.createGroup(
      savedRouteId: 'r-bodensee-road',
      title: 'Bodensee',
      catalogTourId: 'r-bodensee-road',
      meta: const SavedRouteMeta(catalogTourId: 'r-bodensee-road'),
      windowStart: start,
      windowEnd: start.add(const Duration(hours: 5)),
      durationHours: 5,
    );
    expect(g.startWindowEnd.difference(g.startWindowStart).inMinutes, 300);
    expect(g.status, RideGroupStatus.scheduled);
    final before = g.startWindowEnd;
    expect(await store.extendWindow(g.id, hours: 0.5), isTrue);
    final after = await store.groupForRide('r-bodensee-road');
    expect(after!.startWindowEnd.difference(before).inMinutes, 30);
    expect(await store.extendWindow(g.id, hours: 0.1), isFalse);
    final custom = DateTime.now().toUtc().add(const Duration(hours: 8));
    expect(await store.extendWindow(g.id, newEnd: custom), isTrue);
    final setEnd = await store.groupForRide('r-bodensee-road');
    expect(
      setEnd!.startWindowEnd.difference(custom).inSeconds.abs() < 2,
      isTrue,
    );
  });

  test('leave als Host löst auf, Code ist tot', () async {
    final g = await store.createGroup(
      savedRouteId: 'r-bodensee-road',
      title: 'Bodensee',
      catalogTourId: 'r-bodensee-road',
      meta: const SavedRouteMeta(catalogTourId: 'r-bodensee-road'),
    );
    expect(await store.peekByCode(g.joinCode), isNotNull);
    await store.leaveGroup(g.id);
    expect(await store.peekByCode(g.joinCode), isNull);
  });

  test('inboxSeen merkt gelesene Stimmen', () async {
    expect(await store.inboxSeen(), 0);
    await store.markInboxSeen(3);
    expect(await store.inboxSeen(), 3);
  });
}
