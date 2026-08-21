/**
 * P0 Berlin/~60 Quick seeds — always available (not allowDemoContent-gated).
 * Loop honesty: linear excluded; closed seeds included.
 * Run: npx tsx src/lib/discover/berlinLoops.test.ts
 */
import {
  berlinLoopSuggestions,
  berlinSixtyMinLoopSuggestions,
  DEMO_CITY_CHIPS,
  getP0SeedById,
  parseSeedGeometry,
  parseSeedPoiStops,
} from "./berlinLoops";
import { rheinNeckarLoopSuggestions } from "./rheinNeckarLoops";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

const berlin: [number, number] = [13.405, 52.52];
const loops = berlinSixtyMinLoopSuggestions(berlin);

assert(loops.length >= 2, "at least Tempelhofer + another 45–75 loop");
assert(
  loops.some((r) => r.id.includes("tempelhofer")),
  "Tempelhofer present"
);
assert(
  loops.every((r) => r.durationMin >= 45 && r.durationMin <= 75),
  "all in 45–75 band"
);
assert(
  loops.every((r) => r.loop === true),
  "all ~60 Rundkurse are honest loops"
);
assert(
  !loops.some((r) => r.id === "seed-route-spree-commute"),
  "linear Spree commute excluded from Rundkurs lens"
);

// Full seed list still contains the linear route for non-loop contexts.
const all = berlinLoopSuggestions(berlin);
const spree = all.find((r) => r.id === "seed-route-spree-commute");
assert(spree != null && spree.loop === false, "linear seed kept with loop=false");
assert(
  all.some((r) => r.id === "seed-loop-tempelhofer-60" && r.loop),
  "closed Tempelhofer included with loop=true"
);

// DACH + RN loops available for Demo-Stadt / near-me honesty.
assert(
  loops.some((r) => r.id.includes("munich") || r.id.includes("froettmaning")) ||
    berlinSixtyMinLoopSuggestions([11.61, 48.183]).some((r) =>
      r.id.includes("munich")
    ),
  "DACH Munich loop reachable from München center"
);
const hd = berlinSixtyMinLoopSuggestions([8.694, 49.409]);
assert(
  hd.some((r) => r.id === "seed-loop-heidelberg-neckar-60" && r.loop),
  "Rhein-Neckar Heidelberg loop included"
);
assert(
  hd.every((r) => r.loop),
  "HD nearby ~60 list is loops-only"
);

assert(
  loops.some((r) => r.id.includes("mueggelberge")),
  "Berlin Müggelberge MTB gap seed present"
);
assert(
  berlinSixtyMinLoopSuggestions([10.139, 54.323]).some((r) =>
    r.id.includes("roenner")
  ),
  "Kiel Rönner Gehege trail seed present"
);
assert(
  berlinSixtyMinLoopSuggestions([7.749, 46.021]).some((r) =>
    r.id.includes("zermatt")
  ),
  "Zermatt local loop present"
);

assert(
  DEMO_CITY_CHIPS.some((c) => c.name === "Berlin") &&
    DEMO_CITY_CHIPS.some((c) => c.name === "Heidelberg") &&
    DEMO_CITY_CHIPS.some((c) => c.name === "Mannheim"),
  "Demo-Stadt chips include Berlin/HD/MA"
);

const tempel = all.find((r) => r.id === "seed-loop-tempelhofer-60");
assert(tempel != null, "Tempelhofer in full seed list");
assert(
  (tempel!.poiStops?.length ?? 0) >= 2,
  "Tempelhofer poi_stops survive seed mapping"
);
assert(
  tempel!.poiStops!.every((p) => p.atMin > 0 && p.title.length > 0 && p.kind.length > 0),
  "poi_stops have atMin/title/kind"
);
assert(
  tempel!.poiStops!.some((p) => p.kind === "viewpoint" || p.kind === "cafe"),
  "Tempelhofer keeps seed kinds"
);
const parsed = parseSeedPoiStops([
  { at_min: 12, title: "See", kind: "see", why_good: "Water stop." },
  { offset_min: 0, title: "Start", type: "trailhead" },
]);
assert(parsed.length === 2, "parseSeedPoiStops accepts at_min and offset_min");
assert(parsed[0].atMin === 12 && parsed[1].atMin === 0, "offset aliases");
assert(parsed[0].whyGood === "Water stop.", "why_good survives mapping");
assert(
  tempel!.poiStops!.some((p) => (p.whyGood?.length ?? 0) > 0),
  "Tempelhofer keeps why_good"
);

const rnLoops = rheinNeckarLoopSuggestions([8.694, 49.409]);
assert(rnLoops.length === 3, "RN loops catalog has three seeds");
assert(
  rnLoops.every((r) => (r.poiStops?.length ?? 0) >= 4),
  "RN loops JSON keeps poi_stops"
);
assert(
  rnLoops.every((r) => r.poiStops!.some((p) => (p.whyGood?.length ?? 0) > 0)),
  "RN loops keep why_good"
);

const munich = all.find((r) => r.id === "seed-loop-munich-froettmaning-60");
assert(Boolean(munich), "DACH Munich seed in catalog");
assert(
  (munich!.poiStops?.some((p) => (p.whyGood?.length ?? 0) > 0) ?? false),
  "Munich Nähe seed keeps why_good"
);

const titisee = getP0SeedById("seed-loop-titisee-feldberg-mtb-60");
assert(titisee != null, "Titisee seed resolves for public tour page");
assert(
  (titisee!.geometry?.length ?? 0) >= 2,
  "Titisee keeps stored geometry for the public page"
);
assert(
  parseSeedGeometry([[8.16, 47.91]]) == null,
  "single point is not a track"
);
assert(getP0SeedById("no-such-seed") == null, "unknown seed is null");

console.log("berlinLoops.test.ts OK");
