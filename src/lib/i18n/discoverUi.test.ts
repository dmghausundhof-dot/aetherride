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
  assert.equal(d.osmOptional, "OSM · ~60-Min-Rundkurse — Rad optional");
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
  assert.equal(d.fitsYourBike("Enduro"), "passt zu deinem Enduro");
  assert.ok(d.emptyLayers.includes("Pin"));
}

function testBrands() {
  for (const lang of langs) {
    const d = discoverUi(lang);
    assert.equal(d.mappeHeading, "Die Mappe", lang);
    assert.ok(d.importGpx.includes("GPX"), lang);
    assert.ok(d.mappeShowAll.length > 3, lang);
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
assert.equal(
  discoverUi("de").variantValhallaOnly,
  "Weniger hm und mehr Schotter nur mit Live-Strecke — du siehst die geplante Linie.",
);
assert.equal(
  discoverStatus(
    `12.3 km · 45 min · ${discoverUi("de").variantValhallaOnly}`,
    "en",
  ),
  `12.3 km · 45 min · ${discoverUi("en").variantValhallaOnly}`,
);
  assert.equal(de.backToGps, "Zurück zu GPS");
  assert.equal(de.tapLineVia.includes("Zwischenstopp"), true);
  assert.equal(de.tapLineVia.includes("Alt-Klick"), true);
  assert.equal(de.tapLineVia.includes("Höhenprofil"), true);
  assert.equal(de.planUndo, "Rückgängig");
  assert.equal(de.planRedo, "Wiederholen");
  assert.equal(discoverUi("en").planUndo, "Undo");
  assert.equal(discoverUi("en").planRedo, "Redo");
  assert.ok(de.planLineCoach.includes("Linie"));
  assert.ok(de.planLineCoach.includes("Halten"));
  assert.ok(de.planLineCoach.includes("Höhenprofil"));
  assert.ok(de.planLineCoachShort.includes("Halten"));
  assert.ok(de.planLineCoachAdopt.includes("merken"));
  assert.equal(de.planMapSteep, "Steil");
  assert.equal(de.planMapUnknown, "Unbekannt");
  assert.equal(discoverUi("en").planMapUnknown, "Unknown");
  assert.equal(
    discoverUi("en").variantValhallaOnly,
    "Flatter and more gravel need a live route — this is the planned line.",
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
    de.honestyFarmTail,
    "Kein Weg bis zum Pin — Ziel liegt an der Straße.",
  );
  assert.equal(
    discoverUi("en").honestyRoad,
    "Route mostly follows roads — tap a trail on the map and attach it.",
  );
  assert.equal(
    discoverUi("en").honestyCycleway,
    "Little dedicated bike path — the live route often stays on the road.",
  );
  assert.equal(
    discoverUi("en").honestyFarmTail,
    "No path all the way to the pin — destination is on the street.",
  );
  assert.equal(
    discoverUi("en").honestyFarmMid,
    "Parts of the route follow farm tracks — set the destination closer to a street.",
  );
  assert.equal(
    discoverUi("de").lastDestChip("Kino"),
    "Letztes Ziel: Kino",
  );
  assert.equal(discoverUi("en").lastDestUndo, "Undo");
  assert.equal(
    discoverUi("de").endSetComputing,
    "Ziel gesetzt — Route wird berechnet",
  );
  assert.equal(
    discoverUi("de").destSetWaitingGps,
    "Ziel gesetzt — Start ist dein Standort",
  );
  assert.equal(discoverUi("de").planLineCoachOk, "Verstanden");
  assert.ok(discoverUi("de").planStopSetHint.includes("Stopp gesetzt"));
  assert.ok(discoverUi("en").planStopSetHint.toLowerCase().includes("stop"));
  assert.equal(
    discoverUi("de").lastDestApplied,
    "Letztes Ziel übernommen.",
  );
  assert.equal(
    discoverUi("en").lastDestApplied,
    "Last destination applied.",
  );
  assert.equal(discoverUi("en").placeOnRoute, "Include on route");
  for (const lang of langs) {
    const d = discoverUi(lang);
    for (const line of [d.honestyRoad, d.honestyCycleway, d.honestyFarmTail, d.honestyFarmMid]) {
      const lower = line.toLowerCase();
      assert.ok(!lower.includes("graphhopper"), `${lang}: ${line}`);
      assert.ok(!lower.includes("valhalla"), `${lang}: ${line}`);
      assert.ok(!lower.includes("osrm"), `${lang}: ${line}`);
    }
  }
  const mapped = discoverStatus(
    `12.3 km · 45 min · ${de.honestyFarmTail}`,
    "en",
  );
  assert.ok(mapped.includes("No path all the way to the pin"));
  const mappedMid = discoverStatus(
    `12.3 km · 45 min · ${de.honestyFarmMid}`,
    "en",
  );
  assert.ok(mappedMid.includes("farm tracks"));
  assert.ok(!mapped.toLowerCase().includes("graphhopper"));
  assert.ok(!mapped.toLowerCase().includes("valhalla"));
  assert.ok(!mapped.toLowerCase().includes("osrm"));
  assert.ok(de.outdooractive(3).includes("Outdooractive"));
}

function testTrailUnsuitableDoor() {
  assert.ok(discoverUi("de").trailUnsuitable("Gravel").includes("Stand"));
  assert.ok(!discoverUi("de").trailUnsuitable("Gravel").includes("Garage"));
  assert.ok(!discoverUi("en").trailUnsuitable("gravel").toLowerCase().includes("garage"));
}

function testSurface() {
  assert.equal(discoverSurfaceLabel("Schotter", "de"), "Schotter");
  assert.equal(discoverSurfaceLabel("Schotter", "en"), "Gravel");
  assert.equal(discoverSurfaceLabel("unknown", "it"), "unknown");
  for (const lang of langs) {
    const d = discoverUi(lang);
    assert.ok(d.recently.length > 1, lang);
    assert.ok(d.setEndCta.length > 1, lang);
    assert.ok(d.closeLoopHint.length > 1, lang);
    assert.ok(d.browserPlanOnly.length > 1, lang);
    assert.ok(!d.inPlanNeedEnd("X").toLowerCase().includes("compute"), lang);
    assert.ok(!d.inPlanNeedEnd("X").includes("berechnen"), lang);
  }
  assert.equal(discoverUi("de").onMapPlace, "Punkt auf der Karte");
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

function testPacksCopy() {
  assert.equal(discoverUi("de").packsTitle, "Routing-Packs");
  assert.ok(discoverUi("de").packsLead.includes("Browser"));
  for (const lang of langs) {
    const d = discoverUi(lang);
    assert.ok(d.packsLead.toLowerCase().includes("app"), lang);
    assert.ok(!d.packsLead.toLowerCase().includes("tuiles"), lang);
  }
}

function testAroundYouCopy() {
  assert.equal(discoverUi("de").aroundYouCta, "Hier rundherum");
  assert.equal(
    discoverUi("de").aroundYouLoop,
    "Rundkurs um dich · OSM-Wege",
  );
  assert.equal(
    discoverUi("de").aroundYouHint,
    "Rundkurs auf OSM-Wegen — kein Trailforks-Trail",
  );
  for (const lang of langs) {
    const d = discoverUi(lang);
    const blob = [
      d.aroundYouCta,
      d.aroundYouAnother,
      d.aroundYouLoop,
      d.aroundYouHint,
      d.aroundYouBusy,
      d.aroundYouFail,
      d.aroundYouSport,
      d.aroundYouNeedGps,
      d.aroundYouOffline,
      d.aroundYouUncertain,
      d.aroundYouUncertainShort,
      d.aroundYouStats("18.2", 61),
      d.aroundYouReasonDuration(61, 60),
      d.aroundYouReasonSurface("Asphalt"),
      d.aroundYouReasonOsm,
      d.savePreview,
      d.fromHereHint,
      d.previewEngine("18 km"),
    ]
      .join(" ")
      .toLowerCase();
    assert.ok(!blob.includes("graphhopper"), lang);
    assert.ok(!blob.includes("valhalla"), lang);
    assert.ok(!blob.includes("osrm"), lang);
    assert.ok(!blob.includes("openrouteservice"), lang);
    assert.ok(!/\bors\b/.test(blob), lang);
    assert.ok(d.aroundYouCta.length > 3, lang);
    assert.ok(d.aroundYouLoop.toLowerCase().includes("osm"), lang);
    assert.ok(!d.aroundYouUncertain.toLowerCase().includes("ors"), lang);
    const stats = d.aroundYouStats("18.2", 61);
    assert.ok(stats.includes("18.2"), lang);
    assert.ok(stats.includes("61"), lang);
    assert.ok(d.aroundYouUncertainShort.includes("12"), lang);
    assert.equal(d.savePreview.length > 2, true, lang);
  }
}

testDeExact();
testBrands();
testStatusMap();
testPins();
testP2Copy();
testGhMinuteLimit();
testHonestyCopy();
testTrailUnsuitableDoor();
testSurface();
testHeatCopy();
testPacksCopy();
testAroundYouCopy();
console.log("discoverUi.test.ts OK");
