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

const langs = ["de", "en", "fr", "it"] as const;

function testDeExact() {
  const d = discoverUi("de");
  assert.equal(d.sixtyTitle, "~60 Min Rundkurse");
  assert.equal(d.osmOptional, "OSM · ~60-Min-Rundkurse — Bike optional");
  assert.equal(d.noLoopsNearby, "Keine Rundkurse in der Nähe");
  assert.equal(d.saveAria, "Speichern");
  assert.equal(d.mappeHeading, "Die Mappe");
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
  assert.ok(discoverStatus("12.3 km · 45 min · valhalla", "fr").includes("valhalla"));
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

function testSurface() {
  assert.equal(discoverSurfaceLabel("Schotter", "de"), "Schotter");
  assert.equal(discoverSurfaceLabel("Schotter", "en"), "Gravel");
  assert.equal(discoverSurfaceLabel("unknown", "it"), "unknown");
}

testDeExact();
testBrands();
testStatusMap();
testPins();
testSurface();
console.log("discoverUi.test.ts OK");
