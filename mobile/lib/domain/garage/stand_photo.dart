import 'dart:ui';

/// Stand stage is a wide strip. Crop tall phone photos toward the ground.
const double kStandPhotoRatio = 2.35;
const double kStandPhotoYBias = 0.72;

Rect standPhotoSourceRect(
  double imgW,
  double imgH, {
  double targetRatio = kStandPhotoRatio,
  double yBias = kStandPhotoYBias,
}) {
  if (imgW <= 0 || imgH <= 0) {
    return Rect.fromLTWH(0, 0, imgW < 0 ? 0 : imgW, imgH < 0 ? 0 : imgH);
  }
  final imgRatio = imgW / imgH;
  if (imgRatio >= targetRatio) {
    final sw = imgH * targetRatio;
    return Rect.fromLTWH((imgW - sw) / 2, 0, sw, imgH);
  }
  final sh = imgW / targetRatio;
  final maxSy = imgH - sh;
  final sy = maxSy < 0 ? 0.0 : maxSy * yBias;
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
