import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../domain/community/ride_group.dart';
import '../../domain/community/ride_group_policy.dart';
import '../../domain/community/ride_together.dart';
import 'ride_group_cloud.dart';
import 'ride_together_cloud.dart';
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

  Future<RideGroup?> groupForRide(
    String? savedRouteId, {
    String? preferGroupId,
    String? catalogTourId,
  }) async {
    final snap = await _load();
    final now = DateTime.now().toUtc();
    final mine = <RideGroup>[];
    for (final g in await activeGroups()) {
      final members = await membersOf(g.id);
      if (!members.any((m) => _isSelf(snap, m.userId))) continue;
      if (!RideGroupPolicy.canJoin(
        now: now,
        end: g.startWindowEnd,
        status: g.status,
      )) {
        continue;
      }
      mine.add(g);
    }
    final counts = <String, int>{};
    for (final m in snap.members) {
      counts[m.groupId] = (counts[m.groupId] ?? 0) + 1;
    }
    final prefer = preferGroupId?.trim() ?? '';
    if (prefer.isNotEmpty &&
        !RideTogetherPolicy.isFreerideRide(savedRouteId)) {
      for (final g in mine) {
        if (g.id == prefer) return g;
      }
    }
    return RideTogetherPolicy.pickGroupForRide(
      rideRouteId: savedRouteId,
      catalogTourId: catalogTourId,
      groups: mine,
      memberCounts: counts,
    );
  }

  Future<void> adoptCloudBundle(RideGroupCloudBundle bundle) async {
    if (bundle.groups.isEmpty && bundle.members.isEmpty) return;
    await _save(_mergeCloud(await _load(), bundle));
  }

  /// Ride-Stopp: dieses Gerät steigt aus. Die Session bleibt, wenn noch jemand da ist.
  Future<void> endFreerideSession() async {
    final snap = await _load();
    final now = DateTime.now().toUtc();
    final mine = <RideGroup>[];
    for (final g in await activeGroups()) {
      if (!RideTogetherPolicy.isSessionRouteId(g.savedRouteId)) continue;
      if (!(await membersOf(g.id)).any((m) => _isSelf(snap, m.userId))) {
        continue;
      }
      if (!RideGroupPolicy.canJoin(
        now: now,
        end: g.startWindowEnd,
        status: g.status,
      )) {
        continue;
      }
      mine.add(g);
    }
    mine.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    for (final g in mine) {
      await leaveGroup(g.id);
    }
  }

  Future<RideGroup> createGroup({
    required String savedRouteId,
    required String title,
    String? catalogTourId,
    required SavedRouteMeta? meta,
    DateTime? windowStart,
    DateTime? windowEnd,
    num? durationHours,
    String? meetingPoint,
    String displayLabel = 'Du',
    RideGroupVisibility visibility = RideGroupVisibility.private,
  }) async {
    if (!RideGroupPolicy.canAttachCourse(savedRouteId, meta)) {
      throw StateError('Zuerst eine Tour wählen oder selbst planen.');
    }
    final session = await RideGroupCloud.sessionState();
    if (session == 'signedOut') {
      lastNote = RideGroupCloud.needLoginNote;
      throw StateError(RideGroupCloud.needLoginNote);
    }
    final snap = await _load();
    final parsed = RideGroupPolicy.parseWindow(
      startsAt: windowStart ?? DateTime.now().toUtc(),
      endsAt: windowEnd,
      durationHours: windowEnd == null ? (durationHours ?? 3) : null,
      now: DateTime.now().toUtc(),
    );
    if (parsed == null) {
      lastNote = 'Startzeit und Dauer (15 Min–12 h) nötig.';
      throw StateError(lastNote!);
    }
    final start = parsed.start;
    final hours = parsed.durationHours;
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
      startWindowEnd: parsed.end,
      meetingPoint: meetingPoint?.trim().isEmpty == true
          ? null
          : meetingPoint?.trim(),
      joinCode: RideGroupPolicy.generateJoinCode(),
      status: parsed.status,
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
    final normalized = RideGroupPolicy.normalizeJoinCode(code);
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
    if (group != null &&
        RideTogetherPolicy.isSessionRouteId(group.savedRouteId)) {
      if (group.onServer) {
        await RideTogetherCloud.end(group.id);
      }
      final others = [
        for (final m in snap.members)
          if (m.groupId == groupId && !_isSelf(snap, m.userId)) m,
      ];
      if (others.isEmpty) {
        await closeGroup(groupId);
      } else {
        await _save(
          snap.copyWith(
            members: [
              for (final m in snap.members)
                if (!(m.groupId == groupId && _isSelf(snap, m.userId))) m,
            ],
          ),
        );
      }
      await RideTogetherCloud.stopLook();
      lastNote = 'Ausgestiegen — die anderen fahren weiter.';
      return;
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
    final normalized = RideGroupPolicy.normalizeJoinCode(raw);
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
          ? 'Auf dem Platz gelistet — Link oder Code reicht.'
          : 'Nur per Link — nicht auf dem Platz.';
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

  Future<bool> extendWindow(
    String groupId, {
    num hours = 1,
    DateTime? newEnd,
  }) async {
    final snap = await _load();
    RideGroup? group;
    for (final g in snap.groups) {
      if (g.id == groupId) group = g;
    }
    if (group == null || group.status == RideGroupStatus.closed) return false;
    if (!_isSelf(snap, group.hostUserId)) return false;
    if (newEnd == null && !RideGroupPolicy.isValidDurationHours(hours)) {
      lastNote = 'Zeit liegt außerhalb des Rahmens.';
      return false;
    }
    if (newEnd != null) {
      final n = DateTime.now().toUtc();
      final base = group.startWindowEnd.toUtc().isAfter(n)
          ? group.startWindowEnd.toUtc()
          : n;
      if (!newEnd.toUtc().isAfter(base)) {
        lastNote = 'Zeit liegt außerhalb des Rahmens.';
        return false;
      }
    }
    var next = RideGroupPolicy.extendWindowEnd(
      now: DateTime.now(),
      end: group.startWindowEnd,
      hours: hours,
      newEnd: newEnd,
    );
    if (group.onServer) {
      final cloud = await RideGroupCloud.extendWindow(
        id: groupId,
        addHours: hours,
        newEnd: newEnd,
      );
      if (cloud != null && cloud.ok && cloud.bundle!.groups.isNotEmpty) {
        next = cloud.bundle!.groups.first.startWindowEnd;
      } else if (cloud != null && !cloud.ok && cloud.status >= 400) {
        lastNote = cloud.note ?? 'Fenster nicht verlängert.';
        return false;
      }
    }
    final fresh = await _load();
    await _save(
      fresh.copyWith(
        groups: [
          for (final g in fresh.groups)
            if (g.id == groupId) g.copyWith(startWindowEnd: next) else g,
        ],
      ),
    );
    lastNote = 'Fenster verlängert.';
    return true;
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
                visibility: g.visibility,
                meetingPoint: g.meetingPoint,
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

  /// Presence-GET/POST liefert das volle Roster. Ohne Merge bleibt der
  /// Freund lokal unbekannt — [visiblePins] blendet ihn als Nicht-Mitglied aus.
  @visibleForTesting
  Future<void> applyPresenceFromCloud(
    String groupId,
    RideGroupCloudBundle bundle,
  ) =>
      _applyPresenceBundle(groupId, bundle);

  Future<void> _applyPresenceBundle(
    String groupId,
    RideGroupCloudBundle bundle,
  ) async {
    final snap = await _load();
    final incoming = [
      for (final m in bundle.members)
        if (m.groupId == groupId) m,
    ];
    RideGroup? incomingGroup;
    for (final g in bundle.groups) {
      if (g.id == groupId) incomingGroup = g;
    }
    final groups = incomingGroup == null
        ? snap.groups
        : [
            if (!snap.groups.any((g) => g.id == groupId))
              RideGroup(
                id: incomingGroup.id,
                hostUserId: incomingGroup.hostUserId,
                savedRouteId: incomingGroup.savedRouteId,
                catalogTourId: incomingGroup.catalogTourId,
                title: incomingGroup.title,
                startWindowStart: incomingGroup.startWindowStart,
                startWindowEnd: incomingGroup.startWindowEnd,
                joinCode: incomingGroup.joinCode,
                status: incomingGroup.status,
                livePinsAllowed: incomingGroup.livePinsAllowed,
                createdAt: incomingGroup.createdAt,
                onServer: true,
                visibility: incomingGroup.visibility,
                meetingPoint: incomingGroup.meetingPoint,
              ),
            for (final g in snap.groups)
              if (g.id == groupId)
                RideGroup(
                  id: g.id,
                  hostUserId: incomingGroup.hostUserId.isNotEmpty
                      ? incomingGroup.hostUserId
                      : g.hostUserId,
                  savedRouteId: incomingGroup.savedRouteId.isNotEmpty
                      ? incomingGroup.savedRouteId
                      : g.savedRouteId,
                  catalogTourId:
                      incomingGroup.catalogTourId ?? g.catalogTourId,
                  title: incomingGroup.title.isNotEmpty
                      ? incomingGroup.title
                      : g.title,
                  startWindowStart: incomingGroup.startWindowStart,
                  startWindowEnd: incomingGroup.startWindowEnd,
                  joinCode: incomingGroup.joinCode.isNotEmpty
                      ? incomingGroup.joinCode
                      : g.joinCode,
                  status: incomingGroup.status,
                  livePinsAllowed: incomingGroup.livePinsAllowed,
                  createdAt: g.createdAt,
                  onServer: true,
                  visibility: incomingGroup.visibility,
                  meetingPoint: incomingGroup.meetingPoint ?? g.meetingPoint,
                )
              else
                g,
          ];
    await _save(
      snap.copyWith(
        cloudUserId: bundle.me.isEmpty ? snap.cloudUserId : bundle.me,
        groups: groups,
        presence: [
          for (final p in snap.presence)
            if (p.groupId != groupId) p,
          ...bundle.presence,
        ],
        members: incoming.isEmpty
            ? snap.members
            : [
                for (final m in snap.members)
                  if (m.groupId != groupId) m,
                ...incoming,
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
