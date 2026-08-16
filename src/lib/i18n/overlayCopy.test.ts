/**
 * Run: npx tsx src/lib/i18n/overlayCopy.test.ts
 */
import assert from "node:assert/strict";
import { overlayCopy, overlayLegendLabel } from "./overlayCopy";

function testDe() {
  const o = overlayCopy("de");
  assert.equal(o.waysOsm, "Wege · OSM");
  assert.equal(o.unrated, "unbewertet");
  assert.equal(overlayLegendLabel("S1", "de"), "S1");
  assert.equal(overlayLegendLabel("gravel", "de"), "Gravel");
  assert.ok(o.scaleNote.includes("mtb:scale"));
}

function testParity() {
  for (const lang of ["de", "en", "fr", "it"] as const) {
    const o = overlayCopy(lang);
    assert.ok(o.waysOsm.includes("OSM"), lang);
    assert.equal(overlayLegendLabel("S0", lang), "S0", lang);
    assert.equal(overlayLegendLabel("gravel", lang), "Gravel", lang);
    assert.equal(overlayLegendLabel("urban", lang), "City", lang);
    assert.ok(o.scaleNote.includes("mtb:scale"), lang);
  }
  assert.equal(overlayLegendLabel("unrated", "en"), "unrated");
  assert.notEqual(overlayCopy("de").unrated, overlayCopy("en").unrated);
}

testDe();
testParity();
console.log("overlayCopy.test.ts OK");
