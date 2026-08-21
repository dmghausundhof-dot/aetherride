/**
 * Run: npx tsx src/lib/i18n/hofDoorMeta.test.ts
 */
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const garage = readFileSync("src/app/garage/layout.tsx", "utf8");
assert.ok(garage.includes("hofDoorMeta"), "garage door meta");
assert.ok(garage.includes("workshopTitle"), "garage title from hofCopy");
assert.ok(!garage.includes("Uhr koppeln nur in der App"), "no fixed German garage meta");

const home = readFileSync("src/app/home/layout.tsx", "utf8");
assert.ok(home.includes("homeTitle"), "home tab title");

const library = readFileSync("src/app/library/layout.tsx", "utf8");
assert.ok(library.includes("libraryTitle"), "library tab title");

const discover = readFileSync("src/app/discover/layout.tsx", "utf8");
assert.ok(discover.includes("mapTitle"), "map tab title");
assert.ok(
  !discover.includes("Kein Google-Layer"),
  "discover meta is not a fixed German sentence",
);

const planner = readFileSync("src/app/planner/layout.tsx", "utf8");
assert.ok(planner.includes("plannerTitle"), "planner tab title");

const shop = readFileSync("src/app/shop/layout.tsx", "utf8");
assert.ok(shop.includes("hofDoorMeta"), "shop uses request language");
assert.ok(!shop.includes("HOF_COPY.shopTitle"), "shop is not frozen German");

const activities = readFileSync("src/app/activities/layout.tsx", "utf8");
assert.ok(activities.includes("hofDoorMeta"), "activities uses cookie+accept");

const profile = readFileSync("src/app/profile/layout.tsx", "utf8");
assert.ok(profile.includes("profileTitle"), "profile tab title");

const share = readFileSync("src/app/share/layout.tsx", "utf8");
assert.ok(share.includes("shareCopy"), "share meta from shareCopy");

const open = readFileSync("src/app/open/layout.tsx", "utf8");
assert.ok(open.includes("openRideCopy"), "open ride title");
assert.ok(open.includes("rideBridgeHint"), "open ride stays app-only");

const publicLayout = readFileSync("src/app/u/layout.tsx", "utf8");
assert.ok(publicLayout.includes("publicTitle"), "public profile layout");

const handlePage = readFileSync("src/app/u/[handle]/page.tsx", "utf8");
assert.ok(handlePage.includes("publicHint"), "missing handle uses profileCopy");
assert.ok(!handlePage.includes("Öffentliches FlowLine-Profil"), "no fixed German fallback");

const chat = readFileSync("src/app/chat/layout.tsx", "utf8");
assert.ok(chat.includes("chatCopy"), "chat tab title");

const postRide = readFileSync("src/app/post-ride/layout.tsx", "utf8");
assert.ok(postRide.includes("postRideTitle"), "post-ride tab title");

const privacy = readFileSync("src/app/privacy/layout.tsx", "utf8");
assert.ok(privacy.includes("privacyTitle"), "privacy tab title");

console.log("hofDoorMeta.test.ts ok");
