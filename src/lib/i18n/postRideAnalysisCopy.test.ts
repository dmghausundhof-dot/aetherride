/**
 * Run: npx tsx src/lib/i18n/postRideAnalysisCopy.test.ts
 */
import assert from "node:assert/strict";
import {
  fillCopy,
  localizePostRideFact,
  localizePostRideObservation,
  localizePostRideReason,
  postRideAnalysisCopy,
} from "./postRideAnalysisCopy";

const langs = ["de", "en", "fr", "it", "nl"] as const;

function testParity() {
  const keys = Object.keys(postRideAnalysisCopy("de")).sort();
  for (const lang of langs) {
    assert.deepEqual(Object.keys(postRideAnalysisCopy(lang)).sort(), keys, lang);
  }
}

function testFacts() {
  const en = postRideAnalysisCopy("en");
  assert.equal(
    localizePostRideFact("12.4 km · 100 hm ↑ · 40 hm ↓ · 62 min", en),
    "12.4 km · 100 hm ↑ · 40 hm ↓ · 62 min"
  );
  assert.equal(
    localizePostRideFact("12.4 km · 80 hm · 62 min", en),
    "12.4 km · 80 hm · 62 min"
  );
  assert.equal(
    localizePostRideFact('Setup „Trail“ (wet)', en, "en"),
    "Setup “Trail” (Wet)"
  );
  assert.ok(
    localizePostRideFact("Ø SOC 64% · Rider 118 W", en).includes("64")
  );
}

function testObs() {
  const en = postRideAnalysisCopy("en");
  assert.ok(
    localizePostRideObservation(
      {
        id: "elev-gap",
        text: "Höhenlücken auf 0.5 km — Neigung dort nicht belastbar.",
        params: { gap: "0.5" },
      },
      en
    ).includes("0.5")
  );
  assert.ok(
    localizePostRideObservation(
      { id: "fb-soft", text: "Feedback DE" },
      en
    ).toLowerCase().includes("soft")
  );
  assert.equal(fillCopy("a {x}", { x: "1" }), "a 1");
}

function testReason() {
  const en = postRideAnalysisCopy("en");
  assert.equal(
    localizePostRideReason("Feedback „Front zu hart“", en),
    "Feedback “front too firm”"
  );
  assert.ok(
    localizePostRideReason("12 Impacts / 3.4 km · RMS 1.3 g", en).includes("3.4")
  );
}

testParity();
testFacts();
testObs();
testReason();
console.log("postRideAnalysisCopy.test.ts OK");
