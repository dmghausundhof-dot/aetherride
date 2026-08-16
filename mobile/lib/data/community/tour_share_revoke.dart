import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';

/// Widerruf auf dem Server, soweit die Tabelle da ist und der User eingeloggt.
Future<bool> revokeTourShareOnServer({
  required String routeId,
  required int epoch,
}) async {
  if (routeId.isEmpty || epoch < 1) return false;
  String? token;
  try {
    token = Supabase.instance.client.auth.currentSession?.accessToken;
  } catch (_) {
    return false;
  }
  if (token == null || token.isEmpty) return false;
  try {
    final res = await http
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}/api/community/tour-share-revoke'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'routeId': routeId, 'epoch': epoch}),
        )
        .timeout(const Duration(seconds: 8));
    return res.statusCode == 200;
  } catch (_) {
    return false;
  }
}
