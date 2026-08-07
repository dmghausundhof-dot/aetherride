/**
 * Filter für Discover-Vorschläge — Unit-Smoke.
 * Ausführen: npx tsx src/lib/routing/routeFilters.test.ts
 */
import {
  DEFAULT_ROUTE_FILTERS,
  filterRouteSuggestions,
} from "./routeFilters";
import type { RouteSuggestion } from "./suggestions";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

const sample: RouteSuggestion[] = [
  {
    id: "a",
    name: "Flow",
    category: "mtb_trail",
    distanceKm: 20,
    elevationM: 700,
    durationMin: 100,
    mtbScale: "S1–S2",
    surface: "flow/compact",
    loop: true,
    uncertainKmPct: 5,
    matchScore: 90,
    reasons: ["a", "b", "c"],
  },
  {
    id: "b",
    name: "Enduro",
    category: "mtb_enduro",
    distanceKm: 30,
    elevationM: 1300,
    durationMin: 160,
    mtbScale: "S2–S3",
    surface: "trail/root",
    loop: false,
    uncertainKmPct: 10,
    matchScore: 80,
    reasons: ["a", "b", "c"],
  },
];

const loops = filterRouteSuggestions(sample, {
  ...DEFAULT_ROUTE_FILTERS,
  loopOnly: true,
});
assert(loops.length === 1 && loops[0].id === "a", "loopOnly");

const alpine = filterRouteSuggestions(sample, {
  ...DEFAULT_ROUTE_FILTERS,
  elevation: "alpine",
});
assert(alpine.length === 1 && alpine[0].id === "b", "alpine elevation");

const mid = filterRouteSuggestions(sample, {
  ...DEFAULT_ROUTE_FILTERS,
  scale: "mid",
});
assert(mid.some((r) => r.id === "a"), "mid scale includes S1–S2");

console.log("routeFilters.test.ts OK");
