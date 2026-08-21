import 'dart:math' as math;

import 'coverage_graph_ring.dart';
import 'offline_pack_catalog.dart';

enum CoverageLabelKind { active, suggested }

enum CoverageWashKind { active, suggested }

const kCoverageActiveSourceId = 'ar-offline-coverage-active';
const kCoverageActiveFillLayerId = 'ar-offline-coverage-active-fill';
const kCoverageActiveLineLayerId = 'ar-offline-coverage-active-line';
const kCoverageActiveCornersLayerId = 'ar-offline-coverage-active-corners';

const kCoverageSuggestedSourceId = 'ar-offline-coverage-suggested';
const kCoverageSuggestedFillLayerId = 'ar-offline-coverage-suggested-fill';
const kCoverageSuggestedCasingLayerId = 'ar-offline-coverage-suggested-casing';
const kCoverageSuggestedLineLayerId = 'ar-offline-coverage-suggested-line';
const kCoverageSuggestedCornersLayerId =
    'ar-offline-coverage-suggested-corners';

const kCoverageRoleFill = 'fill';
const kCoverageRoleOutline = 'outline';
const kCoverageRoleCorners = 'corners';

const kCoverageOutlineFilter = ['==', 'role', kCoverageRoleOutline];
const kCoverageCornersFilter = ['==', 'role', kCoverageRoleCorners];
const kCoverageFillFilter = ['==', 'role', kCoverageRoleFill];

/// MapLibre `line-dasharray` for a pack that is not loaded yet.
const kCoverageSuggestedDasharray = [2.4, 1.8];

/// Suggested wash uses a dashed outline; the loaded pack stays solid.
bool coverageWashDashed(CoverageWashKind kind) =>
    kind == CoverageWashKind.suggested;

Map<String, dynamic> emptyCoverageFeatureCollection() => <String, dynamic>{
      'type': 'FeatureCollection',
      'features': <dynamic>[],
    };

/// Polygon + outline + L-ticks. A graph ring replaces the chamfered bbox
/// so a city pack reads as coverage, not a rectangle.
Map<String, dynamic> coverageBboxFeatureCollection(
  List<double>? bbox, {
  List<List<double>>? ring,
}) {
  if (bbox == null || bbox.length < 4) return emptyCoverageFeatureCollection();
  final useRing = ring != null && ring.length >= 5
      ? coverageClosedRing(ring)
      : offlinePackCoverageRing(bbox);
  if (useRing.length < 4) return emptyCoverageFeatureCollection();
  final ticks = ring != null && ring.length >= 5
      ? const <List<List<double>>>[]
      : offlinePackCoverageCorners(bbox);
  return {
    'type': 'FeatureCollection',
    'features': [
      {
        'type': 'Feature',
        'properties': {'role': kCoverageRoleFill},
        'geometry': {
          'type': 'Polygon',
          'coordinates': [useRing],
        },
      },
      {
        'type': 'Feature',
        'properties': {'role': kCoverageRoleOutline},
        'geometry': {
          'type': 'LineString',
          'coordinates': useRing,
        },
      },
      if (ticks.isNotEmpty)
        for (final tick in ticks)
          {
            'type': 'Feature',
            'properties': {'role': kCoverageRoleCorners},
            'geometry': {
              'type': 'LineString',
              'coordinates': tick,
            },
          },
    ],
  };
}

/// Four L-shaped ticks at the geographic bbox corners (map-frame).
List<List<List<double>>> offlinePackCoverageCorners(
  List<double> bbox, {
  double frac = 0.16,
}) {
  if (bbox.length < 4) return const [];
  final w = bbox[0];
  final s = bbox[1];
  final e = bbox[2];
  final n = bbox[3];
  final dx = (e - w).abs() * frac;
  final dy = (n - s).abs() * frac;
  if (!(dx > 1e-6) || !(dy > 1e-6)) return const [];
  return [
    [
      [w, s + dy],
      [w, s],
      [w + dx, s],
    ],
    [
      [e - dx, s],
      [e, s],
      [e, s + dy],
    ],
    [
      [e, n - dy],
      [e, n],
      [e - dx, n],
    ],
    [
      [w + dx, n],
      [w, n],
      [w, n - dy],
    ],
  ];
}

