/**
 * npx tsx src/lib/content/kartenCopy.test.ts
 */
import assert from "node:assert/strict";
import { KARTEN_PAGE, offlinePacksSentence } from "./kartenCopy";
import { ONLINE_BASEMAP_RIDER } from "../map/onlineBasemap";
import { FAQ_ITEMS } from "./faq";

assert.ok(KARTEN_PAGE.lead.length > 60);
assert.ok(KARTEN_PAGE.holes.length >= 4);
assert.equal(
  JSON.stringify(KARTEN_PAGE).includes("uk-south-z11") ||
    JSON.stringify(KARTEN_PAGE).includes("dach-z11"),
  false
);
assert.ok(!KARTEN_PAGE.offlineLead.includes("83"));
assert.ok(!KARTEN_PAGE.offlineLead.includes("56"));

const withCount = offlinePacksSentence({
  readyPacks: 83,
  envelopeRegions: 33,
});
assert.ok(withCount.includes("83"));
assert.ok(withCount.includes("33"));
assert.ok(/Stadt/.test(withCount));
assert.ok(!/Länderkarte wie Komoot/.test(withCount));

const withoutCount = offlinePacksSentence({
  readyPacks: null,
  envelopeRegions: 33,
});
assert.ok(!withoutCount.includes("83"));
assert.ok(withoutCount.includes("33"));

const names = ONLINE_BASEMAP_RIDER.map((r) => r.name);
assert.deepEqual(names, [
  "DACH",
  "Frankreich",
  "Alpen-Süd",
  "Benelux",
  "Norditalien",
  "Katalonien / Pyrenäen",
  "Südengland",
]);

const kartenFaq = FAQ_ITEMS.find((item) => item.id === "karten");
assert.ok(kartenFaq);
assert.ok(kartenFaq!.links?.some((l) => l.href === "/karten"));

console.log("kartenCopy.test.ts OK");
