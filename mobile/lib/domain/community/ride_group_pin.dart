import 'dart:math' as math;

import '../routing/route_progress.dart';
import 'ride_group.dart';
import 'ride_group_policy.dart';
import 'ride_together.dart';

/// Karten-Chip und HUD-Zeile für Event-Live-GPS. Kein Demo-Fahrer.
String friendPinInitials(String label) {
  final t = label.trim();
  if (t.isEmpty) return '?';
  if (t.startsWith('@') && t.length > 1) {
    final body = t.substring(1).trim();
    if (body.isNotEmpty) return body[0].toUpperCase();
  }
  final parts = t.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return t[0].toUpperCase();
}

Map<String, int> friendUnnamedNumbers({
  required Iterable<RideGroupMember> members,
  required Set<String> selfIds,
}) {
  final unnamed = [
    for (final m in members)
      if (!selfIds.contains(m.userId) && m.displayLabel.trim().isEmpty) m,
  ]..sort((a, b) => a.userId.compareTo(b.userId));
  return {
    for (var i = 0; i < unnamed.length; i++) unnamed[i].userId: i + 1,
  };
}

String friendRosterName({
  required String displayLabel,
  required bool self,
  int? friendN,
  required String fallbackSelf,
  required String fallbackOther,
  String Function(int n)? friendLabel,
}) {
  final raw = displayLabel.trim();
  if (raw.isNotEmpty) return raw;
  if (self) return fallbackSelf;
  if (friendN != null && friendLabel != null) return friendLabel(friendN);
  return fallbackOther;
}

/// Eine Roster-Zeile: `Du · Gastgeber`, nie `Du · Gastgeber · Du`.
/// Leere Labels nur `Freund n`, nicht `Gast · Gast`.
String friendMemberLine({
  required String displayLabel,
  required bool self,
  required bool isHost,
  int? friendN,
  required String fallbackSelf,
  required String fallbackOther,
  required String hostRole,
  required String guestRole,
  String Function(int n)? friendLabel,
}) {
  final name = friendRosterName(
    displayLabel: displayLabel,
    self: self,
    friendN: friendN,
    fallbackSelf: fallbackSelf,
    fallbackOther: fallbackOther,
    friendLabel: friendLabel,
  );
  final role = isHost ? hostRole : guestRole;
  if (self) return '$name · $role';
  if (displayLabel.trim().isEmpty && friendN != null && friendLabel != null) {
    return friendLabel(friendN);
  }
  if (displayLabel.trim().isEmpty) return role;
  return '$name · $role';
}

/// HUD-Status: allein kein `1/1`. Ratio nur wenn wirklich andere da sind.
String rideGroupHudStatusLine({
  required RideGroupHudSnap snap,
  required String left,
  required String Function(String left) selfOn,
  required String Function(String left) selfOff,
  required String Function(int sharing, int total, String left) ratio,
  required String Function(String detail, String left) withDetail,
  String Function(RideGroupHudMate mate)? mateDetail,
}) {
  final others = [for (final m in snap.mates) if (!m.self) m];
  if (others.isEmpty) {
    return snap.optIn ? selfOn(left) : selfOff(left);
  }
  if (snap.sharing < snap.total && snap.total >= 2) {
    return ratio(snap.sharing, snap.total, left);
  }
  if (mateDetail != null) {
    RideGroupHudMate? nearest;
    for (final m in others) {
      if (!m.sharing || m.meters == null) continue;
      if (nearest == null || m.meters! < (nearest.meters ?? 1 << 30)) {
        nearest = m;
      }
    }
    if (nearest != null) {
      final detail = mateDetail(nearest);
      if (detail.isNotEmpty) return withDetail(detail, left);
    }
  }
  final named = others.where((m) => m.label.trim().isNotEmpty);
  if (named.isNotEmpty) {
    return withDetail(named.first.label, left);
  }
  return ratio(snap.sharing, snap.total, left);
}

String friendPinName(String label, {int max = 12}) {
  final t = label.trim();
  if (t.isEmpty) return '?';
  if (t.length <= max) return t;
  return '${t.substring(0, max - 1)}…';
}

