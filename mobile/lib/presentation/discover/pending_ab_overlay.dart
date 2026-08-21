import 'package:maplibre_gl/maplibre_gl.dart';

import 'discover_map_line_style.dart';

const kPendingAbSourceId = 'flowline-pending-ab';
const kPendingAbLayerId = 'flowline-pending-ab-line';
const kPendingAbCasingLayerId = 'flowline-pending-ab-casing';
const kPendingAbHaloLayerId = 'flowline-pending-ab-halo';
const kPendingAbDotLayerId = 'flowline-pending-ab-dot';
const kPendingAbLabelLayerId = 'flowline-pending-ab-label';

enum PendingAbKind { ghost, rubber }

const _pendingAbGhost = LineLayerProperties(
  lineColor: DiscoverMapLineStyle.pendingAb,
  lineWidth: DiscoverMapLineStyle.pendingAbWidth,
  lineOpacity: DiscoverMapLineStyle.pendingAbOpacity,
  lineDasharray: DiscoverMapLineStyle.pendingAbDash,
  lineCap: 'butt',
  lineJoin: 'round',
);

const _pendingAbRubber = LineLayerProperties(
  lineColor: DiscoverMapLineStyle.planRubber,
  lineWidth: DiscoverMapLineStyle.planRubberWidth,
  lineOpacity: DiscoverMapLineStyle.planRubberOpacity,
  lineCap: 'round',
  lineJoin: 'round',
);

const _pendingAbRubberHalo = LineLayerProperties(
  lineColor: DiscoverMapLineStyle.planRubberHalo,
  lineWidth: DiscoverMapLineStyle.planRubberHaloWidth,
  lineOpacity: DiscoverMapLineStyle.planRubberHaloOpacity,
  lineCap: 'round',
  lineJoin: 'round',
);

const _pendingAbRubberCasing = LineLayerProperties(
  lineColor: DiscoverMapLineStyle.planRubberCasing,
  lineWidth: DiscoverMapLineStyle.planRubberCasingWidth,
  lineOpacity: DiscoverMapLineStyle.planRubberCasingOpacity,
  lineCap: 'round',
  lineJoin: 'round',
);

const _pendingAbDot = CircleLayerProperties(
  circleRadius: 7,
  circleColor: '#FF6A00',
  circleStrokeWidth: 2.6,
  circleStrokeColor: '#FFFFFF',
  circleOpacity: 0.98,
);

const _pendingAbLabel = SymbolLayerProperties(
  textField: [Expressions.get, 'label'],
  textSize: 12,
  textColor: '#E65100',
  textHaloColor: '#FFFFFF',
  textHaloWidth: 1.5,
  textOffset: [0, 1.2],
  textAnchor: 'top',
  textAllowOverlap: true,
  textIgnorePlacement: true,
);

LineLayerProperties pendingAbLinePaint(PendingAbKind kind) =>
    kind == PendingAbKind.rubber ? _pendingAbRubber : _pendingAbGhost;

/// GeoJSON for the ghost/rubber overlay. Survives [clearLines] / [clearSymbols].
Map<String, dynamic> pendingAbFeatureCollection({
  required List<List<double>> lineLngLat,
  String? alongLabel,
  List<double>? labelLngLat,
}) {
  final features = <Map<String, dynamic>>[];
  if (lineLngLat.length >= 2) {
    features.add({
      'type': 'Feature',
      'properties': <String, dynamic>{},
      'geometry': {
        'type': 'LineString',
        'coordinates': lineLngLat,
      },
    });
  }
  final label = alongLabel?.trim() ?? '';
  if (labelLngLat != null && labelLngLat.length >= 2) {
    features.add({
      'type': 'Feature',
      'properties': {'label': label},
      'geometry': {
        'type': 'Point',
        'coordinates': [labelLngLat[0], labelLngLat[1]],
      },
    });
  }
  return {
    'type': 'FeatureCollection',
    'features': features,
  };
}

