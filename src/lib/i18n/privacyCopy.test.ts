/**
 * Run: npx tsx src/lib/i18n/privacyCopy.test.ts
 */
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { privacyCopy, presentPrivacyStatus } from "./privacyCopy";

const langs = ["de", "en", "fr", "it", "nl"] as const;

function testParity() {
  const keys = Object.keys(privacyCopy("de")).sort();
  for (const lang of langs) {
    const c = privacyCopy(lang);
    assert.deepEqual(Object.keys(c).sort(), keys, lang);
    assert.ok(c.consent.raw_data_upload.title, `${lang} raw title`);
    assert.ok(c.consent.health_data.description, `${lang} health body`);
  }
}

function testArb() {
  assert.equal(privacyCopy("de").exportGpx, "Letzten Ride als GPX");
  assert.equal(privacyCopy("en").exportGpx, "Last ride as GPX");
  assert.equal(privacyCopy("fr").consents, "Consentements");
  assert.equal(privacyCopy("it").familyTitle, "Famiglia in bici");
  assert.equal(privacyCopy("nl").zones, "Privacyzones");
  assert.ok(privacyCopy("en").noZonesWeb.includes("app"));
  assert.doesNotMatch(privacyCopy("en").noZonesWeb, /Heimat-Zone/);
  assert.equal(
    presentPrivacyStatus("Strava OAuth nicht konfiguriert.", "en"),
    "Strava OAuth is not configured."
  );
  assert.equal(
    presentPrivacyStatus("Bei Strava hochgeladen (mit Track).", "en"),
    "Uploaded to Strava (with track)."
  );
}

function testWiring() {
  const page = readFileSync("src/app/privacy/page.tsx", "utf8");
  assert.ok(page.includes("privacyCopy"), "privacy page uses copy");
  assert.ok(!page.includes("Einwilligungen"), "consents heading is copy");
  assert.ok(!page.includes("Familie am Rad"), "family heading is copy");
  assert.ok(!page.includes("Letzten Ride als GPX"), "gpx button is copy");
  assert.ok(
    page.includes("noZonesWeb"),
    "web empty zones stay honest (app map)"
  );
  const stand = readFileSync("src/components/home/HofStand.tsx", "utf8");
  assert.ok(stand.includes("hofSportLabel("), "hof stand uses sport label");
  assert.ok(stand.includes("lang"), "hof stand passes chrome lang");
}

testParity();
testArb();
testWiring();
console.log("privacyCopy.test.ts OK");
