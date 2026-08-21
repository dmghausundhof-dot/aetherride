import 'dart:convert';

import '../../domain/ride.dart';
import '../../domain/ride/ride_telemetry.dart';

/// Strava-ähnlicher Activity-Payload (Export-Stub, kein OAuth).
Map<String, dynamic> rideToStravaActivityStub(RideRecord ride) {
  return {
    'name':
        'FlowLine ${ride.startedAt.toLocal().toIso8601String().substring(0, 10)}',
    'type': 'Ride',
    'sport_type': 'MountainBikeRide',
    'start_date_local': ride.startedAt.toIso8601String(),
    'elapsed_time': ride.movingTimeSec,
    'distance': ride.distanceKm * 1000,
    'total_elevation_gain': honestClimbM(ride.track, ride.elevationM),
    'description':
        'Exportiert aus FlowLine — Strava API OAuth in Produktion (Spec 8.6 P1).',
    '_note':
        'Demo-Stub ohne Netzwerkaufruf. Markenrichtlinien Strava beachten.',
  };
}

String rideToStravaActivityJson(RideRecord ride) =>
    const JsonEncoder.withIndent('  ').convert(rideToStravaActivityStub(ride));