PendingAbKind? _raisedKind;

/// Dashed GPS→pin ghost, or rubber-band while reshaping.
/// GeoJSON layer survives [clearLines].
Future<void> syncPendingAbOverlay(
  MapLibreMapController c, {
  required List<LatLng>? line,
  PendingAbKind kind = PendingAbKind.ghost,
  String? alongLabel,
  LatLng? labelAt,
  bool raise = true,
}) async {
  try {
    final sources = [for (final id in await c.getSourceIds()) id.toString()];
    if (!sources.contains(kPendingAbSourceId)) {
      await c.addGeoJsonSource(kPendingAbSourceId, const {
        'type': 'FeatureCollection',
        'features': <dynamic>[],
      });
    }
  } catch (_) {}
  final coords = (line != null && line.length >= 2)
      ? [
          for (final p in line) [p.longitude, p.latitude],
        ]
      : const <List<double>>[];
  try {
    await c.setGeoJsonSource(
      kPendingAbSourceId,
      pendingAbFeatureCollection(
        lineLngLat: coords,
        alongLabel: alongLabel,
        labelLngLat: labelAt == null
            ? null
            : [labelAt.longitude, labelAt.latitude],
      ),
    );
  } catch (_) {}
  await raisePendingAbLayer(c, kind: kind, force: raise);
}

/// Re-add last so the ghost sits above faint farm-track style layers.
Future<void> raisePendingAbLayer(
  MapLibreMapController c, {
  PendingAbKind kind = PendingAbKind.ghost,
  bool force = true,
}) async {
  List<String> layers = const [];
  try {
    layers = [for (final id in await c.getLayerIds()) id.toString()];
  } catch (_) {}
  final haveLine = layers.contains(kPendingAbLayerId);
  if (force && haveLine) {
    for (final id in [
      kPendingAbLabelLayerId,
      kPendingAbDotLayerId,
      kPendingAbLayerId,
      kPendingAbCasingLayerId,
      kPendingAbHaloLayerId,
    ]) {
      try {
        if (layers.contains(id)) await c.removeLayer(id);
      } catch (_) {}
    }
  }
  final needAdd = force || !haveLine;
  if (needAdd) {
    if (kind == PendingAbKind.rubber) {
      try {
        await c.addLineLayer(
          kPendingAbSourceId,
          kPendingAbHaloLayerId,
          _pendingAbRubberHalo,
          filter: [
            '==',
            ['geometry-type'],
            'LineString',
          ],
          enableInteraction: false,
        );
      } catch (_) {}
      try {
        await c.addLineLayer(
          kPendingAbSourceId,
          kPendingAbCasingLayerId,
          _pendingAbRubberCasing,
          filter: [
            '==',
            ['geometry-type'],
            'LineString',
          ],
          enableInteraction: false,
        );
      } catch (_) {}
    }
    try {
      await c.addLineLayer(
        kPendingAbSourceId,
        kPendingAbLayerId,
        pendingAbLinePaint(kind),
        filter: [
          '==',
          ['geometry-type'],
          'LineString',
        ],
        enableInteraction: false,
      );
    } catch (_) {}
    try {
      await c.addCircleLayer(
        kPendingAbSourceId,
        kPendingAbDotLayerId,
        _pendingAbDot,
        filter: [
          '==',
          ['geometry-type'],
          'Point',
        ],
        enableInteraction: false,
      );
    } catch (_) {}
    try {
      await c.addSymbolLayer(
        kPendingAbSourceId,
        kPendingAbLabelLayerId,
        _pendingAbLabel,
        filter: [
          '==',
          ['geometry-type'],
          'Point',
        ],
        enableInteraction: false,
      );
    } catch (_) {}
  } else if (_raisedKind != kind) {
    try {
      await c.setLayerProperties(
        kPendingAbLayerId,
        pendingAbLinePaint(kind),
      );
    } catch (_) {}
  }
  _raisedKind = kind;
}
