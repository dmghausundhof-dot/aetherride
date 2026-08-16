/**
 * Run: npx tsx src/lib/i18n/webChrome.test.ts
 */
import assert from "node:assert/strict";
import { webChrome } from "./webChrome";
import { MARKETING_NAV } from "../nav/marketingNav";

const langs = ["de", "en", "fr", "it"] as const;

function testParity() {
  const de = webChrome("de");
  const keys = Object.keys(de).sort();
  for (const lang of langs) {
    const c = webChrome(lang);
    assert.deepEqual(Object.keys(c).sort(), keys, lang);
    for (const item of MARKETING_NAV) {
      assert.ok(c.marketingNav[item.href], `${lang} ${item.href}`);
    }
    assert.ok(c.hofNav.karte);
    assert.ok(c.hofNav.platz === "Platz", `${lang} Platz stays brand`);
  }
}

function testDeMatchesCurrentChrome() {
  const c = webChrome("de");
  assert.equal(c.marketingNav["/produkt"], "Produkt");
  assert.equal(c.toHof, "Zum Hof");
  assert.equal(c.signIn, "Anmelden");
  assert.equal(c.arriveAtHof, "Am Hof ankommen");
  assert.equal(c.hofNav.shop, "Laden");
  assert.equal(c.dataPrivacy, "Daten & Privatsphäre");
  assert.equal(c.profile, "Profil");
  assert.equal(c.emptyStand, "Leerer Stand");
  assert.equal(c.discoverApp, "App entdecken");
  assert.equal(c.maintenanceDue(3), "3 Wartungen fällig");
}

function testEnFrItChrome() {
  assert.equal(webChrome("en").toHof, "To Home");
  assert.equal(webChrome("en").profile, "Profile");
  assert.equal(webChrome("en").stillToHof, "To Home anyway");
  assert.equal(webChrome("fr").arriveAtHof, "Arriver");
  assert.equal(webChrome("fr").hofNav.werkstatt, "Atelier");
  assert.equal(webChrome("it").profile, "Profilo");
  assert.equal(webChrome("it").hofNav.karte, "Mappa");
  assert.equal(webChrome("de").loading, "Laden…");
}

testParity();
testDeMatchesCurrentChrome();
testEnFrItChrome();
console.log("webChrome.test.ts OK");
