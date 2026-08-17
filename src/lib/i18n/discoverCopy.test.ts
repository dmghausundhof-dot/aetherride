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
  assert.equal(d.distance, "Distanz");
  assert.equal(d.aroundKm(35), "in 35 km");
  assert.equal(d.showTours(1), "1 Tour zeigen");
  assert.equal(d.showTours(3), "3 Touren zeigen");
  assert.equal(d.catalogTours(1), "Katalog 1 Tour");
  assert.equal(d.catalogTours(2), "Katalog 2 Touren");
  assert.equal(d.catalogTours(0), "Katalog 0 Touren");
  assert.equal(d.toursNearby(1), "1 Tour in der Nähe");
  assert.equal(d.toursNearby(2), "2 Touren in der Nähe");
  assert.equal(d.toursNearby(0), "0 Touren in der Nähe");
  assert.equal(d.oaCount(1), "1 Tour in der Nähe");
  assert.equal(d.oaCount(2), "2 Touren in der Nähe");
  assert.equal(d.sport.road, "Rennrad");
  assert.equal(d.sport.mtb, "MTB");
  assert.equal(d.sport.gravel, "Gravel");
  assert.equal(d.sport.ebike, "E-MTB");
  assert.equal(d.mappe, "Mappe");
  assert.equal(d.sportPref, "Disziplin (Präferenz)");
  assert.notEqual(d.sportPref, d.sportPref.toUpperCase());
  assert.notEqual(d.mappe, d.mappe.toUpperCase());
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
    assert.ok(d.distance.length > 0, lang);
    assert.ok(d.searchHint.length > 0, lang);
    assert.ok(d.elevAlpine.includes("hm"), lang);
    assert.ok(d.mappe.includes("Mappe"), lang);
    assert.notEqual(d.catalogTours(1), d.catalogTours(2), lang);
    assert.ok(d.catalogTours(1).includes("1"), lang);
    assert.ok(d.catalogTours(3).includes("3"), lang);
    assert.notEqual(d.toursNearby(1), d.toursNearby(2), lang);
    assert.ok(d.toursNearby(1).includes("1"), lang);
    assert.ok(d.toursNearby(3).includes("3"), lang);
    assert.notEqual(d.oaCount(1), d.oaCount(2), lang);
    assert.notEqual(d.showTours(1), d.showTours(2), lang);
    assert.notEqual(d.sportPref, d.sportPref.toUpperCase(), lang);
    assert.notEqual(d.mappe, d.mappe.toUpperCase(), lang);
  }
  assert.notEqual(discoverCopy("de").reset, discoverCopy("en").reset);
  assert.notEqual(discoverCopy("de").searchHint, discoverCopy("en").searchHint);
  assert.notEqual(discoverCopy("de").planRouteCta, discoverCopy("en").planRouteCta);
  assert.equal(discoverCopy("en").catalogTours(1), "Catalog 1 tour");
  assert.equal(discoverCopy("en").catalogTours(2), "Catalog 2 tours");
  assert.equal(discoverCopy("fr").catalogTours(1), "Catalogue 1 tour");
  assert.equal(discoverCopy("fr").catalogTours(2), "Catalogue 2 tours");
  assert.equal(discoverCopy("it").catalogTours(1), "Catalogo 1 tour");
  assert.equal(discoverCopy("it").catalogTours(2), "Catalogo 2 tour");
  assert.equal(discoverCopy("en").toursNearby(1), "1 tour nearby");
  assert.equal(discoverCopy("en").toursNearby(2), "2 tours nearby");
  assert.equal(discoverCopy("en").oaCount(1), "1 tour nearby");
  assert.equal(discoverCopy("en").oaCount(2), "2 tours nearby");
  assert.equal(discoverCopy("fr").toursNearby(1), "1 tour à proximité");
  assert.equal(discoverCopy("fr").toursNearby(2), "2 tours à proximité");
  assert.equal(
    discoverCopy("fr").oaCount(1),
    "Outdooractive 1 tour · OSM/traces suivent",
  );
  assert.equal(
    discoverCopy("fr").oaCount(2),
    "Outdooractive 2 tours · OSM/traces suivent",
  );
  assert.equal(discoverCopy("it").toursNearby(1), "1 tour nelle vicinanze");
  assert.equal(discoverCopy("it").toursNearby(2), "2 tour nelle vicinanze");
  assert.equal(discoverCopy("it").oaCount(1), "1 tour qui vicino");
  assert.equal(discoverCopy("it").oaCount(2), "2 tour qui vicino");
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
