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
  assert.equal(g.visAll, "Alle");
  assert.equal(g.addRoute, "Route hinzufügen");
  assert.equal(g.intoMappe, "In die Mappe legen");
  assert.ok(g.inviteHint.includes("HUD"));
  assert.ok(g.noTrackMappe.includes("Mappe"));
}

function testParity() {
  const de = platzCopy("de");
  for (const lang of langs) {
    const g = platzCopy(lang);
    assert.equal(g.stimmenTitle, "Stimmen", lang);
    assert.ok(g.shareProfile("https://x").includes("Platz"), lang);
    assert.ok(g.created("x").includes("x"), lang);
    assert.ok(g.collectionTours(3).includes("3"), lang);
    assert.ok(g.intoMappe.includes("Mappe"), lang);
    assert.ok(g.importGpx.includes("GPX"), lang);
    assert.ok(g.notePlaceholder.includes("Stimme"), lang);
  }
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
