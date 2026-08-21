/** https photos cannot be cropped in the browser (CORS). Cover is honest. */
export function standPhotoIsRemote(url?: string | null): boolean {
  if (!url) return false;
  return url.startsWith("https://") || url.startsWith("http://");
}

/** Stand stage is a wide strip. Crop tall phone photos toward the ground. */
export const STAND_PHOTO_RATIO = 2.35;
export const STAND_PHOTO_Y_BIAS = 0.72;

export function standPhotoSourceRect(
  imgW: number,
  imgH: number,
  targetRatio = STAND_PHOTO_RATIO,
  yBias = STAND_PHOTO_Y_BIAS
): { sx: number; sy: number; sw: number; sh: number } {
  if (imgW <= 0 || imgH <= 0) {
    return { sx: 0, sy: 0, sw: Math.max(0, imgW), sh: Math.max(0, imgH) };
  }
  const imgRatio = imgW / imgH;
  if (imgRatio >= targetRatio) {
    const sw = imgH * targetRatio;
    return { sx: (imgW - sw) / 2, sy: 0, sw, sh: imgH };
  }
  const sh = imgW / targetRatio;
  const maxSy = Math.max(0, imgH - sh);
  return { sx: 0, sy: maxSy * yBias, sw: imgW, sh };
}

/** True when the source is not already the stand strip (legacy tall/wide photos). */
export function standPhotoNeedsCrop(
  imgW: number,
  imgH: number,
  epsilon = 0.08
): boolean {
  if (imgW <= 0 || imgH <= 0) return false;
  const r = standPhotoSourceRect(imgW, imgH);
  return r.sw < imgW * (1 - epsilon) || r.sh < imgH * (1 - epsilon);
}
