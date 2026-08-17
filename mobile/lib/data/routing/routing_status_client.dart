import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config.dart';

class RoutingStatus {
  const RoutingStatus({
    required this.configured,
    required this.engine,
    required this.liveVerified,
    this.notice,
    this.valhalla = false,
  });

  final bool configured;
  final String engine;
  final bool liveVerified;
  final String? notice;
  final bool valhalla;

  String get bannerText {
    if (notice != null && notice!.trim().isNotEmpty) return notice!;
    if (!configured) {
      return 'Routen nutzen Demo-Geometrie — Live-Routing nicht konfiguriert.';
    }
    if (!liveVerified) {
      return 'Routing konfiguriert ($engine) — Live noch nicht verifiziert.';
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
      valhalla: m['valhalla'] == true,
    );
  } catch (_) {
    return null;
  }
}
