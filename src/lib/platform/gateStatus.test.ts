/**
 * Gate registry — Human-Gates offen; G-4 Mengen-Ziel separat
 */
import {
  allCriticalGatesOpen,
  G4_CATALOG_SPEC_TARGET,
  gatesOpenSummary,
  listGateStatuses,
} from "./gateStatus";
import { catalogStats } from "@/lib/catalog/bikes";
import { COMPONENT_CATALOG } from "@/lib/catalog/components";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

const rows = listGateStatuses({
  bikeCount: catalogStats().bikes,
  componentCount: COMPONENT_CATALOG.length,
});
assert(rows.length >= 7, "rows");
assert(allCriticalGatesOpen(), "human gates still open");
assert(gatesOpenSummary().includes("Offen"), "summary");
assert(
  COMPONENT_CATALOG.length >= G4_CATALOG_SPEC_TARGET,
  "G-4 component volume"
);
assert(rows.find((r) => r.id === "G-4")!.passed === true, "G-4 passed on volume");
assert(rows.find((r) => r.id === "G-0")!.passed === false, "G-0 still open");

console.log("gateStatus.test OK", {
  open: gatesOpenSummary(),
  components: COMPONENT_CATALOG.length,
});
