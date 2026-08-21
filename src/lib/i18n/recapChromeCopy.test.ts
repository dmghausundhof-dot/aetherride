/**
 * Run: npx tsx src/lib/i18n/recapChromeCopy.test.ts
 */
import assert from "node:assert/strict";
import {
  localizeActivityRecTitle,
  localizeAssistSegment,
  localizeSetupCondition,
  recapChromeCopy,
} from "./recapChromeCopy";
import { rideSportLabel } from "./rideSportLabel";

const langs = ["de", "en", "fr", "it", "nl"] as const;

function testParity() {
  const keys = Object.keys(recapChromeCopy("de")).sort();
  for (const lang of langs) {
    assert.deepEqual(Object.keys(recapChromeCopy(lang)).sort(), keys, lang);
  }
}

function testAssist() {
  const en = recapChromeCopy("en");
  assert.equal(
    localizeAssistSegment("Schätzung: TOUR (Anfahrt)", en),
    "Estimate: TOUR (approach)"
  );
  assert.ok(
    localizeAssistSegment("Schätzung: SPORT (Steigung, Konfidenz 55 %)", en)
      .includes("55")
  );
  assert.ok(
    localizeAssistSegment("Schätzung: SPORT (Steigung, 55 %)", en).includes("55")
  );
}

function testRecs() {
  const en = recapChromeCopy("en");
  assert.equal(
    localizeActivityRecTitle("Kette — wegen Verschleißprognose", en).includes(
      "wear"
    ),
    true
  );
  assert.equal(localizeActivityRecTitle("Wartung überfällig", en), "Maintenance overdue");
}

function testConditionAndSport() {
  const en = recapChromeCopy("en");
  assert.equal(localizeSetupCondition("wet", en), "Wet");
  assert.equal(rideSportLabel("road", "en"), "Road");
  assert.equal(rideSportLabel("road", "de"), "Rennrad");
}

testParity();
testAssist();
testConditionAndSport();
testRecs();
console.log("recapChromeCopy.test.ts OK");
