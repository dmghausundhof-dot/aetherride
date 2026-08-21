import 'dart:io';

import 'package:aetherride_mobile/data/community/group_member_tour.dart';
import 'package:aetherride_mobile/data/community/ride_group_cloud.dart';
import 'package:aetherride_mobile/data/community/ride_group_invite.dart';
import 'package:aetherride_mobile/data/community/ride_group_store.dart';
import 'package:aetherride_mobile/domain/community/ride_group.dart';
import 'package:aetherride_mobile/domain/saved_route.dart';
import 'package:aetherride_mobile/domain/saved_route_note.dart';
import 'package:aetherride_mobile/l10n/app_localizations_de.dart';
import 'package:aetherride_mobile/l10n/app_localizations_en.dart';
import 'package:aetherride_mobile/l10n/app_localizations_fr.dart';
import 'package:aetherride_mobile/l10n/app_localizations_it.dart';
import 'package:aetherride_mobile/l10n/app_localizations_nl.dart';
import 'package:aetherride_mobile/presentation/library/platz_extras.dart';
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
    expect(share,
        contains('Mein Profil: https://aetherride.vercel.app/u/luka'));
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

  test('parsePastedJoin nimmt HTTPS mit Token, Share-Text und weist Müll ab',
      () {
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
    final app =
        RideGroupInvite.customSchemeUrl(groupId: group.id, token: token);
    final share = RideGroupInvite.shareText(
      title: 'Bodensee',
      url: https,
      appUrl: app,
    );
    final fromShare = RideGroupInvite.parsePastedJoin(share);
    expect(fromShare?.code, group.id);
    expect(fromShare?.token, token);
    expect(RideGroupInvite.parsePastedJoin(https)?.token, token);
    expect(RideGroupInvite.parsePastedJoin(app)?.code, group.id);
    expect(RideGroupInvite.parsePastedJoin(''), isNull);
    expect(RideGroupInvite.parsePastedJoin('xyz'), isNull);
    expect(RideGroupInvite.parsePastedJoin('AB'), isNull);
    expect(RideGroupInvite.parsePastedJoin('k7-m2 np')?.code, 'K7M2NP');
    expect(RideGroupInvite.parsePastedJoin('K7M2NP')?.code, 'K7M2NP');
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

  test('öffentlicher Code lokal, privat braucht Link', () async {
    final dir = await Directory.systemTemp.createTemp('rg-pubcode-');
    addTearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });
    final guest = RideGroupStore(dirProvider: () async => dir);
    const id = '11111111-1111-1111-1111-111111111111';
    final now = DateTime.now().toUtc();
    final pub = RideGroup(
      id: id,
      hostUserId: 'host-1',
      savedRouteId: 'r-bodensee-road',
      title: 'Bodensee',
      startWindowStart: now.subtract(const Duration(hours: 1)),
      startWindowEnd: now.add(const Duration(hours: 2)),
      joinCode: 'K7M2NP',
      status: RideGroupStatus.open,
      livePinsAllowed: true,
      createdAt: now,
      visibility: RideGroupVisibility.public,
    );
    await guest.adoptCloudBundle(
      RideGroupCloudBundle(
        me: '',
        groups: [pub],
        members: [
          RideGroupMember(
            groupId: id,
            userId: 'host-1',
            displayLabel: 'Host',
            joinedAt: now,
          ),
        ],
      ),
    );
    final ok = await guest.tryJoin(code: 'k7-m2 np');
    expect(ok.fail, isNull);
    expect(ok.group?.id, id);

    final privDir = await Directory.systemTemp.createTemp('rg-privcode-');
    addTearDown(() async {
      if (await privDir.exists()) await privDir.delete(recursive: true);
    });
    final other = RideGroupStore(dirProvider: () async => privDir);
    await other.adoptCloudBundle(
      RideGroupCloudBundle(
        me: '',
        groups: [pub.copyWith(visibility: RideGroupVisibility.private)],
        members: [
          RideGroupMember(
            groupId: id,
            userId: 'host-1',
            displayLabel: 'Host',
            joinedAt: now,
          ),
        ],
      ),
    );
    final blocked = await other.tryJoin(code: 'K7M2NP');
    expect(blocked.fail, RideGroupJoinFail.needLink);
    expect(blocked.message, contains('Einladungslink'));
    expect(blocked.message.toLowerCase(), isNot(contains('anmelden')));
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
    expect(unknown.message.toLowerCase(), isNot(contains('token')));
  });

  test('Join-Hint spricht Einladungslink, nicht Token', () {
    final de = AppLocalizationsDe();
    expect(de.platzJoinCodeField, 'Einladungslink');
    expect(de.platzJoinCode, 'Code');
    expect(de.platzCopyCode, 'Code kopieren');
    expect(de.platzJoinLinkHint, contains('Einladungslink'));
    expect(de.platzJoinLinkHint, contains('Code'));
    expect(de.platzJoinLinkHint.toLowerCase(), isNot(contains('token')));
    expect(
      AppLocalizationsEn().platzJoinLinkHint,
      contains('invitation link'),
    );
    expect(
      AppLocalizationsEn().platzJoinLinkHint.toLowerCase(),
      isNot(contains('token')),
    );
    expect(
      AppLocalizationsFr().platzJoinLinkHint,
      contains('lien d’invitation'),
    );
    expect(
      AppLocalizationsFr().platzJoinLinkHint.toLowerCase(),
      isNot(contains('jeton')),
    );
    expect(
      AppLocalizationsIt().platzJoinLinkHint,
      contains('link di invito'),
    );
    expect(
      AppLocalizationsIt().platzJoinLinkHint.toLowerCase(),
      isNot(contains('token')),
    );
    expect(
      AppLocalizationsNl().platzJoinLinkHint,
      contains('uitnodigingslink'),
    );
    expect(
      AppLocalizationsNl().platzJoinLinkHint.toLowerCase(),
      isNot(contains('token')),
    );
    const fail = RideGroupJoinOut.fail(RideGroupJoinFail.unknown);
    expect(fail.message, contains('Einladungslink'));
    expect(fail.message.toLowerCase(), isNot(contains('token')));
    expect(
      rideGroupJoinMessage(
        AppLocalizationsDe(),
        const RideGroupJoinOut.fail(RideGroupJoinFail.expired),
      ),
      AppLocalizationsDe().platzJoinExpired,
    );
    expect(
      rideGroupJoinMessage(
        AppLocalizationsEn(),
        const RideGroupJoinOut.fail(RideGroupJoinFail.needLink),
      ),
      AppLocalizationsEn().platzJoinPrivateCode,
    );
  });

  test('lokaler Join sagt, dass der Gastgeber dich nicht sieht', () {
    final group = RideGroup(
      id: '11111111-1111-1111-1111-111111111111',
      hostUserId: 'host-1',
      savedRouteId: 'r-bodensee-road',
      title: 'Bodensee',
      startWindowStart: DateTime.utc(2026, 8, 15, 8),
      startWindowEnd: DateTime.utc(2026, 8, 15, 12),
      joinCode: 'K7M2NP',
      status: RideGroupStatus.open,
      livePinsAllowed: true,
      createdAt: DateTime.utc(2026, 8, 15, 8),
    );
    expect(
        RideGroupJoinOut.ok(group).message, contains('Gastgeber sieht dich nicht'));
    expect(RideGroupJoinOut.ok(group).message, contains('Nur auf diesem Gerät'));
    expect(RideGroupJoinOut.ok(group).message, isNot(contains('Lokal dabei')));
    expect(
      RideGroupJoinOut.ok(group.copyWith(onServer: true)).message,
      'Dabei: Bodensee',
    );
    final de = AppLocalizationsDe();
    expect(de.filterVisibilityPublic, 'Freigegeben');
    expect(de.platzPinsOff, contains('Freunde auf der Karte'));
    expect(de.mappeSubtitle, contains('Touren merken'));
    expect(
      RideGroupInvite.shareText(
          title: 'Bodensee',
          url: 'https://x',
          code: 'K7M2NP',
          visibility: RideGroupVisibility.public),
      contains('Freigegeben:'),
    );
    expect(
      RideGroupInvite.shareText(
          title: 'Bodensee',
          url: 'https://x',
          code: 'K7M2NP',
          visibility: RideGroupVisibility.public),
      contains('Code: K7M2NP'),
    );
    expect(
      RideGroupInvite.shareText(
          title: 'Bodensee',
          url: 'https://x',
          code: 'K7M2NP',
          visibility: RideGroupVisibility.private),
      isNot(contains('Code: K7M2NP')),
    );
    expect(
      RideGroupInvite.shareText(
          title: 'Bodensee',
          url: 'https://x',
          visibility: RideGroupVisibility.private),
      isNot(contains('öffentlich')),
    );
    expect(
      RideGroupInvite.shareText(
          title: 'Bodensee',
          url: 'https://x',
          visibility: RideGroupVisibility.private),
      contains('Nicht gelistet'),
    );
  });

  test('privates GPX-Invite trägt Spur, Gast importiert Host-Id', () {
    final group = RideGroup(
      id: '11111111-1111-1111-1111-111111111111',
      hostUserId: 'host-1',
      savedRouteId: 'gpx-neckar',
      title: 'Neckar',
      startWindowStart: DateTime.utc(2026, 8, 15, 8),
      startWindowEnd: DateTime.utc(2026, 8, 15, 12),
      joinCode: 'K7M2NP',
      status: RideGroupStatus.open,
      livePinsAllowed: true,
      createdAt: DateTime.utc(2026, 8, 15, 8),
    );
    final route = SavedRouteEntry(
      id: 'gpx-neckar',
      name: 'Neckar',
      distanceKm: 12,
      elevationM: 80,
      durationMin: 40,
      savedAt: DateTime.utc(2026, 8, 15),
      source: 'import',
      coordinates: const [
        [8.68, 49.40],
        [8.70, 49.41],
        [8.72, 49.42],
      ],
    );
    final token = RideGroupInvite.encode(group, route: route);
    final decoded = RideGroupInvite.decode(token);
    expect(decoded?.tour, isNotNull);
    expect(decoded?.tour?['includeTrack'], isTrue);
    final imported = importMemberTourFromInvite(
      payload: decoded,
      existing: const [],
    );
    expect(imported?.id, 'gpx-neckar');
    expect(imported?.coordinates.length, greaterThanOrEqualTo(2));
    expect(
      importMemberTourFromInvite(payload: decoded, existing: [route]),
      isNull,
    );
    final catalogToken = RideGroupInvite.encode(
      RideGroup(
        id: group.id,
        hostUserId: group.hostUserId,
        savedRouteId: 'r-bodensee-road',
        catalogTourId: 'r-bodensee-road',
        title: group.title,
        startWindowStart: group.startWindowStart,
        startWindowEnd: group.startWindowEnd,
        joinCode: group.joinCode,
        status: group.status,
        livePinsAllowed: group.livePinsAllowed,
        createdAt: group.createdAt,
      ),
      route: route,
    );
    expect(RideGroupInvite.decode(catalogToken)?.tour, isNull);
  });
}
