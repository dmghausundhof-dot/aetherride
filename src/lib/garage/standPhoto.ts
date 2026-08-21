/** https photos cannot be cropped in the browser (CORS). Cover is honest. */
export function standPhotoIsRemote(url?: string | null): boolean {
  if (!url) return false;
  return url.startsWith("https://") || url.startsWith("http://");
}

/** Stand stage matches the schema paper (1000×500). */
export const STAND_PHOTO_RATIO = 2;
export const STAND_PHOTO_Y_BIAS = 0.72;
export const STAND_PHOTO_X_BIAS = 0.5;

export type StandPhotoPan = { xBias: number; yBias: number };

export function standPhotoSourceRect(
  imgW: number,
  imgH: number,
  targetRatio = STAND_PHOTO_RATIO,
  yBias = STAND_PHOTO_Y_BIAS,
  xBias = STAND_PHOTO_X_BIAS
): { sx: number; sy: number; sw: number; sh: number } {
  if (imgW <= 0 || imgH <= 0) {
    return { sx: 0, sy: 0, sw: Math.max(0, imgW), sh: Math.max(0, imgH) };
  }
  const imgRatio = imgW / imgH;
  const xb = Math.min(1, Math.max(0, xBias));
  const yb = Math.min(1, Math.max(0, yBias));
  if (imgRatio >= targetRatio) {
    const sw = imgH * targetRatio;
    return { sx: Math.max(0, imgW - sw) * xb, sy: 0, sw, sh: imgH };
  }
  const sh = imgW / targetRatio;
  const maxSy = Math.max(0, imgH - sh);
  return { sx: 0, sy: maxSy * yb, sw: imgW, sh };
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

export function standPhotoObjectPosition(
  yBias = STAND_PHOTO_Y_BIAS,
  xBias = STAND_PHOTO_X_BIAS
): string {
  return `${Math.round(xBias * 100)}% ${Math.round(yBias * 100)}%`;
}
