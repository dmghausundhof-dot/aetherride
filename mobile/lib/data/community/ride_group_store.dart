import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../domain/community/ride_group.dart';
import '../../domain/community/ride_group_policy.dart';
import 'ride_group_cloud.dart';
import 'ride_group_invite.dart';
import '../../domain/privacy/consents.dart';
import '../../domain/saved_route_note.dart';

/// Lokale Gruppen — kein Explore, keine Demo-Fahrer.
class RideGroupStore {
  RideGroupStore({Future<Directory> Function()? dirProvider})
      : _dirProvider = dirProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _dirProvider;
  _Snap? _cache;
  String? lastNote;

  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  Future<Set<String>> selfIds() async {
    final snap = await _load();
    return {
      snap.localUserId,
      if (snap.cloudUserId != null && snap.cloudUserId!.isNotEmpty)
        snap.cloudUserId!,
    };
  }

  Future<File> _file() async {
    final dir = await _dirProvider();
    return File(p.join(dir.path, 'ride_groups_local.json'));
  }

  Future<_Snap> _load() async {
    final cached = _cache;
    if (cached != null) return cached;
    try {
      final f = await _file();
      if (!await f.exists()) {
        return _cache = _Snap.empty();
      }
      final decoded = jsonDecode(await f.readAsString());
      if (decoded is! Map) return _cache = _Snap.empty();
      return _cache = _Snap.fromJson(decoded);
    } catch (_) {
      return _cache = _Snap.empty();
    }
  }

  Future<void> _save(_Snap snap) async {
    _cache = snap;
    revision.value++;
    try {
      final f = await _file();
      await f.writeAsString(jsonEncode(snap.toJson()));
    } catch (_) {}
  }

  Future<String> localUserId() async => (await _load()).localUserId;

  Future<bool> isSelfId(String userId) async => _isSelf(await _load(), userId);

  Future<List<RideGroup>> groups() async => (await _load()).groups;

  Future<List<RideGroup>> activeGroups() async {
    final all = await groups();
    return [
      for (final g in all)
        if (g.status != RideGroupStatus.closed) g,
    ];
  }

  Future<List<RideGroupMember>> membersOf(String groupId) async {
    return [
      for (final m in (await _load()).members)
        if (m.groupId == groupId) m,
    ];
  }

  Future<RideGroupMember?> localMember(String groupId) async {
    final snap = await _load();
    for (final m in snap.members) {
      if (m.groupId == groupId && _isSelf(snap, m.userId)) return m;
    }
    return null;
  }

  Future<RideGroup?> groupForRide(String? savedRouteId) async {
    final snap = await _load();
    final now = DateTime.now().toUtc();
    RideGroup? newestOpen;
    for (final g in await activeGroups()) {
      final mine = (await membersOf(g.id)).any((m) => _isSelf(snap, m.userId));
      if (!mine) continue;
      if (!RideGroupPolicy.canJoin(
        now: now,
        end: g.startWindowEnd,
        status: g.status,
      )) {
        continue;
      }
      final routeMatch = savedRouteId != null &&
          savedRouteId.isNotEmpty &&
          (g.savedRouteId == savedRouteId || g.catalogTourId == savedRouteId);
      if (routeMatch) return g;
      if (g.onServer &&
          (newestOpen == null || g.createdAt.isAfter(newestOpen.createdAt))) {
        newestOpen = g;
      }
    }
    return newestOpen;
  }

