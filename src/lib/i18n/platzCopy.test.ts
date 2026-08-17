/**
 * Run: npx tsx src/lib/i18n/platzCopy.test.ts
 */
import assert from "node:assert/strict";
import {
  formatPlatzGroupWhen,
  platzCopy,
  platzNote,
  platzShareHonesty,
} from "./platzCopy";

const langs = ["de", "en", "fr", "it"] as const;

function testDe() {
  const g = platzCopy("de");
  assert.equal(g.createGroup, "Gruppe anlegen");
  assert.equal(g.stimmenTitle, "Stimmen");
  assert.equal(g.visPublic, "Freigegeben");
  assert.equal(g.addRoute, "Route hinzufügen");
  assert.ok(g.addRouteHint.includes("ohne Pin"));
  assert.ok(g.startNone.includes("ohne Pin"));
  assert.ok(!g.addRouteHint.toLowerCase().includes("heidelberg"));
  assert.equal(g.intoMappe, "In die Mappe legen");
  assert.ok(g.inviteHint.includes("Freunde"));
  assert.ok(g.inviteHint.includes("Deine Gruppen bleiben"));
  assert.equal(g.collectionTours(1), "1 Tour");
  assert.equal(g.collectionTours(2), "2 Touren");
  assert.equal(g.collectionsTitle, "Sammlungen");
  assert.equal(g.stimmenTitle, "Stimmen");
  assert.notEqual(g.collectionsTitle, g.collectionsTitle.toUpperCase());
  assert.equal(g.joinWithLink, "Mit Link beitreten");
  assert.equal(g.joinField, "Einladungslink");
  assert.ok(g.joinHint.includes("Einladungslink"));
  assert.ok(!g.joinHint.toLowerCase().includes("token"));
  assert.ok(g.collectionsHint.includes("Katalog"));
}

function testParity() {
  const de = platzCopy("de");
  for (const lang of langs) {
    const g = platzCopy(lang);
    assert.equal(g.stimmenTitle, "Stimmen", lang);
    assert.ok(g.shareProfile("https://x").includes("Platz"), lang);
    assert.ok(g.created("x").includes("x"), lang);
    assert.ok(g.collectionTours(3).includes("3"), lang);
    assert.notEqual(g.collectionTours(1), g.collectionTours(2), lang);
    assert.ok(g.addToCollection.length > 0, lang);
    assert.ok(g.intoMappe.includes("Mappe"), lang);
    assert.ok(g.startNone.length > 8, lang);
    assert.ok(g.startFromGps("1").includes("1"), lang);
    assert.ok(g.startFromMap("1").includes("1"), lang);
    assert.ok(g.importGpx.includes("GPX"), lang);
    assert.ok(g.notePlaceholder.includes("Stimme"), lang);
    assert.ok(!/\b(token|jeton)\b/i.test(g.joinHint), lang);
  }
  assert.ok(platzCopy("en").joinHint.includes("invitation link"));
  assert.ok(platzCopy("fr").joinHint.includes("lien d’invitation"));
  assert.ok(platzCopy("it").joinHint.includes("link di invito"));
  assert.notEqual(de.inviteHint, platzCopy("en").inviteHint);
}

function testNotes() {
  const de =
    "Nicht eingeloggt — nur auf diesem Gerät. Join auf dem Server braucht Login.";
  assert.equal(platzNote(de, "de"), de);
  assert.ok(platzNote(de, "en").toLowerCase().includes("signed"));
  assert.equal(platzNote("unknown-de-error", "fr"), "unknown-de-error");
}

function testWhen() {
  const start = new Date("2026-08-16T10:00:00+02:00");
  const end = new Date("2026-08-16T13:00:00+02:00");
  const now = new Date("2026-08-16T09:00:00+02:00");
  const de = formatPlatzGroupWhen(
    start.toISOString(),
    end.toISOString(),
    "de",
    now,
  );
  const en = formatPlatzGroupWhen(
    start.toISOString(),
    end.toISOString(),
    "en",
    now,
  );
  assert.ok(de.includes("heute"), de);
  assert.ok(en.includes("today"), en);
  assert.ok(de.includes("h"), de);
  assert.ok(en.includes("h"), en);
  assert.notEqual(de, en);
}

function testHonesty() {
  const de = platzShareHonesty(true, false, "de");
  const en = platzShareHonesty(true, false, "en");
  assert.ok(de.includes("Katalog"));
  assert.ok(en.toLowerCase().includes("catalogue"));
  assert.notEqual(de, en);
}

testDe();
testParity();
testNotes();
testWhen();
testHonesty();
console.log("platzCopy.test.ts OK");
