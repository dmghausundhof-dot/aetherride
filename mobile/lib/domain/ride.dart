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

  /// Track points as {lat,lng,timeMs?,elev?}
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
  });

  final double lat;
  final double lng;
  final int timeMs;
  final double? elev;

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'time': timeMs,
        if (elev != null) 'elev': elev,
      };
}
