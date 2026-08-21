/**
 * npx tsx src/lib/routing/loopReasons.test.ts
 */
import assert from "node:assert/strict";
import {
  loopJustificationReasons,
  surfaceFromLoopWarnings,
} from "./loopReasons";

const reasons = loopJustificationReasons({
  durationMin: 61,
  targetMin: 60,
  surface: "Asphalt",
  lang: "de",
});
assert.equal(reasons.length, 3);
assert.ok(reasons[0].includes("61"));
assert.ok(reasons[0].includes("60"));
assert.ok(reasons[1].includes("Asphalt"));
assert.ok(reasons[2].toLowerCase().includes("osm"));
for (const r of reasons) {
  const lower = r.toLowerCase();
  assert.ok(!lower.includes("graphhopper"));
  assert.ok(!lower.includes("valhalla"));
  assert.ok(!lower.includes("openrouteservice"));
  assert.ok(!/\bors\b/.test(lower));
}

assert.equal(
  surfaceFromLoopWarnings(["ORS Oberfläche überwiegend Schotter"]),
  "Schotter"
);
assert.equal(
  loopJustificationReasons({
    durationMin: 50,
    targetMin: 60,
    lang: "en",
  }).length,
  3
);

console.log("loopReasons.test.ts OK");