/// Glanceable pack name: drop „ / Heidelberg“ city tails.
String coverageGlanceName(String packLabel) {
  var t = packLabel.trim();
  if (t.isEmpty) return t;
  final slash = t.indexOf(' / ');
  if (slash >= 4) t = t.substring(0, slash).trim();
  return t;
}

/// Glanceable pack name for the map-contents chip. Full label stays in the tooltip.
String coverageChipCaption(String packLabel, {int maxChars = 14}) {
  final t = coverageGlanceName(packLabel);
  if (t.isEmpty || t.length <= maxChars) return t;
  final space = t.indexOf(' ');
  if (space >= 5 && space <= maxChars) {
    return t.substring(0, space);
  }
  return '${t.substring(0, maxChars - 1)}…';
}

/// MapLibre wash: loaded pack is chrome; suggested pack is sage (not active).
/// Corner ticks are thicker than the octagon so they read as a map frame.
({
  String fillColor,
  double fillOpacity,
  String lineColor,
  double lineWidth,
  double lineOpacity,
  double cornerWidth,
}) coverageWashPaint({
  required CoverageWashKind kind,
  required bool dimmed,
  bool emphasized = false,
}) {
  if (kind == CoverageWashKind.active) {
    return (
      fillColor: '#FF6A00',
      fillOpacity: emphasized ? 0.14 : 0.10,
      lineColor: '#FF6A00',
      lineWidth: emphasized ? 3.0 : 2.6,
      lineOpacity: 0.92,
      cornerWidth: emphasized ? 4.6 : 4.0,
    );
  }
  if (emphasized) {
    return (
      fillColor: '#7A8B73',
      fillOpacity: 0.18,
      lineColor: '#5E6F58',
      lineWidth: 2.8,
      lineOpacity: 0.95,
      cornerWidth: 4.2,
    );
  }
  return (
    fillColor: '#7A8B73',
    fillOpacity: dimmed ? 0.08 : 0.11,
    lineColor: '#7A8B73',
    lineWidth: dimmed ? 2.0 : 2.4,
    lineOpacity: dimmed ? 0.72 : 0.88,
    cornerWidth: dimmed ? 3.2 : 3.6,
  );
}

/// Hide the pack name when the box is a speck or fills street view.
/// Fill and outline stay; only the text goes — unless [coverageOverlayVisible]
/// also drops the wash.
bool coverageNameVisibleAtZoom({
  required double zoom,
  required List<double> bbox,
  String? packId,
}) {
  if (!coverageOverlayVisible(zoom: zoom, bbox: bbox, packId: packId)) {
    return false;
  }
  if (zoom < 6.2) return false;
  return true;
}

/// Orange wash is a city/region bbox, not a country envelope, and not a
/// tint over street/trail zoom.
bool coverageOverlayVisible({
  required double zoom,
  required List<double> bbox,
  String? packId,
}) {
  if (bbox.length < 4) return false;
  if (zoom >= 11.2) return false;
  if (packId != null && isEnvelopePackId(packId)) return false;
  final span = math.max(bbox[2] - bbox[0], bbox[3] - bbox[1]);
  if (span <= 0 || span > 1.8) return false;
  return true;
}

/// Sync markers when the name would appear or vanish.
int coverageNameZoomBand(double zoom) {
  if (zoom < 6.2) return 0;
  if (zoom < 8.5) return 1;
  if (zoom < 9.0) return 2;
  if (zoom < 11.2) return 3;
  return 4;
}

/// True when [inner] lies fully inside [outer] (same box counts).
bool coverageBboxContains(List<double> outer, List<double> inner) {
  if (outer.length < 4 || inner.length < 4) return false;
  return inner[0] >= outer[0] - 1e-6 &&
      inner[1] >= outer[1] - 1e-6 &&
      inner[2] <= outer[2] + 1e-6 &&
      inner[3] <= outer[3] + 1e-6;
}

