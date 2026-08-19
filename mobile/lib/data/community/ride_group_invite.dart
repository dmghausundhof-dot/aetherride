import 'dart:convert';

import '../../core/config.dart';
import '../../domain/community/ride_group.dart';
import '../../domain/community/ride_group_policy.dart';
import '../../domain/saved_route.dart';
import '../../domain/saved_route_note.dart';
import '../../domain/tours/tour_akte.dart';
import 'tour_share_codec.dart';

/// Teilbarer Einladungslink für „Zusammen raus“.
///
/// HTTPS (WhatsApp / Messages / Copy):
///   `https://aetherride.vercel.app/library?group=<id>&g=<token>`
/// Custom scheme (App öffnen):
///   `aetherride://platz?group=<id>&g=<token>`
///
/// `g` trägt Titel, Tour-Id und Fenster — kein Roster, keine Fake-Mitglieder.
/// Join-Code bleibt intern. Alte `?group=ABC234`-Links gelten weiter.
abstract final class RideGroupInvite {
  /// Share-Origin: Emulator/localhost wird zur Production, sonst bricht WhatsApp.
  static String shareOrigin({String? origin}) {
    final raw = (origin ?? AppConfig.apiBaseUrl).replaceAll(RegExp(r'/$'), '');
    if (raw.contains('localhost') ||
        raw.contains('127.0.0.1') ||
        raw.contains('10.0.2.2')) {
      return AppConfig.productionApiBaseUrl;
    }
    return raw;
  }

  static String httpsUrl({
    String? groupId,
    String? code,
    String? token,
    String? origin,
  }) {
    final base = shareOrigin(origin: origin);
    final ref = (groupId != null && groupId.trim().isNotEmpty)
        ? groupId.trim()
        : _code(code ?? '');
    final q = StringBuffer('$base/library?group=$ref');
    if (token != null && token.isNotEmpty) q.write('&g=$token');
    return q.toString();
  }

  static String? profileHttpsUrl({required String handle, String? origin}) {
    final h = handle.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (h.isEmpty) return null;
    return '${shareOrigin(origin: origin)}/u/$h';
  }

  static String customSchemeUrl({
    String? groupId,
    String? code,
    String? token,
  }) {
    final ref = (groupId != null && groupId.trim().isNotEmpty)
        ? groupId.trim()
        : _code(code ?? '');
    final q = StringBuffer('aetherride://platz?group=$ref');
    if (token != null && token.isNotEmpty) q.write('&g=$token');
    return q.toString();
  }

  static String shareText({
    required String title,
    required String url,
    String? appUrl,
    String? code,
    String? profileUrl,
    RideGroupVisibility visibility = RideGroupVisibility.private,
    String? when,
    String? meetingPoint,
  }) {
    final buf = StringBuffer()
      ..writeln('Zusammen raus: $title')
      ..writeln(url);
    final app = appUrl?.trim() ?? '';
    if (app.isNotEmpty && app != url) {
      buf.writeln(app);
    }
    if (visibility == RideGroupVisibility.public) {
      final typed = code == null ? '' : RideGroupPolicy.normalizeJoinCode(code);
      if (typed.length == RideGroupPolicy.joinCodeLen) {
        buf.writeln('Code: $typed');
      }
    }
    if (when != null && when.trim().isNotEmpty) {
      buf.writeln(when.trim());
    }
    if (meetingPoint != null && meetingPoint.trim().isNotEmpty) {
      buf.writeln('Treffpunkt: ${meetingPoint.trim()}');
    }
    if (profileUrl != null && profileUrl.trim().isNotEmpty) {
      buf
        ..writeln()
        ..writeln('Mein Profil: ${profileUrl.trim()}');
    }
    buf
      ..writeln()
      ..write(
        visibility == RideGroupVisibility.public
            ? 'Freigegeben: Link oder Code reicht. '
                'Die Gruppe steht auf dem Platz und als Treffen-Pin auf der Karte.'
            : 'Privat: nur wer diesen Link hat, kann beitreten. '
                'Nicht gelistet.',
      );
    return buf.toString();
  }

  static String encode(
    RideGroup group, {
    SavedRouteEntry? route,
    SavedRouteMeta? meta,
    Map<String, dynamic>? tour,
  }) {
    Map<String, dynamic>? nextTour = tour;
    if (nextTour == null &&
        route != null &&
        needsMemberTrack(
          savedRouteId: group.savedRouteId,
          catalogTourId: group.catalogTourId ?? meta?.catalogTourId,
        )) {
      nextTour = buildTourSharePayload(
        route,
        meta: meta ?? SavedRouteMeta.empty,
      );
    }
    String token = _encodeBody(group, nextTour);
    if (token.length > 2400 &&
        nextTour != null &&
        nextTour['track'] != null) {
      nextTour = Map<String, dynamic>.from(nextTour)
        ..['includeTrack'] = false
        ..remove('track');
      token = _encodeBody(group, nextTour);
    }
    if (token.length > 2400) {
      token = _encodeBody(group, null);
    }
    return token;
  }

