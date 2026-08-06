/**
 * Offline region queue + PMTiles prep (honest web stub)
 */
import {
  canDownloadOfflineOnWeb,
  clearOfflineRegionQueue,
  listOfflineRegionsWithQueue,
  offlinePackWithinBudget,
  offlineRegionsSummary,
  queuedOfflineBudgetMb,
} from "./offlineRegions";
import {
  getNativePmtilesPrepReport,
  mayRegisterPmtilesProtocol,
  nativePmtilesPrepSummaryDe,
  OFFLINE_REGION_MANIFESTS,
  resolvePackUrl,
} from "@/lib/platform/pmtilesPrep";
import { G0_MOBILE_STACK_CONFIRMED } from "@/lib/platform/g0TeamSetup";
import { WEB_PMTILES_REGISTER_FORBIDDEN } from "@/lib/platform/nativeContracts";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

assert(G0_MOBILE_STACK_CONFIRMED === false, "G-0 stays open");
assert(!canDownloadOfflineOnWeb(), "no PMTiles on web");
assert(!mayRegisterPmtilesProtocol(), "no protocol register");
assert(WEB_PMTILES_REGISTER_FORBIDDEN === true, "web forbidden");
assert(offlineRegionsSummary().includes("PMTiles"), "summary");
assert(listOfflineRegionsWithQueue().length >= 3, "regions from manifests");
assert(offlinePackWithinBudget(36, 1200), "budget ok");
assert(!offlinePackWithinBudget(500, 100), "budget fail");

const prep = getNativePmtilesPrepReport();
assert(prep.webCanDownload === false, "prep web");
assert(prep.manifests.length >= 3, "manifests");
assert(prep.postG0StepsDe.length >= 4, "post steps");
assert(nativePmtilesPrepSummaryDe().includes("G-0"), "prep summary");

const url = resolvePackUrl(OFFLINE_REGION_MANIFESTS[0]!);
assert(url.includes(".pmtiles"), "pack url");
assert(url.includes(OFFLINE_REGION_MANIFESTS[0]!.id), "pack id");

clearOfflineRegionQueue();
const budget = queuedOfflineBudgetMb();
assert(budget.sizeMb === 0, "empty budget");

console.log("offlineRegions.test OK", {
  regions: listOfflineRegionsWithQueue().length,
  mayRegister: mayRegisterPmtilesProtocol(),
});
