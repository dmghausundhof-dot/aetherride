/**
 * Pause-Dauer: aktive Zeit ohne Pausensekunden.
 * Ausführen: npx tsx src/lib/ride/activeDuration.test.ts
 */
import { activeDurationSec } from "./activeDuration";

const start = 1_000_000;
let sec = activeDurationSec({
  startMs: start,
  nowMs: start + 80_000,
  pauseAccumMs: 20_000,
  pauseStartedAt: null,
  isPaused: false,
});
if (sec !== 60) throw new Error(`expected 60 got ${sec}`);

sec = activeDurationSec({
  startMs: start,
  nowMs: start + 90_000,
  pauseAccumMs: 20_000,
  pauseStartedAt: start + 80_000,
  isPaused: true,
});
if (sec !== 60) throw new Error(`expected 60 during pause got ${sec}`);

console.log("activeDuration.test.ts OK");
