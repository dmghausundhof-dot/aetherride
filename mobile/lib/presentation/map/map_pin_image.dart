import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/community/map_place.dart';
import '../../domain/routing/tour_filters.dart';

enum MapPinKind {
  /// Legacy disk — privacy zones, HUD fallback.
  circle,

  /// Teardrop map marker with inner jewel.
  drop,

  /// Oval badge with compact FlowLine mountain/wave mark — catalog tours.
  tour,

  /// 3D start pin (green ring + play). Raster PNG, not SDF.
  start,

  /// 3D finish pin (orange ring + flag). Raster PNG, not a checkered square.
  finish,

  /// Numbered via disc (number is MapLibre text).
  via,

  /// Meeting point — diamond.
  meet,

  /// Stimme / tip — speech bubble.
  stimme,

  /// Moving bead on the selected ribbon.
  flow,

  /// Soft ring for meet pulse.
  halo,

  /// Selected-tour POI — cream plate + kind mark, not a bike silhouette.
  poi,
}

/// Compact POI mark inside [MapPinKind.poi]. Not sport/garage glyphs.
enum MapPoiKind {
  place,
  trailhead,
  viewpoint,
  cafe,
  culture,
  water,
  transit,
  meetup,
}

/// 256×320 FlowLine sprites → ~36/42 CSS-px (see scripts/map/render_poi_pins.py).
const kPoiPinSpriteH = 320.0;
const kPoiPinTargetUnselected = 36.0;
const kPoiPinTargetSelected = 42.0;

/// Logical paint size for raster markers. Start/finish export at 2×.
const kMapPinPaintPx = 128.0;
const kMapPinRasterPx = 256.0;

/// MapLibre SDF discs (via / halo) — tinted with icon-color.
const kMapSdfPx = 64.0;
const kMapSdfSpread = 8.0;
const kPlanViaFillHex = '#F4F1EC';
const kPlanViaStrokeHex = '#FF6A00';
const kPlanViaOutStrokeHex = '#7A8B73';
const kPlanHaloTintHex = '#FF8A3D';

double poiStopIconSize({required bool selected}) {
  final targetH = selected ? kPoiPinTargetSelected : kPoiPinTargetUnselected;
  return targetH / kPoiPinSpriteH;
}

/// Start / finish / meet / stimme share the 256×320 sprite sheet.
double routeSpriteIconSize({required bool selected}) =>
    poiStopIconSize(selected: selected);

double destPinPulseIconSize({
  required bool busy,
  required bool pulsing,
  required double t,
}) {
  final targetH = pulsing
      ? kPoiPinTargetUnselected + t * 10
      : (busy ? kPoiPinTargetSelected : kPoiPinTargetUnselected);
  return targetH / kPoiPinSpriteH;
}

double meetPinPulseIconSize(double wave) =>
    (kPoiPinTargetUnselected + 6 * wave) / kPoiPinSpriteH;

/// Catalog tour oval is painted at [kMapPinPaintPx] (128).
double tourPinIconSize({required bool selected, bool atStart = false}) {
  if (atStart) return 0.62;
  return selected ? 0.54 : 0.42;
}

MapPoiKind mapPoiKindFromRaw(String kind) {
  final k = kind.toLowerCase().trim().replaceAll('é', 'e').replaceAll('è', 'e');
  return switch (k) {
    'trailhead' => MapPoiKind.trailhead,
    'viewpoint' || 'aussicht' => MapPoiKind.viewpoint,
    'cafe' => MapPoiKind.cafe,
    'culture' || 'kultur' => MapPoiKind.culture,
    'water' || 'see' => MapPoiKind.water,
    'transit' || 'bahn' => MapPoiKind.transit,
    'meetup' => MapPoiKind.meetup,
    'park' => MapPoiKind.place,
    _ => MapPoiKind.place,
  };
}

/// Coverage café/water/shop → 3D plate. Meet/Stimme keep diamond/bubble.
MapPoiKind? coverageMapPoiKind(MapPlace place) {
  if (place.source == MapPlaceSource.meet ||
      place.source == MapPlaceSource.stimme) {
    return null;
  }
  return switch (place.kind) {
    MapPlaceKind.cafe => MapPoiKind.cafe,
    MapPlaceKind.water => MapPoiKind.water,
    MapPlaceKind.viewpoint => MapPoiKind.viewpoint,
    MapPlaceKind.trailhead => MapPoiKind.trailhead,
    MapPlaceKind.shop || MapPlaceKind.repair => MapPoiKind.place,
    MapPlaceKind.other || MapPlaceKind.tip || MapPlaceKind.meet => null,
  };
}

/// Keep POIs off start/finish and off each other (track fraction 0–1).
const kPoiFracMin = 0.06;
const kPoiFracMax = 0.94;
const kPoiFracGap = 0.05;

bool poiFracFitsAlong(double frac, List<double> placed) {
  if (frac < kPoiFracMin || frac > kPoiFracMax) return false;
  for (final p in placed) {
    if ((frac - p).abs() < kPoiFracGap) return false;
  }
  return true;
}

