/**
 * Rider-facing honesty wiring — Onboarding, Match, Stimmen, jargon, Garage.
 * Run: npx tsx src/lib/discover/uxHonesty.web.test.ts
 */
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { hofCopy } from "../home/hofCopy";
import { webChrome } from "../i18n/webChrome";
import { catalogCopy } from "../i18n/catalogCopy";
import { berlinLoopSuggestions } from "./berlinLoops";
import { riderFacingReasons } from "./riderHonesty";

const onboard = readFileSync("src/components/OnboardingFlow.tsx", "utf8");
const reviews = readFileSync("src/components/community/TourReviews.tsx", "utf8");
const card = readFileSync("src/components/discover/RouteCard.tsx", "utf8");
const detail = readFileSync("src/components/discover/RouteDetail.tsx", "utf8");
const chrome = readFileSync(
  "src/components/discover/DiscoverExploreChrome.tsx",
  "utf8",
);
const discover = readFileSync("src/app/discover/page.tsx", "utf8");
const garage = readFileSync("src/app/garage/page.tsx", "utf8");

assert.ok(onboard.includes("addBikeBasic"), "Weiter creates a bike");
assert.ok(
  onboard.includes("useState<BikeCategory | null>(null)"),
  "no discipline preselected",
);
assert.ok(!onboard.includes('finish("discover")'), "no bike-optional discover fork");

assert.ok(
  reviews.includes("useState<1 | 2 | 3 | 4 | 5 | null>(null)"),
  "Stimmen stars start empty",
);
assert.ok(reviews.includes("STIMME_FORM_TAG_WIRES"), "form uses condition pills");
assert.ok(!reviews.includes("STIMME_TAG_WIRES.map"), "top/works not offered");

assert.ok(card.includes("bikeMatchLine"), "cards hide match without a bike");
assert.ok(!card.includes("matchScore}%"), "no naked match percent on cards");
assert.ok(detail.includes("bikeMatchLine"), "detail match needs a bike");
assert.ok(!detail.includes("matchScore}%"), "no naked match percent on detail");
assert.ok(detail.includes("emptyLayers"), "empty Popular/Photos/Elevation are one line");

assert.ok(
  chrome.includes("exploreFilterChipLabel"),
  "filter chip uses a real name",
);
assert.ok(
  !chrome.includes("`${d.filter} ${filterCount}`"),
  "no Filter 1 badge",
);
assert.ok(
  !discover.includes("d.fromHereStart"),
  "hybrid snap is not a rider action",
);

assert.equal(hofCopy("de").workshopTitle, "Garage");
assert.equal(hofCopy("en").workshopTitle, "Garage");
assert.equal(webChrome("de").hofNav.werkstatt, "Garage");
assert.equal(webChrome("en").hofNav.werkstatt, "Garage");
assert.ok(garage.includes("workshopTitle"), "garage page uses the shared title");
assert.notEqual(hofCopy("de").workshopTitle, "Workshop");
assert.notEqual(hofCopy("en").workshopTitle, "Workshop");

assert.equal(catalogCopy("en").stimmen.namePlaceholder, "Name");
assert.ok(!catalogCopy("en").stimmen.namePlaceholder.includes("Empty stays"));

const reasons = berlinLoopSuggestions([13.4, 52.52]).flatMap((r) => r.reasons);
assert.ok(
  !reasons.some((r) => /seed|lens|peek/i.test(r)),
  "berlin seeds have rider-facing reasons",
);
assert.ok(
  !riderFacingReasons(reasons).some((r) => /seed|lens|peek/i.test(r)),
);

console.log("uxHonesty.web.test.ts OK");
