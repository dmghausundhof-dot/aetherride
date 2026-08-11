/**
 * P0 curated Berlin+RN seeds — always available (not allowDemoContent-gated).
 * source:"seed" (never "demo"); ≥3 honest ~45–75 loops per region.
 * Run: npx tsx src/lib/discover/curatedP0Seeds.test.ts
 */
import {
  curatedP0CatalogSuggestions,
  curatedSixtyMinLoopSuggestions,
} from "./curatedP0Seeds";
import { berlinSixtyMinLoopSuggestions } from "./berlinLoops";
import { rheinNeckarSixtyMinLoopSuggestions } from "./rheinNeckarLoops";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

const berlin: [number, number] = [13.405, 52.52];
const heidelberg: [number, number] = [8.694, 49.409];

const berlinSixty = berlinSixtyMinLoopSuggestions(berlin);
assert(berlinSixty.length >= 3, "Berlin: ≥3 ~45–75 honest loops");
assert(
  berlinSixty.every((r) => r.loop === true),
  "Berlin sixty: loops only"
);
assert(
  berlinSixty.every((r) => r.source === "seed"),
  "Berlin sixty: source seed (not demo)"
);
assert(
  berlinSixty.every((r) => r.durationMin >= 45 && r.durationMin <= 75),
  "Berlin sixty: 45–75 band"
);
assert(
  berlinSixty.some((r) => r.id.includes("tempelhofer")),
  "Tempelhofer present at Berlin"
);
assert(
  !berlinSixty.some((r) => r.id.includes("spree-commute")),
  "linear Spree commute excluded from ~60 loops"
);

const rnSixty = rheinNeckarSixtyMinLoopSuggestions(heidelberg);
assert(rnSixty.length >= 3, "Rhein-Neckar: ≥3 ~45–75 honest loops");
assert(
  rnSixty.every((r) => r.loop === true && r.source === "seed"),
  "RN sixty: honest seed loops"
);

const hdSixty = curatedSixtyMinLoopSuggestions(heidelberg);
assert(
  hdSixty.some((r) => (r.distanceFromOriginKm ?? 999) <= 35),
  "Heidelberg: nearby RN seed within 35 km"
);
assert(
  hdSixty.some((r) => r.id.includes("hd-") || r.id.includes("ma-")),
  "RN seed ids present"
);
assert(
  hdSixty.every((r) => r.source === "seed" && r.source !== ("demo" as never)),
  "curated sixty never source demo"
);
assert(
  hdSixty.every((r) => r.loop),
  "curated sixty: loops only (#37)"
);

const catalog = curatedP0CatalogSuggestions(berlin);
assert(catalog.length >= 6, "catalog fallback ≥6 Berlin route seeds");
assert(
  catalog.every((r) => r.source === "seed"),
  "catalog fallback source seed"
);
assert(
  catalog.some((r) => r.id.includes("tempelhofer")),
  "catalog includes Tempelhofer"
);
assert(
  catalog.some((r) => r.id.includes("hd-") || r.id.includes("ma-")),
  "catalog includes RN"
);

console.log("curatedP0Seeds.test.ts OK");
