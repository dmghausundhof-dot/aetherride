/// Zusammen raus — Gruppe vor dem Tor.
///
/// Types only. Policy lives in `src/lib/community/rideGroup.ts`.
/// HUD: [RideLiveLayer.map] in ride_screen `_drawRideMap` via addSymbol
/// after route lines — not the native puck overlay, not Discover/Explore.
/// No demo riders. Web is a bridge (roster + join code, no live pins).

enum RideGroupStatus { scheduled, open, riding, closed }

enum RideGroupVisibility { private, public }

RideGroupVisibility parseRideGroupVisibility(Object? raw) {
  return '$raw' == 'public'
      ? RideGroupVisibility.public
      : RideGroupVisibility.private;
}

enum RideGroupPresenceVisibility {
  live,
  stale,
  hiddenZone,
  hiddenOffline,
  hiddenOptOut,
  hiddenWindow,
  hiddenNotMember,
}

class RideGroup {
  const RideGroup({
    required this.id,
    required this.hostUserId,
    required this.savedRouteId,
    required this.title,
    required this.startWindowStart,
    required this.startWindowEnd,
    required this.joinCode,
    required this.status,
    required this.livePinsAllowed,
    required this.createdAt,
    this.catalogTourId,
    this.onServer = false,
    this.visibility = RideGroupVisibility.private,
    this.meetingPoint,
  });

  final String id;
  final String hostUserId;
  final String savedRouteId;
  final String? catalogTourId;
  final String title;
  final DateTime startWindowStart;
  final DateTime startWindowEnd;
  final String joinCode;
  final RideGroupVisibility visibility;
  final RideGroupStatus status;
  final bool livePinsAllowed;
  final DateTime createdAt;
  final bool onServer;
  final String? meetingPoint;

  Map<String, dynamic> toJson() => {
        'id': id,
        'hostUserId': hostUserId,
        'savedRouteId': savedRouteId,
        'catalogTourId': catalogTourId,
        'title': title,
        'startWindowStart': startWindowStart.toUtc().toIso8601String(),
        'startWindowEnd': startWindowEnd.toUtc().toIso8601String(),
        'joinCode': joinCode,
        'visibility': visibility.name,
        'status': status.name,
        'livePinsAllowed': livePinsAllowed,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'onServer': onServer,
        if (meetingPoint != null && meetingPoint!.isNotEmpty)
          'meetingPoint': meetingPoint,
      };

  static RideGroup? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final host = raw['hostUserId'];
    final route = raw['savedRouteId'];
    final title = raw['title'];
    final code = raw['joinCode'];
    if (id is! String ||
        host is! String ||
        route is! String ||
        title is! String ||
        code is! String) {
      return null;
    }
    return RideGroup(
      id: id,
      hostUserId: host,
      savedRouteId: route,
      catalogTourId: raw['catalogTourId'] as String?,
      title: title,
      startWindowStart:
          DateTime.tryParse('${raw['startWindowStart']}') ?? DateTime.now(),
      startWindowEnd:
          DateTime.tryParse('${raw['startWindowEnd']}') ?? DateTime.now(),
      joinCode: code,
      visibility: parseRideGroupVisibility(raw['visibility']),
      status: RideGroupStatus.values.firstWhere(
        (s) => s.name == raw['status'],
        orElse: () => RideGroupStatus.open,
      ),
      livePinsAllowed: raw['livePinsAllowed'] == true,
      createdAt: DateTime.tryParse('${raw['createdAt']}') ?? DateTime.now(),
      onServer: raw['onServer'] == true,
      meetingPoint: raw['meetingPoint'] is String
          ? (raw['meetingPoint'] as String).trim()
          : null,
    );
  }

  RideGroup copyWith({
    RideGroupVisibility? visibility,
    bool? onServer,
  }) =>
      RideGroup(
        id: id,
        hostUserId: hostUserId,
        savedRouteId: savedRouteId,
        catalogTourId: catalogTourId,
        title: title,
        startWindowStart: startWindowStart,
        startWindowEnd: startWindowEnd,
        joinCode: joinCode,
        status: status,
        livePinsAllowed: livePinsAllowed,
        createdAt: createdAt,
        onServer: onServer ?? this.onServer,
        visibility: visibility ?? this.visibility,
        meetingPoint: meetingPoint,
      );
}

enum RideGroupJoinFail {
  invalidCode,
  unknown,
  expired,
  closed,
  needLink,
  needLogin,
}

class RideGroupJoinOut {
  const RideGroupJoinOut.ok(this.group, {this.note})
      : fail = null,
        already = false;
  const RideGroupJoinOut.already(this.group, {this.note})
      : fail = null,
        already = true;
  const RideGroupJoinOut.fail(this.fail, {this.note})
      : group = null,
        already = false;

