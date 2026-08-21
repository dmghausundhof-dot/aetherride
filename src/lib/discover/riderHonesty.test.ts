/**
 * Run: npx tsx src/lib/discover/riderHonesty.test.ts
 */
import assert from "node:assert/strict";
import { DEFAULT_ROUTE_FILTERS } from "../routing/routeFilters";
import {
  bikeMatchLine,
  exploreFilterChipLabel,
  riderFacingReason,
  riderFacingReasons,
} from "./riderHonesty";

assert.equal(
  riderFacingReason("Rundkurs-Seed"),
  "Rundkurs",
);
assert.equal(
  riderFacingReason("~60 Min Feierabend-Lens"),
  "~60 Min",
);
assert.equal(
  riderFacingReason("Nähe-Peek Rhein-Neckar"),
  "In der Nähe",
);
assert.ok(
  !riderFacingReasons([
    "Rundkurs-Seed",
    "~60 Min Feierabend-Lens",
    "Kuratierte Region-Seed",
  ]).some((r) => /seed|lens|peek/i.test(r)),
  "seed cards drop internal jargon",
);

assert.equal(bikeMatchLine(false, "Enduro", (l) => `passt zu deinem ${l}`), null);
assert.equal(
  bikeMatchLine(true, "Enduro", (l) => `passt zu deinem ${l}`),
  "passt zu deinem Enduro",
);
assert.equal(bikeMatchLine(true, "  ", (l) => `passt zu deinem ${l}`), null);

assert.equal(
  exploreFilterChipLabel(
    { ...DEFAULT_ROUTE_FILTERS, loopOnly: true },
    60,
    { filter: "Filter", loop: "Rundkurs" },
    1,
  ),
  "Rundkurs",
  "lone loop filter is named, not Filter 1",
);
assert.equal(
  exploreFilterChipLabel(
    { ...DEFAULT_ROUTE_FILTERS, loopOnly: true, sport: "gravel" },
    60,
    { filter: "Filter", loop: "Rundkurs" },
    2,
  ),
  "Filter",
  "mixed filters stay Filter, no count",
);

console.log("riderHonesty.test.ts OK");
