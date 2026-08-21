/**
 * Run: npx tsx src/lib/i18n/catalogCopy.test.ts
 */
import assert from "node:assert/strict";
import { catalogCopy } from "./catalogCopy";

const langs = ["de", "en", "fr", "it", "nl"] as const;

function testDe() {
  const c = catalogCopy("de");
  assert.equal(c.regions.title, "Regionen");
  assert.equal(c.tour.atGate, "Vor dem Tor");
  assert.equal(c.stimmen.heading, "Stimmen");
  assert.equal(c.stimmen.empty, "Noch keine Stimmen.");
  assert.ok(c.tour.honestBody.includes("Stimmen"));
  assert.ok(c.tour.flashSaved.includes("Mappe"));
}

function testParity() {
  const de = catalogCopy("de");
  for (const lang of langs) {
    const c = catalogCopy(lang);
    assert.equal(c.stimmen.heading, "Stimmen", lang);
    assert.ok(c.region.voicesTitle.includes("Stimmen"), lang);
    assert.ok(c.tour.flashSaved.includes("Mappe"), lang);
    assert.ok(c.regions.toursLine(3, "gravel").includes("3"), lang);
    assert.ok(c.region.toursIn("Heidelberg").includes("Heidelberg"), lang);
    assert.equal(typeof c.weather.precip(2, 40), "string", lang);
    assert.ok(!JSON.stringify(Object.values(c.tour)).includes("Musterstraße"), lang);
    assert.ok(c.stimmen.crowdEasier(6).includes("6"), lang);
    assert.ok(c.stimmen.pinOnLine.length > 0, lang);
    assert.ok(c.elevation.noteMeta.includes("km"), lang);
    assert.ok(c.tour.kitTitle.length > 0, lang);
    assert.equal(Object.keys(c.tour.fn).length, 13, lang);
    assert.ok(c.region.mapTitle.length > 0, lang);
    assert.ok(c.region.mapOpen.length > 0, lang);
    assert.ok(c.tour.mapStart.length > 0, lang);
    assert.ok(c.tour.mapLoading.length > 0, lang);
  }
  assert.notEqual(de.regions.lead, catalogCopy("en").regions.lead);
  assert.equal(catalogCopy("nl").regions.title, "Regio's");
  assert.equal(catalogCopy("nl").tour.atGate, "Voor de poort");
}

testDe();
testParity();
console.log("catalogCopy.test.ts OK");
