/**
 * Homepage is five rider blocks — not a manifesto.
 * Run: npx tsx src/lib/landing/homepageSections.test.ts
 */
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { FEATURED_TOUR_IDS } from "../catalog/publicTours";
import { homepageCopy } from "../i18n/homepageCopy";
import { MARKETING_NAV } from "../nav/marketingNav";

const page = readFileSync("src/app/(marketing)/page.tsx", "utf8");
const body = readFileSync("src/components/landing/HomePageBody.tsx", "utf8");
const hero = readFileSync("src/components/landing/LandingHero.tsx", "utf8");

assert.ok(page.includes("LandingHero"), "hero stays");
assert.ok(page.includes("HomePageBody"), "body stays");
assert.ok(!page.includes("ServiceCheckSection"), "no service-check demo");
assert.ok(!page.includes("ScreenGallery"), "no 7-card gallery");
assert.ok(!page.includes("HomePageCta"), "no manifesto CTA stack");
assert.ok(!page.includes("KartenCoverageSection"), "no duplicate nine-sheet map");

assert.ok(hero.includes("heroTagline"), "hero title is Das Rad wohnt hier");
assert.ok(hero.includes("/discover"), "primary CTA is the map");
assert.ok(!hero.includes("/home"), "no Zum Hof CTA");
assert.ok(!hero.includes("toHof"), "no second Hof button");
assert.ok(!hero.includes("HERO_DOORS"), "no four-door chips");

assert.ok(body.includes("levers"), "three levers");
assert.ok(body.includes("productScreen"), "one real screen");
assert.ok(body.includes("featuredPublicTours"), "tour ideas");
assert.ok(body.includes("homeFaq"), "short FAQ");
assert.ok(body.includes("honesty"), "stand");
assert.ok(!body.includes("EDITORIAL_REVIEWS"), "no Stimmen quotes");
assert.ok(!body.includes("/pricing"), "no pricing sell");
assert.ok(!body.includes("/community"), "no community block");
assert.ok(!body.includes("HOME_FAQ_IDS"), "FAQ is inline, not store theater");
assert.ok(body.includes('name="karte"'), "web/app split keeps FlowLine karte mark");

assert.equal(FEATURED_TOUR_IDS[0], "r-heidelberg-road");
assert.equal(FEATURED_TOUR_IDS[1], "r-odenwald-gravel");
assert.ok(!FEATURED_TOUR_IDS.includes("r-hamburg-alster"));
assert.ok(!FEATURED_TOUR_IDS.includes("r-heidelberg-city"));

assert.ok(!MARKETING_NAV.some((i) => i.href === "/community"));
assert.ok(!MARKETING_NAV.some((i) => i.href === "/pricing"));

const de = homepageCopy("de");
assert.equal(de.levers.length, 3);
assert.equal(de.homeFaq.length, 3);
assert.ok(/Enduro/i.test(de.bikesLine));
assert.ok(!JSON.stringify(de.homeFaq).includes("6,99"));
assert.ok(!JSON.stringify(de.honesty).includes("Stripe"));

console.log("homepageSections.test.ts OK");
