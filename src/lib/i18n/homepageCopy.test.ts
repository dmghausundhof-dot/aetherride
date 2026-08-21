/**
 * Run: npx tsx src/lib/i18n/homepageCopy.test.ts
 */
import assert from "node:assert/strict";
import {
  HOME_DISCIPLINES,
  HOME_DOOR_STORIES,
  HOME_GUIDES,
  HOME_HONESTY,
  HOME_INTRO,
  HOME_LEVERS,
} from "../content/homepage";
import { homepageCopy } from "./homepageCopy";

const langs = ["de", "en", "fr", "it", "nl"] as const;

function testDeMatchesSource() {
  const h = homepageCopy("de");
  assert.equal(h.intro.title, HOME_INTRO.title);
  assert.equal(h.intro.lead, HOME_INTRO.lead);
  assert.deepEqual([...h.intro.paragraphs], [...HOME_INTRO.paragraphs]);
  assert.equal(h.honesty.title, HOME_HONESTY.title);
  assert.ok(h.honesty.notYet.some((line) => /Impressum/i.test(line)));
  assert.ok(!JSON.stringify(h.honesty).includes("Musterstraße"));
  assert.deepEqual(
    h.disciplines.map((d) => d.href),
    HOME_DISCIPLINES.map((d) => d.href),
  );
  assert.deepEqual(
    h.doors.map((d) => d.href),
    HOME_DOOR_STORIES.map((d) => d.href),
  );
  assert.deepEqual([...h.guides.slugs], [...HOME_GUIDES.slugs]);
  assert.equal(h.levers.length, HOME_LEVERS.length);
  assert.equal(h.homeFaq.length, 3);
  assert.equal(h.ui.heroTagline, "Das Rad wohnt hier.");
  assert.equal(h.heroCta, "Zur Karte");
}

function testParity() {
  const de = homepageCopy("de");
  for (const lang of langs) {
    const h = homepageCopy(lang);
    assert.equal(h.disciplines.length, de.disciplines.length, lang);
    assert.equal(h.doors.length, de.doors.length, lang);
    assert.equal(h.levers.length, de.levers.length, lang);
    assert.equal(h.homeFaq.length, 3, lang);
    assert.equal(h.webSurfaces.length, de.webSurfaces.length, lang);
    assert.equal(h.appSurfaces.length, de.appSurfaces.length, lang);
    assert.equal(h.journeySteps.length, de.journeySteps.length, lang);
    assert.deepEqual(
      h.disciplines.map((d) => d.href),
      de.disciplines.map((d) => d.href),
      lang,
    );
    assert.deepEqual(
      h.doors.map((d) => d.href),
      de.doors.map((d) => d.href),
      lang,
    );
    assert.deepEqual(
      h.levers.map((d) => d.href),
      de.levers.map((d) => d.href),
      lang,
    );
    assert.deepEqual([...h.guides.slugs], [...de.guides.slugs], lang);
    assert.equal(homepageCopy("de").doors[2]?.title, "Touren");
    assert.equal(homepageCopy("en").doors[2]?.title, "Tours");
    assert.equal(homepageCopy("fr").doors[2]?.title, "Parcours");
    assert.equal(homepageCopy("it").doors[2]?.title, "Percorsi");
    assert.equal(homepageCopy("nl").doors[2]?.title, "Tochten");
    assert.equal(h.voices.kicker, "Stimmen", `${lang} Stimmen stays brand`);
    assert.ok(h.ui.heroLead("X").includes("X"));
    assert.ok(!JSON.stringify(h.honesty).includes("Musterstraße"), lang);
    const offlineApp = h.appSurfaces.find((s) =>
      /offline|hors ligne/i.test(s.title),
    );
    assert.ok(offlineApp, `${lang} offline app surface`);
    assert.match(offlineApp!.body, /pack/i, `${lang} pack not region`);
    assert.doesNotMatch(
      offlineApp!.body,
      /\b(region|région|regio)\b/i,
      `${lang} no region noun`,
    );
  }
}

function testChromeLangs() {
  assert.equal(homepageCopy("en").ui.heroTagline, "The bike lives here.");
  assert.equal(homepageCopy("fr").ui.trustOk, "Compris");
  assert.equal(homepageCopy("it").cta.title.includes("bici"), true);
  assert.ok(homepageCopy("en").pricing.pro.includes("€") || homepageCopy("en").pricing.pro.length > 4);
  assert.ok(homepageCopy("fr").intro.lead.includes("tu "));
  assert.ok(homepageCopy("nl").intro.lead.includes("je "));
  assert.ok(/Enduro/i.test(homepageCopy("de").bikesLine));
}

testDeMatchesSource();
testParity();
testChromeLangs();
console.log("homepageCopy.test.ts OK");
