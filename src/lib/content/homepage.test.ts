/**
 * Run: npx tsx src/lib/content/homepage.test.ts
 */
import assert from "node:assert/strict";
import { getGuide } from "./guides";
import { FAQ_ITEMS } from "./faq";
import {
  HOME_CTA,
  HOME_DISCIPLINES,
  HOME_DOOR_STORIES,
  HOME_FAQ_IDS,
  HOME_GUIDES,
  HOME_HONESTY,
  HOME_INTRO,
  HOME_MAPS,
} from "./homepage";
import { ABOUT_REFUSALS, ABOUT_STORY } from "./aboutPage";

function testHomepageHasProse() {
  assert.ok(HOME_INTRO.lead.length > 80);
  assert.ok(HOME_INTRO.paragraphs.every((p) => p.length > 80));
  assert.equal(HOME_DISCIPLINES.length, 5);
  assert.equal(HOME_DOOR_STORIES.length, 5);
  assert.ok(HOME_DOOR_STORIES.every((d) => d.body.length > 60));
  assert.ok(HOME_HONESTY.notYet.some((line) => /Impressum/i.test(line)));
  assert.ok(!JSON.stringify(HOME_HONESTY).includes("Musterstraße"));
  assert.ok(HOME_CTA.body.length > 40);
  assert.ok(HOME_MAPS.lead.length > 40);
  const honesty = JSON.stringify(HOME_HONESTY);
  assert.ok(honesty.includes("Frankreich"));
  assert.ok(!honesty.includes("56"));
}

function testHomepagePointersExist() {
  for (const slug of HOME_GUIDES.slugs) {
    assert.ok(getGuide(slug), slug);
  }
  const faqIds = new Set(FAQ_ITEMS.map((item) => item.id));
  for (const id of HOME_FAQ_IDS) {
    assert.ok(faqIds.has(id), id);
  }
}

function testAboutProse() {
  assert.equal(ABOUT_STORY.paragraphs.length, 3);
  assert.ok(ABOUT_STORY.paragraphs.every((p) => p.length > 80));
  assert.equal(ABOUT_REFUSALS.length, 3);
}

testHomepageHasProse();
testHomepagePointersExist();
testAboutProse();
console.log("homepage.test.ts OK");
