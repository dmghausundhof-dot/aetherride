import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config.dart';

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.tempC,
    required this.precipMm,
    required this.trailHint,
    required this.summary,
    this.precip72hMm,
    this.trailHintSource,
    this.rideWindowLabel,
  });

  final double tempC;
  final double precipMm;
  final String trailHint; // dry_likely | damp_possible | wet_likely
  final String summary;
  /// Weighted 72h reservoir — optional, older APIs omit it.
  final double? precip72hMm;
  /// soil_72h | current_precip | daily_sum — optional.
  final String? trailHintSource;
  /// Gravel/MTB daylight window — never shown on Hof sky.
  final String? rideWindowLabel;

  String get trailLabel => switch (trailHint) {
        'wet_likely' => 'eher nass',
        'damp_possible' => 'feucht möglich',
        _ => 'eher trocken',
      };

  factory WeatherSnapshot.fromJson(Map<String, dynamic> m) {
    final current = m['current'];
    final currentMap = current is Map ? current : null;
    return WeatherSnapshot(
      tempC: (m['tempC'] as num?)?.toDouble() ??
          (currentMap?['temperature_2m'] as num?)?.toDouble() ??
          12,
      precipMm: (m['precipMm'] as num?)?.toDouble() ??
          (currentMap?['precipitation'] as num?)?.toDouble() ??
          0,
      trailHint: (m['trailHint'] as String?) ?? 'dry_likely',
      summary: (m['summary'] as String?) ?? 'Open-Meteo',
      precip72hMm: (m['precip72hMm'] as num?)?.toDouble(),
      trailHintSource: m['trailHintSource'] as String?,
      rideWindowLabel: () {
        final w = m['rideWindow'];
        if (w is Map && w['label'] is String) return w['label'] as String;
        return m['rideWindowLabel'] as String?;
      }(),
    );
  }
}

class WeatherClient {
  Future<WeatherSnapshot?> fetch({
    required double lat,
    required double lon,
    String? profile,
    String? lang,
  }) async {
    try {
      final qp = <String, String>{
        'lat': '$lat',
        'lon': '$lon',
        if (profile != null && profile.isNotEmpty) 'profile': profile,
        if (lang != null && lang.isNotEmpty) 'lang': lang,
      };
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/weather')
          .replace(queryParameters: qp);
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final m = jsonDecode(res.body) as Map<String, dynamic>;
      return WeatherSnapshot.fromJson(m);
    } catch (_) {
      return null;
    }
  }
}
