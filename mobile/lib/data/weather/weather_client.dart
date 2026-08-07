import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config.dart';

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.tempC,
    required this.precipMm,
    required this.trailHint,
    required this.summary,
  });

  final double tempC;
  final double precipMm;
  final String trailHint; // dry_likely | damp_possible | wet_likely
  final String summary;

  String get trailLabel => switch (trailHint) {
        'wet_likely' => 'eher nass',
        'damp_possible' => 'feucht möglich',
        _ => 'eher trocken',
      };
}

class WeatherClient {
  Future<WeatherSnapshot?> fetch({
    required double lat,
    required double lon,
  }) async {
    try {
      final uri = Uri.parse(
        '${AppConfig.apiBaseUrl}/api/weather?lat=$lat&lon=$lon',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final m = jsonDecode(res.body) as Map<String, dynamic>;
      return WeatherSnapshot(
        tempC: (m['tempC'] as num?)?.toDouble() ??
            (m['current'] is Map
                ? ((m['current'] as Map)['temperature_2m'] as num?)?.toDouble()
                : null) ??
            12,
        precipMm: (m['precipMm'] as num?)?.toDouble() ??
            (m['current'] is Map
                ? ((m['current'] as Map)['precipitation'] as num?)?.toDouble()
                : null) ??
            0,
        trailHint: (m['trailHint'] as String?) ?? 'dry_likely',
        summary: (m['summary'] as String?) ?? 'Open-Meteo',
      );
    } catch (_) {
      return null;
    }
  }
}
