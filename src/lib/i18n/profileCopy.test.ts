/**
 * Run: npx tsx src/lib/i18n/profileCopy.test.ts
 */
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { profileCopy, publicDisciplineLabel } from "./profileCopy";
import {
  GARAGE_ERR_CATALOG,
  GARAGE_ERR_FREE_ONE,
  presentGarageError,
} from "./addBikeCopy";

const langs = ["de", "en", "fr", "it", "nl"] as const;

function testParity() {
  const keys = Object.keys(profileCopy("de")).sort();
  for (const lang of langs) {
    assert.deepEqual(Object.keys(profileCopy(lang)).sort(), keys, lang);
  }
}

function testArbHeadings() {
  assert.equal(profileCopy("de").account, "Konto");
  assert.equal(profileCopy("en").account, "Account");
  assert.equal(profileCopy("fr").signOut, "Se déconnecter");
  assert.equal(profileCopy("it").deleteAccount, "Elimina account");
  assert.equal(profileCopy("nl").publicTitle, "Openbaar profiel");
  assert.equal(profileCopy("en").publicMissingTitle, "Profile is not public");
  assert.equal(profileCopy("de").publicEditorial, "Editorial-Beispiel");
  assert.doesNotMatch(profileCopy("en").publicRidesAgg(3), /Fahrten/);
  assert.equal(publicDisciplineLabel("road", "en"), "Road");
  assert.equal(publicDisciplineLabel("mtb", "fr"), "VTT");
  assert.equal(profileCopy("en").styleAggressive, "Aggressive");
  assert.equal(profileCopy("de").skill(3), "Können (3 / 5)");
  assert.equal(profileCopy("en").skill(3), "Skill (3 / 5)");
  assert.doesNotMatch(profileCopy("en").planHint, /Rad, Basis/);
  assert.doesNotMatch(profileCopy("en").deleteConfirmBody, /Remote-Konto/);
}

function testStoreErrors() {
  assert.equal(
    presentGarageError(GARAGE_ERR_FREE_ONE, "en"),
    "Free includes one bike. Unlock Pro under Profile."
  );
  assert.equal(presentGarageError(GARAGE_ERR_CATALOG, "en"), "Catalog bike not found");
  assert.equal(presentGarageError("other", "en"), "other");
}

function testWiring() {
  const page = readFileSync("src/app/profile/page.tsx", "utf8");
  assert.ok(page.includes("profileCopy"), "profile page uses copy");
  assert.ok(!page.includes("Konto löschen"), "profile page has no hardcoded delete");
  assert.ok(!page.includes("Erfahrungsstufe"), "profile page has no hardcoded skill");
  const pub = readFileSync(
    "src/components/community/PublicProfilePanel.tsx",
    "utf8"
  );
  assert.ok(pub.includes("profileCopy"), "public profile uses copy");
  assert.ok(!pub.includes("Öffentliches Profil"), "public profile heading is copy");
  const view = readFileSync(
    "src/app/u/[handle]/PublicProfileView.tsx",
    "utf8"
  );
  assert.ok(view.includes("profileCopy"), "public view uses copy");
  assert.ok(view.includes("publicDisciplineLabel"), "sports use discipline labels");
  assert.ok(!view.includes("Profil nicht öffentlich"), "missing title is copy");
  assert.ok(!view.includes("Editorial-Beispiel"), "editorial kicker is copy");
  const openRide = readFileSync("src/app/open/ride/page.tsx", "utf8");
  assert.ok(openRide.includes("openRideCopy"), "open-ride uses copy");
  assert.ok(!openRide.includes("App öffnen"), "open-ride title is copy");
  const wizard = readFileSync("src/components/garage/AddBikeWizard.tsx", "utf8");
  assert.ok(wizard.includes("presentGarageError"), "wizard maps store errors");
  const store = readFileSync("src/store/useAppStore.ts", "utf8");
  assert.ok(store.includes("GARAGE_ERR_FREE_ONE"), "store throws stable free-one key");
}

testParity();
testArbHeadings();
testStoreErrors();
testWiring();
console.log("profileCopy.test.ts OK");
