// DACH offline-pack catalog rows (API + local fallback).
// `downloadable` is false for catalog stubs that have no tarball / graph.

import 'overlay_regions.dart';

/// Bundled `assets/routing/offline_graph.json` is the Schwarzwald extract.
const kBundledOfflineGraphRegionId = 'schwarzwald-nord';

/// SHA-256 of the bundled demo graph (must not be activated as another region).
const kBundledOfflineGraphSha256 =
    '849a4ec629b4ca0a513c8bb8475589e49cfb3d6a3f1be877557f073543b4e8f8';

class OfflinePackRow {
  const OfflinePackRow({
    required this.id,
    required this.name,
    this.bbox,
    this.downloadable = false,
    this.bytes,
    this.status = 'stub',
  });

  final String id;
  final String name;

  /// [west, south, east, north]
  final List<double>? bbox;
  final bool downloadable;
  final int? bytes;
  final String status;

  bool get isReady => downloadable && status != 'stub';

  OfflinePackRow copyWith({
    String? name,
    List<double>? bbox,
    bool? downloadable,
    int? bytes,
    String? status,
  }) {
    return OfflinePackRow(
      id: id,
      name: name ?? this.name,
      bbox: bbox ?? this.bbox,
      downloadable: downloadable ?? this.downloadable,
      bytes: bytes ?? this.bytes,
      status: status ?? this.status,
    );
  }
}

bool pointInLngLatBbox(List<double> bbox, double lng, double lat) {
  if (bbox.length < 4) return false;
  return lng >= bbox[0] && lat >= bbox[1] && lng <= bbox[2] && lat <= bbox[3];
}

OfflinePackRow? parseOfflinePackRow(Object? raw) {
  if (raw is! Map) return null;
  final id = raw['id'] as String?;
  if (id == null || id.isEmpty) return null;
  List<double>? bbox;
  final b = raw['bbox'];
  if (b is List && b.length >= 4) {
    bbox = [
      for (final x in b.take(4))
        if (x is num) x.toDouble(),
    ];
    if (bbox.length < 4) bbox = null;
  }
  final files = raw['files'];
  final inferred = files is Map && files.isNotEmpty;
  final downloadable = raw['downloadable'] as bool? ?? inferred;
  final status =
      (raw['status'] as String?) ?? (downloadable ? 'ready' : 'stub');
  return OfflinePackRow(
    id: id,
    name: (raw['name'] as String?) ?? id,
    bbox: bbox,
    downloadable: downloadable,
    bytes: (raw['bytes'] as num?)?.toInt(),
    status: status,
  );
}

List<OfflinePackRow> mergeOfflineCatalog({
  required List<OfflinePackRow> api,
  required List<OverlayRegion> local,
}) {
  final byId = <String, OfflinePackRow>{
    for (final p in api) p.id: p,
  };
  for (final r in local) {
    final existing = byId[r.id];
    if (existing == null) {
      byId[r.id] = OfflinePackRow(
        id: r.id,
        name: r.name,
        bbox: r.bbox,
        downloadable: false,
        status: 'stub',
      );
    } else if (existing.bbox == null || existing.bbox!.length < 4) {
      byId[r.id] = existing.copyWith(bbox: r.bbox);
    }
  }
  return byId.values.toList();
}

/// Prefer [ready] rows when merging two catalog sources (API + Storage CDN).
List<OfflinePackRow> mergePreferReady(
  List<OfflinePackRow> primary,
  List<OfflinePackRow> extra,
) {
  final byId = <String, OfflinePackRow>{
    for (final p in primary) p.id: p,
  };
  for (final p in extra) {
    final existing = byId[p.id];
    if (existing == null || (p.isReady && !existing.isReady)) {
      byId[p.id] = p;
    }
  }
  return byId.values.toList();
}

double? packDistanceDeg(OfflinePackRow r, double lng, double lat) {
  final b = r.bbox;
  if (b == null || b.length < 4) return null;
  final cx = (b[0] + b[2]) / 2;
  final cy = (b[1] + b[3]) / 2;
  final dx = cx - lng;
  final dy = cy - lat;
  return dx * dx + dy * dy;
}

