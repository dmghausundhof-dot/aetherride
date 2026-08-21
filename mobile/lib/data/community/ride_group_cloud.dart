import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';
import '../../domain/community/ride_group.dart';

/// HTTP zu `/api/ride-groups`. Ohne Session: null, kein Demo-User.
class RideGroupCloud {
  static const localOnlyNote =
      'Nicht eingeloggt — nur auf diesem Gerät. Join auf dem Server braucht Login.';
  static const needLoginNote =
      'Anmelden — sonst sieht der Freund die Gruppe nicht auf dem Server.';
  static const needLoginJoinNote =
      'Anmelden — sonst sieht der Gastgeber dich nicht.';
  static const serverTableNote = 'Server-Tabelle fehlt — nur lokal.';
  static const onServerNote = 'Gruppe auf dem Server.';

  /// signedIn / signedOut / unavailable (Tests ohne Supabase).
  static Future<String> sessionState() async {
    try {
      final auth = Supabase.instance.client.auth;
      var session = auth.currentSession;
      if (session == null) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        session = auth.currentSession;
      }
      if (session == null) return 'signedOut';
      if (session.isExpired) {
        final refreshed = await auth.refreshSession();
        session = refreshed.session ?? auth.currentSession;
      }
      return session?.accessToken.isNotEmpty == true ? 'signedIn' : 'signedOut';
    } catch (_) {
      return 'unavailable';
    }
  }

  static Future<String?> accessToken() async {
    try {
      final auth = Supabase.instance.client.auth;
      var session = auth.currentSession;
      if (session == null) {
        // Boot: initialize() is fire-and-forget; wait one tick for storage.
        await Future<void>.delayed(const Duration(milliseconds: 80));
        session = auth.currentSession;
      }
      if (session == null) return null;
      if (session.isExpired) {
        final refreshed = await auth.refreshSession();
        session = refreshed.session ?? auth.currentSession;
      }
      final token = session?.accessToken;
      if (token == null || token.isEmpty) return null;
      return token;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> refreshAccessToken() async {
    try {
      await Supabase.instance.client.auth.refreshSession();
    } catch (_) {}
    return accessToken();
  }

  static Future<RideGroupCloudResult?> list() async {
    return _send(method: 'GET', path: '/api/ride-groups');
  }

  static Future<RideGroupCloudResult?> create({
    required String savedRouteId,
    String? catalogTourId,
    required String title,
    RideGroupVisibility visibility = RideGroupVisibility.private,
    DateTime? startsAt,
    num? durationHours,
    String? meetingPoint,
  }) async {
    return _send(
      method: 'POST',
      path: '/api/ride-groups',
      body: {
        'savedRouteId': savedRouteId,
        if (catalogTourId != null) 'catalogTourId': catalogTourId,
        'title': title,
        'visibility': visibility.name,
        if (startsAt != null) 'startsAt': startsAt.toUtc().toIso8601String(),
        if (durationHours != null) 'durationHours': durationHours,
        if (meetingPoint != null && meetingPoint.trim().isNotEmpty)
          'meetingPoint': meetingPoint.trim(),
      },
    );
  }

  static Future<RideGroupCloudResult?> join({
    String? code,
    String? groupId,
    String? token,
  }) async {
    return _send(
      method: 'POST',
      path: '/api/ride-groups/join',
      body: {
        if (code != null && code.isNotEmpty) 'code': code,
        if (groupId != null && groupId.isNotEmpty) 'groupId': groupId,
        if (token != null && token.isNotEmpty) 'token': token,
      },
    );
  }

  static Future<RideGroupCloudResult?> listPublic() async {
    return _send(method: 'GET', path: '/api/ride-groups?scope=public');
  }

  static Future<RideGroupCloudResult?> setVisibility({
    required String id,
    required RideGroupVisibility visibility,
  }) async {
    return _send(
      method: 'POST',
      path: '/api/ride-groups/visibility',
      body: {'id': id, 'visibility': visibility.name},
    );
  }

  static Future<RideGroupCloudResult?> close(String id) async {
    return _send(
      method: 'POST',
      path: '/api/ride-groups/close',
      body: {'id': id},
    );
  }

  static Future<RideGroupCloudResult?> leave(String id) async {
    return _send(
      method: 'POST',
      path: '/api/ride-groups/leave',
      body: {'id': id},
    );
  }

  static Future<RideGroupCloudResult?> extendWindow({
    required String id,
    num addHours = 1,
    DateTime? newEnd,
  }) async {
    final body = {
      'id': id,
      if (newEnd != null)
        'newEnd': newEnd.toUtc().toIso8601String()
      else
        'addHours': addHours,
    };
    final first = await _send(
      method: 'POST',
      path: '/api/ride-groups/window',
      body: body,
    );
    if (first != null && first.status == 404) {
      return _send(method: 'POST', path: '/api/ride-groups', body: body);
    }
    return first;
  }

  static Future<RideGroupCloudResult?> presenceList(String groupId) async {
    return _send(
      method: 'GET',
      path: '/api/ride-groups/presence?groupId=${Uri.encodeQueryComponent(groupId)}',
    );
  }

  static Future<RideGroupCloudResult?> post(
    String path, [
    Map<String, Object?>? body,
    Duration? timeout,
  ]) {
    return _send(method: 'POST', path: path, body: body, timeout: timeout);
  }

  static Future<RideGroupCloudResult?> presencePublish({
    required String groupId,
    double? lat,
    double? lng,
    bool? inPrivacyZone,
    bool? liveOptIn,
  }) async {
    return _send(
      method: 'POST',
      path: '/api/ride-groups/presence',
      body: {
        'groupId': groupId,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (inPrivacyZone != null) 'inPrivacyZone': inPrivacyZone,
        if (liveOptIn != null) 'liveOptIn': liveOptIn,
      },
    );
  }

  static Future<RideGroupCloudResult?> _send({
    required String method,
    required String path,
    Map<String, Object?>? body,
    Duration? timeout,
  }) async {
    final token = await accessToken();
    if (token == null || token.isEmpty) return null;
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
      // Physical devices: Vercel cold start can exceed 8s; 10.0.2.2 is unreachable.
      // Local `next dev` compiles a route on first hit — join took 47s here.
      final wait = timeout ??
          (method == 'GET'
              ? const Duration(seconds: 20)
              : const Duration(seconds: 25));
      Future<http.Response> once(String bearer) {
        final headers = {
          'Authorization': 'Bearer $bearer',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        };
        return method == 'GET'
            ? http.get(uri, headers: headers).timeout(wait)
            : http
                .post(uri, headers: headers, body: jsonEncode(body ?? const {}))
                .timeout(wait);
      }

      var res = await once(token);
      if (res.statusCode == 401) {
        try {
          await Supabase.instance.client.auth.refreshSession();
        } catch (_) {}
        final retry = await accessToken();
        if (retry != null && retry.isNotEmpty) {
          res = await once(retry);
        }
      }
      return parseResponse(res.statusCode, res.body);
    } catch (_) {
      return const RideGroupCloudResult.fail(
        status: 0,
        error: 'network',
        note: 'Server nicht erreicht — lokal bleiben.',
      );
    }
  }

  /// Test-/Parser-Hilfe.
  static RideGroupCloudResult parseResponse(int status, String raw) {
    Object? decoded;
    try {
      decoded = raw.isEmpty ? null : jsonDecode(raw);
    } catch (_) {
      decoded = null;
    }
    final map = decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    if (status < 200 || status >= 300) {
      return RideGroupCloudResult.fail(
        status: status,
        error: '${map?['error'] ?? 'failed'}',
        note: map?['note']?.toString(),
        stub: map?['stub'] == true,
      );
    }
    return RideGroupCloudResult.ok(parseBundle(map));
  }

  static RideGroupCloudBundle parseBundle(Map<String, dynamic>? map) {
    if (map == null) {
      return const RideGroupCloudBundle(me: '', groups: [], members: []);
    }
    final groups = <RideGroup>[];
    final one = RideGroup.fromJson(map['group']);
    if (one != null) {
      groups.add(
        RideGroup(
          id: one.id,
          hostUserId: one.hostUserId,
          savedRouteId: one.savedRouteId,
          catalogTourId: one.catalogTourId,
          title: one.title,
          startWindowStart: one.startWindowStart,
          startWindowEnd: one.startWindowEnd,
          joinCode: one.joinCode,
          status: one.status,
          livePinsAllowed: one.livePinsAllowed,
          createdAt: one.createdAt,
          onServer: true,
          visibility: one.visibility,
          meetingPoint: one.meetingPoint,
        ),
      );
    }
    final rawGroups = map['groups'];
    if (rawGroups is List) {
      for (final e in rawGroups) {
        final g = RideGroup.fromJson(e);
        if (g == null) continue;
        groups.add(
          RideGroup(
            id: g.id,
            hostUserId: g.hostUserId,
            savedRouteId: g.savedRouteId,
            catalogTourId: g.catalogTourId,
            title: g.title,
            startWindowStart: g.startWindowStart,
            startWindowEnd: g.startWindowEnd,
            joinCode: g.joinCode,
            status: g.status,
            livePinsAllowed: g.livePinsAllowed,
            createdAt: g.createdAt,
            onServer: true,
            visibility: g.visibility,
            meetingPoint: g.meetingPoint,
          ),
        );
      }
    }
    final members = <RideGroupMember>[];
    final rawMembers = map['members'];
    if (rawMembers is List) {
      for (final e in rawMembers) {
        final m = RideGroupMember.fromJson(e);
        if (m != null) members.add(m);
      }
    }
    final presence = <RideGroupPresence>[];
    final rawPresence = map['presence'];
    if (rawPresence is List) {
      for (final e in rawPresence) {
        final p = RideGroupPresence.fromJson(e);
        if (p != null) presence.add(p);
      }
    }
    return RideGroupCloudBundle(
      me: '${map['me'] ?? ''}',
      groups: groups,
      members: members,
      presence: presence,
      already: map['already'] == true,
      stub: map['stub'] == true,
    );
  }
}

class RideGroupCloudBundle {
  const RideGroupCloudBundle({
    required this.me,
    required this.groups,
    required this.members,
    this.presence = const [],
    this.already = false,
    this.stub = false,
  });

  final String me;
  final List<RideGroup> groups;
  final List<RideGroupMember> members;
  final List<RideGroupPresence> presence;
  final bool already;
  final bool stub;
}

class RideGroupCloudResult {
  const RideGroupCloudResult.ok(this.bundle)
      : status = 200,
        error = null,
        note = null,
        stub = false;
  const RideGroupCloudResult.fail({
    required this.status,
    required this.error,
    this.note,
    this.stub = false,
  }) : bundle = null;

  final int status;
  final RideGroupCloudBundle? bundle;
  final String? error;
  final String? note;
  final bool stub;

  bool get ok => bundle != null && error == null;
}
