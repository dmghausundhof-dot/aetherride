class RideSummary {
  const RideSummary({
    required this.id,
    required this.bikeId,
    required this.startedAt,
    this.endedAt,
    this.distanceKm = 0,
    this.movingTimeSec = 0,
  });

  final String id;
  final String bikeId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double distanceKm;
  final int movingTimeSec;

  bool get isActive => endedAt == null;
}
