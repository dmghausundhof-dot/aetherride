/**
 * Run: npx tsx src/lib/content/guides.related.test.ts
 */
import assert from "node:assert/strict";
import {
  listGuidesGrouped,
  relatedGuidesForTour,
  relatedGuidesForRegion,
  listGuideSlugs,
  getGuide,
} from "./guides";

function testGroupedCoversAll() {
  const grouped = listGuidesGrouped();
  const slugs = grouped.flatMap((g) => g.guides.map((x) => x.slug));
  assert.deepEqual([...slugs].sort(), [...listGuideSlugs()].sort());
  assert.ok(grouped.length >= 3);
}

function testRelatedRoad() {
  const g = relatedGuidesForTour({
    id: "r-bodensee-road",
    primaryCategory: "road",
  });
  assert.ok(g.some((x) => x.slug === "web-vs-app"));
  assert.ok(g.some((x) => x.slug === "rennrad-hoehenmeter"));
  assert.equal(g.length, 3);
}

function testRelatedRegion() {
  const g = relatedGuidesForRegion(["road", "touring", "urban"]);
  assert.ok(g.some((x) => x.slug === "rennrad-hoehenmeter"));
  assert.ok(g.some((x) => x.slug === "teilen-per-link"));
  assert.ok(g.length <= 4);
  assert.ok(getGuide("laden-ohne-zweite-kasse"));
  assert.ok(getGuide("teilen-per-link"));
}

testGroupedCoversAll();
testRelatedRoad();
testRelatedRegion();
console.log("guides.related.test.ts OK");