bool coveragePointInBbox({
  required double lng,
  required double lat,
  required List<double> bbox,
  double padDeg = 0.01,
}) {
  if (bbox.length < 4) return false;
  return lng >= bbox[0] - padDeg &&
      lat >= bbox[1] - padDeg &&
      lng <= bbox[2] + padDeg &&
      lat <= bbox[3] + padDeg;
}

List<double> _coveragePaddedBox(List<double> bbox, double padDeg) => [
      bbox[0] - padDeg,
      bbox[1] - padDeg,
      bbox[2] + padDeg,
      bbox[3] + padDeg,
    ];

bool _coverageSameLngLat(List<double> a, List<double> b) =>
    a.length >= 2 &&
    b.length >= 2 &&
    (a[0] - b[0]).abs() < 1e-10 &&
    (a[1] - b[1]).abs() < 1e-10;

List<double> _coverageLerpLngLat(List<double> a, List<double> b, double t) => [
      a[0] + (b[0] - a[0]) * t,
      a[1] + (b[1] - a[1]) * t,
    ];

/// Parameter t in (0, 1) where segment [a]→[b] hits the padded bbox edge.
List<double> _coverageSegmentBboxHits(
  List<double> a,
  List<double> b,
  List<double> box,
) {
  final ax = a[0];
  final ay = a[1];
  final dx = b[0] - ax;
  final dy = b[1] - ay;
  final ts = <double>[];
  void addT(double t) {
    if (t <= 1e-8 || t >= 1 - 1e-8) return;
    for (final e in ts) {
      if ((e - t).abs() < 1e-8) return;
    }
    ts.add(t);
  }

  if (dx.abs() > 1e-14) {
    for (final x in [box[0], box[2]]) {
      final t = (x - ax) / dx;
      final y = ay + t * dy;
      if (y >= box[1] - 1e-9 && y <= box[3] + 1e-9) addT(t);
    }
  }
  if (dy.abs() > 1e-14) {
    for (final y in [box[1], box[3]]) {
      final t = (y - ay) / dy;
      final x = ax + t * dx;
      if (x >= box[0] - 1e-9 && x <= box[2] + 1e-9) addT(t);
    }
  }
  ts.sort();
  return ts;
}

void _coverageEmitLineRun(
  List<({bool outside, List<List<double>> coords})> runs, {
  required bool outside,
  required List<double> from,
  required List<double> to,
}) {
  if (_coverageSameLngLat(from, to)) return;
  if (runs.isNotEmpty && runs.last.outside == outside) {
    final acc = runs.last.coords;
    if (!_coverageSameLngLat(acc.last, from)) {
      acc.add(List<double>.from(from));
    }
    acc.add(List<double>.from(to));
    return;
  }
  runs.add((
    outside: outside,
    coords: [List<double>.from(from), List<double>.from(to)],
  ));
}

bool coveragePointInCoverage({
  required double lng,
  required double lat,
  required List<double> bbox,
  List<List<double>>? ring,
  double padDeg = 0.01,
}) {
  if (ring != null && ring.length >= 4) {
    return coveragePointInRing(lng: lng, lat: lat, ring: ring);
  }
  return coveragePointInBbox(lng: lng, lat: lat, bbox: bbox, padDeg: padDeg);
}

bool coverageCoversLngLats({
  required Iterable<({double lng, double lat})> points,
  required List<double> bbox,
  List<List<double>>? ring,
}) {
  for (final p in points) {
    if (!coveragePointInCoverage(
      lng: p.lng,
      lat: p.lat,
      bbox: bbox,
      ring: ring,
    )) {
      return false;
    }
  }
  return true;
}