/// Number-only below zoom 12 — matches web `browsePoiPinText`.
String poiPinLabel({
  required int index,
  required String title,
  required double zoom,
}) {
  if (zoom < 12) return '$index';
  final t = title.trim();
  return t.isEmpty ? '$index' : '$index · $t';
}

String poiPinImageId(MapPoiKind kind) =>
    kind == MapPoiKind.place ? 'aether-poi' : 'aether-poi-${kind.name}';

/// 3D FlowLine sprites from `scripts/map/render_poi_pins.py` (256×320).
String poiPinAssetPath(MapPoiKind kind) {
  final stem = kind == MapPoiKind.place ? 'poi' : 'poi-${kind.name}';
  return 'assets/map/pins/$stem.png';
}

/// Prefers the rendered 3D PNG; canvas [MapPinKind.poi] is the fallback.
Future<Uint8List> loadPoiPinPng(MapPoiKind kind) {
  return buildMapMarkerPng(
    fill: const Color(0xFF2A2E32),
    kind: MapPinKind.poi,
    poiKind: kind,
  );
}

const kViaDiscPx = 256.0;

double viaDiscIconSize({required bool pulse}) =>
    (pulse ? 34.0 : 30.0) / kViaDiscPx;

double viaHandleIconSize() => 18.0 / kViaDiscPx;

String? routePinAssetPath(MapPinKind kind, {bool outside = false}) {
  return switch (kind) {
    MapPinKind.start =>
      outside ? 'assets/map/pins/pin-start-out.png' : 'assets/map/pins/pin-start.png',
    MapPinKind.finish =>
      outside
          ? 'assets/map/pins/pin-finish-out.png'
          : 'assets/map/pins/pin-finish.png',
    MapPinKind.via =>
      outside ? 'assets/map/pins/pin-via-out.png' : 'assets/map/pins/pin-via.png',
    MapPinKind.meet => 'assets/map/pins/pin-meet.png',
    MapPinKind.stimme => 'assets/map/pins/pin-stimme.png',
    _ => null,
  };
}

Future<Uint8List> loadRoutePinPng(
  MapPinKind kind, {
  bool outside = false,
}) {
  return buildMapMarkerPng(
    fill: outside ? AppColors.sage : AppColors.accent,
    kind: kind,
  );
}

/// Inner plate of the tour oval. `mark` = FlowLine peaks; others = bikes/hike.
enum MapPinGlyph {
  mark,
  mtb,
  emtb,
  gravel,
  road,
  urban,
  hike,
  dh,
}

MapPinGlyph mapPinGlyphForSport(TourSportKey sport) => switch (sport) {
      TourSportKey.mtb => MapPinGlyph.mtb,
      TourSportKey.emtb => MapPinGlyph.emtb,
      TourSportKey.gravel => MapPinGlyph.gravel,
      TourSportKey.road => MapPinGlyph.road,
      TourSportKey.urban => MapPinGlyph.urban,
      TourSportKey.hiking => MapPinGlyph.hike,
      TourSportKey.dh => MapPinGlyph.dh,
    };

String tourPinImageId(TourSportKey sport, {required bool selected}) {
  final tag = mapPinGlyphForSport(sport).name;
  return selected ? 'aether-pin-tour-on-$tag' : 'aether-pin-tour-$tag';
}

/// Simple circle pin for MapLibre `addImage` — OpenFreeMap has no `marker-15`.
/// Default fill is cartographic green; orange pins pass [AppColors.accent].
Future<Uint8List> buildMapPinPng({
  Color fill = const Color(0xFF00C853),
  Color stroke = AppColors.hofGround,
}) {
  return buildMapMarkerPng(
    fill: fill,
    stroke: stroke,
    kind: MapPinKind.circle,
  );
}

