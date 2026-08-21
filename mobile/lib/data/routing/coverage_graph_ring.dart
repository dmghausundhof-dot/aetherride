import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

/// Cached next to `offline_graph.json` so Explore does not reparse 18 MB.
const kCoverageRingFileName = 'coverage_ring.json';

/// Bump when the occupancy grid or smoothing changes so old rings rebuild.
const kCoverageRingCacheVersion = 5;

/// 128-cell wash; two dilates keep the same geographic pad.
const kCoverageRingCells = 128;
const kCoverageRingDilate = 2;
const kCoverageSketchDotCap = 96;
const kCoverageSketchTraceCap = 48;

/// Occupancy outline, or a filled extract that should keep the chamfered bbox.
class CoverageRingCache {
  const CoverageRingCache({
    required this.solid,
    required this.ring,
    this.dots = const [],
    this.traces = const [],
  });

  final bool solid;
  final List<List<double>> ring;

  /// Downsampled graph nodes for the sheet sketch — not fake relief.
  final List<List<double>> dots;

  /// Downsampled graph edges `[lng0, lat0, lng1, lat1]` — still not DEM.
  final List<List<double>> traces;

  List<List<double>>? get outline => solid || ring.length < 5 ? null : ring;
}

/// Evenly spaced nodes so the 88 px sketch shows the trail cloud.
List<List<double>> coverageSketchDots(
  List<List<double>> lngLat, {
  int cap = kCoverageSketchDotCap,
}) {
  if (lngLat.isEmpty || cap < 1) return const [];
  if (lngLat.length <= cap) {
    return [
      for (final p in lngLat)
        if (p.length >= 2) [p[0], p[1]],
    ];
  }
  final step = lngLat.length / cap;
  final out = <List<double>>[];
  for (var i = 0; i < cap; i++) {
    final p = lngLat[(i * step).floor().clamp(0, lngLat.length - 1)];
    if (p.length >= 2) out.add([p[0], p[1]]);
  }
  return out;
}

List<List<double>> coverageTraceListFromJson(dynamic raw) {
  if (raw is! List) return const [];
  final out = <List<double>>[];
  for (final p in raw) {
    if (p is! List || p.length < 4) continue;
    final a = p[0];
    final b = p[1];
    final c = p[2];
    final d = p[3];
    if (a is num && b is num && c is num && d is num) {
      out.add([a.toDouble(), b.toDouble(), c.toDouble(), d.toDouble()]);
    }
  }
  return out;
}

/// Evenly spaced graph edges so the 88 px sketch shows trails, not a blob.
List<List<double>> coverageSketchTracesFromGraphJson(
  dynamic decoded, {
  int cap = kCoverageSketchTraceCap,
}) {
  if (decoded is! Map || cap < 1) return const [];
  final nodes = decoded['nodes'];
  final edges = decoded['edges'];
  if (nodes is! List || edges is! List || edges.isEmpty) return const [];
  final byId = <String, List<double>>{};
  for (final n in nodes) {
    if (n is! Map) continue;
    final id = '${n['id'] ?? ''}';
    final lng = n['lng'];
    final lat = n['lat'];
    if (id.isEmpty || lng is! num || lat is! num) continue;
    byId[id] = [lng.toDouble(), lat.toDouble()];
  }
  if (byId.isEmpty) return const [];
  final step = edges.length <= cap
      ? 1
      : (edges.length / cap).ceil().clamp(1, edges.length);
  final out = <List<double>>[];
  for (var i = 0; i < edges.length && out.length < cap; i += step) {
    final e = edges[i];
    if (e is! Map) continue;
    final from = byId['${e['from'] ?? e['a'] ?? ''}'];
    final to = byId['${e['to'] ?? e['b'] ?? ''}'];
    if (from == null || to == null) continue;
    out.add([from[0], from[1], to[0], to[1]]);
  }
  return out;
}

bool _sameLngLat(List<double> a, List<double> b) =>
    a.length >= 2 &&
    b.length >= 2 &&
    (a[0] - b[0]).abs() < 1e-12 &&
    (a[1] - b[1]).abs() < 1e-12;

List<List<double>> coverageLngLatListFromJson(dynamic raw) {
  if (raw is! List) return const [];
  final out = <List<double>>[];
  for (final p in raw) {
    if (p is! List || p.length < 2) continue;
    final lng = p[0];
    final lat = p[1];
    if (lng is num && lat is num) {
      out.add([lng.toDouble(), lat.toDouble()]);
    }
  }
  return out;
}

List<double> coverageBboxOfRing(List<List<double>> ring) {
  var west = double.infinity;
  var south = double.infinity;
  var east = -double.infinity;
  var north = -double.infinity;
  for (final p in ring) {
    if (p.length < 2) continue;
    west = math.min(west, p[0]);
    south = math.min(south, p[1]);
    east = math.max(east, p[0]);
    north = math.max(north, p[1]);
  }
  if (!west.isFinite) return const [];
  return [west, south, east, north];
}

