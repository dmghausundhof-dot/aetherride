import '../../domain/privacy/consents.dart';
import '../../domain/privacy/track_trim.dart';
import '../../domain/ride.dart';
import 'fit.dart';
import 'gpx.dart';

/// Apply privacy trim then export helpers.
///
/// Empty result stays empty — never fall back to the raw track (that would
/// leak a ride that sat entirely inside a zone).
RideRecord rideWithTrimmedTrack(
  RideRecord ride,
  List<PrivacyZone> zones,
) {
  if (ride.track.length < 3) return ride;
  final trimmed = trimTrackForPrivacyZones(
    List<Map<String, dynamic>>.from(ride.track),
    zones,
  );
  return RideRecord(
    id: ride.id,
    bikeId: ride.bikeId,
    startedAt: ride.startedAt,
    endedAt: ride.endedAt,
    distanceKm: ride.distanceKm,
    movingTimeSec: ride.movingTimeSec,
    elevationM: ride.elevationM,
    name: ride.name,
    routeId: ride.routeId,
    setupId: ride.setupId,
    track: trimmed,
    feedback: ride.feedback,
    summary: ride.summary,
  );
}

String exportGpxTrimmed(
  RideRecord ride, {
  required List<PrivacyZone> zones,
  String? bikeName,
}) {
  return rideToGpx(rideWithTrimmedTrack(ride, zones), bikeName: bikeName);
}

List<int> exportFitTrimmed(
  RideRecord ride, {
  required List<PrivacyZone> zones,
}) {
  return rideToFit(rideWithTrimmedTrack(ride, zones));
}
