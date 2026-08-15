/**
 * npx tsx src/lib/discover/tourCoverage.test.ts
 */
import assert from "node:assert/strict";
import { pickNearbyThenFill } from "./tourCoverage";

assert.deepEqual(
  pickNearbyThenFill<number>([], (n) => n),
  []
);

const dense = pickNearbyThenFill(
  Array.from({ length: 40 }, (_, i) => i),
  (n) => n,
  { nearbyKm: 90, minCount: 12, maxItems: 32 }
);
assert.equal(dense.length, 32);
assert.equal(dense[0], 0);
assert.equal(dense[31], 31);

const thin = pickNearbyThenFill(
  [
    { id: "hd", km: 12 },
    { id: "ma", km: 18 },
    { id: "boxberg", km: 22 },
    { id: "ka", km: 48 },
    { id: "mainz", km: 72 },
    { id: "ffm", km: 80 },
    { id: "stgt", km: 88 },
    { id: "wue", km: 95 },
    { id: "koeln", km: 180 },
    { id: "muc", km: 270 },
    { id: "berlin", km: 530 },
    { id: "wien", km: 620 },
  ],
  (e) => e.km,
  { nearbyKm: 90, minCount: 12, maxItems: 32 }
);
assert.equal(thin.length, 12, "fill to min 12 when nearby is a 3-card stub");
assert.deepEqual(
  thin.slice(0, 3).map((e) => e.id),
  ["hd", "ma", "boxberg"]
);
assert.ok(thin.some((e) => e.id === "ka"));
assert.equal(thin[thin.length - 1].id, "wien");

const few = pickNearbyThenFill([10, 20, 30], (n) => n);
assert.deepEqual(few, [10, 20, 30]);

console.log("tourCoverage.test.ts OK");