List<List<double>> coverageClosedRing(List<List<double>> ring) {
  if (ring.length < 3) return const [];
  if (_sameLngLat(ring.first, ring.last)) {
    return [for (final p in ring) List<double>.from(p)];
  }
  return [
    for (final p in ring) List<double>.from(p),
    List<double>.from(ring.first),
  ];
}

/// Ray-cast. [ring] may be open or closed.
bool coveragePointInRing({
  required double lng,
  required double lat,
  required List<List<double>> ring,
}) {
  if (ring.length < 3) return false;
  final closed = ring.length >= 4 && _sameLngLat(ring.first, ring.last);
  final n = closed ? ring.length - 1 : ring.length;
  if (n < 3) return false;
  var inside = false;
  var j = n - 1;
  for (var i = 0; i < n; i++) {
    final yi = ring[i][1];
    final yj = ring[j][1];
    final xi = ring[i][0];
    final xj = ring[j][0];
    final intersect = ((yi > lat) != (yj > lat)) &&
        (lng < (xj - xi) * (lat - yi) / ((yj - yi) + 1e-18) + xi);
    if (intersect) inside = !inside;
    j = i;
  }
  return inside;
}

List<List<double>> coverageNodesFromGraphJson(dynamic decoded) {
  if (decoded is! Map) return const [];
  final nodes = decoded['nodes'];
  if (nodes is! List) return const [];
  final out = <List<double>>[];
  for (final n in nodes) {
    if (n is! Map) continue;
    final lng = n['lng'];
    final lat = n['lat'];
    if (lng is num && lat is num) {
      out.add([lng.toDouble(), lat.toDouble()]);
    }
  }
  return out;
}

List<double>? coverageBboxFromGraphJson(dynamic decoded) {
  if (decoded is! Map) return null;
  final b = decoded['bbox'];
  if (b is! List || b.length < 4) return null;
  final out = <double>[
    for (final x in b.take(4))
      if (x is num) x.toDouble(),
  ];
  return out.length >= 4 ? out : null;
}