  Future<RideGroup> createGroup({
    required String savedRouteId,
    required String title,
    String? catalogTourId,
    required SavedRouteMeta? meta,
    DateTime? windowStart,
    DateTime? windowEnd,
    int? durationHours,
    String? meetingPoint,
    String displayLabel = 'Du',
    RideGroupVisibility visibility = RideGroupVisibility.private,
  }) async {
    if (!RideGroupPolicy.canAttachCourse(savedRouteId, meta)) {
      throw StateError('Nur freigegebene oder Katalog-Touren.');
    }
    final session = await RideGroupCloud.sessionState();
    if (session == 'signedOut') {
      lastNote = RideGroupCloud.needLoginNote;
      throw StateError(RideGroupCloud.needLoginNote);
    }
    final snap = await _load();
    final hours = durationHours ??
        (windowStart != null && windowEnd != null
            ? windowEnd.difference(windowStart).inHours.clamp(1, 12).toInt()
            : 3);
    final start = windowStart ?? DateTime.now().toUtc();
    final cloud = await RideGroupCloud.create(
      savedRouteId: savedRouteId,
      catalogTourId: catalogTourId,
      title: title.trim().isEmpty ? 'Gruppe' : title.trim(),
      visibility: visibility,
      startsAt: start,
      durationHours: hours,
      meetingPoint: meetingPoint,
    );
    if (cloud != null && cloud.ok && cloud.bundle!.groups.isNotEmpty) {
      lastNote = RideGroupCloud.onServerNote;
      await _save(_mergeCloud(snap, cloud.bundle!));
      return cloud.bundle!.groups.first;
    }
    if (session == 'signedIn') {
      lastNote = cloud?.note ??
          (cloud?.status == 401
              ? RideGroupCloud.needLoginNote
              : 'Anlegen auf dem Server fehlgeschlagen.');
      throw StateError(lastNote!);
    }
    if (cloud != null && (cloud.status == 501 || cloud.stub)) {
      lastNote = cloud.note ?? RideGroupCloud.serverTableNote;
    } else if (cloud == null || cloud.status == 401) {
      lastNote = RideGroupCloud.localOnlyNote;
    } else if (cloud.status == 0) {
      lastNote = cloud.note ?? RideGroupCloud.localOnlyNote;
    } else {
      lastNote = cloud.note ?? RideGroupCloud.localOnlyNote;
    }
    final now = DateTime.now().toUtc();
    final group = RideGroup(
      id: 'rg-${const Uuid().v4()}',
      hostUserId: snap.localUserId,
      savedRouteId: savedRouteId,
      catalogTourId: catalogTourId,
      title: title.trim().isEmpty ? 'Gruppe' : title.trim(),
      startWindowStart: start,
      startWindowEnd: windowEnd ?? start.add(Duration(hours: hours)),
      meetingPoint: meetingPoint?.trim().isEmpty == true
          ? null
          : meetingPoint?.trim(),
      joinCode: RideGroupPolicy.generateJoinCode(),
      status: RideGroupStatus.open,
      livePinsAllowed: true,
      createdAt: now,
      visibility: visibility,
    );
    final host = RideGroupMember(
      groupId: group.id,
      userId: snap.localUserId,
      displayLabel: displayLabel,
      joinedAt: now,
    );
    await _save(
      snap.copyWith(
        groups: [group, ...snap.groups],
        members: [host, ...snap.members],
      ),
    );
    return group;
  }

  Future<void> pullCloud() async {
    final cloud = await RideGroupCloud.list();
    if (cloud == null) return;
    if (!cloud.ok) {
      if (cloud.status == 501 || cloud.stub) {
        lastNote = cloud.note ?? RideGroupCloud.serverTableNote;
      }
      return;
    }
    lastNote = cloud.bundle!.groups.isEmpty
        ? lastNote
        : RideGroupCloud.onServerNote;
    await _save(_mergeCloud(await _load(), cloud.bundle!));
  }