enum FriendRel { ahead, behind, left, right }

double friendBearingDeg(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  final lat1r = lat1 * math.pi / 180;
  final lat2r = lat2 * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final y = math.sin(dLng) * math.cos(lat2r);
  final x = math.cos(lat1r) * math.sin(lat2r) -
      math.sin(lat1r) * math.cos(lat2r) * math.cos(dLng);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

FriendRel? friendRelative({
  required double? headingDeg,
  required double bearingDeg,
}) {
  if (headingDeg == null) return null;
  final d = (bearingDeg - headingDeg + 360) % 360;
  if (d >= 315 || d < 45) return FriendRel.ahead;
  if (d < 135) return FriendRel.right;
  if (d < 225) return FriendRel.behind;
  return FriendRel.left;
}

String friendPinChip({
  required String name,
  int? meters,
  required bool stale,
  required String staleLabel,
  String? relLabel,
}) {
  final short = friendPinName(name);
  if (stale) return '$short · $staleLabel';
  if (meters == null) return short;
  final dist = friendDistLabel(meters);
  if (relLabel == null || relLabel.isEmpty) return '$short · $dist';
  return '$short · $dist $relLabel';
}

String friendDistLabel(int meters) {
  if (meters < 1000) return '$meters m';
  final km = meters / 1000;
  return km >= 10 ? '${km.round()} km' : '${km.toStringAsFixed(1)} km';
}

String friendUntilHm(DateTime end) {
  final l = end.toLocal();
  final h = l.hour.toString().padLeft(2, '0');
  final m = l.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String friendShareOnLine({
  required List<String> otherNames,
  required String untilHm,
  required String Function(String name, String time) one,
  required String Function(int count, String time) many,
  required String Function(String time) none,
}) {
  if (otherNames.isEmpty) return none(untilHm);
  if (otherNames.length == 1) return one(otherNames.first, untilHm);
  return many(otherNames.length, untilHm);
}

String? friendRelLabel(
  FriendRel? rel, {
  required String ahead,
  required String behind,
  required String left,
  required String right,
}) {
  return switch (rel) {
    FriendRel.ahead => ahead,
    FriendRel.behind => behind,
    FriendRel.left => left,
    FriendRel.right => right,
    null => null,
  };
}

enum RideGroupHudNote { none, windowClosed, mateLeft, groupGone }

class RideGroupHudDelta {
  const RideGroupHudDelta(this.note, [this.name]);
  final RideGroupHudNote note;
  final String? name;
}

RideGroupHudDelta friendHudDelta({
  required RideGroupHudSnap? prev,
  required RideGroupHudSnap? next,
  required DateTime now,
}) {
  if (prev == null) return const RideGroupHudDelta(RideGroupHudNote.none);
  final nowUtc = now.toUtc();
  final prevOpen = !nowUtc.isAfter(prev.windowEnd.toUtc());
  if (next == null) {
    return RideGroupHudDelta(
      prevOpen ? RideGroupHudNote.groupGone : RideGroupHudNote.windowClosed,
    );
  }
  final nextOpen = !nowUtc.isAfter(next.windowEnd.toUtc());
  if (prevOpen && !nextOpen) {
    return const RideGroupHudDelta(RideGroupHudNote.windowClosed);
  }
  final prevIds = {
    for (final m in prev.mates)
      if (!m.self) m.userId: m.label,
  };
  final nextIds = {for (final m in next.mates) if (!m.self) m.userId};
  for (final e in prevIds.entries) {
    if (!nextIds.contains(e.key)) {
      return RideGroupHudDelta(RideGroupHudNote.mateLeft, e.value);
    }
  }
  return const RideGroupHudDelta(RideGroupHudNote.none);
}

int? friendPinMeters({
  required double? selfLat,
  required double? selfLng,
  required double? lat,
  required double? lng,
}) {
  if (selfLat == null || selfLng == null || lat == null || lng == null) {
    return null;
  }
  return haversineM(selfLat, selfLng, lat, lng).round();
}

String friendWindowLeft({
  required DateTime end,
  required DateTime now,
  required String closed,
  required String Function(int hours) hours,
  required String Function(int minutes) mins,
}) {
  final left = end.toUtc().difference(now.toUtc());
  if (left.isNegative || left.inSeconds <= 0) return closed;
  if (left.inMinutes >= 60) return hours(left.inHours);
  return mins(left.inMinutes == 0 ? 1 : left.inMinutes);
}

String friendHudLine({
  required int sharing,
  required int total,
  required String left,
}) =>
    '$sharing/$total · $left';

class RideGroupHudMate {
  const RideGroupHudMate({
    required this.userId,
    required this.label,
    required this.self,
    required this.sharing,
    this.stale = false,
    this.meters,
    this.lat,
    this.lng,
    this.rel,
  });

  final String userId;
  final String label;
  final bool self;
  final bool sharing;
  final bool stale;
  final int? meters;
  final double? lat;
  final double? lng;
  final FriendRel? rel;
}

class RideGroupHudSnap {
  const RideGroupHudSnap({
    required this.groupId,
    required this.title,
    required this.optIn,
    required this.sharing,
    required this.total,
    required this.windowEnd,
    required this.mates,
    this.selfIsHost = false,
    this.isSession = false,
    this.joinCode,
    this.atCap = false,
  });

  final String groupId;
  final String title;
  final bool optIn;
  final int sharing;
  final int total;
  final DateTime windowEnd;
  final List<RideGroupHudMate> mates;
  final bool selfIsHost;
  final bool isSession;
  final String? joinCode;
  final bool atCap;
}

RideGroupHudSnap buildRideGroupHudSnap({
  required RideGroup group,
  required List<RideGroupMember> members,
  required List<RideGroupPresence> pins,
  required Set<String> selfIds,
  required bool optIn,
  double? selfLat,
  double? selfLng,
  double? headingDeg,
  String fallbackSelf = 'Du',
  String fallbackOther = 'Gast',
  String Function(int n)? friendN,
}) {
  final pinByUser = {for (final p in pins) p.userId: p};
  final numbered = friendUnnamedNumbers(members: members, selfIds: selfIds);
  final mates = <RideGroupHudMate>[];
  for (final m in members) {
    final self = selfIds.contains(m.userId);
    final pin = pinByUser[m.userId];
    final sharing = pin != null &&
        RideGroupPolicy.pinVisible(pin.visibility) &&
        pin.lat != null;
    final label = friendRosterName(
      displayLabel: m.displayLabel,
      self: self,
      friendN: numbered[m.userId],
      fallbackSelf: fallbackSelf,
      fallbackOther: fallbackOther,
      friendLabel: friendN,
    );
    final meters = self
        ? null
        : friendPinMeters(
            selfLat: selfLat,
            selfLng: selfLng,
            lat: pin?.lat,
            lng: pin?.lng,
          );
    FriendRel? rel;
    if (!self &&
        selfLat != null &&
        selfLng != null &&
        pin?.lat != null &&
        pin?.lng != null) {
      rel = friendRelative(
        headingDeg: headingDeg,
        bearingDeg: friendBearingDeg(selfLat, selfLng, pin!.lat!, pin.lng!),
      );
    }
    mates.add(
      RideGroupHudMate(
        userId: m.userId,
        label: label,
        self: self,
        sharing: self ? optIn : sharing,
        stale: pin?.visibility == RideGroupPresenceVisibility.stale,
        meters: meters,
        lat: self ? selfLat : pin?.lat,
        lng: self ? selfLng : pin?.lng,
        rel: rel,
      ),
    );
  }
  final sharing = mates.where((e) => e.sharing).length;
  return RideGroupHudSnap(
    groupId: group.id,
    title: group.title,
    optIn: optIn,
    sharing: sharing,
    total: members.length,
    windowEnd: group.startWindowEnd,
    mates: mates,
    selfIsHost: selfIds.contains(group.hostUserId),
    isSession: RideTogetherPolicy.isSessionRouteId(group.savedRouteId),
    joinCode: RideTogetherPolicy.isSessionRouteId(group.savedRouteId)
        ? group.joinCode
        : null,
    atCap: members.length >= RideTogetherPolicy.memberCap,
  );
}
