import 'dart:ui';

/// Stand stage matches the schema paper (1000×500). Crop to this, then
/// `cover` in a 2:1 frame does not cut a second time.
const double kStandPhotoRatio = 2.0;
const double kStandPhotoYBias = 0.72;
const double kStandPhotoXBias = 0.5;

class StandPhotoPan {
  const StandPhotoPan({
    this.yBias = kStandPhotoYBias,
    this.xBias = kStandPhotoXBias,
  });

  final double yBias;
  final double xBias;
}

Rect standPhotoSourceRect(
  double imgW,
  double imgH, {
  double targetRatio = kStandPhotoRatio,
  double yBias = kStandPhotoYBias,
  double xBias = kStandPhotoXBias,
}) {
  if (imgW <= 0 || imgH <= 0) {
    return Rect.fromLTWH(0, 0, imgW < 0 ? 0 : imgW, imgH < 0 ? 0 : imgH);
  }
  final imgRatio = imgW / imgH;
  if (imgRatio >= targetRatio) {
    final sw = imgH * targetRatio;
    final maxSx = imgW - sw;
    final sx = maxSx < 0 ? 0.0 : maxSx * xBias.clamp(0.0, 1.0);
    return Rect.fromLTWH(sx, 0, sw, imgH);
  }
  final sh = imgW / targetRatio;
  final maxSy = imgH - sh;
  final sy = maxSy < 0 ? 0.0 : maxSy * yBias.clamp(0.0, 1.0);
  return Rect.fromLTWH(0, sy, imgW, sh);
}

/// True when the source is not already the stand strip (legacy tall/wide photos).
bool standPhotoNeedsCrop(
  double imgW,
  double imgH, {
  double epsilon = 0.08,
}) {
  if (imgW <= 0 || imgH <= 0) return false;
  final r = standPhotoSourceRect(imgW, imgH);
  return r.width < imgW * (1 - epsilon) || r.height < imgH * (1 - epsilon);
}