Future<Uint8List> buildMapMarkerPng({
  required Color fill,
  Color stroke = const Color(0xFFFFFFFF),
  MapPinKind kind = MapPinKind.drop,
  MapPinGlyph glyph = MapPinGlyph.mark,
  MapPoiKind poiKind = MapPoiKind.place,
}) async {
  if (kind == MapPinKind.poi) {
    try {
      final data = await rootBundle.load(poiPinAssetPath(poiKind));
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } on FlutterError {
      // Tests / missing asset — paint the 2D cream plate.
    }
  }
  final routeAsset = routePinAssetPath(
    kind,
    outside: fill == AppColors.sage,
  );
  if (routeAsset != null) {
    try {
      final data = await rootBundle.load(routeAsset);
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } on FlutterError {
      // Tests / missing asset — paint the 2D mark.
    }
  }
  const paintPx = kMapPinPaintPx;
  final hiRes = kind == MapPinKind.start || kind == MapPinKind.finish;
  final outPx = hiRes ? kMapPinRasterPx : paintPx;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  if (hiRes) canvas.scale(outPx / paintPx);
  switch (kind) {
    case MapPinKind.circle:
      _paintCircle(canvas, paintPx, fill, stroke);
    case MapPinKind.drop:
      _paintDrop(canvas, paintPx, fill);
    case MapPinKind.tour:
      _paintTour(canvas, paintPx, fill, glyph);
    case MapPinKind.start:
      _paintStart(canvas, paintPx, fill);
    case MapPinKind.finish:
      _paintFinish(canvas, paintPx, accent: fill);
    case MapPinKind.via:
      _paintVia(canvas, paintPx, fill);
    case MapPinKind.meet:
      _paintMeet(canvas, paintPx, fill);
    case MapPinKind.stimme:
      _paintStimme(canvas, paintPx, fill);
    case MapPinKind.flow:
      _paintFlow(canvas, paintPx, fill);
    case MapPinKind.halo:
      _paintHalo(canvas, paintPx, fill);
    case MapPinKind.poi:
      _paintPoi(canvas, paintPx, fill, poiKind);
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(outPx.toInt(), outPx.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

/// Scale that used to be `iconSize` on a 128-px sprite.
double mapPinRasterIconSize(double sizeOn128) =>
    sizeOn128 * (kMapPinPaintPx / kMapPinRasterPx);

double mapPinSdfIconSize(double sizeOn128) =>
    sizeOn128 * (kMapPinPaintPx / kMapSdfPx);

double mapChevronIconSize(double sizeOn64) => sizeOn64 * 0.5;

/// Raster glow ring — not SDF. Grayscale SDF discs read as a black circle
/// when MapLibre does not tint `icon-color`.
Future<Uint8List> buildHaloRingPng(Color fill) async {
  const size = kMapSdfPx;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final c = Offset(size / 2, size / 2);
  canvas.drawCircle(
    c,
    22,
    Paint()..color = fill.withValues(alpha: 0.18),
  );
  canvas.drawCircle(
    c,
    16.5,
    Paint()
      ..color = fill.withValues(alpha: 0.92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.4,
  );
  canvas.drawCircle(
    c,
    16.5,
    Paint()
      ..color = const Color(0x66FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

Future<Uint8List> _encodeRgbaPng(Uint8List rgba, int size) async {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    rgba,
    size,
    size,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  final image = await completer.future;
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

/// Grayscale SDF for MapLibre `addImage(..., sdf: true)` + icon-color.
Future<Uint8List> buildMapSdfDiscPng({bool ring = false}) async {
  const size = kMapSdfPx;
  const spread = kMapSdfSpread;
  final cx = size / 2;
  final cy = size / 2;
  final radius = ring ? 20.0 : size / 2 - spread - 1;
  final halfStroke = ring ? 3.2 : 0.0;
  final rgba = Uint8List(size.toInt() * size.toInt() * 4);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final dx = x + 0.5 - cx;
      final dy = y + 0.5 - cy;
      final hypot = math.sqrt(dx * dx + dy * dy);
      final dist = ring ? (hypot - radius).abs() - halfStroke : hypot - radius;
      final n = 128 - (dist / spread) * 128;
      final v = n.round().clamp(0, 255);
      final i = (y * size.toInt() + x) * 4;
      rgba[i] = v;
      rgba[i + 1] = v;
      rgba[i + 2] = v;
      // Transparent outside the spread — opaque SDF squares read as black.
      rgba[i + 3] = dist < spread ? 255 : 0;
    }
  }
  return _encodeRgbaPng(rgba, size.toInt());
}

void _paintCircle(Canvas canvas, double size, Color fill, Color stroke) {
  final c = Offset(size / 2, size / 2);
  canvas.drawCircle(c, 28, Paint()..color = fill);
  canvas.drawCircle(
    c,
    28,
    Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5,
  );
}

void _paintDrop(Canvas canvas, double size, Color fill) {
  final cx = size / 2;
  final tip = Offset(cx, size - 8);
  final shadow = Paint()
    ..color = const Color(0x55000000)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  canvas.drawOval(
    Rect.fromCenter(center: tip.translate(0, -3), width: 22, height: 10),
    shadow,
  );
  final body = Path()
    ..moveTo(tip.dx, tip.dy)
    ..cubicTo(18, 78, 20, 28, cx, 16)
    ..cubicTo(size - 20, 28, size - 18, 78, tip.dx, tip.dy)
    ..close();
  canvas.drawPath(
    body.shift(const Offset(0, 1.5)),
    Paint()..color = const Color(0x33000000),
  );
  canvas.drawPath(body, Paint()..color = fill);
  canvas.drawPath(
    body,
    Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeJoin = StrokeJoin.round,
  );
  final hi = Paint()
    ..shader = ui.Gradient.linear(
      Offset(cx - 10, 22),
      Offset(cx + 16, 70),
      [
        Colors.white.withValues(alpha: 0.38),
        Colors.white.withValues(alpha: 0.0),
      ],
    );
  canvas.save();
  canvas.clipPath(body);
  canvas.drawPath(body, hi);
  canvas.restore();
  final jewel = Offset(cx, 42);
  canvas.drawCircle(jewel, 13, Paint()..color = Colors.white);
  canvas.drawCircle(jewel, 7.5, Paint()..color = fill);
  canvas.drawCircle(
    jewel.translate(-2.4, -2.6),
    2.4,
    Paint()..color = Colors.white.withValues(alpha: 0.85),
  );
}

void _paintTour(Canvas canvas, double size, Color fill, MapPinGlyph glyph) {
  canvas.save();
  canvas.translate((size - 64 * (size / 80)) / 2, 0);
  canvas.scale(size / 80);
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(32, 76.8), width: 17, height: 6.4),
    Paint()..color = const Color(0x47000000),
  );
  final body = Path()
    ..moveTo(32, 3)
    ..cubicTo(47, 3, 54, 14, 54, 26)
    ..lineTo(54, 44)
    ..cubicTo(54, 56, 40, 68, 32, 78)
    ..cubicTo(24, 68, 10, 56, 10, 44)
    ..lineTo(10, 26)
    ..cubicTo(10, 14, 17, 3, 32, 3)
    ..close();
  canvas.drawPath(
    body.shift(const Offset(0, 1.2)),
    Paint()..color = const Color(0x33000000),
  );
  canvas.drawPath(body, Paint()..color = fill);
  canvas.save();
  canvas.clipPath(body);
  canvas.drawPath(
    body,
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(18, 6),
        const Offset(46, 52),
        [
          Colors.white.withValues(alpha: 0.32),
          Colors.white.withValues(alpha: 0.0),
        ],
      ),
  );
  canvas.restore();
  canvas.drawPath(
    body,
    Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeJoin = StrokeJoin.round,
  );
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(32, 30), width: 32, height: 34),
    Paint()..color = const Color(0xFFF4F1EC),
  );
  canvas.save();
  canvas.clipPath(
    Path()
      ..addOval(
        Rect.fromCenter(center: const Offset(32, 30), width: 32, height: 34),
      ),
  );
  if (glyph == MapPinGlyph.mark) {
    canvas.translate(18.4, 21.5);
    canvas.scale(0.565);
    _paintCompactFlowlineMark(canvas);
  } else {
    canvas.translate(16.6, 19.6);
    canvas.scale(0.64);
    _paintSportGlyph(canvas, glyph);
  }
  canvas.restore();
  canvas.restore();
}

/// Compact FlowLine mark in 48×26 — same geometry as `assets/map/pins/`.
void _paintCompactFlowlineMark(Canvas canvas) {
  final mass = Path()
    ..moveTo(1.4, 23.6)
    ..lineTo(8, 13.4)
    ..lineTo(11.1, 16.9)
    ..lineTo(16.6, 6.4)
    ..lineTo(21.3, 13.1)
    ..lineTo(28, 1.1)
    ..lineTo(34.3, 11.4)
    ..lineTo(37.9, 6.6)
    ..lineTo(46.6, 23.6)
    ..close();
  canvas.drawPath(mass, Paint()..color = const Color(0xFF3A4046));
  canvas.drawPath(
    Path()
      ..moveTo(8, 13.4)
      ..lineTo(5.4, 18.1)
      ..lineTo(9.6, 18.9)
      ..lineTo(4.1, 22.6)
      ..lineTo(10.6, 17.4)
      ..close(),
    Paint()..color = Colors.white,
  );
  canvas.drawPath(
    Path()
      ..moveTo(16.6, 6.4)
      ..lineTo(13.1, 12.1)
      ..lineTo(17.9, 13.6)
      ..lineTo(12.6, 18.6)
      ..lineTo(18.7, 14.1)
      ..lineTo(21.3, 13.1)
      ..close(),
    Paint()..color = Colors.white,
  );
  canvas.drawPath(
    Path()
      ..moveTo(28, 1.1)
      ..lineTo(24.1, 8.6)
      ..lineTo(21.8, 12.6)
      ..lineTo(25.1, 13.6)
      ..lineTo(20.8, 19.2)
      ..lineTo(26.1, 15.1)
      ..lineTo(28.2, 19.6)
      ..lineTo(30.6, 14.4)
      ..lineTo(33.6, 19.1)
      ..lineTo(34.3, 11.4)
      ..close(),
    Paint()..color = Colors.white,
  );
  canvas.drawPath(
    Path()
      ..moveTo(37.9, 6.6)
      ..lineTo(35.1, 11.6)
      ..lineTo(39.6, 13.1)
      ..lineTo(33.8, 18.2)
      ..lineTo(40.4, 12.1)
      ..close(),
    Paint()..color = Colors.white,
  );
  canvas.drawPath(
    Path()
      ..moveTo(2.4, 21.1)
      ..cubicTo(9.2, 19.4, 15.2, 20.1, 21.6, 19.3)
      ..cubicTo(28.1, 18.5, 34.6, 19.6, 40.6, 20.8)
      ..cubicTo(43.1, 21.4, 45.1, 21.8, 46.6, 22.2)
      ..lineTo(46.6, 24.9)
      ..lineTo(2.4, 24.9)
      ..close(),
    Paint()..color = const Color(0xFFE57532),
  );
  canvas.drawPath(
    Path()
      ..moveTo(6.2, 23.5)
      ..cubicTo(14.1, 22.7, 22.2, 22.5, 30.1, 22.9)
      ..cubicTo(38, 23.3, 43.2, 24.2, 46.2, 24.6)
      ..lineTo(6.2, 24.9)
      ..close(),
    Paint()..color = const Color(0xFF818C7B),
  );
  canvas.drawPath(
    Path()
      ..moveTo(14.2, 24.1)
      ..cubicTo(22.1, 23.3, 30.2, 23.2, 38.1, 23.8)
      ..lineTo(38.1, 25.2)
      ..lineTo(14.2, 25.2)
      ..close(),
    Paint()..color = const Color(0xFF9A9C9B),
  );
}

const _glyphInk = Color(0xFF1A120C);
const _glyphAccent = Color(0xFFFF6A00);
const _glyphPlate = Color(0xFFF4F1EC);

Paint _glyphStrokePaint(Color color, double width) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

void _paintBikeWheels(Canvas canvas, double radius) {
  for (final cx in [10.0, 38.0]) {
    canvas.drawCircle(Offset(cx, 18), radius, Paint()..color = _glyphInk);
    canvas.drawCircle(
      Offset(cx, 18),
      radius * 0.4,
      Paint()..color = _glyphPlate,
    );
  }
}

void _glyphPath(Canvas canvas, List<Offset> pts,
    {Color color = _glyphInk, double width = 3}) {
  if (pts.length < 2) return;
  final path = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (var i = 1; i < pts.length; i++) {
    path.lineTo(pts[i].dx, pts[i].dy);
  }
  canvas.drawPath(path, _glyphStrokePaint(color, width));
}

void _paintMtbFrame(Canvas canvas) {
  _paintBikeWheels(canvas, 7);
  _glyphPath(canvas, const [
    Offset(10, 18),
    Offset(20.2, 18),
    Offset(16.4, 6.4),
    Offset(31.6, 8.2),
    Offset(20.2, 18),
  ]);
  _glyphPath(canvas, const [Offset(16.4, 6.4), Offset(10, 18)]);
  _glyphPath(canvas, const [Offset(31.6, 8.2), Offset(38, 18)]);
  _glyphPath(
    canvas,
    const [Offset(13.4, 6.4), Offset(19.6, 6.4)],
    color: _glyphAccent,
    width: 2.5,
  );
  _glyphPath(canvas, const [
    Offset(31.6, 8.2),
    Offset(31.6, 3.8),
    Offset(41, 3.8),
  ]);
}

void _paintBolt(Canvas canvas) {
  canvas.drawPath(
    Path()
      ..moveTo(28.4, 2.2)
      ..lineTo(21, 13.8)
      ..lineTo(27, 13.8)
      ..lineTo(22.4, 24.4)
      ..lineTo(32.6, 10)
      ..lineTo(26.2, 10)
      ..close(),
    Paint()..color = _glyphAccent,
  );
}

void _paintSportGlyph(Canvas canvas, MapPinGlyph glyph) {
  switch (glyph) {
    case MapPinGlyph.mark:
      _paintCompactFlowlineMark(canvas);
    case MapPinGlyph.hike:
      canvas.drawCircle(
        const Offset(22, 6.2),
        3.5,
        Paint()..color = _glyphInk,
      );
      _glyphPath(canvas, const [Offset(22, 9.8), Offset(22, 16.2)]);
      _glyphPath(canvas, const [Offset(22, 16.2), Offset(16.2, 24.2)]);
      _glyphPath(canvas, const [Offset(22, 16.2), Offset(28.6, 23.4)]);
      _glyphPath(canvas, const [Offset(22, 11.8), Offset(17.6, 16.4)]);
      _glyphPath(
        canvas,
        const [Offset(29.4, 3.2), Offset(24.2, 24.4)],
        color: _glyphAccent,
        width: 2.4,
      );
    case MapPinGlyph.urban:
      _paintBikeWheels(canvas, 6.2);
      _glyphPath(canvas, const [
        Offset(10, 18),
        Offset(19.6, 18),
        Offset(23.2, 10),
        Offset(34.6, 10),
        Offset(38, 18),
      ]);
      _glyphPath(canvas, const [
        Offset(34.6, 10),
        Offset(34.6, 3.6),
        Offset(41, 3.6),
      ]);
      _glyphPath(
        canvas,
        const [Offset(20.8, 10), Offset(26, 10)],
        color: _glyphAccent,
        width: 2.5,
      );
    case MapPinGlyph.road:
      _paintBikeWheels(canvas, 5.05);
      _glyphPath(canvas, const [
        Offset(10, 18),
        Offset(19.4, 18),
        Offset(17, 7.2),
        Offset(32, 8.6),
        Offset(19.4, 18),
      ]);
      _glyphPath(canvas, const [Offset(17, 7.2), Offset(10, 18)]);
      _glyphPath(canvas, const [Offset(32, 8.6), Offset(38, 18)]);
      _glyphPath(
        canvas,
        const [Offset(14.2, 7.2), Offset(19.2, 7.2)],
        color: _glyphAccent,
        width: 2.4,
      );
      canvas.drawPath(
        Path()
          ..moveTo(32, 8.6)
          ..lineTo(32, 4.2)
          ..quadraticBezierTo(26.4, 4, 26.8, 12.2),
        _glyphStrokePaint(_glyphInk, 3),
      );
    case MapPinGlyph.gravel:
      _paintBikeWheels(canvas, 6.15);
      _glyphPath(canvas, const [
        Offset(10, 18),
        Offset(20, 18),
        Offset(16.6, 6.8),
        Offset(31.4, 8.4),
        Offset(20, 18),
      ]);
      _glyphPath(canvas, const [Offset(16.6, 6.8), Offset(10, 18)]);
      _glyphPath(canvas, const [Offset(31.4, 8.4), Offset(38, 18)]);
      _glyphPath(
        canvas,
        const [Offset(13.6, 6.8), Offset(19.4, 6.8)],
        color: _glyphAccent,
        width: 2.5,
      );
      _glyphPath(canvas, const [
        Offset(24.2, 5.6),
        Offset(31.4, 3.4),
        Offset(40.2, 5.6),
      ]);
      _glyphPath(canvas, const [Offset(31.4, 8.4), Offset(31.4, 3.4)]);
    case MapPinGlyph.dh:
      _paintBikeWheels(canvas, 7.1);
      _glyphPath(canvas, const [
        Offset(10, 18),
        Offset(21.2, 18),
        Offset(24.8, 4.2),
        Offset(33.4, 10.2),
        Offset(21.2, 18),
      ]);
      _glyphPath(canvas, const [Offset(24.8, 4.2), Offset(38, 18)]);
      _glyphPath(canvas, const [
        Offset(24.8, 4.2),
        Offset(24.8, 1.8),
        Offset(36.2, 1.8),
      ]);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(26.6, 5.6, 8.4, 4.6),
          const Radius.circular(0.8),
        ),
        Paint()..color = _glyphAccent,
      );
    case MapPinGlyph.mtb:
      _paintMtbFrame(canvas);
    case MapPinGlyph.emtb:
      _paintMtbFrame(canvas);
      _paintBolt(canvas);
  }
}

