/**
 * Filter für Discover-Vorschläge — Unit-Smoke.
 * Ausführen: npx tsx src/lib/routing/routeFilters.test.ts
 */
import {
  DEFAULT_ROUTE_FILTERS,
  difficultyOptionsForProfile,
  filterRouteSuggestions,
  parseSurfaceKey,
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
  "D-60-LOOP-FILTER-01: loopOnly keeps only honest loops"
);
assert(
  !loops.some((r) => r.id === "b"),
  "D-60-LOOP-FILTER-01: linear Enduro excluded from Rundkurs"
);
assert(
  loops.some((r) => r.id === "a") && loops.some((r) => r.id === "c"),
  "D-60-LOOP-FILTER-01: closed Flow + City included under Rundkurs"
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
assert(mid.some((r) => r.id === "c"), "mid keeps unrated road/city");

const roadSport = filterRouteSuggestions(sample, {
  ...DEFAULT_ROUTE_FILTERS,
  sport: "road",
});
assert(roadSport.length === 1 && roadSport[0].id === "c", "sport is exclusive");

const ebikeSport = filterRouteSuggestions(sample, {
  ...DEFAULT_ROUTE_FILTERS,
  sport: "ebike",
});
assert(ebikeSport.length === 2, "ebike includes MTB family");
assert(
  ebikeSport.every(
    (r) => r.category === "mtb_trail" || r.category === "mtb_enduro",
  ),
  "ebike filter keeps MTB family (E-MTB parity)",
);

const away = filterRouteSuggestions(
  sample.map((r, i) => ({ ...r, distanceFromOriginKm: i === 0 ? 12 : 80 })),
  { ...DEFAULT_ROUTE_FILTERS, maxAwayKm: 20 },
);
assert(away.length === 1 && away[0].id === "a", "away km is Umkreis");

const asphalt = filterRouteSuggestions(sample, {
  ...DEFAULT_ROUTE_FILTERS,
  surfaceQuery: "asphalt",
});
assert(asphalt.length === 1 && asphalt[0].id === "c", "asphalt surface key");

assert(parseSurfaceKey("asphalt/bike-lane") === "asphalt", "catalog asphalt");
assert(parseSurfaceKey("gravel/asphalt") === "gravel", "catalog gravel");
assert(parseSurfaceKey("trail/forest") === "trail", "catalog trail");
assert(parseSurfaceKey("flow/compact") === "gravel", "legacy flow→gravel");

const near = filterRouteSuggestions(sample, {
  ...DEFAULT_ROUTE_FILTERS,
  maxDistanceKm: 22,
});
assert(near.length === 1 && near[0].id === "a", "distance max");

const mtbOpts = difficultyOptionsForProfile("mtb_allmountain");
assert(
  mtbOpts.some((o) => o.label === "Leicht" || o.label.includes("S0")),
  "MTB difficulty labels"
);
const roadOpts = difficultyOptionsForProfile("road");
assert(
  roadOpts.some((o) => o.label === "Entspannt" || o.label === "Sportlich"),
  "Road difficulty labels"
);

console.log("routeFilters.test.ts OK");
