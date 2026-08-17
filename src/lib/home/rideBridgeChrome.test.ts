/**
 * Ride-Web /ride Kicker — Ausführen: npx tsx src/lib/home/rideBridgeChrome.test.ts
 */
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { HOF_COPY, hofCopy } from "./hofCopy";

assert.equal(HOF_COPY.ridePlannedKicker, "Geplante Tour");
assert.notEqual(
  HOF_COPY.ridePlannedKicker,
  HOF_COPY.ridePlannedKicker.toUpperCase(),
);
assert.equal(hofCopy("en").ridePlannedKicker, "Planned tour");
assert.equal(hofCopy("fr").ridePlannedKicker, "Tour prévu");
assert.equal(hofCopy("it").ridePlannedKicker, "Tour pianificato");
assert.equal(hofCopy("nl").ridePlannedKicker, "Geplande tocht");

const page = readFileSync("src/app/ride/page.tsx", "utf8");
assert(
  !page.includes("uppercase tracking"),
  "Ride planned-tour kicker stays sentence case",
);
assert(page.includes("tracking-wide"), "Ride kicker tracking stays");
assert(
  page.includes("copy.ridePlannedKicker"),
  "Ride kicker uses hofCopy, not a hardcoded cap string",
);
assert(
  !page.includes("uppercase"),
  "no CSS uppercase on Ride-Web chrome kickers",
);

console.log("rideBridgeChrome.test.ts OK");