Future<Uint8List> buildRouteChevronPng() async {
  const paintPx = 64.0;
  const outPx = 128.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.scale(outPx / paintPx);
  const c = Offset(32, 32);
  final path = Path()
    ..moveTo(c.dx, c.dy - 14)
    ..lineTo(c.dx + 12, c.dy + 12)
    ..lineTo(c.dx, c.dy + 6)
    ..lineTo(c.dx - 12, c.dy + 12)
    ..close();
  canvas.drawPath(path, Paint()..color = const Color(0xFFFFFFFF));
  canvas.drawPath(
    path,
    Paint()
      ..color = const Color(0xFF1A120C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeJoin = StrokeJoin.round,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(outPx.toInt(), outPx.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

void _paintStart(Canvas canvas, double size, Color fill) {
  _paintRouteTeardrop(
    canvas,
    size,
    fill: fill,
    inner: (c) {
      final play = Path()
        ..moveTo(c.dx - 7.2, c.dy - 10.4)
        ..lineTo(c.dx - 7.2, c.dy + 10.4)
        ..lineTo(c.dx + 13.6, c.dy)
        ..close();
      canvas.drawPath(play, Paint()..color = const Color(0xFFFF6A00));
    },
  );
}

void _paintFinish(Canvas canvas, double size, {Color? accent}) {
  final rim = accent ?? const Color(0xFFFF6A00);
  _paintRouteTeardrop(
    canvas,
    size,
    fill: rim,
    inner: (c) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(c.dx - 10.2, c.dy - 12, 3.6, 24),
          const Radius.circular(1.4),
        ),
        Paint()..color = const Color(0xFF1A120C),
      );
      final flag = Path()
        ..moveTo(c.dx - 6.6, c.dy - 12)
        ..lineTo(c.dx + 12.4, c.dy - 12)
        ..lineTo(c.dx + 8.4, c.dy - 2.2)
        ..lineTo(c.dx - 6.6, c.dy - 2.2)
        ..close();
      canvas.drawPath(flag, Paint()..color = rim);
    },
  );
}

void _paintRouteTeardrop(
  Canvas canvas,
  double size, {
  required Color fill,
  required void Function(Offset center) inner,
}) {
  canvas.save();
  canvas.translate((size - 64 * (size / 80)) / 2, 0);
  canvas.scale(size / 80);
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(32, 76.8), width: 16.4, height: 6),
    Paint()..color = const Color(0x52000000),
  );
  final body = Path()
    ..moveTo(32, 6)
    ..cubicTo(45, 6, 52, 16, 52, 27)
    ..lineTo(52, 42)
    ..cubicTo(52, 54, 40, 66, 32, 76)
    ..cubicTo(24, 66, 12, 54, 12, 42)
    ..lineTo(12, 27)
    ..cubicTo(12, 16, 19, 6, 32, 6)
    ..close();
  canvas.drawPath(
    body.shift(const Offset(0, 1.2)),
    Paint()..color = const Color(0x33000000),
  );
  canvas.drawPath(body, Paint()..color = fill);
  canvas.drawPath(
    body,
    Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeJoin = StrokeJoin.round,
  );
  const plate = Offset(32, 30);
  canvas.drawOval(
    Rect.fromCenter(center: plate, width: 32.8, height: 32.8),
    Paint()..color = const Color(0xFFF4F1EC),
  );
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(27.4, 25.6), width: 12.8, height: 8.4),
    Paint()..color = const Color(0x6BFFFFFF),
  );
  inner(plate);
  canvas.restore();
}

