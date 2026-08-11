/**
 * P0 Berlin ~60 Quick seeds — always available (not allowDemoContent-gated).
 * Run: npx tsx src/lib/discover/berlinLoops.test.ts
 */
import {
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
  loops.some((r) => r.loop),
  "includes true loops"
);
assert(
  DEMO_CITY_CHIPS.some((c) => c.name === "Berlin") &&
    DEMO_CITY_CHIPS.some((c) => c.name === "Heidelberg") &&
    DEMO_CITY_CHIPS.some((c) => c.name === "Mannheim"),
  "Demo-Stadt chips include Berlin/HD/MA"
);

console.log("berlinLoops.test.ts OK");
