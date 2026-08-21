/**
 * npx tsx src/lib/garage/lastRideHero.test.ts
 */
import { lastRideHeroLine, lastRideHeroLineForBike } from "./lastRideHero";
import { addCategories, categoryPickGroups } from "./bikeAssist";
import type { Ride } from "@/types";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

assert(lastRideHeroLine(undefined) === null, "no ride");
const withKm = {
  id: "r1",
  bikeId: "b1",
  sportType: "road",
  startTime: "2026-08-01T10:00:00.000Z",
  endTime: "2026-08-01T12:00:00.000Z",
  distanceM: 12400,
  elevationGainM: 0,
  durationSec: 2400,
  summaryMetrics: {},
} as Ride;
assert(lastRideHeroLine(withKm) === "Zuletzt 12.4 km", "km line");
assert(
  lastRideHeroLine({ ...withKm, elevationGainM: 140 }) ===
    "Zuletzt 12.4 km · 140 hm",
  "climb when stored"
);
assert(
  lastRideHeroLine({ ...withKm, distanceM: 0 }) ===
    "Zuletzt unterwegs — ohne GPS-Strecke",
  "no fake km"
);
assert(lastRideHeroLineForBike([withKm], "b2") === null, "other bike");
assert(lastRideHeroLineForBike([withKm], "b1") === "Zuletzt 12.4 km", "match");
const live = {
  ...withKm,
  id: "live",
  startTime: "2026-08-16T10:00:00.000Z",
  endTime: undefined,
  distanceM: 900,
};
assert(
  lastRideHeroLineForBike([live, withKm], "b1") === "Zuletzt 12.4 km",
  "skip live session"
);
assert(lastRideHeroLineForBike([live], "b1") === null, "live only");

assert(addCategories("muscle").includes("mtb_am"), "add has mtb");
assert(!addCategories("muscle").includes("mtb_enduro"), "add hides enduro");
assert(addCategories("ebike")[1] === "etrekking", "e-trekking in add");

const muscle = categoryPickGroups("muscle");
assert(muscle[0].id === "everyday", "alltag first");
assert(muscle[0].categories[0] === "urban", "city first");
assert(muscle[0].categories.includes("cargo"), "cargo in alltag");
assert(!muscle[0].categories.includes("mtb_am"), "no mtb in alltag");

const ebike = categoryPickGroups("ebike");
assert(ebike[0].categories[0] === "etrekking", "e-trekking first");
assert(
  ebike.find((g) => g.id === "trail")?.categories.join() === "emtb",
  "e-trail is emtb"
);

assert(
  !muscle.some((g) => g.categories.includes("hiking")),
  "hiking nicht in Pick-Gruppen"
);
assert(
  !addCategories("muscle").includes("hiking"),
  "hiking nicht beim Anlegen"
);

console.log("lastRideHero.test.ts ok");
