/** Aktive Aufnahmezeit ohne Pausensekunden (Spec Ride). */

export function activeDurationSec(input: {
  startMs: number;
  nowMs?: number;
  pauseAccumMs: number;
  pauseStartedAt: number | null;
  isPaused: boolean;
}): number {
  const now = input.nowMs ?? Date.now();
  const openPause =
    input.isPaused && input.pauseStartedAt != null
      ? now - input.pauseStartedAt
      : 0;
  return Math.max(
    0,
    Math.round(
      (now - input.startMs - input.pauseAccumMs - openPause) / 1000
    )
  );
}
