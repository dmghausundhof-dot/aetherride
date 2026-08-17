import type { RouteSuggestion } from "@/lib/routing/suggestions";
import {
  formatHofGateAway,
  hofGateEmptyTitle,
  isTrailHeavyLoop,
  pickHofGate,
} from "./hofGate";

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

const innsbruckTrail = loop({
  id: "seed-loop-innsbruck-nordkette-mtb-60",
  name: "Nordkette MTB",
  category: "mtb_am",
  surface: "trail 50%",
  center: [11.404, 47.28],
});
const innsbruckRoad = loop({
  id: "seed-loop-innsbruck-inn-road-60",
  name: "Inn-Radweg",
  category: "road",
  surface: "asphalt 90%",
  center: [11.39, 47.26],
});
const mtbAtInnsbruck = pickHofGate({
  loops: [innsbruckRoad, innsbruckTrail],
  lat: 47.269,
  lng: 11.404,
  preferred: "mtb_am",
});
if (mtbAtInnsbruck.seed?.id !== innsbruckTrail.id) {
  throw new Error(
    `Innsbruck MTB must pick Nordkette, got ${mtbAtInnsbruck.seed?.id}`
  );
}
const roadAtInnsbruck = pickHofGate({
  loops: [innsbruckRoad, innsbruckTrail],
  lat: 47.269,
  lng: 11.404,
  preferred: "road",
});
if (roadAtInnsbruck.seed?.id !== innsbruckRoad.id) {
  throw new Error(
    `Innsbruck road must pick Inn-Radweg, got ${roadAtInnsbruck.seed?.id}`
  );
}

const awayCopy = { near: "unter 1 km", km: (n: number) => `${n} km` };
if (formatHofGateAway(undefined, awayCopy) != null) {
  throw new Error("unknown distance must stay quiet");
}
if (formatHofGateAway(0.4, awayCopy) !== "unter 1 km") {
  throw new Error("under 1 km must not say 0 km");
}
if (formatHofGateAway(6.4, awayCopy) !== "6 km") {
  throw new Error(`6.4 km should round to 6 km, got ${formatHofGateAway(6.4, awayCopy)}`);
}

const emptyCopy = {
  gateWetClosed: "Trails nass — kein ehrlicher Asphalt-Rundkurs in der Nähe",
  noHonestLoop: "Kein ehrlicher Trail-Rundkurs",
};
if (hofGateEmptyTitle("wetClosed", emptyCopy) !== emptyCopy.gateWetClosed) {
  throw new Error("wet-closed must not say no loop exists");
}
if (hofGateEmptyTitle("none", emptyCopy) !== emptyCopy.noHonestLoop) {
  throw new Error("none must keep no-loop copy");
}

console.log("hofGate.test.ts ok");
