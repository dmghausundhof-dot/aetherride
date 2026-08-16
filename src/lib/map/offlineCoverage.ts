/**
 * Offline routing packs vs named envelopes — counts from catalog + registry.
 * Never hardcode “83 packs” on the website.
 */

import { DACH_ENVELOPE_REGIONS } from "@/lib/coverage/dachRegions";
import {
  fetchPublishedCatalog,
  listMergedOfflineCatalog,
  summarizeOfflinePacks,
} from "@/lib/routing/offlinePacks";

export type OfflineCoverageStats = {
  catalogOk: boolean;
  readyPacks: number | null;
  stubPacks: number | null;
  envelopeRegions: number;
};

export { summarizeOfflinePacks };

/** CDN catalog first; envelopes always from the DACH registry (named holes). */
export async function loadOfflineCoverageStats(): Promise<OfflineCoverageStats> {
  const envelopeRegions = DACH_ENVELOPE_REGIONS.length;
  try {
    const published = await fetchPublishedCatalog();
    if (published?.length) {
      const summary = summarizeOfflinePacks(published);
      return {
        catalogOk: true,
        readyPacks: summary.ready,
        stubPacks: summary.stub,
        envelopeRegions,
      };
    }
    const merged = await listMergedOfflineCatalog();
    if (!merged.length) {
      return {
        catalogOk: false,
        readyPacks: null,
        stubPacks: null,
        envelopeRegions,
      };
    }
    const summary = summarizeOfflinePacks(merged);
    return {
      catalogOk: true,
      readyPacks: summary.ready,
      stubPacks: summary.stub,
      envelopeRegions,
    };
  } catch {
    return {
      catalogOk: false,
      readyPacks: null,
      stubPacks: null,
      envelopeRegions,
    };
  }
}