  Future<RideGroup?> peekByCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.length != RideGroupPolicy.joinCodeLen) return null;
    for (final g in await activeGroups()) {
      if (g.joinCode == normalized) return g;
    }
    return null;
  }

  Future<void> leaveGroup(String groupId) async {
    final snap = await _load();
    RideGroup? group;
    for (final g in snap.groups) {
      if (g.id == groupId) group = g;
    }
    final host = group != null && _isSelf(snap, group.hostUserId);
    if (group != null && group.onServer) {
      final cloud = host
          ? await RideGroupCloud.close(groupId)
          : await RideGroupCloud.leave(groupId);
      if (cloud != null && cloud.ok) {
        lastNote = host ? 'Gruppe aufgelöst.' : 'Gruppe verlassen.';
      } else if (cloud != null && cloud.status == 0) {
        lastNote = cloud.note ?? 'Server nicht erreicht — Stand wird geprüft.';
      } else if (cloud != null && cloud.note != null) {
        lastNote = cloud.note;
      }
    }
    if (host) {
      await closeGroup(groupId);
    } else {
      await _save(
        snap.copyWith(
          groups: [
            for (final g in snap.groups)
              if (g.id != groupId) g,
          ],
          members: [
            for (final m in snap.members)
              if (m.groupId != groupId) m,
          ],
        ),
      );
    }
    await pullCloud();
  }

  Future<RideGroup?> joinByCode(String code, {String displayLabel = 'Du'}) async {
    return (await tryJoin(code: code, displayLabel: displayLabel)).group;
  }

  Future<RideGroupJoinOut> tryJoin({
    String? code,
    String? groupId,
    String? token,
    String displayLabel = 'Du',
  }) async {
    final raw = (groupId ?? code ?? '').trim();
    final asId = RideGroupPolicy.isGroupId(raw);
    final normalized = raw.toUpperCase();
    final asCode = !asId &&
        normalized.length == RideGroupPolicy.joinCodeLen;
    if (!asId && !asCode && (token == null || token.isEmpty)) {
      return const RideGroupJoinOut.fail(RideGroupJoinFail.needLink);
    }
    final session = await RideGroupCloud.sessionState();
    if (session == 'signedOut') {
      return const RideGroupJoinOut.fail(
        RideGroupJoinFail.needLogin,
        note: RideGroupCloud.needLoginJoinNote,
      );
    }
    final cloud = await RideGroupCloud.join(
      code: asCode ? normalized : null,
      groupId: asId ? raw : null,
      token: token,
    );
    if (cloud != null && cloud.ok && cloud.bundle!.groups.isNotEmpty) {
      lastNote = RideGroupCloud.onServerNote;
      await _save(_mergeCloud(await _load(), cloud.bundle!));
      final g = cloud.bundle!.groups.first;
      return cloud.bundle!.already
          ? RideGroupJoinOut.already(g, note: 'Schon dabei: ${g.title}. ${RideGroupCloud.onServerNote}')
          : RideGroupJoinOut.ok(g, note: 'Dabei: ${g.title}. ${RideGroupCloud.onServerNote}');
    }
    if (cloud != null && cloud.status == 403) {
      return RideGroupJoinOut.fail(
        RideGroupJoinFail.needLink,
        note: cloud.note,
      );
    }
    if (cloud != null && cloud.status == 400) {
      return RideGroupJoinOut.fail(
        RideGroupJoinFail.needLink,
        note: cloud.note,
      );
    }
    if (cloud != null && cloud.status == 410) {
      return RideGroupJoinOut.fail(
        RideGroupJoinFail.expired,
        note: cloud.note,
      );
    }
    if (cloud != null && cloud.status == 409) {
      return RideGroupJoinOut.fail(
        RideGroupJoinFail.closed,
        note: cloud.note,
      );
    }
    if (cloud != null && cloud.status == 401) {
      return RideGroupJoinOut.fail(
        RideGroupJoinFail.needLogin,
        note: cloud.note ?? RideGroupCloud.needLoginJoinNote,
      );
    }
    if (cloud != null && cloud.status == 404 && (token == null || token.isEmpty)) {
      return RideGroupJoinOut.fail(
        RideGroupJoinFail.unknown,
        note: cloud.note ??
            'Kein offener Link auf dem Server. Nur lokal angelegte Gruppen brauchen den Einladungslink.',
      );
    }
    final snap = await _load();
    RideGroup? hit;
    for (final g in snap.groups) {
      if ((asId && g.id.toLowerCase() == raw.toLowerCase()) ||
          (asCode && g.joinCode == normalized)) {
        hit = g;
        break;
      }
    }
    if (hit != null &&
        (token == null || token.isEmpty) &&
        hit.visibility == RideGroupVisibility.private &&
        !snap.members.any(
          (m) => m.groupId == hit!.id && m.userId == snap.localUserId,
        )) {
      return RideGroupJoinOut.fail(
        RideGroupJoinFail.needLink,
        note: 'Privat — nur mit Einladungslink.',
      );
    }
    if (hit != null) {
      if (hit.status == RideGroupStatus.closed) {
        return const RideGroupJoinOut.fail(RideGroupJoinFail.closed);
      }
      final now = DateTime.now().toUtc();
      if (!RideGroupPolicy.canJoin(
        now: now,
        end: hit.startWindowEnd,
        status: hit.status,
      )) {
        return RideGroupJoinOut.fail(
          RideGroupJoinFail.expired,
          note:
              'Fenster zu — ${RideGroupPolicy.formatWhen(hit.startWindowStart, hit.startWindowEnd)}.',
        );
      }
      if (session == 'signedIn' && hit.onServer) {
        return RideGroupJoinOut.fail(
          RideGroupJoinFail.unknown,
          note: cloud?.note ?? 'Beitritt auf dem Server fehlgeschlagen.',
        );
      }
      if (snap.members.any(
        (m) => m.groupId == hit!.id && m.userId == snap.localUserId,
      )) {
        return RideGroupJoinOut.already(hit);
      }
      final member = RideGroupMember(
        groupId: hit.id,
        userId: snap.localUserId,
        displayLabel: displayLabel,
        joinedAt: now,
      );
      await _save(snap.copyWith(members: [member, ...snap.members]));
      return RideGroupJoinOut.ok(hit);
    }
    if (token == null || token.isEmpty) {
      return RideGroupJoinOut.fail(
        RideGroupJoinFail.unknown,
        note: session == 'signedOut'
            ? RideGroupCloud.needLoginJoinNote
            : cloud?.note ??
                'Kein offener Link auf dem Server.',
      );
    }
    if (session == 'signedIn') {
      return RideGroupJoinOut.fail(
        RideGroupJoinFail.unknown,
        note: cloud?.note ?? 'Beitritt auf dem Server fehlgeschlagen.',
      );
    }
    return tryJoinFromInvite(
      code: raw,
      token: token,
      displayLabel: displayLabel,
    );
  }

  Future<void> setVisibility(String groupId, RideGroupVisibility visibility) async {
    final cloud = await RideGroupCloud.setVisibility(
      id: groupId,
      visibility: visibility,
    );
    final snap = await _load();
    RideGroup? updated;
    if (cloud != null && cloud.ok && cloud.bundle!.groups.isNotEmpty) {
      updated = cloud.bundle!.groups.first;
      lastNote = visibility == RideGroupVisibility.public
          ? 'Gruppe öffentlich — wer den Link hat, kann beitreten.'
          : 'Gruppe privat — nur der Link.';
    }
    await _save(
      snap.copyWith(
        groups: [
          for (final g in snap.groups)
            if (g.id == groupId)
              (updated ?? g).copyWith(visibility: visibility)
            else
              g,
        ],
      ),
    );
  }

  Future<List<RideGroup>> publicGroups() async {
    final cloud = await RideGroupCloud.listPublic();
    if (cloud == null || !cloud.ok) return const [];
    final mine = {for (final g in await activeGroups()) g.id};
    return [
      for (final g in cloud.bundle!.groups)
        if (!mine.contains(g.id)) g,
    ];
  }

  Future<void> relabelLocal(String groupId, String displayLabel) async {
    final next = displayLabel.trim();
    if (next.isEmpty) return;
    final snap = await _load();
    var changed = false;
    final members = <RideGroupMember>[];
    for (final m in snap.members) {
      if (m.groupId == groupId &&
          _isSelf(snap, m.userId) &&
          m.displayLabel != next) {
        changed = true;
        members.add(m.copyWith(displayLabel: next));
      } else {
        members.add(m);
      }
    }
    if (!changed) return;
    await _save(snap.copyWith(members: members));
  }

  /// Beitritt per Link: lokaler Code oder Invite-Token (Titel/Tour/Fenster).
  /// Kein Fake-Roster — nur dieser Speicher, nur echte Gruppe.
  Future<RideGroup?> joinFromInvite({
    required String code,
    String? token,
    String displayLabel = 'Du',
  }) async {
    return (await tryJoin(
      code: code,
      token: token,
      displayLabel: displayLabel,
    )).group;
  }

  Future<RideGroupJoinOut> tryJoinFromInvite({
    String? code,
    required String token,
    String displayLabel = 'Du',
  }) async {
    final payload = RideGroupInvite.decode(token);
    if (payload == null) {
      return const RideGroupJoinOut.fail(RideGroupJoinFail.unknown);
    }
    final raw = (code ?? '').trim();
    if (raw.isNotEmpty) {
      final matchesCode = raw.toUpperCase() == payload.code;
      final matchesId = raw.toLowerCase() == payload.id.toLowerCase();
      if (!matchesCode && !matchesId) {
        return const RideGroupJoinOut.fail(RideGroupJoinFail.unknown);
      }
    }
    final now = DateTime.now().toUtc();
    if (!payload.windowOpen(now)) {
      return const RideGroupJoinOut.fail(RideGroupJoinFail.expired);
    }

    final snap = await _load();
    final already = snap.groups.any((g) => g.id == payload.id);
    final group = already
        ? snap.groups.firstWhere((g) => g.id == payload.id)
        : RideGroup(
            id: payload.id,
            hostUserId:
                payload.hostUserId.isEmpty ? 'invite-host' : payload.hostUserId,
            savedRouteId: payload.savedRouteId,
            catalogTourId: payload.catalogTourId,
            title: payload.title,
            startWindowStart: payload.start,
            startWindowEnd: payload.end,
            joinCode: payload.code,
            status: RideGroupStatus.open,
            livePinsAllowed: true,
            createdAt: now,
          );
    if (group.status == RideGroupStatus.closed) {
      return const RideGroupJoinOut.fail(RideGroupJoinFail.closed);
    }
    if (snap.members.any(
      (m) => m.groupId == group.id && m.userId == snap.localUserId,
    )) {
      return RideGroupJoinOut.already(group);
    }
    final member = RideGroupMember(
      groupId: group.id,
      userId: snap.localUserId,
      displayLabel: displayLabel,
      joinedAt: now,
    );
    await _save(
      snap.copyWith(
        groups: already ? snap.groups : [group, ...snap.groups],
        members: [member, ...snap.members],
      ),
    );
    return RideGroupJoinOut.ok(group);
  }

  Future<void> setLiveOptIn(String groupId, bool on) async {
    final snap = await _load();
    await _save(
      snap.copyWith(
        members: [
          for (final m in snap.members)
            if (m.groupId == groupId && _isSelf(snap, m.userId))
              m.copyWith(liveOptIn: on)
            else
              m,
        ],
      ),
    );
    RideGroup? group;
    for (final g in snap.groups) {
      if (g.id == groupId) group = g;
    }
    if (group != null && group.onServer) {
      await RideGroupCloud.presencePublish(groupId: groupId, liveOptIn: on);
    }
  }

  Future<void> closeGroup(String groupId) async {
    final snap = await _load();
    await _save(
      snap.copyWith(
        groups: [
          for (final g in snap.groups)
            if (g.id == groupId)
              RideGroup(
                id: g.id,
                hostUserId: g.hostUserId,
                savedRouteId: g.savedRouteId,
                catalogTourId: g.catalogTourId,
                title: g.title,
                startWindowStart: g.startWindowStart,
                startWindowEnd: g.startWindowEnd,
                joinCode: g.joinCode,
                status: RideGroupStatus.closed,
                livePinsAllowed: g.livePinsAllowed,
                createdAt: g.createdAt,
                onServer: g.onServer,
              )
            else
              g,
        ],
      ),
    );
  }

  Future<void> publishPresence({
    required String groupId,
    required double lat,
    required double lng,
    required List<PrivacyZone> zones,
  }) async {
    final snap = await _load();
    RideGroup? group;
    for (final g in snap.groups) {
      if (g.id == groupId) group = g;
    }
    if (group == null) return;
    RideGroupMember? me;
    for (final m in snap.members) {
      if (m.groupId == groupId && _isSelf(snap, m.userId)) {
        me = m;
        break;
      }
    }
    if (me == null) return;
    final now = DateTime.now().toUtc();
    final q = RideGroupPolicy.quantize(lat, lng);
    final vis = RideGroupPolicy.resolvePresence(
      isMember: true,
      livePinsAllowed: group.livePinsAllowed,
      liveOptIn: me.liveOptIn,
      inEventWindow: RideGroupPolicy.isEventWindowOpen(
        now: now,
        start: group.startWindowStart,
        end: group.startWindowEnd,
        status: group.status,
      ),
      inPrivacyZone: RideGroupPolicy.pointInPrivacyZones(q.lat, q.lng, zones),
      hasFix: true,
      ageMs: 0,
    );
    final next = RideGroupPresence(
      groupId: groupId,
      userId: snap.localUserId,
      lng: RideGroupPolicy.pinVisible(vis) ? q.lng : null,
      lat: RideGroupPolicy.pinVisible(vis) ? q.lat : null,
      updatedAt: now,
      visibility: vis,
    );
    await _save(
      snap.copyWith(
        presence: [
          next,
          for (final p in snap.presence)
            if (!(p.groupId == groupId && p.userId == snap.localUserId)) p,
        ],
      ),
    );
    if (group.onServer) {
      final cloud = await RideGroupCloud.presencePublish(
        groupId: groupId,
        lat: q.lat,
        lng: q.lng,
        inPrivacyZone: vis == RideGroupPresenceVisibility.hiddenZone,
        liveOptIn: me.liveOptIn,
      );
      if (cloud != null && cloud.ok) {
        await _applyPresenceBundle(groupId, cloud.bundle!);
      }
    }
  }

  Future<void> pullPresence(String groupId) async {
    RideGroup? group;
    for (final g in await groups()) {
      if (g.id == groupId) group = g;
    }
    if (group == null || !group.onServer) return;
    final cloud = await RideGroupCloud.presenceList(groupId);
    if (cloud == null || !cloud.ok) return;
    await _applyPresenceBundle(groupId, cloud.bundle!);
  }

  Future<void> _applyPresenceBundle(
    String groupId,
    RideGroupCloudBundle bundle,
  ) async {
    final snap = await _load();
    final opt = {for (final m in bundle.members) m.userId: m.liveOptIn};
    await _save(
      snap.copyWith(
        presence: [
          for (final p in snap.presence)
            if (p.groupId != groupId) p,
          ...bundle.presence,
        ],
        members: [
          for (final m in snap.members)
            if (m.groupId == groupId && opt.containsKey(m.userId))
              m.copyWith(liveOptIn: opt[m.userId])
            else
              m,
        ],
      ),
    );
  }

  Future<List<RideGroupPresence>> visiblePins({
    required String groupId,
    required List<PrivacyZone> zones,
  }) async {
    final snap = await _load();
    RideGroup? group;
    for (final g in snap.groups) {
      if (g.id == groupId) group = g;
    }
    if (group == null) return const [];
    final now = DateTime.now().toUtc();
    final inWindow = RideGroupPolicy.isEventWindowOpen(
      now: now,
      start: group.startWindowStart,
      end: group.startWindowEnd,
      status: group.status,
    );
    final out = <RideGroupPresence>[];
    for (final p in snap.presence) {
      if (p.groupId != groupId) continue;
      final member = snap.members.any(
        (m) => m.groupId == groupId && m.userId == p.userId,
      );
      final opt = snap.members.any(
        (m) =>
            m.groupId == groupId && m.userId == p.userId && m.liveOptIn,
      );
      final age = now.difference(p.updatedAt).inMilliseconds;
      final vis = RideGroupPolicy.resolvePresence(
        isMember: member,
        livePinsAllowed: group.livePinsAllowed,
        liveOptIn: opt,
        inEventWindow: inWindow,
        inPrivacyZone: p.lat != null && p.lng != null
            ? RideGroupPolicy.pointInPrivacyZones(p.lat!, p.lng!, zones)
            : false,
        hasFix: p.lat != null && p.lng != null,
        ageMs: age,
      );
      if (!RideGroupPolicy.pinVisible(vis)) continue;
      if (p.lat == null || p.lng == null) continue;
      out.add(
        RideGroupPresence(
          groupId: p.groupId,
          userId: p.userId,
          lat: p.lat,
          lng: p.lng,
          updatedAt: p.updatedAt,
          visibility: vis,
        ),
      );
    }
    return out;
  }

  Future<int> inboxSeen() async => (await _load()).inboxSeen;
  Future<void> markInboxSeen(int n) async {
    final snap = await _load();
    if (snap.inboxSeen == n) return;
    await _save(snap.copyWith(inboxSeen: n));
  }
}