void _paintVia(Canvas canvas, double size, Color fill) {
  final c = Offset(size / 2, size / 2);
  canvas.drawCircle(c, 32, Paint()..color = const Color(0xFFF4F1EC));
  canvas.drawCircle(
    c,
    32,
    Paint()
      ..color = fill
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.4,
  );
}

void _paintMeet(Canvas canvas, double size, Color fill) {
  final c = Offset(size / 2, size / 2 - 2);
  canvas.drawCircle(
    c,
    36,
    Paint()..color = fill.withValues(alpha: 0.16),
  );
  canvas.save();
  canvas.translate(c.dx, c.dy);
  canvas.rotate(math.pi / 4);
  final outer = RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset.zero, width: 44, height: 44),
    const Radius.circular(10),
  );
  canvas.drawRRect(
    outer.shift(const Offset(1.4, 1.8)),
    Paint()..color = const Color(0x33000000),
  );
  canvas.drawRRect(outer, Paint()..color = Colors.white);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 34, height: 34),
      const Radius.circular(8),
    ),
    Paint()..color = fill,
  );
  canvas.restore();
  void head(Offset o) {
    canvas.drawCircle(o, 5.2, Paint()..color = Colors.white);
    canvas.drawArc(
      Rect.fromCenter(center: o.translate(0, 9.5), width: 12, height: 9),
      math.pi,
      math.pi,
      true,
      Paint()..color = Colors.white,
    );
  }

  head(c.translate(-7.5, -3));
  head(c.translate(7.5, -3));
}

