/**
 * Filter für Discover-Vorschläge — Unit-Smoke.
 * Ausführen: npx tsx src/lib/routing/routeFilters.test.ts
 */
import {
  DEFAULT_ROUTE_FILTERS,
  difficultyOptionsForProfile,
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
  {
    id: "c",
    name: "City",
    category: "road",
    distanceKm: 25,
    elevationM: 120,
    durationMin: 70,
    mtbScale: "—",
    surface: "asphalt",
    loop: true,
    uncertainKmPct: 2,
    matchScore: 70,
    reasons: ["a", "b", "c"],
  },
];

const loops = filterRouteSuggestions(sample, {
  ...DEFAULT_ROUTE_FILTERS,
  loopOnly: true,
});
assert(loops.length === 2, "loopOnly");
assert(
  loops.every((r) => r.loop === true),
  "loopOnly keeps only honest loops"
);
assert(
  !loops.some((r) => r.id === "b"),
  "linear Enduro excluded from Rundkurs filter"
);
assert(
  loops.some((r) => r.id === "a") && loops.some((r) => r.id === "c"),
  "closed Flow + City included under Rundkurs filter"
);

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

const roadSport = filterRouteSuggestions(sample, {
  ...DEFAULT_ROUTE_FILTERS,
  sport: "road",
});
assert(roadSport.length === 1 && roadSport[0].id === "c", "sport road");

const mtbOpts = difficultyOptionsForProfile("mtb_allmountain");
assert(
  mtbOpts.some((o) => o.label.includes("S0") || o.label.includes("S1")),
  "MTB difficulty labels"
);
const roadOpts = difficultyOptionsForProfile("road");
assert(
  roadOpts.some((o) => o.label === "Entspannt" || o.label === "Sportlich"),
  "Road difficulty labels"
);

console.log("routeFilters.test.ts OK");