final _rng = Random();

double mathRandom() => _rng.nextDouble();

bool _isSelf(_Snap snap, String userId) =>
    userId == snap.localUserId ||
    (snap.cloudUserId != null &&
        snap.cloudUserId!.isNotEmpty &&
        userId == snap.cloudUserId);

_Snap _mergeCloud(_Snap snap, RideGroupCloudBundle bundle) {
  final ids = {for (final g in bundle.groups) g.id};
  final codes = {for (final g in bundle.groups) g.joinCode};
  final merged = snap.copyWith(
    cloudUserId: bundle.me.isEmpty ? snap.cloudUserId : bundle.me,
  );
  final keepLocal = [
    for (final g in snap.groups)
      if (!ids.contains(g.id) &&
          !codes.contains(g.joinCode) &&
          RideGroupPolicy.keepLocalAfterCloud(
            onServer: g.onServer,
            selfIsHost: _isSelf(merged, g.hostUserId),
          ))
        g,
  ];
  final keepIds = {for (final g in keepLocal) g.id};
  return merged.copyWith(
    groups: [...bundle.groups, ...keepLocal],
    members: [
      ...bundle.members,
      for (final m in snap.members)
        if (!ids.contains(m.groupId) && keepIds.contains(m.groupId)) m,
    ],
  );
}