void _paintStimme(Canvas canvas, double size, Color fill) {
  final body = RRect.fromRectAndRadius(
    const Rect.fromLTWH(28, 24, 72, 52),
    const Radius.circular(18),
  );
  final tail = Path()
    ..moveTo(46, 72)
    ..quadraticBezierTo(40, 92, 34, 100)
    ..quadraticBezierTo(52, 84, 62, 72)
    ..close();
  canvas.drawRRect(
    body.shift(const Offset(1.2, 2)),
    Paint()..color = const Color(0x33000000),
  );
  canvas.drawPath(
    tail.shift(const Offset(1.2, 2)),
    Paint()..color = const Color(0x33000000),
  );
  canvas.drawRRect(body, Paint()..color = Colors.white);
  canvas.drawPath(tail, Paint()..color = Colors.white);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(34, 30, 60, 40),
      const Radius.circular(13),
    ),
    Paint()..color = fill,
  );
  final bar = Paint()
    ..color = Colors.white.withValues(alpha: 0.92)
    ..strokeWidth = 3.4
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(const Offset(46, 44), const Offset(82, 44), bar);
  canvas.drawLine(const Offset(46, 54), const Offset(72, 54), bar);
}

void _paintFlow(Canvas canvas, double size, Color fill) {
  final c = Offset(size / 2, size / 2);
  canvas.drawCircle(
    c,
    28,
    Paint()..color = fill.withValues(alpha: 0.18),
  );
  canvas.drawCircle(
    c,
    16,
    Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
  );
  canvas.drawCircle(c, 15, Paint()..color = Colors.white);
  canvas.drawCircle(c, 8.5, Paint()..color = fill);
  canvas.drawCircle(
    c.translate(-2, -2.4),
    2.2,
    Paint()..color = Colors.white.withValues(alpha: 0.8),
  );
}

