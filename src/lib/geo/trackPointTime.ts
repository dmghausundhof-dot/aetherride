/**
 * Uhrzeit eines Trackpunkts.
 * Native Stamps sind Epoch-ms; ältere Web-Punkte oft Sekunden ab Start.
 * Kleine Zahlen bleiben Offsets — nie als absolute Uhr missverstehen.
 */

export function trackPointEpochMs(
  time: number | undefined,
  startMs: number,
  index: number,
  durationSec: number,
  count: number
): number {
  if (typeof time === "number" && Number.isFinite(time)) {
    if (time >= 1e12) return time;
    if (time >= 1e9) return time * 1000;
    return startMs + time * 1000;
  }
  if (count <= 1) return startMs;
  const frac = index / Math.max(1, count - 1);
  return startMs + durationSec * 1000 * frac;
}
