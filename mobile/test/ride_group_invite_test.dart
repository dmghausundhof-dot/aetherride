import 'dart:io';

import 'package:aetherride_mobile/data/community/ride_group_invite.dart';
import 'package:aetherride_mobile/data/community/ride_group_store.dart';
import 'package:aetherride_mobile/domain/community/ride_group.dart';
import 'package:aetherride_mobile/domain/saved_route_note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('https + scheme enthalten Id, Token rund, kein Code in Share', () {
    final group = RideGroup(
      id: '11111111-1111-1111-1111-111111111111',
      hostUserId: 'host-1',
      savedRouteId: 'r-bodensee-road',
      catalogTourId: 'r-bodensee-road',
      title: 'Bodensee',
      startWindowStart: DateTime.utc(2026, 8, 15, 8),
      startWindowEnd: DateTime.utc(2026, 8, 15, 12),
      joinCode: 'K7M2NP',
      status: RideGroupStatus.open,
      livePinsAllowed: true,
      createdAt: DateTime.utc(2026, 8, 15, 8),
    );
    final token = RideGroupInvite.encode(group);
    final https = RideGroupInvite.httpsUrl(
      groupId: group.id,
      token: token,
      origin: 'https://aetherride.vercel.app',
    );
    expect(
      https,
      'https://aetherride.vercel.app/library?group=${group.id}&g=$token',
    );
    expect(
      RideGroupInvite.customSchemeUrl(groupId: group.id, token: token),
      'aetherride://platz?group=${group.id}&g=$token',
    );
    final decoded = RideGroupInvite.decode(token);
    expect(decoded?.code, 'K7M2NP');
    expect(decoded?.id, group.id);
    expect(decoded?.title, 'Bodensee');
    expect(decoded?.windowOpen(DateTime.utc(2026, 8, 15, 10)), isTrue);
    expect(decoded?.windowOpen(DateTime.utc(2026, 8, 16)), isFalse);
    final share = RideGroupInvite.shareText(
      title: 'Bodensee',
      url: https,
      appUrl: RideGroupInvite.customSchemeUrl(groupId: group.id, token: token),
      profileUrl: 'https://aetherride.vercel.app/u/luka',
    );
    expect(share, contains('aetherride://platz?group=${group.id}'));
    expect(share, contains('Mein Platz-Profil: https://aetherride.vercel.app/u/luka'));
    expect(share, isNot(contains('Code K7M2NP')));
    expect(share, contains('Privat:'));
    expect(
      RideGroupInvite.profileHttpsUrl(
        handle: 'Luka!',
        origin: 'https://aetherride.vercel.app',
      ),
      'https://aetherride.vercel.app/u/luka',
    );
    expect(
      RideGroupInvite.shareOrigin(origin: 'http://10.0.2.2:3001'),
      'https://aetherride.vercel.app',
    );
  });

  test('joinFromInvite importiert ohne lokales Original', () async {
    final dir = await Directory.systemTemp.createTemp('rg-inv-');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    final host = RideGroupStore(dirProvider: () async => dir);
    final created = await host.createGroup(
      savedRouteId: 'r-bodensee-road',
      title: 'Bodensee',
      catalogTourId: 'r-bodensee-road',
      meta: const SavedRouteMeta(catalogTourId: 'r-bodensee-road'),
    );
    final token = RideGroupInvite.encode(created);

    final guestDir = await Directory.systemTemp.createTemp('rg-guest-');
    addTearDown(() async {
      if (await guestDir.exists()) await guestDir.delete(recursive: true);
    });
    final guest = RideGroupStore(dirProvider: () async => guestDir);
    expect(await guest.joinByCode(created.joinCode), isNull);
    final hit = await guest.joinFromInvite(
      code: created.joinCode,
      token: token,
    );
    expect(hit?.id, created.id);
    expect(hit?.title, 'Bodensee');
    expect(await guest.localMember(created.id), isNotNull);
  });

  test('tryJoin unterscheidet unbekannt und ungültig', () async {
    final dir = await Directory.systemTemp.createTemp('rg-join-');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    final store = RideGroupStore(dirProvider: () async => dir);
    final bad = await store.tryJoin(code: 'AB');
    expect(bad.fail, RideGroupJoinFail.needLink);
    final unknown = await store.tryJoin(code: 'XXXXXX');
    expect(unknown.fail, RideGroupJoinFail.unknown);
  });
}
