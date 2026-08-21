import 'routing/route_progress.dart';

/// Persistierte Ride-Session (Spiegel Web Ride, verkürzt für Mobile-P0).
class RideRecord {
  const RideRecord({
    required this.id,
    required this.bikeId,
    required this.startedAt,
    this.endedAt,
    this.distanceKm = 0,
    this.movingTimeSec = 0,
    this.elevationM = 0,
    this.name,
    this.routeId,
    this.setupId,
    this.track = const [],
    this.feedback,
    this.summary = const {},
  });

  final String id;
  final String bikeId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double distanceKm;
  final int movingTimeSec;
  final double elevationM;
  final String? name;
  final String? routeId;
  final String? setupId;

  /// Track points as {lat,lng,timeMs?,elev?,hr?,cad?,power?}
  final List<Map<String, dynamic>> track;
  final RideFeedback? feedback;
  final Map<String, dynamic> summary;

  bool get isActive => endedAt == null;
}

class RideFeedback {
  const RideFeedback({
    required this.overallFeel,
    this.frontFeel,
    this.brakeDive,
    this.smallBump,
    this.skipped = false,
  });

  /// 1–5
  final int overallFeel;
  final String? frontFeel; // too_soft | ok | too_firm
  final String? brakeDive; // dives | neutral | harsh
  final String? smallBump; // harsh | ok | vague
  final bool skipped;

  Map<String, dynamic> toJson() => {
        'overallFeel': overallFeel,
        if (frontFeel != null) 'frontFeel': frontFeel,
        if (brakeDive != null) 'brakeDive': brakeDive,
        if (smallBump != null) 'smallBump': smallBump,
        'skipped': skipped,
      };

  factory RideFeedback.fromJson(Map<String, dynamic> json) {
    return RideFeedback(
      overallFeel: (json['overallFeel'] as num?)?.toInt() ?? 3,
      frontFeel: json['frontFeel'] as String?,
      brakeDive: json['brakeDive'] as String?,
      smallBump: json['smallBump'] as String?,
      skipped: json['skipped'] == true,
    );
  }
}

class TrackPoint {
  const TrackPoint({
    required this.lat,
    required this.lng,
    required this.timeMs,
    this.elev,
    this.heartRateBpm,
    this.cadenceRpm,
    this.powerW,
    this.leanDeg,
    this.gPeak,
    this.impact = false,
    this.speedKmh,
  });

  final double lat;
  final double lng;
  final int timeMs;
  final double? elev;
  /// Live 0x180D — omitted when null, never 0.
  final double? heartRateBpm;
  /// CSC crank — omitted when idle/unknown.
  final double? cadenceRpm;
  /// Cycling Power 0x1818 — omitted when null.
  final double? powerW;
  /// IMU lean at this GPS sample — omitted when unknown.
  final double? leanDeg;
  /// Peak g in the last fused window.
  final double? gPeak;
  /// True when the last window detected an impact.
  final bool impact;
  /// GPS speed — omitted when stalled / unknown.
  final double? speedKmh;

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'time': timeMs,
        if (elev != null) 'elev': elev,
        if (heartRateBpm != null &&
            heartRateBpm! >= 1 &&
            heartRateBpm! <= 239)
          'hr': heartRateBpm!.round(),
        if (cadenceRpm != null && cadenceRpm! > 0.5)
          'cad': cadenceRpm!.round(),
        if (powerW != null && powerW! > 0 && powerW! < 2500)
          'power': powerW!.round(),
        if (leanDeg != null && leanDeg!.abs() <= 80)
          'lean': (leanDeg! * 10).round() / 10,
        if (gPeak != null && gPeak! > 0 && gPeak! <= 20)
          'g': (gPeak! * 100).round() / 100,
        if (impact) 'impact': 1,
        if (speedKmh != null && speedKmh! > 0.4 && speedKmh! < 90)
          'spd': (speedKmh! * 10).round() / 10,
      };

  /// Inverse of [toJson] plus the looser keys already used on export/sync.
  static TrackPoint? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);
    final lat = (json['lat'] as num?)?.toDouble() ??
        (json['latitude'] as num?)?.toDouble();
    final lng = (json['lng'] as num?)?.toDouble() ??
        (json['lon'] as num?)?.toDouble() ??
        (json['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    if (lat.abs() > 90 || lng.abs() > 180) return null;
    final time = (json['time'] as num?)?.toInt() ??
        (json['timeMs'] as num?)?.toInt() ??
        0;
    return TrackPoint(
      lat: lat,
      lng: lng,
      timeMs: time,
      elev: (json['elev'] as num?)?.toDouble(),
      heartRateBpm: liveHrFromTrackPoint(json)?.toDouble(),
      cadenceRpm: liveCadFromTrackPoint(json)?.toDouble(),
      powerW: livePowerFromTrackPoint(json)?.toDouble(),
      leanDeg: liveLeanFromTrackPoint(json),
      gPeak: liveGFromTrackPoint(json),
      impact: liveImpactFromTrackPoint(json),
      speedKmh: liveSpeedFromTrackPoint(json),
    );
  }
}

