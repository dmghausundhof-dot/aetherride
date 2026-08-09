/**
 * Smoke: npx tsx src/lib/heatmap/client.test.ts
 */
import assert from "node:assert/strict";
import { bboxAround } from "./client";

const b = bboxAround(7.85, 47.99);
assert.ok(b.west < 7.85 && b.east > 7.85);
assert.ok(b.south < 47.99 && b.north > 47.99);
assert.equal(Number(b.west.toFixed(2)), 7.4);

console.log("heatmap client bbox ok");