  final RideGroup? group;
  final RideGroupJoinFail? fail;
  final bool already;
  final String? note;

  String get message {
    if (note != null && note!.isNotEmpty) return note!;
    if (already && group != null) {
      return group!.onServer
          ? 'Schon dabei: ${group!.title}. Derselbe Speicher — kein zweites Konto.'
          : 'Nur auf diesem Gerät: ${group!.title}. Der Host sieht dich nicht — anmelden.';
    }
    return switch (fail) {
      RideGroupJoinFail.invalidCode => 'Beitritt nur über den Einladungslink.',
      RideGroupJoinFail.needLink =>
        'Privat — nur mit Einladungslink. Kein Code zum Abtippen.',
      RideGroupJoinFail.unknown =>
        'Kein offener Link. Ohne Login gilt nur dieser Speicher; sonst den Einladungslink einfügen.',
      RideGroupJoinFail.expired => 'Fenster zu — der Link gilt nicht mehr.',
      RideGroupJoinFail.needLogin =>
        'Anmelden — sonst sieht der Host dich nicht.',
      RideGroupJoinFail.closed => 'Gruppe ist aufgelöst.',
      null => group != null
          ? (group!.onServer
              ? 'Dabei: ${group!.title}'
              : 'Nur auf diesem Gerät: ${group!.title}. Der Host sieht dich nicht — anmelden.')
          : 'Beitritt fehlgeschlagen.',
    };
  }
}

class RideGroupMember {
  const RideGroupMember({
    required this.groupId,
    required this.userId,
    required this.displayLabel,
    required this.joinedAt,
    this.liveOptIn = false,
  });

  final String groupId;
  final String userId;
  final String displayLabel;
  final DateTime joinedAt;
  final bool liveOptIn;

  RideGroupMember copyWith({bool? liveOptIn, String? displayLabel}) =>
      RideGroupMember(
        groupId: groupId,
        userId: userId,
        displayLabel: displayLabel ?? this.displayLabel,
        joinedAt: joinedAt,
        liveOptIn: liveOptIn ?? this.liveOptIn,
      );

  Map<String, dynamic> toJson() => {
        'groupId': groupId,
        'userId': userId,
        'displayLabel': displayLabel,
        'joinedAt': joinedAt.toUtc().toIso8601String(),
        'liveOptIn': liveOptIn,
      };

  static RideGroupMember? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final g = raw['groupId'];
    final u = raw['userId'];
    final label = raw['displayLabel'];
    if (g is! String || u is! String || label is! String) return null;
    return RideGroupMember(
      groupId: g,
      userId: u,
      displayLabel: label,
      joinedAt: DateTime.tryParse('${raw['joinedAt']}') ?? DateTime.now(),
      liveOptIn: raw['liveOptIn'] == true,
    );
  }
}

RideGroupPresenceVisibility parsePresenceVisibility(Object? raw) {
  switch ('$raw') {
    case 'live':
      return RideGroupPresenceVisibility.live;
    case 'stale':
      return RideGroupPresenceVisibility.stale;
    case 'hidden_zone':
    case 'hiddenZone':
      return RideGroupPresenceVisibility.hiddenZone;
    case 'hidden_offline':
    case 'hiddenOffline':
      return RideGroupPresenceVisibility.hiddenOffline;
    case 'hidden_opt_out':
    case 'hiddenOptOut':
      return RideGroupPresenceVisibility.hiddenOptOut;
    case 'hidden_window':
    case 'hiddenWindow':
      return RideGroupPresenceVisibility.hiddenWindow;
    case 'hidden_not_member':
    case 'hiddenNotMember':
      return RideGroupPresenceVisibility.hiddenNotMember;
    default:
      return RideGroupPresenceVisibility.hiddenOffline;
  }
}

class RideGroupPresence {
  const RideGroupPresence({
    required this.groupId,
    required this.userId,
    required this.updatedAt,
    required this.visibility,
    this.lng,
    this.lat,
  });

  final String groupId;
  final String userId;
  final double? lng;
  final double? lat;
  final DateTime updatedAt;
  final RideGroupPresenceVisibility visibility;

  Map<String, dynamic> toJson() => {
        'groupId': groupId,
        'userId': userId,
        'lng': lng,
        'lat': lat,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'visibility': visibility.name,
      };

  static RideGroupPresence? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final g = raw['groupId'];
    final u = raw['userId'];
    if (g is! String || u is! String) return null;
    return RideGroupPresence(
      groupId: g,
      userId: u,
      lng: (raw['lng'] as num?)?.toDouble(),
      lat: (raw['lat'] as num?)?.toDouble(),
      updatedAt: DateTime.tryParse('${raw['updatedAt']}') ?? DateTime.now(),
      visibility: parsePresenceVisibility(raw['visibility']),
    );
  }
}