int? liveHrFromTrackPoint(Map<String, dynamic> p) {
  final v = p['hr'] ?? p['heartRateBpm'];
  if (v is! num) return null;
  final n = v.round();
  if (n < 1 || n > 239) return null;
  return n;
}

int? liveCadFromTrackPoint(Map<String, dynamic> p) {
  final v = p['cad'] ?? p['cadenceRpm'];
  if (v is! num) return null;
  final n = v.round();
  if (n < 1 || n > 254) return null;
  return n;
}

int? livePowerFromTrackPoint(Map<String, dynamic> p) {
  final v = p['power'] ?? p['powerW'] ?? p['riderPowerW'];
  if (v is! num) return null;
  final n = v.round();
  if (n < 1 || n > 2500) return null;
  return n;
}

double? liveLeanFromTrackPoint(Map<String, dynamic> p) {
  final v = p['lean'] ?? p['leanDeg'];
  if (v is! num) return null;
  final n = v.toDouble();
  if (n.abs() > 80) return null;
  return n;
}

double? liveGFromTrackPoint(Map<String, dynamic> p) {
  final v = p['g'] ?? p['gPeak'];
  if (v is! num) return null;
  final n = v.toDouble();
  if (n <= 0 || n > 20) return null;
  return n;
}

bool liveImpactFromTrackPoint(Map<String, dynamic> p) {
  final v = p['impact'];
  if (v == true) return true;
  if (v is num) return v > 0;
  return false;
}

double? liveSpeedFromTrackPoint(Map<String, dynamic> p) {
  final v = p['spd'] ?? p['speedKmh'];
  if (v is! num) return null;
  final n = v.toDouble();
  if (n < 0.4 || n > 90) return null;
  return n;
}

/// Track-Länge in km (Haversine). 0 wenn zu wenige gültige Punkte.
double distanceKmFromTrack(Iterable<Map<String, dynamic>> track) {
  double meters = 0;
  double? prevLat;
  double? prevLng;
  for (final p in track) {
    final lat = (p['lat'] as num?)?.toDouble() ??
        (p['latitude'] as num?)?.toDouble();
    final lng = (p['lng'] as num?)?.toDouble() ??
        (p['lon'] as num?)?.toDouble() ??
        (p['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) continue;
    if (prevLat != null && prevLng != null) {
      meters += haversineM(prevLat, prevLng, lat, lng);
    }
    prevLat = lat;
    prevLng = lng;
  }
  return meters / 1000.0;
}

/// Profil-Stats: nie „0 km“ verkaufen, wenn es Rides gibt.
String formatProfileDistanceKm({
  required int rideCount,
  required double totalKm,
  required bool distanceKnown,
}) {
  if (rideCount <= 0) return '0';
  if (!distanceKnown) return '—';
  if (totalKm < 1) return '<1';
  return totalKm.round().toString();
}
