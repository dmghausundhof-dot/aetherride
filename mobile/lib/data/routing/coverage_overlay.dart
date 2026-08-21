import 'package:maplibre_gl/maplibre_gl.dart';

import 'coverage_label.dart';

/// One in-flight sync per wash kind — MapLibre SIGSEGV on duplicate addSource.
final Map<CoverageWashKind, Future<void>> _coverageSyncInflight = {};

typedef _CoverageLayerIds = ({
  String source,
  String fill,
  String line,
  String corners,
  String? casing,
});

_CoverageLayerIds _coverageLayerIds(CoverageWashKind kind) {
  return switch (kind) {
    CoverageWashKind.active => (
        source: kCoverageActiveSourceId,
        fill: kCoverageActiveFillLayerId,
        line: kCoverageActiveLineLayerId,
        corners: kCoverageActiveCornersLayerId,
        casing: null,
      ),
    CoverageWashKind.suggested => (
        source: kCoverageSuggestedSourceId,
        fill: kCoverageSuggestedFillLayerId,
        line: kCoverageSuggestedLineLayerId,
        corners: kCoverageSuggestedCornersLayerId,
        casing: kCoverageSuggestedCasingLayerId,
      ),
    CoverageWashKind.street => (
        source: kCoverageStreetSourceId,
        fill: kCoverageStreetFillLayerId,
        line: kCoverageStreetLineLayerId,
        corners: kCoverageStreetCornersLayerId,
        casing: null,
      ),
  };
}

Future<void> _addLineLayer(
  MapLibreMapController c, {
  required String source,
  required String layerId,
  required LineLayerProperties props,
  required List<dynamic> filter,
  String? belowLayerId,
}) async {
  try {
    await c.addLineLayer(
      source,
      layerId,
      props,
      belowLayerId: belowLayerId,
      filter: filter,
      enableInteraction: false,
    );
  } catch (_) {
    try {
      await c.addLineLayer(
        source,
        layerId,
        props,
        filter: filter,
        enableInteraction: false,
      );
    } catch (_) {}
  }
}

/// Pack wash as GeoJSON so [MapLibreMapController.clearLines] cannot wipe it.
///
/// [belowLayerId] seats the wash under trails / tour lines / pins.
/// Suggested packs get a light casing + dashed outline.
/// Corner ticks use a separate, thicker layer so they read as a map frame.
Future<void> syncCoverageWashOverlay(
  MapLibreMapController c, {
  required CoverageWashKind kind,
  required List<double>? bbox,
  required bool dimmed,
  bool emphasized = false,
  String? belowLayerId,
  List<List<double>>? ring,
}) {
  final prev = _coverageSyncInflight[kind] ?? Future<void>.value();
  final run = prev.then(
    (_) => _syncCoverageWashOverlayBody(
      c,
      kind: kind,
      bbox: bbox,
      dimmed: dimmed,
      emphasized: emphasized,
      belowLayerId: belowLayerId,
      ring: ring,
    ),
  );
  _coverageSyncInflight[kind] = run.catchError((_) {});
  return run;
}

Future<void> _syncCoverageWashOverlayBody(
  MapLibreMapController c, {
  required CoverageWashKind kind,
  required List<double>? bbox,
  required bool dimmed,
  required bool emphasized,
  String? belowLayerId,
  List<List<double>>? ring,
}) async {
  final ids = _coverageLayerIds(kind);
  final paint = coverageWashPaint(
    kind: kind,
    dimmed: dimmed,
    emphasized: emphasized,
  );
  final dashed = coverageWashDashed(kind);

  var hasSource = false;
  try {
    hasSource = (await c.getSourceIds()).contains(ids.source);
  } catch (_) {}
  if (!hasSource) {
    try {
      await c.addGeoJsonSource(ids.source, emptyCoverageFeatureCollection());
    } catch (_) {}
  }

  Future<void> drop(String layerId) async {
    try {
      await c.removeLayer(layerId);
    } catch (_) {}
  }

  await drop(ids.fill);
  final casingId = ids.casing;
  if (casingId != null) await drop(casingId);
  await drop(ids.line);
  await drop(ids.corners);

  try {
    await c.addFillLayer(
      ids.source,
      ids.fill,
      FillLayerProperties(
        fillColor: paint.fillColor,
        fillOpacity: paint.fillOpacity,
        fillOutlineColor: 'rgba(0,0,0,0)',
      ),
      belowLayerId: belowLayerId,
      filter: kCoverageFillFilter,
      enableInteraction: false,
    );
  } catch (_) {
    try {
      await c.addFillLayer(
        ids.source,
        ids.fill,
        FillLayerProperties(
          fillColor: paint.fillColor,
          fillOpacity: paint.fillOpacity,
          fillOutlineColor: 'rgba(0,0,0,0)',
        ),
        filter: kCoverageFillFilter,
        enableInteraction: false,
      );
    } catch (_) {}
  }
  if (casingId != null) {
    await _addLineLayer(
      c,
      source: ids.source,
      layerId: casingId,
      belowLayerId: belowLayerId,
      filter: kCoverageOutlineFilter,
      props: LineLayerProperties(
        lineColor: '#F7F4EE',
        lineWidth: paint.lineWidth + 2.4,
        lineOpacity: dimmed && !emphasized ? 0.35 : 0.5,
        lineCap: 'butt',
        lineJoin: 'round',
      ),
    );
  }
  await _addLineLayer(
    c,
    source: ids.source,
    layerId: ids.line,
    belowLayerId: belowLayerId,
    filter: kCoverageOutlineFilter,
    props: LineLayerProperties(
      lineColor: paint.lineColor,
      lineWidth: paint.lineWidth,
      lineOpacity: paint.lineOpacity,
      lineDasharray: dashed ? kCoverageSuggestedDasharray : null,
      lineCap: dashed ? 'butt' : 'round',
      lineJoin: 'round',
    ),
  );
  if (paint.cornerWidth > 0) {
    await _addLineLayer(
      c,
      source: ids.source,
      layerId: ids.corners,
      belowLayerId: belowLayerId,
      filter: kCoverageCornersFilter,
      props: LineLayerProperties(
        lineColor: paint.lineColor,
        lineWidth: paint.cornerWidth,
        lineOpacity: paint.lineOpacity,
        lineCap: 'square',
        lineJoin: 'miter',
      ),
    );
  }

  if (!hasSource) {
    try {
      hasSource = (await c.getSourceIds()).contains(ids.source);
    } catch (_) {}
  }
  if (!hasSource) return;
  try {
    await c.setGeoJsonSource(
      ids.source,
      coverageBboxFeatureCollection(bbox, ring: ring),
    );
  } catch (_) {}
}
