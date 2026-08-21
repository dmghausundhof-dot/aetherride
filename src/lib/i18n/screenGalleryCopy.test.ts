/**
 * Run: npx tsx src/lib/i18n/screenGalleryCopy.test.ts
 */
import assert from "node:assert/strict";
import { SCREEN_GALLERY } from "../content/screenGallery";
import { screenGalleryCopy } from "./screenGalleryCopy";

const langs = ["de", "en", "fr", "it", "nl"] as const;

function testDe() {
  const g = screenGalleryCopy("de");
  assert.deepEqual(
    g.shots.map((s) => s.src),
    SCREEN_GALLERY.map((s) => s.src),
  );
}

function testParity() {
  const de = screenGalleryCopy("de");
  for (const lang of langs) {
    const g = screenGalleryCopy(lang);
    assert.deepEqual(
      g.shots.map((s) => s.src),
      de.shots.map((s) => s.src),
      lang,
    );
    const toursDoor = {
      de: "Touren",
      en: "Tours",
      fr: "Parcours",
      it: "Percorsi",
      nl: "Tochten",
    } as const;
    assert.ok(g.hint.includes(toursDoor[lang]), lang);
  }
}

function testNl() {
  assert.equal(screenGalleryCopy("nl").shots[1].door, "Kaart");
}

testDe();
testParity();
testNl();
console.log("screenGalleryCopy.test.ts OK");
