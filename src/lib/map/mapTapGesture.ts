/** Keep in sync with tour_nav_geometry map-tap quiet windows. */

export const MAP_TAP_AFTER_CAMERA_MS = 280;

export function mapClickAfterCameraGesture(
  nowMs: number,
  suppressUntilMs: number
): boolean {
  return nowMs < suppressUntilMs;
}
