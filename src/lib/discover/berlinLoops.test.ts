/**
 * P0 Berlin/~60 Quick seeds — always available (not allowDemoContent-gated).
 * Loop honesty: linear excluded; closed seeds included.
 * Run: npx tsx src/lib/discover/berlinLoops.test.ts
 */
import {
  berlinLoopSuggestions,
  berlinSixtyMinLoopSuggestions,
  DEMO_CITY_CHIPS,
} from "./berlinLoops";

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
  DEMO_CITY_CHIPS.some((c) => c.name === "Berlin") &&
    DEMO_CITY_CHIPS.some((c) => c.name === "Heidelberg") &&
    DEMO_CITY_CHIPS.some((c) => c.name === "Mannheim"),
  "Demo-Stadt chips include Berlin/HD/MA"
);

console.log("berlinLoops.test.ts OK");