List<double> _coverageSegmentRingCrossing(
  List<double> a,
  List<double> b,
  List<List<double>> ring,
) {
  var lo = 0.0;
  var hi = 1.0;
  final aIn = coveragePointInRing(lng: a[0], lat: a[1], ring: ring);
  for (var i = 0; i < 14; i++) {
    final t = (lo + hi) / 2;
    final p = _coverageLerpLngLat(a, b, t);
    final inn = coveragePointInRing(lng: p[0], lat: p[1], ring: ring);
    if (inn == aIn) {
      lo = t;
    } else {
      hi = t;
    }
  }
  return _coverageLerpLngLat(a, b, (lo + hi) / 2);
}

void _coverageSplitSegment(
  List<({bool outside, List<List<double>> coords})> runs, {
  required List<double> a,
  required List<double> b,
  required bool Function(List<double> p) outsideOf,
  List<double> Function(List<double> a, List<double> b)? crossing,
}) {
  final aOut = outsideOf(a);
  final bOut = outsideOf(b);
  final mid = _coverageLerpLngLat(a, b, 0.5);
  final mOut = outsideOf(mid);
  if (aOut == bOut && aOut == mOut) {
    _coverageEmitLineRun(runs, outside: aOut, from: a, to: b);
    return;
  }
  if (crossing == null) {
    _coverageEmitLineRun(
      runs,
      outside: aOut || bOut || mOut,
      from: a,
      to: b,
    );
    return;
  }
  if (aOut != bOut) {
    final x = crossing(a, b);
    _coverageEmitLineRun(runs, outside: aOut, from: a, to: x);
    _coverageEmitLineRun(runs, outside: bOut, from: x, to: b);
    return;
  }
  final x1 = crossing(a, mid);
  final x2 = crossing(mid, b);
  _coverageEmitLineRun(runs, outside: aOut, from: a, to: x1);
  _coverageEmitLineRun(runs, outside: !aOut, from: x1, to: x2);
  _coverageEmitLineRun(runs, outside: bOut, from: x2, to: b);
}

/// Split a lng/lat polyline at the pack bbox. Crossing vertices sit on the
/// padded edge so chrome and sage runs meet without a gap.
///
/// [ring] (graph occupancy) replaces the rectangle when present.
/// [routingReady] false or a missing bbox → one inside run (leave the line
/// chrome — there is no pack to be outside of).
List<({bool outside, List<List<double>> coords})> coverageSplitLineByBbox({
  required List<List<double>> lineLngLat,
  required List<double>? bbox,
  required bool routingReady,
  List<List<double>>? ring,
  double padDeg = 0.01,
}) {
  if (lineLngLat.length < 2) return const [];
  if (!routingReady || bbox == null || bbox.length < 4) {
    return [
      (
        outside: false,
        coords: [for (final p in lineLngLat) List<double>.from(p)],
      ),
    ];
  }
  final runs = <({bool outside, List<List<double>> coords})>[];
  final useRing = ring != null && ring.length >= 4;
  if (useRing) {
    bool outOf(List<double> p) =>
        p.length < 2 ||
        !coveragePointInRing(lng: p[0], lat: p[1], ring: ring);
    for (var i = 0; i < lineLngLat.length - 1; i++) {
      final a = lineLngLat[i];
      final b = lineLngLat[i + 1];
      if (a.length < 2 || b.length < 2) continue;
      _coverageSplitSegment(
        runs,
        a: a,
        b: b,
        outsideOf: outOf,
        crossing: (from, to) => _coverageSegmentRingCrossing(from, to, ring),
      );
    }
    return runs;
  }
  final box = _coveragePaddedBox(bbox, padDeg);
  for (var i = 0; i < lineLngLat.length - 1; i++) {
    final a = lineLngLat[i];
    final b = lineLngLat[i + 1];
    if (a.length < 2 || b.length < 2) continue;
    final hits = _coverageSegmentBboxHits(a, b, box);
    var prev = a;
    for (final t in hits) {
      final at = _coverageLerpLngLat(a, b, t);
      final mid = _coverageLerpLngLat(prev, at, 0.5);
      _coverageEmitLineRun(
        runs,
        outside: !coveragePointInBbox(
          lng: mid[0],
          lat: mid[1],
          bbox: bbox,
          padDeg: padDeg,
        ),
        from: prev,
        to: at,
      );
      prev = at;
    }
    final mid = _coverageLerpLngLat(prev, b, 0.5);
    _coverageEmitLineRun(
      runs,
      outside: !coveragePointInBbox(
        lng: mid[0],
        lat: mid[1],
        bbox: bbox,
        padDeg: padDeg,
      ),
      from: prev,
      to: b,
    );
  }
  return runs;
}

