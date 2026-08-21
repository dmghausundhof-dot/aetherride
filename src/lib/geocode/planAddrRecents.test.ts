/**
 * npx tsx src/lib/geocode/planAddrRecents.test.ts
 */
import assert from "node:assert/strict";
import {
  parsePlanAddrRecents,
  pushPlanAddrRecent,
} from "./planAddrRecents";

const a = { label: "Kino", lat: 49.3, lng: 8.64 };
const b = { label: "Markt", lat: 49.41, lng: 8.69 };

assert.deepEqual(parsePlanAddrRecents(null), []);
assert.deepEqual(parsePlanAddrRecents([{ label: "Kino", lat: 49.3, lng: 8.64 }]), [
  a,
]);
assert.equal(parsePlanAddrRecents([{ label: "x", lat: 99, lng: 0 }]).length, 0);
assert.equal(
  parsePlanAddrRecents([a, a, b, { label: "C", lat: 1, lng: 2 }, { label: "D", lat: 1, lng: 3 }, { label: "E", lat: 1, lng: 4 }, { label: "F", lat: 1, lng: 5 }]).length,
  5
);

const pushed = pushPlanAddrRecent(b, [a]);
assert.deepEqual(pushed.map((x) => x.label), ["Markt", "Kino"]);
const again = pushPlanAddrRecent(a, pushed);
assert.deepEqual(again.map((x) => x.label), ["Kino", "Markt"]);

console.log("planAddrRecents.test.ts OK");
