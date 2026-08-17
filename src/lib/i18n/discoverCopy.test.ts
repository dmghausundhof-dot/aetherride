/**
 * Run: npx tsx src/lib/i18n/discoverCopy.test.ts
 */
import assert from "node:assert/strict";
import { difficultyOptionsForProfile } from "../routing/routeFilters";
import {
  discoverCopy,
  discoverDifficulty,
  discoverElevationLabel,
} from "./discoverCopy";

const langs = ["de", "en", "fr", "it"] as const;

function testDe() {
  const d = discoverCopy("de");
  assert.equal(d.loop, "Rundkurs");
  assert.equal(d.searchHint, "Ort oder Tour");
  assert.equal(d.planRouteCta, "Navigieren");
  assert.equal(d.filter, "Filter");
  assert.equal(d.aroundKm(35), "in 35 km");
  assert.equal(d.showTours(3), "3 Touren zeigen");
  assert.equal(d.sport.road, "Rennrad");
  assert.equal(d.sport.mtb, "MTB");
  assert.equal(d.sport.gravel, "Gravel");
  assert.equal(d.sport.ebike, "E-MTB");
  assert.equal(d.mappe, "Mappe");
  assert.equal(d.dist(20), "≤ 20 km");
  assert.ok(d.elevFlat.includes("hm"));
}

function testParity() {
  for (const lang of langs) {
    const d = discoverCopy(lang);
    assert.equal(d.sport.mtb, "MTB", lang);
    assert.equal(d.sport.gravel, "Gravel", lang);
    assert.equal(d.sport.ebike, "E-MTB", lang);
    assert.equal(d.surface.trail, "Trail", lang);
    assert.ok(d.dist(40).includes("km"), lang);
    assert.ok(d.aroundKm(35).includes("km"), lang);
    assert.ok(d.searchHint.length > 0, lang);
    assert.ok(d.elevAlpine.includes("hm"), lang);
    assert.ok(d.mappe.includes("Mappe"), lang);
  }
  assert.notEqual(discoverCopy("de").reset, discoverCopy("en").reset);
  assert.notEqual(discoverCopy("de").searchHint, discoverCopy("en").searchHint);
  assert.notEqual(discoverCopy("de").planRouteCta, discoverCopy("en").planRouteCta);
}

function testDifficultyIdsMatchDomain() {
  const profiles = ["road", "gravel", "emtb", "hiking", "urban"] as const;
  for (const profile of profiles) {
    const deUi = discoverDifficulty(profile, "de");
    const domain = difficultyOptionsForProfile(profile);
    assert.deepEqual(
      deUi.map((o) => o.id),
      domain.map((o) => o.id),
      profile,
    );
    assert.deepEqual(
      deUi.map((o) => o.label),
      domain.map((o) => o.label),
      `${profile} DE labels`,
    );
    const en = discoverDifficulty(profile, "en");
    assert.notEqual(en[1]?.label, deUi[1]?.label, profile);
  }
}

function testElevation() {
  assert.equal(discoverElevationLabel("flat", "de"), "< 400 hm");
  assert.ok(discoverElevationLabel("alpine", "fr").includes("hm"));
}

testDe();
testParity();
testDifficultyIdsMatchDomain();
testElevation();
console.log("discoverCopy.test.ts OK");
