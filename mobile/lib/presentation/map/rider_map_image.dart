import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

const kRiderLiveAsset = 'assets/community/rider/rider-live.png';
const kRiderStaleAsset = 'assets/community/rider/rider-stale.png';
const kRiderGlbAsset = 'assets/community/rider/rider.glb';

const kRiderNavImageId = 'aether-rider-nav';
const kRiderTourLiveImageId = 'aether-rider-tour-live';
const kRiderTourStaleImageId = 'aether-rider-tour-stale';
const kRiderFlowImageId = 'aether-rider-flow';

/// MapLibre `iconSize` — 128-px-Bild, zugeschnitten.
abstract final class RiderMapIconSize {
  static const nav = 0.94;
  /// Klassischer Pfeil — bewusst kleiner als der 3D-Fahrer.
  static const navClassic = 0.80;
  static const tourSelected = 0.70;
  static const tourIdle = 0.50;
  static const tourStart = 0.74;
  static const flow = 0.40;
  static const flowBead = 0.28;
  static const friend = 0.62;
}

final Map<String, Uint8List> _pngCache = {};
ui.Image? _liveImage;
ui.Image? _staleImage;

Future<ui.Image> decodeRiderAsset({required bool live}) async {
  final cached = live ? _liveImage : _staleImage;
  if (cached != null) return cached;
  final data = await rootBundle.load(live ? kRiderLiveAsset : kRiderStaleAsset);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  if (live) {
    _liveImage = frame.image;
  } else {
    _staleImage = frame.image;
  }
  return frame.image;
}

/// 3D-Fahrer, auf die opake Silhouette zugeschnitten, in ein Quadrat skaliert.
Future<Uint8List> buildRiderMapPng({
  required bool live,
  int pixelSize = 128,
}) async {
  final key = '${live ? 'live' : 'stale'}_$pixelSize';
  final hit = _pngCache[key];
  if (hit != null) return hit;
  final src = await decodeRiderAsset(live: live);
  final box = await _alphaBounds(src) ??
      Rect.fromLTWH(0, 0, src.width.toDouble(), src.height.toDouble());
  final pad = math.max(box.width, box.height) * 0.07;
  final crop = Rect.fromLTRB(
    (box.left - pad).clamp(0, src.width.toDouble()),
    (box.top - pad).clamp(0, src.height.toDouble()),
    (box.right + pad).clamp(0, src.width.toDouble()),
    (box.bottom + pad).clamp(0, src.height.toDouble()),
  );
  final side = pixelSize.toDouble();
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final fitted = _fitContain(crop.size, Size(side, side));
  canvas.drawImageRect(
    src,
    crop,
    fitted,
    ui.Paint()..filterQuality = ui.FilterQuality.high,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(pixelSize, pixelSize);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final out = bytes!.buffer.asUint8List();
  _pngCache[key] = out;
  return out;
}

Rect _fitContain(Size src, Size dst) {
  final scale = math.min(dst.width / src.width, dst.height / src.height);
  final w = src.width * scale;
  final h = src.height * scale;
  return Rect.fromLTWH((dst.width - w) / 2, (dst.height - h) / 2, w, h);
}

Future<Rect?> _alphaBounds(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) return null;
  final bytes = data.buffer.asUint8List();
  final w = image.width;
  final h = image.height;
  var minX = w;
  var minY = h;
  var maxX = 0;
  var maxY = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final a = bytes[(y * w + x) * 4 + 3];
      if (a < 18) continue;
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
  }
  if (maxX < minX || maxY < minY) return null;
  return Rect.fromLTRB(
    minX.toDouble(),
    minY.toDouble(),
    (maxX + 1).toDouble(),
    (maxY + 1).toDouble(),
  );
}
