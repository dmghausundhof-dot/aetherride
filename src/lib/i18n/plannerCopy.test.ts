/**
 * Run: npx tsx src/lib/i18n/plannerCopy.test.ts
 */
import assert from "node:assert/strict";
import {
  PLANNER_STATUS_DE,
  plannerCopy,
  plannerStatus,
} from "./plannerCopy";

function testDe() {
  const p = plannerCopy("de");
  assert.equal(p.needStartEnd, "Start und Ziel setzen");
  assert.equal(p.inMappe, "In der Mappe");
  assert.ok(p.tourIdeaLoaded("Alster").includes("Alster"));
}

function testParity() {
  for (const lang of ["de", "en", "fr", "it"] as const) {
    const p = plannerCopy(lang);
    assert.ok(p.inMappe.includes("Mappe"), lang);
    assert.equal(p.via, "Via", lang);
    assert.ok(p.tourIdeaLoaded("X").includes("X"), lang);
  }
  assert.notEqual(plannerCopy("de").navOffline, plannerCopy("en").navOffline);
}

function testStatus() {
  assert.equal(
    plannerStatus(PLANNER_STATUS_DE.inMappe, "de"),
    PLANNER_STATUS_DE.inMappe,
  );
  assert.ok(plannerStatus(PLANNER_STATUS_DE.inMappe, "en").includes("Mappe"));
  const de = plannerCopy("de").tourIdeaLoaded("Neckar");
  assert.ok(plannerStatus(de, "en").includes("Neckar"));
  assert.equal(plannerStatus("12.3 km · valhalla", "fr"), "12.3 km · valhalla");
}

testDe();
testParity();
testStatus();
console.log("plannerCopy.test.ts OK");
