import 'dart:io';

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

  test('createGroup wirft bei privater GPX', () async {
    expect(
      () => store.createGroup(
        savedRouteId: 'gpx-neckar',
        title: 'Privat',
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
