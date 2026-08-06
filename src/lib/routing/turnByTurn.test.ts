/**
 * Turn-by-Turn from PlannedRoute
 */
import {
  buildManeuversFromPlanned,
  nextTbtAnnouncement,
} from "./turnByTurn";
import type { PlannedRoute } from "./rideHandoff";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

const planned: PlannedRoute = {
  id: "p1",
  name: "Testtrail",
  profile: "MTB_TRAIL",
  source: "discover_suggestion",
  distanceM: 12000,
  elevationGainM: 500,
  durationMin: 90,
  geometryLngLat: Array.from({ length: 40 }, (_, i) => [
    12.15 + i * 0.002,
    47.45 + Math.sin(i / 5) * 0.01,
  ]),
  mtbScale: "S2",
};

const man = buildManeuversFromPlanned(planned);
assert(man[0].type === "start", "start");
assert(man[man.length - 1].type === "arrive", "arrive");
assert(man.length >= 3, "has turns");

const next = man.find((m) => m.distanceAlongM > 100)!;
assert(!!next, "next man");
const along = next.distanceAlongM - 150;
const ann = nextTbtAnnouncement({
  maneuvers: man,
  distanceAlongM: along,
  speedKmh: 18,
  lang: "de",
});
assert(ann != null && ann.text.length > 0, "cue");
const again = nextTbtAnnouncement({
  maneuvers: man,
  distanceAlongM: along,
  speedKmh: 18,
  lang: "de",
  lastKey: ann!.key,
});
assert(again == null, "dedupe");

console.log("turnByTurn.test OK", { maneuvers: man.length });
