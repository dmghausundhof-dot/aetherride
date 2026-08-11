/**
 * P0 elevation guard — absurd hm/km hidden.
 * Run: npx tsx src/lib/discover/elevationGuard.test.ts
 */
import { sanitizeElevationM, formatDistanceElevation } from "./elevationGuard";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

assert(sanitizeElevationM(40, 18) === 40, "normal ascent kept");
assert(sanitizeElevationM(518, 6.9) === null, "518/6.9 ≈75 hm/km hidden at 50 threshold");
assert(sanitizeElevationM(1670, 16) === null, "absurd 1670/16 hidden");
assert(sanitizeElevationM(-5, 10) === null, "negative hidden");
assert(sanitizeElevationM(null, 10) === null, "null hidden");
assert(sanitizeElevationM(100, null) === 100, "no km → keep rounded");
assert(
  formatDistanceElevation(16, null) === "16 km",
  "format omits hm when null"
);
assert(
  formatDistanceElevation(16, 45) === "16 km · 45 hm",
  "format includes hm"
);
console.log("elevationGuard.test.ts OK");
