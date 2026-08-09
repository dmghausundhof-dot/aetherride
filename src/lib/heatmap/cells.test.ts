/**
 * Smoke: npx tsx src/lib/heatmap/cells.test.ts
 */
import assert from "node:assert/strict";
import {
  cellsFromTrack,
  HEATMAP_K_THRESHOLD,
  heatmapCellId,
  parseHeatmapCellId,
} from "./cells";

assert.equal(heatmapCellId(47.4481, 12.1482), "47.448:12.148");
assert.deepEqual(parseHeatmapCellId("47.448:12.148"), {
  lat: 47.448,
  lng: 12.148,
});

const cells = cellsFromTrack([
  { lat: 47.448, lng: 12.148 },
  { lat: 47.448, lng: 12.148 },
  { lat: 47.449, lng: 12.149 },
]);
assert.equal(cells.length, 2);
assert.equal(HEATMAP_K_THRESHOLD, 5);

console.log("heatmap cells ok");
