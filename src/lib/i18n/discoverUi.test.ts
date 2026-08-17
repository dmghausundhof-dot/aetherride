/**
 * Run: npx tsx src/lib/i18n/discoverUi.test.ts
 */
import assert from "node:assert/strict";
import {
  DEMO_ROUTING_NOTICE,
  UNVERIFIED_ROUTING_NOTICE,
} from "../routing/routingStatus";
import {
  DISCOVER_PIN_DE,
  DISCOVER_STATUS_DE,
  discoverDraftLabel,
  discoverPinLabel,
  discoverStatus,
  discoverSurfaceLabel,
  discoverUi,
} from "./discoverUi";

const langs = ["de", "en", "fr", "it", "nl"] as const;

function testDeExact() {
  const d = discoverUi("de");
  assert.equal(d.sixtyTitle, "~60 Min Rundkurse");
  assert.equal(d.osmOptional, "OSM · ~60-Min-Rundkurse — Bike optional");
  assert.equal(d.noLoopsNearby, "Keine Rundkurse in der Nähe");
  assert.equal(d.saveAria, "Speichern");
  assert.equal(d.mappeHeading, "Die Mappe");
  assert.equal(d.waysNearby, "Wege in der Nähe");
  assert.equal(d.outdooractive(3), "Outdooractive (3)");
  assert.equal(d.collectionsTitle, "Sammlungen");
  assert.notEqual(d.sixtyTitle, d.sixtyTitle.toUpperCase());
  assert.notEqual(d.waysNearby, d.waysNearby.toUpperCase());
  assert.notEqual(d.outdooractive(1), d.outdooractive(1).toUpperCase());
  assert.notEqual(d.mappeHeading, d.mappeHeading.toUpperCase());
  assert.notEqual(d.collectionsTitle, d.collectionsTitle.toUpperCase());
  assert.ok(d.sixtyLead.includes("Tempelhofer"));
}

function testBrands() {
  for (const lang of langs) {
    const d = discoverUi(lang);
    assert.equal(d.mappeHeading, "Die Mappe", lang);
    assert.ok(d.importGpx.includes("GPX"), lang);
    assert.ok(d.nearbyLiveHint.includes("MTB"), lang);
    assert.ok(d.rangeLine(40, 80).includes("km"), lang);
    assert.ok(d.elevEst(200).includes("hm"), lang);
    assert.notEqual(d.sixtyTitle, d.sixtyTitle.toUpperCase(), lang);
    assert.notEqual(d.waysNearby, d.waysNearby.toUpperCase(), lang);
    assert.notEqual(d.outdooractive(2), d.outdooractive(2).toUpperCase(), lang);
    assert.notEqual(d.mappeHeading, d.mappeHeading.toUpperCase(), lang);
    assert.notEqual(d.collectionsTitle, d.collectionsTitle.toUpperCase(), lang);
  }
}

function testStatusMap() {
  assert.equal(
    discoverStatus(DISCOVER_STATUS_DE.locGps, "de"),
    DISCOVER_STATUS_DE.locGps,
  );
  assert.ok(discoverStatus(DISCOVER_STATUS_DE.locGps, "en").includes("GPS"));
  assert.notEqual(
    discoverStatus(DISCOVER_STATUS_DE.calcSlow, "fr"),
    DISCOVER_STATUS_DE.calcSlow,
  );
  assert.equal(
    discoverStatus("Demo-Region: Berlin · 60 min Rundkurse", "en"),
    discoverUi("en").demoRegionLoops("Berlin"),
  );
  assert.equal(
    discoverStatus("12.3 km · 45 min · valhalla", "fr"),
    "12.3 km · 45 min",
  );
  assert.ok(
    !discoverStatus("12.3 km · 45 min · osrm", "en")
      .toLowerCase()
      .includes("osrm"),
  );
  assert.equal(discoverStatus(DEMO_ROUTING_NOTICE, "de"), DEMO_ROUTING_NOTICE);
  assert.notEqual(
    discoverStatus(UNVERIFIED_ROUTING_NOTICE, "en"),
    UNVERIFIED_ROUTING_NOTICE,
  );
}

function testPins() {
  assert.equal(discoverPinLabel(DISCOVER_PIN_DE.myPos, "de"), "Meine Position");
  assert.equal(discoverPinLabel(DISCOVER_PIN_DE.myPos, "en"), "My position");
  assert.equal(
    discoverDraftLabel("Alster (von hier)", "en"),
    "Alster (from here)",
  );
  assert.equal(discoverDraftLabel("Alster", "fr"), "Alster");
}