void _paintHalo(Canvas canvas, double size, Color fill) {
  final c = Offset(size / 2, size / 2);
  canvas.drawCircle(
    c,
    46,
    Paint()
      ..color = fill.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill,
  );
  canvas.drawCircle(
    c,
    34,
    Paint()
      ..color = fill.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5,
  );
}

void _paintPoi(Canvas canvas, double size, Color fill, MapPoiKind kind) {
  canvas.save();
  canvas.translate((size - 64 * (size / 80)) / 2, 0);
  canvas.scale(size / 80);
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(32, 76.8), width: 15, height: 5.6),
    Paint()..color = const Color(0x47000000),
  );
  final body = Path()
    ..moveTo(32, 6)
    ..cubicTo(45, 6, 52, 16, 52, 27)
    ..lineTo(52, 42)
    ..cubicTo(52, 54, 40, 66, 32, 76)
    ..cubicTo(24, 66, 12, 54, 12, 42)
    ..lineTo(12, 27)
    ..cubicTo(12, 16, 19, 6, 32, 6)
    ..close();
  canvas.drawPath(
    body.shift(const Offset(0, 1.2)),
    Paint()..color = const Color(0x33000000),
  );
  canvas.drawPath(body, Paint()..color = fill);
  canvas.drawPath(
    body,
    Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeJoin = StrokeJoin.round,
  );
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(32, 30), width: 32.8, height: 32.8),
    Paint()..color = _glyphPlate,
  );
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(27.4, 25.6), width: 12.8, height: 8.4),
    Paint()..color = const Color(0x6BFFFFFF),
  );
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(32, 30), width: 32.8, height: 32.8),
    Paint()
      ..color = _glyphAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2,
  );
  canvas.save();
  canvas.translate(32, 30);
  _paintPoiKindMark(canvas, kind);
  canvas.restore();
  canvas.restore();
}

