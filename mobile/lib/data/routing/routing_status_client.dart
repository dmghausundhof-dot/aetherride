import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config.dart';

class RoutingStatus {
  const RoutingStatus({
    required this.configured,
    required this.engine,
    required this.liveVerified,
    this.notice,
  });

  final bool configured;
  final String engine;
  final bool liveVerified;
  final String? notice;

  String get bannerText {
    // Never surface Routing-Key / API_KEY chrome (server should already sanitize).
    final n = notice?.trim();
    if (n != null &&
        n.isNotEmpty &&
        !n.contains('Routing-Key') &&
        !n.contains('API_KEY') &&
        !RegExp(r'API[_ ]?KEY', caseSensitive: false).hasMatch(n)) {
      return n;
    }
    if (!configured) {
      return 'Routen nutzen Demo-Geometrie — Live-Routing nicht konfiguriert.';
    }
    // Configured live engine: silent unless debug UI builds a generic line.
    if (!liveVerified) {
      return 'Live-Routing konfiguriert ($engine) — Verifikation ausstehend.';
    }
    return 'Live-Routing ($engine)';
  }
}

Future<RoutingStatus?> fetchRoutingStatus() async {
  try {
    final res = await http
        .get(
          Uri.parse('${AppConfig.apiBaseUrl}/api/routing/status'),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return null;
    final m = jsonDecode(res.body);
    if (m is! Map) return null;
    return RoutingStatus(
      configured: m['configured'] == true,
      engine: (m['engine'] as String?) ?? 'demo',
      liveVerified: m['liveVerified'] == true,
      notice: m['notice'] as String?,
    );
  } catch (_) {
    return null;
  }
}
