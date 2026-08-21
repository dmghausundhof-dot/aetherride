/**
 * Trail View honesty — no demo placeholders when demo content is off.
 * npx tsx src/lib/routing/trailView.honesty.test.ts
 */
import assert from "node:assert/strict";
import {
  emptyTrailView,
  getTrailViewNear,
  unavailableTrailView,
} from "./trailView";

function withDemoFlag(value: string | undefined, fn: () => void) {
  const prev = process.env.ALLOW_DEMO_CONTENT;
  if (value === undefined) delete process.env.ALLOW_DEMO_CONTENT;
  else process.env.ALLOW_DEMO_CONTENT = value;
  try {
    fn();
  } finally {
    if (prev === undefined) delete process.env.ALLOW_DEMO_CONTENT;
    else process.env.ALLOW_DEMO_CONTENT = prev;
  }
}

withDemoFlag("false", () => {
  const r = unavailableTrailView(
    52.52,
    13.405,
    "Keine Mapillary-Bilder (API 500)."
  );
  assert.equal(r.usingDemo, false);
  assert.equal(r.photos.length, 0);
  assert.ok(!r.disclaimer.includes("Demo"));
  assert.ok(!r.disclaimer.includes("Beispiel"));
});

withDemoFlag("true", () => {
  const r = unavailableTrailView(
    52.52,
    13.405,
    "Mapillary API 500 — Demo-Fallback."
  );
  assert.equal(r.usingDemo, true);
  assert.equal(r.photos.length, 1);
  assert.equal(r.photos[0].demo, true);
  assert.match(r.photos[0].imageUrl, /^data:image\/svg\+xml/);
});

const demo = getTrailViewNear(52.52, 13.405);
assert.equal(demo.usingDemo, true);
assert.equal(demo.photos[0]?.demo, true);

const empty = emptyTrailView();
assert.equal(empty.usingDemo, false);
assert.equal(empty.photos.length, 0);

console.log("trailView.honesty.test.ts OK");