  static String _encodeBody(RideGroup group, Map<String, dynamic>? tour) {
    return _toBase64Url(
      jsonEncode({
        'v': 1,
        'kind': 'group',
        'id': group.id,
        'code': _code(group.joinCode),
        'title': group.title,
        'savedRouteId': group.savedRouteId,
        if (group.catalogTourId != null) 'catalogTourId': group.catalogTourId,
        'hostUserId': group.hostUserId,
        'start': group.startWindowStart.toUtc().toIso8601String(),
        'end': group.startWindowEnd.toUtc().toIso8601String(),
        if (tour != null) 'tour': tour,
      }),
    );
  }

  static RideGroupInvitePayload? decode(String token) {
    final raw = _fromBase64Url(token);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw);
      if (data is! Map) return null;
      if (data['v'] != 1 || data['kind'] != 'group') return null;
      final code = _code('${data['code'] ?? ''}');
      final title = '${data['title'] ?? ''}'.trim();
      final route = '${data['savedRouteId'] ?? ''}'.trim();
      final id = '${data['id'] ?? ''}'.trim();
      if (code.length != RideGroupPolicy.joinCodeLen ||
          title.isEmpty ||
          route.isEmpty ||
          id.isEmpty) {
        return null;
      }
      final start = DateTime.tryParse('${data['start']}');
      final end = DateTime.tryParse('${data['end']}');
      if (start == null || end == null) return null;
      return RideGroupInvitePayload(
        id: id,
        code: code,
        title: title,
        savedRouteId: route,
        catalogTourId: (data['catalogTourId'] as String?)?.trim(),
        hostUserId: '${data['hostUserId'] ?? ''}'.trim(),
        start: start.toUtc(),
        end: end.toUtc(),
        tour: parseTourShareMap(data['tour']),
      );
    } catch (_) {
      return null;
    }
  }

  static String _code(String raw) => raw.trim().toUpperCase();

  /// Paste from WhatsApp / Messages: HTTPS, App-Scheme, or bare id.
  /// Prefers the URL that carries `g=` (private groups need the token).
  static PlatzPastedJoin? parsePastedJoin(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    PlatzPastedJoin? withoutToken;
    final urlRe = RegExp(
      r'(?:https?://|aetherride://)[^\s]+',
      caseSensitive: false,
    );
    for (final m in urlRe.allMatches(text)) {
      final uri = Uri.tryParse(m.group(0)!);
      if (uri == null) continue;
      final group =
          (uri.queryParameters['group'] ?? uri.queryParameters['code'] ?? '')
              .trim();
      if (group.isEmpty) continue;
      final token = uri.queryParameters['g']?.trim();
      final hit = PlatzPastedJoin(
        code: group,
        token: (token == null || token.isEmpty) ? null : token,
      );
      if (hit.token != null) return hit;
      withoutToken ??= hit;
    }
    if (withoutToken != null) return withoutToken;
    final compact = text.replaceAll(RegExp(r'\s+'), '');
    if (RideGroupPolicy.isGroupId(compact)) {
      return PlatzPastedJoin(code: compact);
    }
    if (RideGroupPolicy.isTypedJoinCode(text)) {
      return PlatzPastedJoin(code: RideGroupPolicy.normalizeJoinCode(text));
    }
    return null;
  }
}

class PlatzPastedJoin {
  const PlatzPastedJoin({required this.code, this.token});

  final String code;
  final String? token;
}

class RideGroupInvitePayload {
  const RideGroupInvitePayload({
    required this.id,
    required this.code,
    required this.title,
    required this.savedRouteId,
    required this.start,
    required this.end,
    this.catalogTourId,
    this.hostUserId = '',
    this.tour,
  });

  final String id;
  final String code;
  final String title;
  final String savedRouteId;
  final String? catalogTourId;
  final String hostUserId;
  final DateTime start;
  final DateTime end;
  final Map<String, dynamic>? tour;

  bool windowOpen(DateTime now) => !now.isAfter(end);
}

String _toBase64Url(String json) {
  return base64Url.encode(utf8.encode(json)).replaceAll('=', '');
}

String? _fromBase64Url(String token) {
  try {
    var b64 = token.replaceAll('-', '+').replaceAll('_', '/');
    final pad = b64.length % 4 == 0 ? 0 : 4 - (b64.length % 4);
    b64 = b64.padRight(b64.length + pad, '=');
    return utf8.decode(base64.decode(b64));
  } catch (_) {
    return null;
  }
}
