import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config.dart';
import 'public_profile_store.dart';
import 'ride_group_cloud.dart';

/// HTTP zu `/api/community/profile`. Ohne Session: null.
class PublicProfileCloud {
  static Future<PublicProfileSettings?> pullMine() async {
    final token = await RideGroupCloud.accessToken();
    if (token == null || token.isEmpty) return null;
    try {
      final res = await http
          .get(
            Uri.parse('${AppConfig.apiBaseUrl}/api/community/profile'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final decoded = jsonDecode(res.body);
      if (decoded is! Map) return null;
      final raw = decoded['profile'];
      if (raw is! Map) return null;
      return fromApi(Map<String, dynamic>.from(raw));
    } catch (_) {
      return null;
    }
  }

  static Future<bool> push(PublicProfileSettings s) async {
    final token = await RideGroupCloud.accessToken();
    if (token == null || token.isEmpty) return false;
    final handle = s.handle.trim().toLowerCase();
    if (handle.length < 3) return false;
    try {
      final res = await http
          .put(
            Uri.parse('${AppConfig.apiBaseUrl}/api/community/profile'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'handle': handle,
              'displayName': s.displayName,
              'bio': s.bio,
              'sports': s.sports,
              'showRideCount': s.showRideCount,
              'regionLabel': s.regionLabel,
              'enabled': s.enabled,
            }),
          )
          .timeout(const Duration(seconds: 20));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  static PublicProfileSettings fromApi(Map<String, dynamic> raw) {
    return PublicProfileSettings(
      enabled: raw['enabled'] == true,
      handle: '${raw['handle'] ?? ''}',
      displayName: '${raw['display_name'] ?? raw['displayName'] ?? ''}',
      bio: '${raw['bio'] ?? ''}',
      sports: [
        for (final e in (raw['sports'] as List? ?? const []))
          if (e is String) e,
      ],
      showRideCount: raw['show_ride_count'] != false &&
          raw['showRideCount'] != false,
      regionLabel: '${raw['region_label'] ?? raw['regionLabel'] ?? ''}',
    );
  }
}