List<OfflinePackRow> sortOfflinePacks(
  List<OfflinePackRow> packs, {
  double? userLng,
  double? userLat,
}) {
  final copy = [...packs];
  copy.sort((a, b) {
    final da = a.isReady ? 0 : 1;
    final db = b.isReady ? 0 : 1;
    if (da != db) return da - db;
    if (userLng != null && userLat != null) {
      final ra = packDistanceDeg(a, userLng, userLat) ?? 1e9;
      final rb = packDistanceDeg(b, userLng, userLat) ?? 1e9;
      final c = ra.compareTo(rb);
      if (c != 0) return c;
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return copy;
}

String formatPackBytes(int? bytes) {
  if (bytes == null || bytes <= 0) return '';
  if (bytes < 1000000) {
    return '${(bytes / 1000).round()} KB';
  }
  return '${(bytes / 1000000).toStringAsFixed(1)} MB';
}

String offlinePackSubtitle(
  OfflinePackRow r, {
  required bool active,
  required bool installed,
}) {
  if (active) return 'Aktiv — tippen zum Aktualisieren';
  if (installed) return 'Installiert — tippen zum Aktivieren';
  if (!r.isReady) {
    if (r.id == kBundledOfflineGraphRegionId) {
      return 'Demo-Graph in der App (kein Remote-Pack)';
    }
    return 'Envelope ohne Graph — online-only, nichts zum Laden';
  }
  // Graph pack download; Valhalla tiles (if any) are a separate engine path.
  final size = formatPackBytes(r.bytes);
  return size.isEmpty ? 'Graph + Karte laden' : '$size · Graph + Karte';
}

/// Normalize MapLibre offline progress (0–1 or 0–100) to 0–1.
double normalizeOfflineProgress(double p) {
  final n = p > 1 ? p / 100 : p;
  if (n.isNaN || n.isInfinite) return 0;
  return n.clamp(0.0, 1.0);
}

/// Vector-tile zoom cap. z14 on a city bbox is too many OpenFreeMap tiles
/// for a first download; z13 stays usable on the trail.
double maxBasemapZoomForBbox(List<double> bbox) {
  if (bbox.length < 4) return 12;
  final area = (bbox[2] - bbox[0]) * (bbox[3] - bbox[1]);
  if (area > 1.5) return 11;
  if (area > 0.4) return 12;
  return 13;
}

const kBasemapMinZoom = 8.0;

/// True when a graph on disk actually belongs to [regionId].
/// Rejects the bundled Schwarzwald extract copied into a stub folder.
bool packGraphBelongsToRegion({
  required String regionId,
  required int graphBytes,
  String? manifestId,
  String? graphSha256,
}) {
  if (graphBytes < 1000) return false;
  if (manifestId != null &&
      manifestId.isNotEmpty &&
      manifestId != regionId) {
    return false;
  }
  final sha = graphSha256?.toLowerCase();
  if (sha != null &&
      sha.isNotEmpty &&
      sha == kBundledOfflineGraphSha256 &&
      regionId != kBundledOfflineGraphRegionId) {
    return false;
  }
  if (manifestId == regionId) return true;
  // No manifest / no SHA: the bundled graph is ~5.44 MB.
  if (regionId != kBundledOfflineGraphRegionId &&
      graphBytes >= 5200000 &&
      graphBytes <= 5600000) {
    return false;
  }
  return true;
}

enum ExtractedGraphCheck { ok, missing, shaMismatch, bundledMislabel }

ExtractedGraphCheck checkExtractedGraph({
  required String regionId,
  required int graphBytes,
  String? actualSha256,
  String? expectedSha256,
  String? manifestId,
}) {
  if (graphBytes < 1000) return ExtractedGraphCheck.missing;
  if (!packGraphBelongsToRegion(
    regionId: regionId,
    graphBytes: graphBytes,
    manifestId: manifestId,
    graphSha256: actualSha256,
  )) {
    return ExtractedGraphCheck.bundledMislabel;
  }
  if (expectedSha256 != null &&
      expectedSha256.isNotEmpty &&
      actualSha256 != null &&
      actualSha256.toLowerCase() != expectedSha256.toLowerCase()) {
    return ExtractedGraphCheck.shaMismatch;
  }
  return ExtractedGraphCheck.ok;
}

String extractedGraphError(ExtractedGraphCheck check, String name) {
  return switch (check) {
    ExtractedGraphCheck.ok => '',
    ExtractedGraphCheck.missing => 'Kein Graph in $name',
    ExtractedGraphCheck.shaMismatch => 'Graph-SHA von $name stimmt nicht',
    ExtractedGraphCheck.bundledMislabel =>
      'Demo-Graph Schwarzwald passt nicht zu $name',
  };
}

String offlineEngineStatusLine({
  required String valhallaStatus,
  String? engineHint,
}) {
  final s = valhallaStatus.trim();
  final h = engineHint?.trim();
  if (h == null || h.isEmpty) return s;
  if (s.contains(h)) return s;
  return '$s · $h';
}

/// Release copy: graph routing until Valhalla region tiles exist.
String honestOfflineEngineCopy({
  required String valhallaStatus,
  String? engineHint,
}) {
  final tiles = engineHint == 'valhalla' ||
      valhallaStatus.toLowerCase().contains('valhalla-tiles');
  if (tiles) {
    return offlineEngineStatusLine(
      valhallaStatus: valhallaStatus,
      engineHint: engineHint,
    );
  }
  final linked = valhallaStatus.contains('Valhalla-Feature verfügbar') ||
      valhallaStatus.contains('libvalhalla gelinkt') ||
      valhallaStatus.contains('valhalla_linked');
  if (linked) {
    return 'Graph-Engine · Valhalla gelinkt, Region-Tiles fehlen noch';
  }
  return 'Graph-Engine · Valhalla-Tiles nicht gebaut';
}

List<OfflinePackRow> visibleReadyPacks({
  required List<OfflinePackRow> filtered,
  required Set<String> installed,
  required bool searching,
}) {
  if (searching) return filtered;
  return [
    for (final r in filtered)
      if (r.isReady || installed.contains(r.id)) r,
  ];
}

List<OfflinePackRow> visibleStubPacks({
  required List<OfflinePackRow> filtered,
  required Set<String> installed,
  required bool searching,
}) {
  if (searching) return const [];
  return [
    for (final r in filtered)
      if (!r.isReady && !installed.contains(r.id)) r,
  ];
}