void _paintPoiKindMark(Canvas canvas, MapPoiKind kind) {
  final ink = Paint()..color = _glyphInk;
  final accent = Paint()..color = _glyphAccent;
  switch (kind) {
    case MapPoiKind.trailhead:
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-10, -11, 4, 22),
          const Radius.circular(1.4),
        ),
        ink,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-6, -11, 16.5, 10.5),
          const Radius.circular(1.8),
        ),
        accent,
      );
    case MapPoiKind.viewpoint:
      canvas.drawPath(
        Path()
          ..moveTo(-11, 8)
          ..lineTo(-4.2, -2.4)
          ..lineTo(1.2, 4.4)
          ..lineTo(6.4, -8)
          ..lineTo(11, 8)
          ..close(),
        ink,
      );
      canvas.drawCircle(const Offset(6.4, -9.2), 3, accent);
    case MapPoiKind.cafe:
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-9.2, -5.6, 15, 14),
          const Radius.circular(3),
        ),
        ink,
      );
      canvas.drawPath(
        Path()
          ..moveTo(5.6, -2.4)
          ..cubicTo(11.2, -2.4, 11.2, 7.2, 5.6, 7.2),
        _glyphStrokePaint(_glyphInk, 3.6),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-6.4, -8.2, 9.2, 2.6),
          const Radius.circular(1),
        ),
        accent,
      );
    case MapPoiKind.culture:
      canvas.drawRect(const Rect.fromLTWH(-11, 5.8, 22, 4), ink);
      canvas.drawRect(const Rect.fromLTWH(-10, -6.8, 5.2, 13.4), ink);
      canvas.drawRect(const Rect.fromLTWH(-2.6, -6.8, 5.2, 13.4), ink);
      canvas.drawRect(const Rect.fromLTWH(4.8, -6.8, 5.2, 13.4), ink);
      canvas.drawRect(const Rect.fromLTWH(-11.2, -11.2, 22.4, 4.4), accent);
    case MapPoiKind.water:
      canvas.drawPath(
        Path()
          ..moveTo(0, -10.4)
          ..cubicTo(8.2, -1.2, 9.2, 4.6, 0, 10.4)
          ..cubicTo(-9.2, 4.6, -8.2, -1.2, 0, -10.4)
          ..close(),
        ink,
      );
      canvas.drawCircle(const Offset(-1.8, 1.2), 2.6, accent);
    case MapPoiKind.transit:
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-10, -6.8, 20, 12.4),
          const Radius.circular(3.4),
        ),
        ink,
      );
      canvas.drawCircle(const Offset(-4.6, 8), 2.8, ink);
      canvas.drawCircle(const Offset(4.6, 8), 2.8, ink);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-6.6, -3.6, 6.2, 4.6),
          const Radius.circular(0.8),
        ),
        accent,
      );
    case MapPoiKind.meetup:
      canvas.drawCircle(const Offset(-5.4, -3.2), 4.8, ink);
      canvas.drawCircle(const Offset(5.4, -3.2), 4.8, ink);
      canvas.drawCircle(const Offset(0, 5.6), 3.6, accent);
    case MapPoiKind.place:
      canvas.drawCircle(Offset.zero, 7.2, ink);
      canvas.drawCircle(Offset.zero, 3.6, accent);
  }
}

/// Same start / finish / via mark as the map, scaled to a list-row disc.
class MapPinBadge extends StatelessWidget {
  const MapPinBadge({
    super.key,
    required this.kind,
    this.fill,
    this.size = 28,
    this.label,
  });

  final MapPinKind kind;
  final Color? fill;
  final double size;
  final String? label;

  Color get _fill =>
      fill ??
      (kind == MapPinKind.start ? const Color(0xFF2E7D32) : AppColors.accent);

  @override
  Widget build(BuildContext context) {
    final asset = routePinAssetPath(kind, outside: fill == AppColors.sage);
    final fallback = CustomPaint(
      size: Size.square(size),
      painter: MapPinBadgePainter(kind: kind, fill: _fill),
    );
    final mark = asset == null
        ? fallback
        : Image.asset(
            asset,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => fallback,
          );
    final text = label?.trim() ?? '';
    return SizedBox(
      width: size,
      height: size,
      child: text.isEmpty
          ? mark
          : Stack(
              alignment: Alignment.center,
              children: [
                mark,
                Text(
                  text,
                  style: TextStyle(
                    fontSize: size * 0.36,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1F1F1F),
                    height: 1,
                  ),
                ),
              ],
            ),
    );
  }
}

class MapPinBadgePainter extends CustomPainter {
  MapPinBadgePainter({
    required this.kind,
    required this.fill,
  });

  final MapPinKind kind;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.save();
    canvas.scale(size.width / 128, size.height / 128);
    switch (kind) {
      case MapPinKind.start:
        _paintStart(canvas, 128, fill);
      case MapPinKind.finish:
        _paintFinish(canvas, 128, accent: fill);
      case MapPinKind.via:
        _paintVia(canvas, 128, fill);
      default:
        _paintCircle(canvas, 128, fill, Colors.white);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MapPinBadgePainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.fill != fill;
}
