/**
 * Run: npx tsx src/lib/i18n/dieBoxCopy.test.ts
 */
import assert from "node:assert/strict";
import {
  dieBoxChipLabel,
  dieBoxCopy,
  dieBoxReadinessUi,
  dieBoxSentenceUi,
  lastRideHeroUi,
  localizeDieBoxItem,
} from "./dieBoxCopy";
import type { DieBoxPlan, DieBoxTodayItem } from "@/lib/garage/dieBox";
import type { Bike } from "@/types";

function testParity() {
  const keys = Object.keys(dieBoxCopy("de")).sort();
  for (const lang of ["de", "en", "fr", "it"] as const) {
    assert.deepEqual(Object.keys(dieBoxCopy(lang)).sort(), keys, lang);
  }
}

function testDeFallback() {
  const c = dieBoxCopy("de");
  assert.equal(c.ready, "Bereit");
  assert.equal(c.nothingDueMonday, "Montag-bereit — Licht und Kette sitzen.");
  assert.equal(c.setActiveTitle, "Dieses Rad nach vorn");
  assert.equal(dieBoxChipLabel("Licht", "de"), "Licht");
  assert.equal(dieBoxChipLabel("Kette", "de"), "Kette");
  assert.equal(dieBoxChipLabel("700c", "de"), "700c");
  assert.equal(dieBoxReadinessUi("unknown", "de"), "Neu hier");
  assert.equal(dieBoxChipLabel("Kette", "de"), "Kette");
  assert.equal(dieBoxChipLabel("700c", "de"), "700c");
  assert.equal(dieBoxReadinessUi("unknown", "de"), "Neu hier");
}

function testChrome() {
  assert.equal(dieBoxChipLabel("Licht", "en"), "Lights");
  assert.equal(dieBoxChipLabel("Licht", "fr"), "Éclairage");
  assert.equal(dieBoxChipLabel("Licht", "it"), "Luci");
  assert.equal(dieBoxChipLabel("CSC", "fr"), "CSC");
  assert.equal(dieBoxChipLabel("SAG", "it"), "SAG");
  const item: DieBoxTodayItem = {
    id: "setActive",
    title: "Dieses Rad nach vorn",
    hint: "Eines steht in der Box — Umschalten holt es nach vorn.",
    cta: "Als aktiv setzen",
  };
  assert.equal(localizeDieBoxItem(item, "en").title, "Bring this bike forward");
  assert.equal(localizeDieBoxItem(item, "de").title, item.title);
}

function testLastRide() {
  assert.equal(lastRideHeroUi(undefined, "en"), null);
  assert.equal(
    lastRideHeroUi(
      { id: "r", bikeId: "b", startTime: "2026-01-01", distanceM: 12400 } as never,
      "de",
    ),
    "Zuletzt 12.4 km",
  );
  assert.equal(
    lastRideHeroUi(
      { id: "r", bikeId: "b", startTime: "2026-01-01", distanceM: 0 } as never,
      "en",
    ),
    "Last out — no GPS track",
  );
}

function testSentence() {
  const bike = { name: "Grizl", travelFrontMm: 0, travelRearMm: 0 } as Bike;
  const plan = {
    kind: "urban",
    readiness: "ready",
    chips: [],
    hasElectricAssist: false,
    showParkTrail: false,
  } as unknown as DieBoxPlan;
  assert.equal(
    dieBoxSentenceUi(plan, bike, "de"),
    "Grizl wohnt hier · Montag-bereit",
  );
  assert.equal(
    dieBoxSentenceUi(plan, bike, "en"),
    "Grizl lives here · Monday-ready",
  );
}

testParity();
testDeFallback();
testChrome();
testLastRide();
testSentence();
console.log("dieBoxCopy.test.ts OK");
