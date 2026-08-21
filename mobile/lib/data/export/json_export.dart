import 'dart:convert';

import '../../domain/bike.dart';
import '../../domain/ride.dart';
import '../../domain/ride/ride_telemetry.dart';

/// Full portable JSON dump (DSGVO Art. 20) — web `fullJsonExport`.
String fullJsonExport({
  required List<Bike> bikes,
  required List<RideRecord> rides,
  Map<String, dynamic>? profile,
  List<Map<String, dynamic>>? setups,
  Map<String, bool>? consents,
}) {
  return const JsonEncoder.withIndent('  ').convert({
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
    'format': 'aetherride-portable-v1',
    'legal': 'DSGVO Art. 20 Datenportabilität',
    if (profile != null) 'riderProfile': profile,
    'bikes': [
      for (final b in bikes)
        {
          'id': b.id,
          'name': b.name,
          'category': b.category.name,
          'brand': b.brand,
          'model': b.model,
          'year': b.year,
          'wheelSize': b.wheelSize?.name,
          'odometerKm': b.odometerKm,
          'hours': b.hours,
          'isActive': b.isActive,
        },
    ],
    'rides': [
      for (final r in rides)
        {
          'id': r.id,
          'bikeId': r.bikeId,
          'startTime': r.startedAt.toIso8601String(),
          'endTime': r.endedAt?.toIso8601String(),
          'distanceM': r.distanceKm * 1000,
          'elevationGainM': honestClimbM(r.track, r.elevationM),
          'durationSec': r.movingTimeSec,
          'name': r.name,
          'routeId': r.routeId,
          'track': r.track,
          if (r.feedback != null) 'feedback': r.feedback!.toJson(),
          'summary': r.summary,
        },
    ],
    if (setups != null) 'setups': setups,
    if (consents != null) 'consents': consents,
  });
}
