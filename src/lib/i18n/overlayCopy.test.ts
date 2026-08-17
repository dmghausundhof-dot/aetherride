/**
 * Run: npx tsx src/lib/i18n/overlayCopy.test.ts
 */
import assert from "node:assert/strict";
import { overlayCopy, overlayLegendCompactLabel, overlayLegendLabel } from "./overlayCopy";

function testDe() {
  const o = overlayCopy("de");
  assert.equal(o.waysOsm, "Wege · OSM");
  assert.equal(o.unrated, "unbewertet");
  assert.equal(overlayLegendLabel("S1", "de"), "S1");
  assert.equal(overlayLegendLabel("gravel", "de"), "Gravel");
  assert.ok(o.scaleNote.includes("mtb:scale"));
  assert.ok(o.empty.includes("kein Wege-Overlay"));
  assert.ok(!o.empty.includes("Hausbergen"));
  assert.ok(!o.empty.includes("Annecy"));
  assert.ok(!o.empty.includes("Paris"));
  assert.equal(overlayLegendCompactLabel("urban", "de"), "City");
  assert.equal(overlayLegendCompactLabel("mtb", "de"), "MTB");
}

function testParity() {
  for (const lang of ["de", "en", "fr", "it"] as const) {
    const o = overlayCopy(lang);
    assert.ok(o.waysOsm.includes("OSM"), lang);
    assert.ok(o.meshOsm.includes("OSM"), lang);
    assert.ok(o.meshNote.includes("ICN"), lang);
    assert.equal(overlayLegendLabel("S0", lang), "S0", lang);
    assert.equal(overlayLegendLabel("gravel", lang), "Gravel", lang);
    assert.equal(overlayLegendLabel("urban", lang), "City", lang);
    assert.ok(o.scaleNote.includes("mtb:scale"), lang);
    assert.ok(o.empty.length > 20, lang);
    assert.ok(!o.empty.includes("Hausbergen"), lang);
    assert.equal(overlayLegendCompactLabel("gravel", lang), "Gravel", lang);
  }
  assert.equal(overlayLegendLabel("unrated", "en"), "unrated");
  assert.notEqual(overlayCopy("de").unrated, overlayCopy("en").unrated);
}

testDe();
testParity();
console.log("overlayCopy.test.ts OK");
