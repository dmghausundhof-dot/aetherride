import '../privacy/consents.dart';
import '../privacy/track_trim.dart';

/// F-NAV-005 Heatmap-Aggregation aus eigenen Rides (Port heatmaps.ts).
class HeatSegment {
  const HeatSegment({
    required this.id,
    required this.coordinatesLngLat,
    required this.uniqueUsers,
    required this.intensity,
    required this.visible,
    this.hideReason,
  });

  final String id;
  /// [lng, lat]
  final List<List<double>> coordinatesLngLat;
  final int uniqueUsers;
  final double intensity;
  final bool visible;
  final String? hideReason;
}

class HeatmapResult {
  const HeatmapResult({
    required this.segments,
    required this.coldStart,
    required this.kThreshold,
    required this.attribution,
    required this.disclaimer,
  });

  final List<HeatSegment> segments;
  final bool coldStart;
  final int kThreshold;
  final String attribution;
  final String disclaimer;

  List<HeatSegment> get visibleSegments =>
      [for (final s in segments) if (s.visible) s];
}

const kHeatmapThreshold = 5;

HeatmapResult buildHeatmapFromRides({
  required bool consentHeatmap,
  required List<({String id, List<Map<String, dynamic>> track})> rides,
  List<PrivacyZone> privacyZones = const [],
  bool includeSeedFallback = false,
}) {
  final fromRides = <HeatSegment>[];

  for (final ride in rides) {
    if (ride.track.length < 3) continue;
    final trimmed = trimTrackForPrivacyZones(ride.track, privacyZones);
    if (trimmed.length < 4) continue;
    final step = (trimmed.length / 8).floor().clamp(1, trimmed.length);
    final coords = <List<double>>[];
    for (var i = 0; i < trimmed.length; i += step) {
      final p = trimmed[i];
      final lat = (p['lat'] as num?)?.toDouble() ?? 0;
      final lng =
          (p['lng'] as num?)?.toDouble() ?? (p['lon'] as num?)?.toDouble() ?? 0;
      coords.add([lng, lat]);
    }
    if (coords.length < 2) continue;
    fromRides.add(
      HeatSegment(
        id: 'ride-${ride.id}',
        coordinatesLngLat: coords,
        uniqueUsers: consentHeatmap ? kHeatmapThreshold : 1,
        intensity: consentHeatmap ? 0.65 : 0,
        visible: consentHeatmap,
        hideReason: consentHeatmap
            ? null
            : 'Beitrag zur Beliebtheitskarte ist aus — unter Privatsphäre aktivierbar',
      ),
    );
  }

  final useSeed = fromRides.isEmpty && includeSeedFallback;
  final seed = useSeed ? _seedSegments() : const <HeatSegment>[];
  final segments = [...fromRides, ...seed];
  final visibleCount = segments.where((s) => s.visible).length;

  return HeatmapResult(
    segments: segments,
    coldStart: fromRides.isEmpty || visibleCount < 3,
    kThreshold: kHeatmapThreshold,
    attribution: '© OpenStreetMap · AetherRide eigene Aggregate',
    disclaimer: fromRides.isNotEmpty
        ? (consentHeatmap
            ? 'Aus deinen Rides (Start/Ziel und Privatbereiche ausgeblendet).'
            : 'Deine Strecken sind ausgeblendet — Consent unter Privatsphäre.')
        : (useSeed
            ? 'Noch wenig eigene Daten — Beispielabschnitte bis genug Rides da sind.'
            : 'Noch keine eigenen Tracks für die Beliebtheitskarte — kein Community-Demo.'),
  );
}

List<HeatSegment> _seedSegments() {
  const raw = <(String, int, List<List<double>>)>[
    (
      'hs-flow-demo',
      12,
      [
        [7.85, 47.99],
        [7.86, 48.00],
        [7.87, 48.01],
        [7.88, 48.015],
      ],
    ),
    (
      'hs-trail-demo',
      8,
      [
        [7.88, 48.00],
        [7.89, 48.005],
        [7.90, 48.01],
      ],
    ),
    (
      'hs-private',
      2,
      [
        [7.84, 47.98],
        [7.842, 47.981],
      ],
    ),
  ];
  return [
    for (final s in raw)
      HeatSegment(
        id: s.$1,
        coordinatesLngLat: s.$3,
        uniqueUsers: s.$2,
        intensity: s.$2 < kHeatmapThreshold ? 0 : (s.$2 / 20).clamp(0.0, 1.0),
        visible: s.$2 >= kHeatmapThreshold,
        hideReason: s.$2 < kHeatmapThreshold
            ? 'Zu wenig Fahrer (${s.$2} von mind. $kHeatmapThreshold)'
            : null,
      ),
  ];
}