/// Occupied-cell outline of graph nodes. [solid] when the extract fills the
/// bbox — caller keeps the chamfered plate.
CoverageRingCache coverageOccupancy({
  required List<List<double>> lngLat,
  List<double>? bbox,
  int cells = kCoverageRingCells,
  int dilate = kCoverageRingDilate,
  double solidFrac = 0.94,
}) {
  if (lngLat.length < 8 || cells < 8) {
    return CoverageRingCache(
      solid: false,
      ring: const [],
      dots: coverageSketchDots(lngLat),
    );
  }
  var box = bbox;
  if (box == null || box.length < 4) {
    box = coverageBboxOfRing(lngLat);
  }
  if (box.length < 4) {
    return CoverageRingCache(
      solid: false,
      ring: const [],
      dots: coverageSketchDots(lngLat),
    );
  }
  final west = box[0];
  final south = box[1];
  final east = box[2];
  final north = box[3];
  final spanLng = east - west;
  final spanLat = north - south;
  if (!(spanLng > 1e-8) || !(spanLat > 1e-8)) {
    return CoverageRingCache(
      solid: false,
      ring: const [],
      dots: coverageSketchDots(lngLat),
    );
  }

  final occ = List<List<bool>>.generate(
    cells,
    (_) => List<bool>.filled(cells, false),
  );
  for (final p in lngLat) {
    if (p.length < 2) continue;
    var c = ((p[0] - west) / spanLng * cells).floor();
    var r = ((p[1] - south) / spanLat * cells).floor();
    c = c.clamp(0, cells - 1);
    r = r.clamp(0, cells - 1);
    occ[r][c] = true;
  }
  for (var d = 0; d < dilate; d++) {
    final next = List<List<bool>>.generate(
      cells,
      (r) => List<bool>.from(occ[r]),
    );
    for (var r = 0; r < cells; r++) {
      for (var c = 0; c < cells; c++) {
        if (!occ[r][c]) continue;
        for (var dr = -1; dr <= 1; dr++) {
          for (var dc = -1; dc <= 1; dc++) {
            final rr = r + dr;
            final cc = c + dc;
            if (rr < 0 || cc < 0 || rr >= cells || cc >= cells) continue;
            next[rr][cc] = true;
          }
        }
      }
    }
    for (var r = 0; r < cells; r++) {
      occ[r] = next[r];
    }
  }
  var filled = 0;
  for (final row in occ) {
    for (final v in row) {
      if (v) filled++;
    }
  }
  if (filled < 6) {
    return CoverageRingCache(
      solid: false,
      ring: const [],
      dots: coverageSketchDots(lngLat),
    );
  }
  if (filled / (cells * cells) >= solidFrac) {
    return CoverageRingCache(
      solid: true,
      ring: const [],
      dots: coverageSketchDots(lngLat),
    );
  }

  final adj = <String, List<String>>{};
  void add(int x0, int y0, int x1, int y1) {
    final a = '$x0,$y0';
    final b = '$x1,$y1';
    (adj[a] ??= []).add(b);
    (adj[b] ??= []).add(a);
  }

  bool occupied(int r, int c) {
    if (r < 0 || c < 0 || r >= cells || c >= cells) return false;
    return occ[r][c];
  }

  for (var r = 0; r < cells; r++) {
    for (var c = 0; c < cells; c++) {
      if (!occ[r][c]) continue;
      if (!occupied(r, c - 1)) add(c, r, c, r + 1);
      if (!occupied(r, c + 1)) add(c + 1, r, c + 1, r + 1);
      if (!occupied(r - 1, c)) add(c, r, c + 1, r);
      if (!occupied(r + 1, c)) add(c, r + 1, c + 1, r + 1);
    }
  }
  if (adj.isEmpty) {
    return CoverageRingCache(
      solid: false,
      ring: const [],
      dots: coverageSketchDots(lngLat),
    );
  }

  String edgeKey(String a, String b) => a.compareTo(b) < 0 ? '$a|$b' : '$b|$a';

  List<String>? walk(String start, String first) {
    final used = <String>{};
    final path = <String>[start];
    var cur = start;
    var nxt = first;
    used.add(edgeKey(cur, nxt));
    path.add(nxt);
    while (true) {
      final nbs = adj[nxt] ?? const <String>[];
      String? pick;
      for (final n in nbs) {
        if (n == cur) continue;
        if (used.contains(edgeKey(nxt, n))) continue;
        pick = n;
        break;
      }
      if (pick == null) {
        return path.first == path.last && path.length >= 4 ? path : null;
      }
      used.add(edgeKey(nxt, pick));
      cur = nxt;
      nxt = pick;
      path.add(nxt);
      if (nxt == start) return path;
      if (path.length > cells * cells * 4) return null;
    }
  }

  List<String> best = const [];
  final tried = <String>{};
  for (final start in adj.keys) {
    for (final nb in adj[start] ?? const <String>[]) {
      final k = edgeKey(start, nb);
      if (!tried.add(k)) continue;
      final path = walk(start, nb);
      if (path != null && path.length > best.length) best = path;
    }
  }
  if (best.length < 5) {
    return CoverageRingCache(
      solid: false,
      ring: const [],
      dots: coverageSketchDots(lngLat),
    );
  }

  List<double> toLngLat(String key) {
    final parts = key.split(',');
    final x = int.parse(parts[0]);
    final y = int.parse(parts[1]);
    return [
      west + x / cells * spanLng,
      south + y / cells * spanLat,
    ];
  }

  final ring = [for (final k in best) toLngLat(k)];
  final cell = math.max(spanLng, spanLat) / cells;
  final simplified = coverageSimplifyClosedRing(ring, cell * 0.35);
  final smooth = coverageChaikinClosedRing(simplified, iterations: 3);
  return CoverageRingCache(
    solid: false,
    ring: coverageSimplifyClosedRing(smooth, cell * 0.12),
    dots: coverageSketchDots(lngLat),
  );
}

/// Occupied-cell outline. Empty when the extract is a filled rectangle.
List<List<double>> coverageOccupancyRing({
  required List<List<double>> lngLat,
  List<double>? bbox,
  int cells = kCoverageRingCells,
  int dilate = kCoverageRingDilate,
  double solidFrac = 0.94,
}) {
  return coverageOccupancy(
        lngLat: lngLat,
        bbox: bbox,
        cells: cells,
        dilate: dilate,
        solidFrac: solidFrac,
      ).outline ??
      const [];
}

List<List<double>> coverageSimplifyClosedRing(
  List<List<double>> ring,
  double eps,
) {
  if (ring.length < 5 || !(eps > 0)) return coverageClosedRing(ring);
  final pts = [
    for (final p in ring) List<double>.from(p),
  ];
  if (_sameLngLat(pts.first, pts.last)) pts.removeLast();
  if (pts.length < 3) return coverageClosedRing(ring);

  List<List<double>> dp(int a, int b) {
    var maxD = -1.0;
    var idx = -1;
    final ax = pts[a][0];
    final ay = pts[a][1];
    final dx = pts[b][0] - ax;
    final dy = pts[b][1] - ay;
    final den = dx * dx + dy * dy;
    for (var i = a + 1; i < b; i++) {
      final d = den < 1e-18
          ? math.sqrt(
              math.pow(pts[i][0] - ax, 2) + math.pow(pts[i][1] - ay, 2),
            )
          : ((pts[i][0] - ax) * dy - (pts[i][1] - ay) * dx).abs() /
              math.sqrt(den);
      if (d > maxD) {
        maxD = d;
        idx = i;
      }
    }
    if (maxD > eps && idx > a) {
      return [...dp(a, idx), ...dp(idx, b).skip(1)];
    }
    return [pts[a], pts[b]];
  }

  final simplified = dp(0, pts.length - 1);
  if (simplified.length < 4) return coverageClosedRing(ring);
  return coverageClosedRing(simplified);
}

