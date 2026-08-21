/**
 * Run: npx tsx src/lib/i18n/onboardCopy.test.ts
 */
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { onboardCopy } from "./onboardCopy";

const langs = ["de", "en", "fr", "it", "nl"] as const;

function testParity() {
  const keys = Object.keys(onboardCopy("de")).sort();
  for (const lang of langs) {
    const c = onboardCopy(lang);
    assert.deepEqual(Object.keys(c).sort(), keys, lang);
    assert.ok(c.blurbs.urban, `${lang} urban blurb`);
    assert.ok(c.blurbs.emtb, `${lang} emtb blurb`);
  }
}

function testArb() {
  assert.equal(onboardCopy("de").howYouRide, "Wie fährst du?");
  assert.equal(onboardCopy("en").howYouRide, "How do you ride?");
  assert.equal(onboardCopy("fr").later, "Configurer plus tard");
  assert.equal(onboardCopy("it").skip, "Salta");
  assert.equal(onboardCopy("nl").next, "Volgende");
  assert.doesNotMatch(onboardCopy("en").weightHint, /SAG-Vorlagen/);
}

function testWiring() {
  const flow = readFileSync("src/components/OnboardingFlow.tsx", "utf8");
  assert.ok(flow.includes("onboardCopy"), "onboarding uses copy");
  assert.ok(flow.includes("bikeCategoryLabel"), "sports use category labels");
  assert.ok(flow.includes("addBikeBasic"), "Weiter creates a bike");
  assert.ok(
    flow.includes("useState<BikeCategory | null>(null)"),
    "no City/urban default",
  );
  assert.ok(!flow.includes('useState<BikeCategory>("urban")'), "no urban seed");
  assert.ok(!flow.includes("Was fährst du?"), "title is copy");
  assert.ok(!flow.includes("Später einrichten"), "later is copy");
  assert.ok(!flow.includes("showTours"), "no bike-optional fork after pick");
  assert.ok(!flow.includes("workshopAdd"), "Weiter creates, does not send to garage");
}

testParity();
testArb();
testWiring();
console.log("onboardCopy.test.ts OK");
