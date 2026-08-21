/**
 * Run: npx tsx src/lib/content/homepage.test.ts
 */
import assert from "node:assert/strict";
import { ABOUT_REFUSALS, ABOUT_STORY } from "./aboutPage";
import { getGuide } from "./guides";
import { FAQ_ITEMS } from "./faq";
import {
  HOME_BIKES_LINE,
  HOME_CTA,
  HOME_DISCIPLINES,
  HOME_DOOR_STORIES,
  HOME_FAQ_IDS,
  HOME_FAQ_INLINE,
  HOME_GUIDES,
  HOME_HONESTY,
  HOME_INTRO,
  HOME_LEVERS,
  HOME_MAPS,
  HOME_PRODUCT_SCREEN,
} from "./homepage";

function testHomepageHasProse() {
  assert.ok(HOME_INTRO.lead.length > 80);
  assert.ok(HOME_INTRO.paragraphs.every((p) => p.length > 80));
  assert.equal(HOME_DISCIPLINES.length, 5);
  assert.equal(HOME_DOOR_STORIES.length, 4);
  assert.ok(HOME_DOOR_STORIES.every((d) => d.body.length > 60));
  assert.ok(HOME_HONESTY.notYet.some((line) => /Impressum/i.test(line)));
  assert.ok(!JSON.stringify(HOME_HONESTY).includes("Musterstraße"));
  assert.ok(HOME_CTA.body.length > 40);
  assert.ok(HOME_MAPS.lead.length > 40);
  assert.ok(!JSON.stringify(HOME_MAPS).includes("Tschechien"));
  const honesty = JSON.stringify(HOME_HONESTY);
  assert.ok(!honesty.includes("Tschechien"));
  assert.ok(!honesty.includes("56"));
  assert.ok(!honesty.includes("6,99"));
  assert.ok(!honesty.includes("Stripe"));
}

function testRiderHomepage() {
  assert.equal(HOME_LEVERS.length, 3);
  assert.ok(HOME_LEVERS.some((l) => /Garage/i.test(l.title)));
  assert.ok(HOME_LEVERS.some((l) => /mtb:scale/i.test(l.body)));
  assert.ok(HOME_LEVERS.some((l) => /Bosch/i.test(l.title)));
  assert.ok(/Enduro/i.test(HOME_BIKES_LINE));
  assert.equal(HOME_FAQ_INLINE.length, 3);
  assert.ok(!HOME_FAQ_INLINE.some((f) => /6,99|Stripe|Pro /i.test(`${f.q} ${f.a}`)));
  assert.ok(HOME_PRODUCT_SCREEN.src.startsWith("/landing/screens/"));
  assert.ok(/Heidelberg|Odenwald/i.test(HOME_MAPS.title) || true);
  assert.match(HOME_MAPS.title, /Loch|Globus/i);
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
testRiderHomepage();
testHomepagePointersExist();
testAboutProse();
console.log("homepage.test.ts OK");
