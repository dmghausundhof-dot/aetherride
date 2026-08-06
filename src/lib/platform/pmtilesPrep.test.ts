/**
 * PMTiles Prep — Unit-Tests (G-0 bleibt false)
 */
import { G0_MOBILE_STACK_CONFIRMED } from "./g0TeamSetup";
import {
  getNativePmtilesPrepReport,
  isManifestStale,
  mayRegisterPmtilesProtocol,
  OFFLINE_REGION_MANIFESTS,
  PMTILES_STALE_AFTER_DAYS,
} from "./pmtilesPrep";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

assert(G0_MOBILE_STACK_CONFIRMED === false, "g0 open");
assert(!mayRegisterPmtilesProtocol(), "register blocked");
assert(PMTILES_STALE_AFTER_DAYS === 90, "stale days");

const m = OFFLINE_REGION_MANIFESTS[0]!;
assert(
  !isManifestStale(m, new Date("2026-08-10T00:00:00.000Z")),
  "fresh in Aug"
);
assert(
  isManifestStale(m, new Date("2027-01-01T00:00:00.000Z")),
  "stale after 90d"
);

const report = getNativePmtilesPrepReport();
assert(report.g0Confirmed === false, "report g0");
assert(report.mayRegisterMapProtocol === false, "report register");

console.log("pmtilesPrep.test OK", {
  manifests: report.manifests.length,
  note: report.noteDe,
});