function testP2Copy() {
  const de = discoverUi("de");
  assert.equal(de.variantPlanned, "Wie geplant");
  assert.equal(de.variantFlatter, "Weniger hm");
  assert.equal(de.variantUnpaved, "Mehr Schotter");
  assert.ok(!de.variantUnpaved.toLowerCase().includes("unpaved"));
  assert.equal(de.openNativeApp, "In der App öffnen");
  assert.equal(de.placeKind("cafe"), "Café");
  assert.equal(de.placeKind("shop"), "Laden");
  assert.equal(de.variantValhallaOnly, "Ohne Live-Strecke keine Varianten");
  assert.equal(
    discoverUi("en").variantValhallaOnly,
    "No variants without a live route",
  );
  for (const lang of langs) {
    const line = discoverUi(lang).variantValhallaOnly.toLowerCase();
    assert.ok(!line.includes("valhalla"), lang);
    assert.ok(!line.includes("osrm"), lang);
    assert.ok(!line.includes("graphhopper"), lang);
  }
}

function testGhMinuteLimit() {
  const de = discoverUi("de");
  assert.equal(
    de.ghMinuteLimit,
    "Vorschläge und Zeit gerade gedrosselt — kurz warten oder sparsam planen.",
  );
  assert.equal(
    discoverUi("en").ghMinuteLimit,
    "Suggestions and times are limited — wait a bit or plan sparingly.",
  );
  for (const lang of langs) {
    const line = discoverUi(lang).ghMinuteLimit.toLowerCase();
    assert.ok(!line.includes("graphhopper"), lang);
    assert.ok(!line.includes("valhalla"), lang);
    assert.ok(!line.includes("osrm"), lang);
  }
}

function testHonestyCopy() {
  const de = discoverUi("de");
  assert.equal(
    de.honestyRoad,
    "Route folgt überwiegend Straßen — Trail auf der Karte antippen und anhängen.",
  );
  assert.equal(
    de.honestyCycleway,
    "Wenig eigener Radweg — Live-Strecke oft auf der Fahrbahn.",
  );
  assert.equal(
    discoverUi("en").honestyRoad,
    "Route mostly follows roads — tap a trail on the map and attach it.",
  );
  assert.equal(
    discoverUi("en").honestyCycleway,
    "Little dedicated bike path — the live route often stays on the road.",
  );
  for (const lang of langs) {
    const d = discoverUi(lang);
    for (const line of [d.honestyRoad, d.honestyCycleway]) {
      const lower = line.toLowerCase();
      assert.ok(!lower.includes("graphhopper"), `${lang}: ${line}`);
      assert.ok(!lower.includes("valhalla"), `${lang}: ${line}`);
      assert.ok(!lower.includes("osrm"), `${lang}: ${line}`);
    }
  }
  const mapped = discoverStatus(
    `12.3 km · 45 min · ${de.honestyCycleway}`,
    "en",
  );
  assert.ok(mapped.includes("Little dedicated bike path"));
  assert.ok(!mapped.toLowerCase().includes("graphhopper"));
  assert.ok(!mapped.toLowerCase().includes("valhalla"));
  assert.ok(!mapped.toLowerCase().includes("osrm"));
  assert.ok(de.outdooractive(3).includes("Outdooractive"));
}

function testSurface() {
  assert.equal(discoverSurfaceLabel("Schotter", "de"), "Schotter");
  assert.equal(discoverSurfaceLabel("Schotter", "en"), "Gravel");
  assert.equal(discoverSurfaceLabel("unknown", "it"), "unknown");
}

function testHeatCopy() {
  const de = discoverUi("de");
  assert.equal(de.heatCell, "Wo viele fahren");
  assert.ok(de.heatSegments(3).includes("3"));
  assert.ok(!de.heatCold(5).toLowerCase().includes("heatmap"));
  assert.ok(!de.heatConsent(5).includes("k≥"));
  assert.ok(!de.heatmapOffline.toLowerCase().includes("heatmap"));
  for (const lang of langs) {
    const d = discoverUi(lang);
    assert.ok(!d.heatCell.toLowerCase().includes("heatmap"), lang);
    assert.ok(d.heatSegments(2).includes("2"), lang);
  }
}

testDeExact();
testBrands();
testStatusMap();
testPins();
testP2Copy();
testGhMinuteLimit();
testHonestyCopy();
testSurface();
testHeatCopy();
console.log("discoverUi.test.ts OK");
