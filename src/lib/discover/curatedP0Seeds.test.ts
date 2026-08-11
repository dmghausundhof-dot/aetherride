/**
 * P0 curated Berlin+RN seeds — always available (not allowDemoContent-gated).
 * Run: npx tsx src/lib/discover/curatedP0Seeds.test.ts
 */
import {
  curatedP0CatalogSuggestions,
  curatedSixtyMinLoopSuggestions,
} from "./curatedP0Seeds";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

const berlin: [number, number] = [13.405, 52.52];
const heidelberg: [number, number] = [8.694, 49.409];

const berlinSixty = curatedSixtyMinLoopSuggestions(berlin);
assert(berlinSixty.length >= 2, "Berlin: at least Tempelhofer + another");
assert(
  berlinSixty.some((r) => r.id.includes("tempelhofer")),
  "Tempelhofer present at Berlin"
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

const catalog = curatedP0CatalogSuggestions(berlin);
assert(catalog.length >= 6, "catalog fallback ≥6 Berlin route seeds");
assert(
  catalog.some((r) => r.id.includes("tempelhofer")),
  "catalog includes Tempelhofer"
);
assert(
  catalog.some((r) => r.id.includes("hd-") || r.id.includes("ma-")),
  "catalog includes RN"
);

console.log("curatedP0Seeds.test.ts OK");
