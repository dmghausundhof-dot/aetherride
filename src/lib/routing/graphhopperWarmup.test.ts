/**
 * npx tsx src/lib/routing/graphhopperWarmup.test.ts
 */
import assert from "node:assert/strict";
import {
  GH_WARMUP_OFFSET_M,
  graphhopperWarmupCell,
  graphhopperWarmupTo,
  shouldWarmLiveRouting,
} from "./graphhopperWarmup";

assert.equal(GH_WARMUP_OFFSET_M, 380);

const near: [number, number] = [8.67, 49.4];
const to = graphhopperWarmupTo(near);
assert.equal(to[1], near[1]);
assert.ok(to[0] > near[0]);
assert.ok(to[0] - near[0] < 0.01);

assert.equal(
  graphhopperWarmupCell("gravel", near),
  graphhopperWarmupCell("gravel", [8.669, 49.401])
);
assert.notEqual(
  graphhopperWarmupCell("gravel", near),
  graphhopperWarmupCell("urban", near)
);

assert.equal(
  shouldWarmLiveRouting({ hasStart: true, hasEnd: false }),
  true
);
assert.equal(
  shouldWarmLiveRouting({ hasStart: false, hasEnd: true }),
  true
);
assert.equal(
  shouldWarmLiveRouting({ hasStart: true, hasEnd: true }),
  false
);

console.log("graphhopperWarmup.test.ts OK");
