/**
 * Fail-closed debug UI + client notice sanitization (no Routing-Key chrome).
 * Run: npx tsx src/lib/routing/routingStatus.test.ts
 */
import {
  clientRoutingNotice,
  sanitizeClientRoutingNotice,
  showRoutingDebugUi,
} from "./routingStatus";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

// Contract of the gate (same predicate the export uses).
function gate(v: string | undefined): boolean {
  return v === "1";
}

assert(gate(undefined) === false, "unset → false");
assert(gate("") === false, "empty → false");
assert(gate("true") === false, '"true" must NOT enable');
assert(gate("0") === false, '"0" → false');
assert(gate("1") === true, 'only "1" → true');

// Live export respects current process.env (may already be set in CI).
const current = process.env.NEXT_PUBLIC_SHOW_ROUTING_DEBUG;
assert(
  showRoutingDebugUi() === (current === "1"),
  'showRoutingDebugUi matches NEXT_PUBLIC_SHOW_ROUTING_DEBUG === "1"'
);

// --- Notice sanitization ---
assert(sanitizeClientRoutingNotice(null) === null, "null stays null");
assert(sanitizeClientRoutingNotice("") === null, "empty → null");
assert(
  sanitizeClientRoutingNotice(
    "Routing-Key gesetzt — Live noch nicht verifiziert. Bei Fehlern Demo-Geometrie."
  ) === null,
  "Routing-Key notice scrubbed"
);
assert(
  sanitizeClientRoutingNotice(
    "Produktion: GRAPHHOPPER_API_KEY, VALHALLA_URL oder OSRM_URL setzen."
  ) === null,
  "API_KEY / env-name notice scrubbed"
);
assert(
  sanitizeClientRoutingNotice(
    "Routen nutzen Demo-Geometrie — Live-Routing nicht konfiguriert."
  ) ===
    "Routen nutzen Demo-Geometrie — Live-Routing nicht konfiguriert.",
  "safe demo notice kept"
);

// --- Prefer notice:null when live engine configured ---
assert(
  clientRoutingNotice({
    configured: true,
    engine: "graphhopper",
    liveVerified: false,
    publicOsrm: false,
  }) === null,
  "graphhopper configured → notice null (even unverified)"
);
assert(
  clientRoutingNotice({
    configured: true,
    engine: "osrm",
    liveVerified: false,
    publicOsrm: false,
  }) === null,
  "private osrm configured → notice null"
);
assert(
  clientRoutingNotice({
    configured: true,
    engine: "valhalla",
    liveVerified: true,
    publicOsrm: false,
  }) === null,
  "valhalla configured → notice null"
);
assert(
  clientRoutingNotice({
    configured: false,
    engine: "demo",
    liveVerified: false,
    publicOsrm: false,
  }) != null,
  "unconfigured demo may show notice"
);
const publicNotice = clientRoutingNotice({
  configured: true,
  engine: "osrm",
  liveVerified: true,
  publicOsrm: true,
});
assert(publicNotice != null, "public OSRM may notice");
assert(
  !/API_KEY|Routing-Key|GRAPHHOPPER/i.test(publicNotice!),
  "public OSRM notice has no key chrome"
);

console.log("routingStatus.test.ts OK");
