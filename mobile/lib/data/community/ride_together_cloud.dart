import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config.dart';
import '../../domain/community/ride_group.dart';
import '../../domain/community/ride_group_policy.dart';
import '../../domain/community/ride_together.dart';
import 'ride_group_cloud.dart';

/// HTTP zu `/api/ride-together`. Ohne Session: null.
abstract final class RideTogetherCloud {
  static Future<TogetherLookSnap?> look({
    required double lat,
    required double lng,
    String? label,
  }) async {
    final map = await _post('/api/ride-together/look', {
      'lat': lat,
      'lng': lng,
      if (label != null && label.trim().isNotEmpty) 'label': label.trim(),
    });
    if (map == null) return null;
    return parseLook(map.status, map.body);
  }

  static Future<TogetherLookSnap?> stopLook() async {
    final map = await _post('/api/ride-together/look', {'stop': true});
    if (map == null) return null;
    return parseLook(map.status, map.body);
  }

  static Future<RideGroupCloudResult?> request({
    required String toUserId,
    String? label,
  }) {
    return RideGroupCloud.post('/api/ride-together/request', {
      'toUserId': toUserId,
      if (label != null && label.trim().isNotEmpty) 'label': label.trim(),
    });
  }

  static Future<RideGroupCloudResult?> respond({
    required String requestId,
    required bool accept,
    String? label,
  }) {
    return RideGroupCloud.post('/api/ride-together/respond', {
      'requestId': requestId,
      'accept': accept,
      if (label != null && label.trim().isNotEmpty) 'label': label.trim(),
    });
  }

  static Future<RideGroupCloudResult?> joinCode(String code, {String? label}) async {
    final body = <String, Object?>{
      'code': RideGroupPolicy.normalizeJoinCode(code),
      if (label != null && label.trim().isNotEmpty) 'label': label.trim(),
    };
    Future<RideGroupCloudResult?> once() {
      return RideGroupCloud.post(
        '/api/ride-together/join',
        body,
        const Duration(seconds: 60),
      );
    }

    final first = await once();
    if (first != null && first.status == 0) return once();
    return first;
  }

  static Future<RideGroupCloudResult?> end(String groupId) {
    return RideGroupCloud.post('/api/ride-together/end', {'groupId': groupId});
  }

  static TogetherLookSnap parseLook(int status, String raw) {
    Object? decoded;
    try {
      decoded = raw.isEmpty ? null : jsonDecode(raw);
    } catch (_) {
      decoded = null;
    }
    final map = decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    if (status < 200 || status >= 300 || map == null) {
      return TogetherLookSnap(
        me: '',
        note: map?['note']?.toString() ?? map?['error']?.toString(),
        stub: map?['stub'] == true,
      );
    }
    final nearby = <TogetherNearby>[];
    final rawNear = map['nearby'];
    if (rawNear is List) {
      for (final e in rawNear) {
        final n = TogetherNearby.fromJson(e);
        if (n != null) nearby.add(n);
      }
    }
    final inbound = <TogetherInbound>[];
    final rawIn = map['inbound'];
    if (rawIn is List) {
      for (final e in rawIn) {
        final n = TogetherInbound.fromJson(e);
        if (n != null) inbound.add(n);
      }
    }
    final outbound = <TogetherOutbound>[];
    final rawOut = map['outbound'];
    if (rawOut is List) {
      for (final e in rawOut) {
        final n = TogetherOutbound.fromJson(e);
        if (n != null) outbound.add(n);
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
    return TogetherLookSnap(
      me: '${map['me'] ?? ''}',
      joinCode: map['joinCode'] is String ? map['joinCode'] as String : null,
      lookingUntil: DateTime.tryParse('${map['lookingUntil'] ?? ''}'),
      nearby: nearby,
      inbound: inbound,
      outbound: outbound,
      group: RideGroup.fromJson(map['group']),
      members: members,
      note: map['note']?.toString(),
      stub: map['stub'] == true,
      stopped: map['stopped'] == true,
    );
  }

  static Future<({int status, String body})?> _post(
    String path,
    Map<String, Object?> body,
  ) async {
    final token = await RideGroupCloud.accessToken();
    if (token == null || token.isEmpty) return null;
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
      Future<http.Response> once(String bearer) {
        return http
            .post(
              uri,
              headers: {
                'Authorization': 'Bearer $bearer',
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 20));
      }

      var res = await once(token);
      if (res.statusCode == 401) {
        final retry = await RideGroupCloud.refreshAccessToken();
        if (retry != null && retry.isNotEmpty) {
          res = await once(retry);
        }
      }
      return (status: res.statusCode, body: res.body);
    } catch (_) {
      return (status: 0, body: '{"error":"network","note":"Server nicht erreicht."}');
    }
  }
}
