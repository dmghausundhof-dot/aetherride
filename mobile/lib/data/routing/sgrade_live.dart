import '../../domain/routing/bike_overlay_class.dart';
import '../../domain/routing/trail_difficulty.dart';
import 'osm_trail_network_client.dart';

const kOsmSGradeSourceId = 'osm-sgrade';
const kOsmSGradeLayerId = 'osm-sgrade-mtb';

/// Below this zoom Overpass would return a country-sized mesh / time out.
const kOsmSGradeMinZoom = 11.0;

/// Max viewport span (degrees) sent to Overpass — same honesty as osmLive clamp.
const kOsmSGradeMaxBboxDeg = 0.4;

bool shouldFetchSGradeLive({
  required bool overlayOn,
  required Set<BikeOverlayClass> extraOn,
  required double zoom,
}) {
  if (!overlayOn) return false;
  if (!extraOn.contains(BikeOverlayClass.mtb)) return false;
  return zoom + 1e-9 >= kOsmSGradeMinZoom;
}

bool isHonestSGradeTrail(OsmTrailSegment trail) =>
    trail.difficulty != TrailDifficulty.open;

Map<String, dynamic> sGradeFeatureCollection(List<OsmTrailSegment> trails) {
  final features = <Map<String, dynamic>>[];
  for (final t in trails) {
    if (!isHonestSGradeTrail(t)) continue;
    if (t.geometry.length < 2) continue;
    features.add({
      'type': 'Feature',
      'properties': {
        'bike_class': 'mtb',
        'mtb_scale': trailDifficultyLabel(t.difficulty),
        'osm_id': t.osmWayId ?? t.id,
        'name': t.name,
        'highway': t.highway ?? '',
      },
      'geometry': {
        'type': 'LineString',
        'coordinates': t.geometry,
      },
    });
  }
  return {'type': 'FeatureCollection', 'features': features};
}

({double west, double south, double east, double north}) clampSGradeBbox({
  required double west,
  required double south,
  required double east,
  required double north,
}) {
  final cx = (west + east) / 2;
  final cy = (south + north) / 2;
  final halfLng = (east - west).abs() / 2;
  final halfLat = (north - south).abs() / 2;
  final cap = kOsmSGradeMaxBboxDeg / 2;
  return (
    west: cx - halfLng.clamp(0.0, cap),
    south: cy - halfLat.clamp(0.0, cap),
    east: cx + halfLng.clamp(0.0, cap),
    north: cy + halfLat.clamp(0.0, cap),
  );
}
