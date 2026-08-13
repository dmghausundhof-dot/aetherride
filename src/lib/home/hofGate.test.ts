import type { RouteSuggestion } from "@/lib/routing/suggestions";
import { isTrailHeavyLoop, pickHofGate } from "./hofGate";

function loop(
  partial: Partial<RouteSuggestion> & { id: string; name: string }
): RouteSuggestion {
  return {
    category: "urban",
    distanceKm: 18,
    elevationM: 40,
    durationMin: 55,
    mtbScale: "—",
    surface: "asphalt 90% / path 10%",
    loop: true,
    uncertainKmPct: 12,
    matchScore: 82,
    reasons: ["Rundkurs-Seed", "~60 Min", "Nähe"],
    center: [9.993, 53.551],
    ...partial,
  };
}

const hamburg = loop({
  id: "seed-loop-hamburg-alster-60",
  name: "Außenalster & Stadtpark",
  center: [9.993, 53.551],
});
const munich = loop({
  id: "seed-loop-munich-froettmaning-60",
  name: "Fröttmaninger Berg & Isar",
  category: "gravel",
  surface: "gravel 55% / asphalt 35%",
  center: [11.61, 48.183],
  durationMin: 65,
});
const trail = loop({
  id: "seed-loop-grunewald-trail-60",
  name: "Grunewald Trails",
  category: "mtb_trail",
  surface: "trail 80%",
  center: [13.2, 52.48],
});

if (!isTrailHeavyLoop(trail) || !isTrailHeavyLoop(munich)) {
  throw new Error("gravel/trail loops must be trail-heavy");
}
if (isTrailHeavyLoop(hamburg)) {
  throw new Error("Alster asphalt must not be trail-heavy");
}

const fromHamburg = pickHofGate({
  loops: [hamburg, munich, trail],
  lat: 53.551,
  lng: 9.993,
});
if (fromHamburg.seed?.id !== hamburg.id) {
  throw new Error(
    `Hamburg GPS must pick Alster, got ${fromHamburg.seed?.id}`
  );
}

const noGps = pickHofGate({
  loops: [hamburg, munich],
});
if (noGps.honesty !== "none" || noGps.seed) {
  throw new Error("without GPS, never invent a default landscape");
}

const wetBerlin = pickHofGate({
  loops: [trail],
  lat: 52.52,
  lng: 13.405,
  trailsWet: true,
});
if (wetBerlin.honesty !== "wetClosed") {
  throw new Error("wet trails without asphalt alt must close the gate");
}

const wetHamburg = pickHofGate({
  loops: [hamburg, trail],
  lat: 53.551,
  lng: 9.993,
  trailsWet: true,
});
if (wetHamburg.seed?.id !== hamburg.id) {
  throw new Error("wet Hamburg may keep asphalt Alster");
}

const tooFar = pickHofGate({
  loops: [munich],
  lat: 53.551,
  lng: 9.993,
});
if (tooFar.honesty !== "none") {
  throw new Error("Hamburg must not see Munich as the hour at the gate");
}

console.log("hofGate.test.ts ok");
