/**
 * Offline region queue (honest web stub)
 */
import {
  canDownloadOfflineOnWeb,
  listOfflineRegionsWithQueue,
  offlinePackWithinBudget,
  offlineRegionsSummary,
} from "./offlineRegions";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

assert(!canDownloadOfflineOnWeb(), "no PMTiles on web");
assert(offlineRegionsSummary().includes("PMTiles"), "summary");
assert(listOfflineRegionsWithQueue().length >= 2, "regions");
assert(offlinePackWithinBudget(36, 1200), "budget ok");
assert(!offlinePackWithinBudget(500, 100), "budget fail");

console.log("offlineRegions.test OK");
