/**
 * Run: npx tsx src/lib/routing/trailAccess.test.ts
 */
import assert from "node:assert/strict";
import { orientTrail } from "./trailAccess";

const geo: [number, number][] = [
  [8.4, 48.0],
  [8.41, 48.01],
];

{
  const n = orientTrail({
    geometry: geo,
    fromLng: 8.4,
    fromLat: 48.0,
    preferDownhill: false,
  });
  assert.equal(n.reversed, false);
  assert.equal(n.usedElevation, false);
}

{
  const down = orientTrail({
    geometry: geo,
    fromLng: 8.4,
    fromLat: 48.0,
    startElevM: 400,
    endElevM: 900,
    preferDownhill: true,
  });
  assert.equal(down.reversed, true);
  assert.equal(down.usedElevation, true);
  assert.deepEqual(down.entry, [8.41, 48.01]);
}

{
  const alreadyTop = orientTrail({
    geometry: geo,
    fromLng: 8.4,
    fromLat: 48.0,
    startElevM: 900,
    endElevM: 400,
    preferDownhill: true,
  });
  assert.equal(alreadyTop.reversed, false);
  assert.equal(alreadyTop.usedElevation, true);
}

{
  const tiny = orientTrail({
    geometry: geo,
    fromLng: 8.4,
    fromLat: 48.0,
    startElevM: 500,
    endElevM: 504,
    preferDownhill: true,
  });
  assert.equal(tiny.usedElevation, false);
}

console.log("trailAccess.test.ts OK");