/// Two Chaikin cuts — raster stairs become a rideable outline.
List<List<double>> coverageChaikinClosedRing(
  List<List<double>> ring, {
  int iterations = 2,
}) {
  if (ring.length < 4 || iterations < 1) return coverageClosedRing(ring);
  var pts = [
    for (final p in ring) List<double>.from(p),
  ];
  if (_sameLngLat(pts.first, pts.last)) pts.removeLast();
  if (pts.length < 3) return coverageClosedRing(ring);
  for (var n = 0; n < iterations; n++) {
    final next = <List<double>>[];
    for (var i = 0; i < pts.length; i++) {
      final a = pts[i];
      final b = pts[(i + 1) % pts.length];
      next.add([
        0.75 * a[0] + 0.25 * b[0],
        0.75 * a[1] + 0.25 * b[1],
      ]);
      next.add([
        0.25 * a[0] + 0.75 * b[0],
        0.25 * a[1] + 0.75 * b[1],
      ]);
    }
    pts = next;
  }
  return coverageClosedRing(pts);
}

/// Isolate payload: maps and lists of doubles, not a custom class.
Map<String, Object?> coverageRingEvaluateGraphFile(String path) {
  final file = File(path);
  if (!file.existsSync()) return <String, Object?>{'ok': false};
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    final pts = coverageNodesFromGraphJson(decoded);
    final traces = coverageSketchTracesFromGraphJson(decoded);
    final occ = coverageOccupancy(
      lngLat: pts,
      bbox: coverageBboxFromGraphJson(decoded),
    );
    return <String, Object?>{
      'ok': true,
      'solid': occ.solid,
      'ring': occ.ring,
      'dots': occ.dots,
      'traces': traces,
    };
  } catch (_) {
    return <String, Object?>{'ok': false};
  }
}

CoverageRingCache? coverageRingCacheFromPayload(Map payload) {
  if (payload['ok'] != true) return null;
  final solid = payload['solid'] == true;
  final ring = coverageLngLatListFromJson(payload['ring']);
  final dots = coverageLngLatListFromJson(payload['dots']);
  final traces = coverageTraceListFromJson(payload['traces']);
  if (solid) {
    return CoverageRingCache(
      solid: true,
      ring: coverageClosedRing(ring),
      dots: dots,
      traces: traces,
    );
  }
  if (ring.length < 5) return null;
  return CoverageRingCache(
    solid: false,
    ring: coverageClosedRing(ring),
    dots: dots,
    traces: traces,
  );
}

/// Parse nodes from a graph file and build the occupancy ring.
List<List<double>> coverageRingFromGraphFile(String path) {
  return coverageRingCacheFromPayload(coverageRingEvaluateGraphFile(path))
          ?.outline ??
      const [];
}

CoverageRingCache? coverageRingFromCacheJson(
  String raw, {
  required int graphBytes,
}) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final version = decoded['v'];
    if (version is! num || version.toInt() != kCoverageRingCacheVersion) {
      return null;
    }
    final cells = decoded['cells'];
    if (cells is num && cells.toInt() != kCoverageRingCells) return null;
    final bytes = decoded['graphBytes'];
    if (bytes is! num || bytes.toInt() != graphBytes) return null;
    final solid = decoded['solid'] == true;
    final out = coverageLngLatListFromJson(decoded['ring']);
    final dots = coverageLngLatListFromJson(decoded['dots']);
    final traces = coverageTraceListFromJson(decoded['traces']);
    if (solid) {
      return CoverageRingCache(
        solid: true,
        ring: coverageClosedRing(out),
        dots: dots,
        traces: traces,
      );
    }
    return out.length >= 5
        ? CoverageRingCache(
            solid: false,
            ring: coverageClosedRing(out),
            dots: dots,
            traces: traces,
          )
        : null;
  } catch (_) {
    return null;
  }
}

String coverageRingCacheJson({
  required List<List<double>> ring,
  required int graphBytes,
  bool solid = false,
  List<List<double>> dots = const [],
  List<List<double>> traces = const [],
}) {
  return jsonEncode({
    'v': kCoverageRingCacheVersion,
    'cells': kCoverageRingCells,
    'graphBytes': graphBytes,
    'solid': solid,
    'ring': ring,
    'dots': dots,
    'traces': traces,
  });
}
