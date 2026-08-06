/**
 * Gate registry — alle kritischen Flags bleiben offen
 */
import {
  allCriticalGatesOpen,
  gatesOpenSummary,
  listGateStatuses,
} from "./gateStatus";
import { catalogStats } from "@/lib/catalog/bikes";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

const rows = listGateStatuses({ bikeCount: catalogStats().bikes });
assert(rows.length >= 7, "rows");
assert(allCriticalGatesOpen(), "no fake closes");
assert(gatesOpenSummary().includes("Offen"), "summary");
assert(rows.find((r) => r.id === "G-4")!.passed === false, "G-4 seed open");

console.log("gateStatus.test OK", { open: gatesOpenSummary() });
