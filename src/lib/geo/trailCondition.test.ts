/**
 * Trailforks pins: name + link, no Open-Meteo as fake trail condition.
 * npx tsx src/lib/geo/trailCondition.test.ts
 */
process.env.ALLOW_DEMO_CONTENT = "true";

import assert from "node:assert/strict";
import { buildTrailforksPins, conditionFromTrailHint } from "./trailCondition";

function testWeatherHintNotPaintedOnPins() {
  const wet = buildTrailforksPins("wet_likely", { lat: 48.64, lon: 8.42 });
  assert.ok(wet.pins.length > 0);
  for (const p of wet.pins) {
    assert.equal(p.condition, "unknown");
    assert.equal(p.conditionLabel, "");
    assert.equal(p.conditionSource, "trailforks");
    assert.ok(p.openUrl.includes("trailforks.com"));
    assert.ok(!/nass|trocken|feucht/i.test(p.conditionLabel));
  }
  assert.ok(
    !/Wetter-Proxy|nass|trocken/.test(wet.disclaimer) ||
      /kein Live-Zustand/i.test(wet.disclaimer)
  );
}

function testHofWeatherHelperStillWorks() {
  assert.equal(conditionFromTrailHint("wet_likely").condition, "wet_likely");
  assert.ok(conditionFromTrailHint("wet_likely").label.includes("Wetter"));
}

testWeatherHintNotPaintedOnPins();
testHofWeatherHelperStillWorks();
console.log("trailCondition.test.ts OK");