class _Snap {
  _Snap({
    required this.localUserId,
    required this.groups,
    required this.members,
    required this.presence,
    required this.inboxSeen,
    this.cloudUserId,
  });

  factory _Snap.empty() => _Snap(
        localUserId: 'local-${const Uuid().v4()}',
        groups: const [],
        members: const [],
        presence: const [],
        inboxSeen: 0,
      );

  final String localUserId;
  final String? cloudUserId;
  final List<RideGroup> groups;
  final List<RideGroupMember> members;
  final List<RideGroupPresence> presence;
  final int inboxSeen;

  _Snap copyWith({
    String? cloudUserId,
    List<RideGroup>? groups,
    List<RideGroupMember>? members,
    List<RideGroupPresence>? presence,
    int? inboxSeen,
  }) =>
      _Snap(
        localUserId: localUserId,
        cloudUserId: cloudUserId ?? this.cloudUserId,
        groups: groups ?? this.groups,
        members: members ?? this.members,
        presence: presence ?? this.presence,
        inboxSeen: inboxSeen ?? this.inboxSeen,
      );

  Map<String, dynamic> toJson() => {
        'localUserId': localUserId,
        'cloudUserId': cloudUserId,
        'inboxSeen': inboxSeen,
        'groups': [for (final g in groups) g.toJson()],
        'members': [for (final m in members) m.toJson()],
        'presence': [for (final p in presence) p.toJson()],
      };

  factory _Snap.fromJson(Map raw) {
    return _Snap(
      localUserId: raw['localUserId'] as String? ?? 'local-${const Uuid().v4()}',
      cloudUserId: raw['cloudUserId'] as String?,
      inboxSeen: (raw['inboxSeen'] as num?)?.toInt() ?? 0,
      groups: [
        for (final e in (raw['groups'] as List? ?? const []))
          if (RideGroup.fromJson(e) != null) RideGroup.fromJson(e)!,
      ],
      members: [
        for (final e in (raw['members'] as List? ?? const []))
          if (RideGroupMember.fromJson(e) != null) RideGroupMember.fromJson(e)!,
      ],
      presence: [
        for (final e in (raw['presence'] as List? ?? const []))
          if (RideGroupPresence.fromJson(e) != null)
            RideGroupPresence.fromJson(e)!,
      ],
    );
  }
}