/// Inside-only parts of [lineLngLat] — surface/steep tints stay in the pack.
List<List<List<double>>> coverageLinePartsInside({
  required List<List<double>> lineLngLat,
  required List<double>? bbox,
  required bool routingReady,
  List<List<double>>? ring,
  double padDeg = 0.01,
}) {
  return [
    for (final run in coverageSplitLineByBbox(
      lineLngLat: lineLngLat,
      bbox: bbox,
      routingReady: routingReady,
      ring: ring,
      padDeg: padDeg,
    ))
      if (!run.outside) run.coords,
  ];
}

/// GPS next to a loaded pack — Explore still looks empty without this flag.
bool coverageRiderOutside({
  required double? lng,
  required double? lat,
  required List<double>? bbox,
  required bool routingReady,
  List<List<double>>? ring,
}) {
  if (!routingReady || bbox == null || bbox.length < 4) return false;
  if (lng == null || lat == null) return false;
  return !coveragePointInCoverage(
    lng: lng,
    lat: lat,
    bbox: bbox,
    ring: ring,
  );
}

/// Suggested wash that swallows the active pack reads as a second country.
bool coverageSuggestedOccludesActive({
  required List<double>? active,
  required List<double>? suggested,
}) {
  if (active == null || suggested == null) return false;
  if (active.length < 4 || suggested.length < 4) return false;
  return coverageBboxContains(suggested, active);
}

/// Insert coverage under trails / tour lines / the rubber-band, above streets.
String? coverageSeatBelowLayerId(Iterable<dynamic> layerIds) {
  const known = {
    'bike-overlay-mtb',
    'bike-overlay-mtb-unrated',
    'bike-overlay-gravel',
    'bike-overlay-road',
    'bike-overlay-urban',
    'osm-sgrade-mtb',
    'osm-live-path',
    'osm-live-track',
    'osm-live-cycleway',
    'osm-live-street',
    'flowline-plan-paved-line',
    'flowline-plan-gravel-line',
    'flowline-plan-trail-line',
    'flowline-plan-steep-line',
    'flowline-plan-pack-out-line',
    'flowline-pending-ab-line',
  };
  final annotation = RegExp(r'^[A-Za-z0-9]{8,}_[0-9]+$');
  for (final raw in layerIds) {
    final id = raw.toString();
    if (id.startsWith('ar-offline-coverage')) continue;
    if (known.contains(id)) return id;
    if (id.startsWith('flowline-')) return id;
    if (annotation.hasMatch(id)) return id;
  }
  return null;
}

/// North rim of the bbox, slightly inside the fill — not the empty centroid.
({double lng, double lat}) coverageLabelLngLat({
  required List<double> bbox,
  required CoverageLabelKind kind,
  List<({double lng, double lat})> avoid = const [],
}) {
  final west = bbox[0];
  final south = bbox[1];
  final east = bbox[2];
  final north = bbox[3];
  final lat = south + (north - south) * 0.88;
  var lng = kind == CoverageLabelKind.suggested
      ? west + (east - west) * 0.72
      : (west + east) / 2;
  for (final a in avoid) {
    if ((lng - a.lng).abs() < 0.045 && (lat - a.lat).abs() < 0.045) {
      lng = west +
          (east - west) * (kind == CoverageLabelKind.suggested ? 0.28 : 0.22);
      break;
    }
  }
  return (lng: lng, lat: lat);
}
