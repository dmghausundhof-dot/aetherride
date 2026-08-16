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
} from "../content/homepage";
import { homepageCopy } from "./homepageCopy";

const langs = ["de", "en", "fr", "it"] as const;

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
}

function testParity() {
  const de = homepageCopy("de");
  for (const lang of langs) {
    const h = homepageCopy(lang);
    assert.equal(h.disciplines.length, de.disciplines.length, lang);
    assert.equal(h.doors.length, de.doors.length, lang);
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
    assert.deepEqual([...h.guides.slugs], [...de.guides.slugs], lang);
    assert.equal(h.doors[2]?.title, "Platz", `${lang} Platz stays brand`);
    assert.equal(h.voices.kicker, "Stimmen", `${lang} Stimmen stays brand`);
    assert.ok(h.ui.heroLead("X").includes("X"));
    assert.ok(!JSON.stringify(h.honesty).includes("Musterstraße"), lang);
  }
}

function testChromeLangs() {
  assert.equal(homepageCopy("en").ui.heroTagline, "The bike lives here.");
  assert.equal(homepageCopy("fr").ui.trustOk, "Compris");
  assert.equal(homepageCopy("it").cta.title.includes("bici"), true);
  assert.ok(homepageCopy("en").pricing.pro.includes("€"));
  assert.ok(homepageCopy("fr").intro.lead.includes("tu "));
}

testDeMatchesSource();
testParity();
testChromeLangs();
console.log("homepageCopy.test.ts OK");
